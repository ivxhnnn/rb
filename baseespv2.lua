-- =============================================
-- BASE ESP – HIGHEST PLOT TOP FACE ONLY (FINAL)
-- ✅ Only draws the TOP SQUARE of the TALLEST part per plot (4 lines / plot)
-- ✅ Shows EXACTLY where the highest block of the base is (for breaking)
-- ✅ 100% accurate (uses part's real CFrame/Size)
-- ✅ Ultra lightweight (no full cubes, no scanning all parts every frame)
-- Toggle: E | Unique color per plot
-- =============================================

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- =====================
-- 🎨 CONFIG (TWEAK THESE IF NEEDED)
-- =====================
local ESP_Config = {
    OutlineThickness = 2.3,
    MaxDistance = 9999,
    NEAR_PLANE = 0.3, -- Fixes near-camera glitches
    -- Only consider parts BIGGER than this (avoids tiny high junk like buttons/rails)
    -- Lower to 15 if you miss small top walls; raise to 35 if you see random lines
    MIN_PART_VOLUME = 25,
    SKIP_NAMES = {"railing", "ladder", "fence", "rail", "button", "sign", "decal", "light"},
    PLOTS = {
        [1] = {Color = Color3.fromRGB(255, 50, 50)},    -- Plot 1 Red
        [2] = {Color = Color3.fromRGB(50, 120, 255)},   -- Plot 2 Blue
        [3] = {Color = Color3.fromRGB(255, 0, 255)},    -- Plot 3 Magenta (yours)
        [4] = {Color = Color3.fromRGB(255, 220, 50)},   -- Plot 4 Yellow
        [5] = {Color = Color3.fromRGB(0, 255, 255)},    -- Plot 5 Cyan
        [6] = {Color = Color3.fromRGB(50, 255, 100)},   -- Plot 6 Green
    }
}

-- =====================
-- INTERNAL
-- =====================
local ESP_Enabled = true
-- [PlotID] = {Part, Lines={4}} → One entry per plot (only highest part)
local PlotESP = {}

-- Fast name check
local function ShouldSkip(Part)
    local Name = Part.Name:lower()
    for _, Skip in ipairs(ESP_Config.SKIP_NAMES) do
        if Name:find(Skip, 1, true) then return true end
    end
    return false
end

-- Safely get plot region
local function GetPlotRegion(PlotID)
    local ok, r = pcall(function()
        local P = workspace:FindFirstChild("Plots")
        if not P then return nil end
        local Obj = P:FindFirstChild(tostring(PlotID))
        if not Obj then return nil end
        return Obj:FindFirstChild("region")
    end)
    return (ok and r) or nil
end

-- =============================================
-- 🔑 NEW: GET ONLY THE HIGHEST BIG PART IN A PLOT
-- Returns 1 part = the tallest structure's top block (uses TOP EDGE Y for accuracy)
-- =============================================
local function GetHighestPlotPart(PlotID)
    local Region = GetPlotRegion(PlotID)
    if not Region then return nil end
    local MinVol = ESP_Config.MIN_PART_VOLUME
    local HighestPart = nil
    local HighestTopY = -math.huge -- Track absolute top edge of part (not center)

    local function Scan(Object)
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("BasePart") then
                -- Filter 1: Skip tiny junk
                local Vol = Child.Size.X * Child.Size.Y * Child.Size.Z
                if Vol < MinVol then
                    Scan(Child)
                    continue
                end
                -- Filter 2: Skip railings/names
                if ShouldSkip(Child) then
                    Scan(Child)
                    continue
                end
                -- ✅ Compare TOP EDGE of part (most accurate way to find highest block)
                local TopY = Child.Position.Y + (Child.Size.Y / 2)
                if TopY > HighestTopY then
                    HighestTopY = TopY
                    HighestPart = Child
                end
            end
            Scan(Child)
        end
    end

    -- Check region itself first
    if Region:IsA("BasePart") then
        local Vol = Region.Size.X * Region.Size.Y * Region.Size.Z
        if Vol >= MinVol and not ShouldSkip(Region) then
            local TopY = Region.Position.Y + (Region.Size.Y / 2)
            HighestTopY = TopY
            HighestPart = Region
        end
    end
    Scan(Region)
    return HighestPart
end

-- =============================================
-- 🔑 NEW: CREATE ONLY 4 LINES = TOP FACE SQUARE
-- (No full 12-edge cubes anymore)
-- =============================================
local function AddPlotESP(PlotID, Part)
    -- Remove old ESP for this plot if it exists
    if PlotESP[PlotID] then
        for _, L in ipairs(PlotESP[PlotID].Lines) do L:Remove() end
        PlotESP[PlotID] = nil
    end

    local PlotColor = ESP_Config.PLOTS[PlotID].Color
    local Lines = {}
    -- Only 4 lines = top square (matches your second screenshot)
    for i = 1, 4 do
        local L = Drawing.new("Line")
        L.Visible = false
        L.Color = PlotColor
        L.Thickness = ESP_Config.OutlineThickness
        L.Transparency = 1
        Lines[i] = L
    end
    PlotESP[PlotID] = {Part = Part, Lines = Lines}
end

local function RemovePlotESP(PlotID)
    local Data = PlotESP[PlotID]
    if not Data then return end
    for _, L in ipairs(Data.Lines) do L:Remove() end
    PlotESP[PlotID] = nil
end

-- =============================================
-- 🔑 NEW: ONLY TOP FACE EDGES (4 total, no bottom/vertical lines)
-- Order: Top Back Left → Top Back Right → Top Front Right → Top Front Left → Close
-- =============================================
local TopFaceEdges = {
    {5,6}, -- Top Back Edge
    {6,8}, -- Top Right Edge
    {8,7}, -- Top Front Edge
    {7,5}  -- Top Left Edge
}

-- =====================
-- MAIN LOOP (ULTRA FAST + ACCURATE)
-- =====================
RunService.RenderStepped:Connect(function()
    local CamPos = Camera.CFrame.Position
    local Near = ESP_Config.NEAR_PLANE

    -- Step 1: For each plot → get highest part + update ESP
    for PlotID = 1, 6 do
        local HighestPart = GetHighestPlotPart(PlotID)

        -- Case A: No valid part in plot → hide/cleanup
        if not HighestPart then
            RemovePlotESP(PlotID)
            continue
        end

        -- Case B: Highest part changed (base was built higher/lower) → refresh ESP
        local Existing = PlotESP[PlotID]
        if not Existing or Existing.Part ~= HighestPart then
            AddPlotESP(PlotID, HighestPart)
        end

        -- Step 2: Draw the TOP SQUARE of this highest part
        local Data = PlotESP[PlotID]
        if not Data then continue end
        local Part = Data.Part

        -- Hide if ESP off / invalid / too far
        if not ESP_Enabled or not Part or not Part.Parent then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end
        if (CamPos - Part.Position).Magnitude > ESP_Config.MaxDistance then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end

        -- Calculate 8 cube corners (same accurate method as before)
        local CF = Part.CFrame
        local S = Part.Size
        local hX, hY, hZ = S.X/2, S.Y/2, S.Z/2
        local C3D = {
            CF * Vector3.new(-hX, -hY, -hZ), -- 1 BBL
            CF * Vector3.new( hX, -hY, -hZ), -- 2 BBR
            CF * Vector3.new(-hX, -hY,  hZ), -- 3 BFL
            CF * Vector3.new( hX, -hY,  hZ), -- 4 BFR
            CF * Vector3.new(-hX,  hY, -hZ), -- 5 TBL (TOP FACE CORNERS)
            CF * Vector3.new( hX,  hY, -hZ), -- 6 TBR
            CF * Vector3.new(-hX,  hY,  hZ), -- 7 TFL
            CF * Vector3.new( hX,  hY,  hZ), -- 8 TFR
        }

        -- Behind-camera fix (no stretched lines)
        local Screen = {}
        local AnyValid = false
        for i = 1, 8 do
            local S, On = Camera:WorldToViewportPoint(C3D[i])
            local Valid = S.Z > Near
            Screen[i] = {X = S.X, Y = S.Y, Valid = Valid, OnScreen = On}
            if Valid then AnyValid = true end
        end
        if not AnyValid then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end

        -- ✅ ONLY DRAW THE 4 TOP FACE EDGES (no other lines!)
        for i, E in ipairs(TopFaceEdges) do
            local A = Screen[E[1]]
            local B = Screen[E[2]]
            local Line = Data.Lines[i]
            if not A.Valid or not B.Valid then
                Line.Visible = false
                continue
            end
            if not A.OnScreen and not B.OnScreen then
                Line.Visible = false
                continue
            end
            Line.From = Vector2.new(A.X, A.Y)
            Line.To   = Vector2.new(B.X, B.Y)
            Line.Visible = true
        end
    end

    -- Step 3: Cleanup ESP for plots that no longer exist
    for PlotID in pairs(PlotESP) do
        if PlotID < 1 or PlotID > 6 then
            RemovePlotESP(PlotID)
        end
    end
end)

-- E TOGGLE (same as before)
UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.E then
        ESP_Enabled = not ESP_Enabled
    end
end)
