local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera


local ESP_Config = {
    OutlineThickness = 2.3,
    MaxDistance = 9999,
    NEAR_PLANE = 0.3, 

    MIN_PART_VOLUME = 25,

    SKIP_NAMES = {"railing", "ladder", "fence", "rail", "button", "sign", "decal", "light"},
    PLOTS = {
        [1] = {Color = Color3.fromRGB(255, 50, 50)},    -- Plot 1 Red
        [2] = {Color = Color3.fromRGB(50, 120, 255)},   -- Plot 2 Blue
        [3] = {Color = Color3.fromRGB(255, 0, 255)},    -- Plot 3 Magenta 
        [4] = {Color = Color3.fromRGB(255, 220, 50)},   -- Plot 4 Yellow
        [5] = {Color = Color3.fromRGB(0, 255, 255)},    -- Plot 5 Cyan
        [6] = {Color = Color3.fromRGB(50, 255, 100)},   -- Plot 6 Green
    }
}


local ESP_Enabled = true

local PartESP = {}


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

local function GetBigPlotParts(PlotID)
    local Region = GetPlotRegion(PlotID)
    if not Region then return {} end
    local Parts = {}
    local MinVol = ESP_Config.MIN_PART_VOLUME

    local function Scan(Object)
        for _, Child in ipairs(Object:GetChildren()) do
            if Child:IsA("BasePart") then
               
                local Vol = Child.Size.X * Child.Size.Y * Child.Size.Z
                if Vol < MinVol then
                    Scan(Child)
                    continue
                end
                
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


local Edges = {
    {1,2}, {2,4}, {4,3}, {3,1}, -- Bottom
    {5,6}, {6,8}, {8,7}, {7,5}, -- Top
    {1,5}, {2,6}, {3,7}, {4,8}  -- Vertical
}


RunService.RenderStepped:Connect(function()
    local CamPos = Camera.CFrame.Position
    local Near = ESP_Config.NEAR_PLANE
    local AllValidParts = {}


    for PlotID = 1, 6 do
        local BigParts = GetBigPlotParts(PlotID)
        for _, P in ipairs(BigParts) do
            AllValidParts[P] = true
            AddPartESP(P, PlotID) 
        end
    end

    
    for Part in pairs(PartESP) do
        if not AllValidParts[Part] or not Part or not Part.Parent then
            RemovePartESP(Part)
        end
    end

    
    for Part, Data in pairs(PartESP) do
        
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
            CF * Vector3.new(-hX, -hY, -hZ), -- 1 BBL
            CF * Vector3.new( hX, -hY, -hZ), -- 2 BBR
            CF * Vector3.new(-hX, -hY,  hZ), -- 3 BFL
            CF * Vector3.new( hX, -hY,  hZ), -- 4 BFR
            CF * Vector3.new(-hX,  hY, -hZ), -- 5 TBL
            CF * Vector3.new( hX,  hY, -hZ), -- 6 TBR
            CF * Vector3.new(-hX,  hY,  hZ), -- 7 TFL
            CF * Vector3.new( hX,  hY,  hZ), -- 8 TFR
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


UserInputService.InputBegan:Connect(function(Input, GP)
    if GP then return end
    if Input.KeyCode == Enum.KeyCode.E then
        ESP_Enabled = not ESP_Enabled
    end
end)
