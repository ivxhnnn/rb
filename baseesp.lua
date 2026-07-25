-- =============================================
-- ALL 6 PLOTS – PERFECT ALIGNMENT + NO LAG (FINAL VERSION)
-- ✅ USES FIRST SCRIPT'S METHOD: Draws each part's REAL 3D cube (100% accurate, NO GUESSWORK)
-- ✅ BUT ONLY DRAWS BIG STRUCTURAL PARTS (floors/walls/pillars) → SKIPS ALL TINY JUNK → NO LAG
-- ✅ + BEHIND-CAMERA FIX (no stretched lines when moving)
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
    -- ✅ THE MAGIC NUMBER: Only draw parts BIGGER than this (volume = X*Y*Z studs)
    -- 25 = draws only floors, big walls, big pillars. SKIPS railings/ladders/buttons/decor.
    -- If you miss small walls → lower to 15. If still laggy → raise to 35.
    MIN_PART_VOLUME = 25,
    -- Extra name blacklist just to be 100% sure no junk gets through
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
-- [Part] = {PlotID, Lines={12}}
local PartESP = {}

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

-- Get ONLY BIG VALID PARTS inside a plot (THE LAG FIX)
local function GetBigPlotParts(PlotID)
    local Region = GetPlotRegion(PlotID)
    if not Region then return {} end
    local Parts = {}
    local MinVol = ESP_Config.MIN_PART_VOLUME

    local function Scan(Object)
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("BasePart") then
                -- ✅ FILTER 1: Skip tiny junk by volume
                local Vol = Child.Size.X * Child.Size.Y * Child.Size.Z
                if Vol < MinVol then
                    Scan(Child)
                    continue
                end
                -- ✅ FILTER 2: Skip railings/ladders by name
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

-- Create 12 lines = 1 full 3D cube per BIG part (PERFECT ALIGNMENT METHOD)
local function AddPartESP(Part, PlotID)
    if PartESP[Part] then return end
    local PlotColor = ESP_Config.PLOTS[PlotID].Color
    local Lines = {}
    for i = 1, 12 do
        local L = Drawing.new("Line")
        L.Visible = false
        L.Color = PlotColor
        L.Thickness = ESP_Config.OutlineThickness
        L.Transparency = 1
        Lines[i] = L
    end
    PartESP[Part] = {PlotID = PlotID, Lines = Lines}
end

local function RemovePartESP(Part)
    local Data = PartESP[Part]
    if not Data then return end
    for _, L in ipairs(Data.Lines) do L:Remove() end
    PartESP[Part] = nil
end

-- 12 edges of a cube
local Edges = {
    {1,2}, {2,4}, {4,3}, {3,1}, -- Bottom
    {5,6}, {6,8}, {8,7}, {7,5}, -- Top
    {1,5}, {2,6}, {3,7}, {4,8}  -- Vertical
}

-- =====================
-- MAIN LOOP (PERFECT + FAST + NO GLITCHES)
-- =====================
RunService.RenderStepped:Connect(function()
    local CamPos = Camera.CFrame.Position
    local Near = ESP_Config.NEAR_PLANE
    local AllValidParts = {}

    -- Step 1: Get ONLY BIG parts for ALL 6 plots
    for PlotID = 1, 6 do
        local BigParts = GetBigPlotParts(PlotID)
        for _, P in ipairs(BigParts) do
            AllValidParts[P] = true
            AddPartESP(P, PlotID) -- Only creates lines once per part
        end
    end

    -- Step 2: Clean up dead parts
    for Part in pairs(PartESP) do
        if not AllValidParts[Part] or not Part or not Part.Parent then
            RemovePartESP(Part)
        end
    end

    -- Step 3: DRAW EVERY BIG PART'S REAL 3D CUBE (100% ACCURATE = FIRST SCRIPT METHOD)
    for Part, Data in pairs(PartESP) do
        -- Hide if off / invalid / too far
        if not ESP_Enabled or not Part or not Part.Parent then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end
        if (CamPos - Part.Position).Magnitude > ESP_Config.MaxDistance then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end

        -- ✅ FIRST SCRIPT'S MAGIC: Use the part's OWN CFrame + Size directly
        -- → This is why it was ALWAYS perfectly aligned, no bounding box math needed
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

        -- ✅ ADD BEHIND-CAMERA FIX (no stretched lines when moving)
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

        -- Draw each edge ONLY IF BOTH CORNERS ARE IN FRONT OF CAMERA
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

-- E TOGGLE (no conflict with Pet ESP Q key)
UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.E then
        ESP_Enabled = not ESP_Enabled
    end
end)
