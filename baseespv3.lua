-- =============================================
-- ORIGINAL 12-LINE ESP – HIGHEST PART ONLY (FULL CUBE PER PLOT)
-- ✅ FULL 12 EDGES / COMPLETE CUBE (exactly your original)
-- ✅ 99% YOUR ORIGINAL SCRIPT – all tracking/filtering/alignment UNCHANGED
-- ✅ ONLY NEW: Picks 1 HIGHEST BIG PART per plot → draws its full cube (no other parts)
-- ✅ Keeps every original fix: volume filter, name skip, behind-camera, near-plane
-- Toggle: E | Unique color per plot
-- =============================================

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- =====================
-- 🎨 ORIGINAL CONFIG (100% UNCHANGED)
-- =====================
local ESP_Config = {
    OutlineThickness = 2.3,
    MaxDistance = 9999,
    NEAR_PLANE = 0.3, -- Fixes near-camera glitches
    -- ✅ ORIGINAL MAGIC NUMBER – KEEP THIS AS IS (why your tracking never failed)
    MIN_PART_VOLUME = 25,
    -- Original name blacklist (unchanged)
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
-- INTERNAL (MODIFIED: 1 entry per plot = highest part + 12 lines)
-- =====================
local ESP_Enabled = true
-- [PlotID] = {Part = highest big part, Lines = {12 full cube edges}}
local PlotHighestESP = {}

-- =====================
-- ✅ ALL ORIGINAL HELPER FUNCTIONS – 100% UNTOUCHED
-- This is the core that made your original track plots perfectly
-- =====================
local function ShouldSkip(Part)
    local Name = Part.Name:lower()
    for _, Skip in ipairs(ESP_Config.SKIP_NAMES) do
        if Name:find(Skip, 1, true) then return true end
    end
    return false
end

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

-- ✅ ORIGINAL GET BIG PARTS – NO CHANGES (same scan, same filters)
local function GetBigPlotParts(PlotID)
    local Region = GetPlotRegion(PlotID)
    if not Region then return {} end
    local Parts = {}
    local MinVol = ESP_Config.MIN_PART_VOLUME

    local function Scan(Object)
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("BasePart") then
                -- Original filter 1: volume
                local Vol = Child.Size.X * Child.Size.Y * Child.Size.Z
                if Vol < MinVol then
                    Scan(Child)
                    continue
                end
                -- Original filter 2: name blacklist
                if ShouldSkip(Child) then
                    Scan(Child)
                    continue
                end
                table.insert(Parts, Child)
            end
            Scan(Child)
        end
    end
    if Region:IsA("BasePart") then
        local Vol = Region.Size.X * Region.Size.Y * Region.Size.Z
        if Vol >= MinVol and not ShouldSkip(Region) then table.insert(Parts, Region) end
    end
    Scan(Region)
    return Parts
end

-- =====================
-- 🔑 ONLY NEW FUNCTION: Pick HIGHEST big part from original list
-- (Uses ONLY your original valid big parts – no new scanning, no wrong parts)
-- =====================
local function GetHighestBigPart(PlotID)
    local BigParts = GetBigPlotParts(PlotID) -- Calls your original function
    if #BigParts == 0 then return nil end

    local HighestPart = nil
    local HighestTopY = -math.huge -- Compare TOP EDGE (most accurate height check)

    for _, P in ipairs(BigParts) do
        local TopY = P.Position.Y + (P.Size.Y / 2)
        if TopY > HighestTopY then
            HighestTopY = TopY
            HighestPart = P
        end
    end
    return HighestPart
end

-- =====================
-- ✅ ORIGINAL 12 LINES PER PART – RESTORED (no more 4-line top face)
-- Exact same line creation as your original script
-- =====================
local function AddHighestESP(PlotID, Part)
    -- Clean up old ESP for this plot if highest part changed
    if PlotHighestESP[PlotID] then
        for _, L in ipairs(PlotHighestESP[PlotID].Lines) do L:Remove() end
        PlotHighestESP[PlotID] = nil
    end

    local PlotColor = ESP_Config.PLOTS[PlotID].Color
    local Lines = {}
    -- ✅ FULL 12 LINES = COMPLETE CUBE (exact original count)
    for i = 1, 12 do
        local L = Drawing.new("Line")
        L.Visible = false
        L.Color = PlotColor
        L.Thickness = ESP_Config.OutlineThickness
        L.Transparency = 1
        Lines[i] = L
    end
    PlotHighestESP[PlotID] = {Part = Part, Lines = Lines}
end

local function RemoveHighestESP(PlotID)
    local Data = PlotHighestESP[PlotID]
    if not Data then return end
    for _, L in ipairs(Data.Lines) do L:Remove() end
    PlotHighestESP[PlotID] = nil
end

-- =====================
-- ✅ ORIGINAL 12 EDGES TABLE – 100% UNCHANGED
-- Bottom 4 + Top 4 + Vertical 4 = FULL CUBE
-- =====================
local Edges = {
    {1,2}, {2,4}, {4,3}, {3,1}, -- Bottom 4 edges
    {5,6}, {6,8}, {8,7}, {7,5}, -- Top 4 edges
    {1,5}, {2,6}, {3,7}, {4,8}  -- Vertical 4 edges
}

-- =====================
-- MAIN LOOP (ORIGINAL STRUCTURE – ONLY FILTERED TO 1 PART/PLOT)
-- =====================
RunService.RenderStepped:Connect(function()
    local CamPos = Camera.CFrame.Position
    local Near = ESP_Config.NEAR_PLANE
    local ActivePlots = {} -- Track valid plots this frame

    -- Step 1: For each plot → get highest big part (from original big part list)
    for PlotID = 1, 6 do
        local HighestPart = GetHighestBigPart(PlotID)
        ActivePlots[PlotID] = HighestPart ~= nil

        -- No valid big part → hide/cleanup
        if not HighestPart then
            RemoveHighestESP(PlotID)
            continue
        end

        -- If highest part changed (base built higher/lower) → refresh 12 lines
        local Existing = PlotHighestESP[PlotID]
        if not Existing or Existing.Part ~= HighestPart then
            AddHighestESP(PlotID, HighestPart)
        end
    end

    -- Step 2: Cleanup dead plots
    for PlotID in pairs(PlotHighestESP) do
        if not ActivePlots[PlotID] then
            RemoveHighestESP(PlotID)
        end
    end

    -- Step 3: ✅ DRAW FULL 12-EDGE CUBE FOR HIGHEST PART (ORIGINAL METHOD)
    -- Exact same corner math + drawing logic as your original script
    for PlotID, Data in pairs(PlotHighestESP) do
        local Part = Data.Part
        -- Original hide checks (unchanged)
        if not ESP_Enabled or not Part or not Part.Parent then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end
        if (CamPos - Part.Position).Magnitude > ESP_Config.MaxDistance then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end

        -- ✅ ORIGINAL MAGIC: Exact same CFrame + 8 corner calculation (100% accurate)
        local CF = Part.CFrame
        local S = Part.Size
        local hX, hY, hZ = S.X/2, S.Y/2, S.Z/2
        local C3D = {
            CF * Vector3.new(-hX, -hY, -hZ), -- 1 BBL
            CF * Vector3.new( hX, -hY, -hZ), -- 2 BBR
            CF * Vector3.new(-hX, -hY,  hZ), -- 3 BFL
            CF * Vector3.new( hX, -hY,  hZ), -- 4 BFR
            CF * Vector3.new(-hX,  hY, -hZ), -- 5 TBL
            CF * Vector3.new( hX,  hY, -hZ), -- 6 TBR
            CF * Vector3.new(-hX,  hY,  hZ), -- 7 TFL
            CF * Vector3.new( hX,  hY,  hZ), -- 8 TFR
        }

        -- ✅ ORIGINAL BEHIND-CAMERA FIX (100% UNCHANGED)
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

        -- ✅ DRAW ALL 12 EDGES (full cube – exactly your original loop)
        for i, E in ipairs(Edges) do
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
end)

-- ✅ ORIGINAL E TOGGLE (UNCHANGED)
UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.C then
        ESP_Enabled = not ESP_Enabled
    end
end)
