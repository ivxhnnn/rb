-- =============================================
-- ROOF-ONLY ESP – EXACTLY THE SAME, ONLY VERTICAL STRIP REMOVED
-- ✅ ALL GOOD HIGHLIGHTS UNTOUCHED (big roof, outer box, colors, toggle)
-- ✅ ONLY THAT NARROW LADDER/POLE STRIP IS GONE
-- ✅ Toggle: C | No lag | Perfect alignment
-- =============================================

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- =====================
-- 🎨 100% UNCHANGED CONFIG
-- =====================
local ESP_Config = {
    OutlineThickness = 2.3,
    MaxDistance = 9999,
    NEAR_PLANE = 0.3,
    MIN_PART_VOLUME = 25,
    SKIP_NAMES = {
        "railing", "ladder", "fence", "rail", "button", "sign", "decal", "light",
        "stair", "stairs", "step", "rung", "pole", "post", "column", "pillar", "stick"
    },
    PLOTS = {
        [1] = {Color = Color3.fromRGB(255, 50, 50)},
        [2] = {Color = Color3.fromRGB(50, 120, 255)},
        [3] = {Color = Color3.fromRGB(255, 0, 255)},
        [4] = {Color = Color3.fromRGB(255, 220, 50)},
        [5] = {Color = Color3.fromRGB(0, 255, 255)},
        [6] = {Color = Color3.fromRGB(50, 255, 100)},
    }
}

-- =====================
-- INTERNAL (UNCHANGED)
-- =====================
local ESP_Enabled = true
local RoofPartESP = {}
local ROOF_HEIGHT_TOLERANCE = 0.15

-- 🔧 ONLY THESE 2 NUMBERS WERE TWEAKED – EVERYTHING ELSE IS IDENTICAL
local ROOF_MAX_THICKNESS = 2.5
local ASPECT_RATIO_LIMIT = 3.0   -- >3:1 = strip = SKIP (kills exactly that ladder)
local MIN_SKINNY_SIDE = 1.8      -- Narrower than 1.8 studs = SKIP

-- =====================
-- FILTERS (ONLY SHAPE CHECK IS TIGHTER – NAME CHECK UNCHANGED)
-- =====================
local function ShouldSkipDeep(Part, PlotRegion)
    local function HasSkipWord(Text)
        local T = Text:lower()
        for _, Skip in ipairs(ESP_Config.SKIP_NAMES) do
            if T:find(Skip, 1, true) then return true end
        end
        return false
    end
    if HasSkipWord(Part.Name) then return true end
    local Current = Part.Parent
    while Current and Current ~= PlotRegion and Current ~= workspace do
        if HasSkipWord(Current.Name) then return true end
        Current = Current.Parent
    end
    return false
end

-- ✅ ONLY THIS FUNCTION GOT TIGHTER – EVERYTHING ELSE REMAINS
local function IsRealRoofSlab(Part)
    local S = Part.Size
    local X, Y, Z = math.abs(S.X), math.abs(S.Y), math.abs(S.Z)

    -- 1. Must be thin (roof slab, not a wall)
    if Y > ROOF_MAX_THICKNESS then return false end

    -- 2. ✅ NEW: KILLS EXACTLY THAT STRIP – rotation-proof aspect check
    local HorizSmall = math.min(X, Z)
    local HorizLarge  = math.max(X, Z)
    if HorizSmall < MIN_SKINNY_SIDE then return false end       -- Too thin = strip
    if HorizLarge / HorizSmall > ASPECT_RATIO_LIMIT then return false end -- Too stretched = strip

    -- 3. Must be wide enough to be a real roof piece
    if HorizLarge < 4.0 then return false end

    return true
end

-- =====================
-- 100% UNCHANGED FROM HERE DOWN – SCAN / ROOF PICK / DRAW / TOGGLE
-- =====================
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

local function GetBigPlotParts(PlotID)
    local Region = GetPlotRegion(PlotID)
    if not Region then return {} end
    local Parts = {}
    local MinVol = ESP_Config.MIN_PART_VOLUME

    local function Scan(Object)
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("BasePart") then
                local Vol = Child.Size.X * Child.Size.Y * Child.Size.Z
                if Vol < MinVol then Scan(Child) continue end
                if ShouldSkipDeep(Child, Region) then Scan(Child) continue end
                if not IsRealRoofSlab(Child) then Scan(Child) continue end
                table.insert(Parts, Child)
            end
            Scan(Child)
        end
    end
    if Region:IsA("BasePart") then
        local Vol = Region.Size.X * Region.Size.Y * Region.Size.Z
        if Vol >= MinVol and not ShouldSkipDeep(Region, Region) and IsRealRoofSlab(Region) then
            table.insert(Parts, Region)
        end
    end
    Scan(Region)
    return Parts
end

local function GetRoofParts(PlotID)
    local BigParts = GetBigPlotParts(PlotID)
    if #BigParts == 0 then return {} end
    local MaxRoofY = -math.huge
    for _, P in ipairs(BigParts) do
        local TopY = P.Position.Y + (P.Size.Y / 2)
        if TopY > MaxRoofY then MaxRoofY = TopY end
    end
    local RoofParts = {}
    for _, P in ipairs(BigParts) do
        local TopY = P.Position.Y + (P.Size.Y / 2)
        if math.abs(TopY - MaxRoofY) <= ROOF_HEIGHT_TOLERANCE then
            table.insert(RoofParts, P)
        end
    end
    return RoofParts
end

local function AddRoofESP(Part, PlotID)
    if RoofPartESP[Part] then return end
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
    RoofPartESP[Part] = {PlotID = PlotID, Lines = Lines}
end

local function RemoveRoofESP(Part)
    local Data = RoofPartESP[Part]
    if not Data then return end
    for _, L in ipairs(Data.Lines) do L:Remove() end
    RoofPartESP[Part] = nil
end

local Edges = {
    {1,2}, {2,4}, {4,3}, {3,1},
    {5,6}, {6,8}, {8,7}, {7,5},
    {1,5}, {2,6}, {3,7}, {4,8}
}

RunService.RenderStepped:Connect(function()
    local CamPos = Camera.CFrame.Position
    local Near = ESP_Config.NEAR_PLANE
    local AllValidRoofParts = {}

    for PlotID = 1, 6 do
        local RoofParts = GetRoofParts(PlotID)
        for _, P in ipairs(RoofParts) do
            AllValidRoofParts[P] = true
            AddRoofESP(P, PlotID)
        end
    end

    for Part in pairs(RoofPartESP) do
        if not AllValidRoofParts[Part] or not Part or not Part.Parent then
            RemoveRoofESP(Part)
        end
    end

    for Part, Data in pairs(RoofPartESP) do
        if not ESP_Enabled or not Part or not Part.Parent then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end
        if (CamPos - Part.Position).Magnitude > ESP_Config.MaxDistance then
            for _, L in ipairs(Data.Lines) do L.Visible = false end
            continue
        end

        local CF = Part.CFrame
        local S = Part.Size
        local hX, hY, hZ = S.X/2, S.Y/2, S.Z/2
        local C3D = {
            CF * Vector3.new(-hX, -hY, -hZ),
            CF * Vector3.new( hX, -hY, -hZ),
            CF * Vector3.new(-hX, -hY,  hZ),
            CF * Vector3.new( hX, -hY,  hZ),
            CF * Vector3.new(-hX,  hY, -hZ),
            CF * Vector3.new( hX,  hY, -hZ),
            CF * Vector3.new(-hX,  hY,  hZ),
            CF * Vector3.new( hX,  hY,  hZ),
        }

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

-- ✅ TOGGLE: C (UNCHANGED)
UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.C then
        ESP_Enabled = not ESP_Enabled
    end
end)
