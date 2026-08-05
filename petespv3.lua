-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_Config = {
    MaxDistance = 9999,
    BoxThickness = 1.5,
    CornerSize = 0.25,
    Font = 2,
    PanelWidth = 110,
    RowHeight = 18,
    RowPadding = 1,
    MinMPS = 50000000, 
    OwnPetBoxColor = Color3.fromRGB(100, 255, 100), -- (no longer used for owned pets)
 
    TierColors = {
        [1] = Color3.fromRGB(255, 50, 50),   
        [2] = Color3.fromRGB(50, 120, 255),  
        [3] = Color3.fromRGB(255, 220, 50)   
    },
    RowColors = {
        Color3.fromRGB(25, 50, 60)
    },
    LabelColor = Color3.fromRGB(100, 220, 160) 
}


local function GetTierColor(NumMPS)
    if NumMPS >= 200000000 then
        return ESP_Config.TierColors[3] 
    elseif NumMPS >= 100000000 then
        return ESP_Config.TierColors[2] 
    else
        return ESP_Config.TierColors[1] 
    end
end


local SuffixMultipliers = {
    k = 1e3, K = 1e3,
    m = 1e6, M = 1e6,
    b = 1e9, B = 1e9,
    t = 1e12, T = 1e12,
    q = 1e15, Q = 1e15,
}
local function ParseMPS(Value)
    if not Value then return 0 end
    if type(Value) == "number" then return Value end
    local Clean = tostring(Value):gsub("%$", ""):gsub(",", ""):gsub("%s+", ""):gsub("/s$", ""):gsub("/sec$", "")
    local Num, Suffix = Clean:match("^([%d%.]+)(%a?)$")
    if not Num then return 0 end
    local N = tonumber(Num) or 0
    if Suffix ~= "" and SuffixMultipliers[Suffix] then N *= SuffixMultipliers[Suffix] end
    return N
end


local ESP_Objects = {}
local ESP_Enabled = true


local function DrawLine(Color, Thickness)
    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Color = Color or Color3.new(1,1,1)
    Line.Thickness = Thickness or 1.5
    Line.Transparency = 1
    return Line
end

local function DrawText(Size, Color, Center)
    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Color = Color or Color3.new(1,1,1)
    Text.Size = Size or 13
    Text.Center = Center or false
    Text.Outline = true
    Text.OutlineColor = Color3.new(0,0,0)
    Text.Font = ESP_Config.Font
    Text.Transparency = 1
    return Text
end

local function DrawSquare(Color, Thickness, Filled, Transparency)
    local Square = Drawing.new("Square")
    Square.Visible = false
    Square.Color = Color or Color3.new(1,1,1)
    Square.Thickness = Thickness or 1
    Square.Filled = Filled or false
    Square.Transparency = Transparency or 1
    return Square
end


local function AddPetESP(PetModel)
    -- ✅ EXEMPTION: Don't create ESP for pets owned by the local player
    local OwnerId = PetModel:GetAttribute("OwnerUserId")
    if OwnerId == LocalPlayer.UserId then
        return -- skip entirely
    end

    if ESP_Objects[PetModel] then return end

    local ESP = {Corners = {}}
    for i = 1, 4 do
        ESP.Corners[i] = DrawLine(ESP_Config.TierColors[1], ESP_Config.BoxThickness)
    end
    ESP.PanelBG = DrawSquare(Color3.fromRGB(12,12,18), 1, true, 0.35)
    ESP.PanelBorder = DrawSquare(Color3.fromRGB(80,80,120), 1, false, 0.7)
    ESP.Rows = {}
    for i = 1, 1 do
        ESP.Rows[i] = {
            BG = DrawSquare(),
            Label = DrawText(11),
            Value = DrawText(14)
        }
    end

    ESP_Objects[PetModel] = ESP
end

local function RemovePetESP(PetModel)
    local ESP = ESP_Objects[PetModel]
    if not ESP then return end
    for _, Corner in ipairs(ESP.Corners) do Corner:Remove() end
    ESP.PanelBG:Remove()
    ESP.PanelBorder:Remove()
    for _, Row in ipairs(ESP.Rows) do
        Row.BG:Remove()
        Row.Label:Remove()
        Row.Value:Remove()
    end
    ESP_Objects[PetModel] = nil
end


local function GetPetData(PetModel)
    local Species = PetModel:GetAttribute("Species") or PetModel.Name or "Unknown"
    local Mutation = PetModel:GetAttribute("Mutation") or "None"
    local RawMPS = PetModel:GetAttribute("MPS") 
           or PetModel:GetAttribute("ValuePerSecond") 
           or PetModel:GetAttribute("MoneyPerSecond") 
           or "?"

    if RawMPS == "?" then
        local Tag = PetModel:FindFirstChild("ItemNameTag", true)
        if Tag then
            local MutLabel = Tag:FindFirstChild("Mutation")
            if MutLabel and MutLabel:IsA("TextLabel") then
                Mutation = MutLabel.Text ~= "" and MutLabel.Text or Mutation
            end

            local MpsLabel = Tag:FindFirstChild("MPS") 
                          or Tag:FindFirstChild("Value") 
                          or Tag:FindFirstChild("Money")
            if MpsLabel then
                local InnerLabel = MpsLabel:FindFirstChildWhichIsA("TextLabel")
                if InnerLabel then
                    RawMPS = InnerLabel.Text ~= "" and InnerLabel.Text or RawMPS
                elseif MpsLabel:IsA("TextLabel") then
                    RawMPS = MpsLabel.Text ~= "" and MpsLabel.Text or RawMPS
                end
            end
        end
    end

    local NumMPS = ParseMPS(RawMPS)
    local DisplayMPS = RawMPS
    if NumMPS > 0 then
        if NumMPS >= 1e15 then
            DisplayMPS = string.format("%.1fQ", NumMPS / 1e15)
        elseif NumMPS >= 1e12 then
            DisplayMPS = string.format("%.1fT", NumMPS / 1e12)
        elseif NumMPS >= 1e9 then
            DisplayMPS = string.format("%.1fB", NumMPS / 1e9)
        elseif NumMPS >= 1e6 then
            DisplayMPS = string.format("%.1fM", NumMPS / 1e6)
        elseif NumMPS >= 1e3 then
            DisplayMPS = string.format("%.1fK", NumMPS / 1e3)
        else
            DisplayMPS = tostring(math.floor(NumMPS))
        end
    end

    return Species, Mutation, DisplayMPS, NumMPS
end


RunService.RenderStepped:Connect(function()
    local CameraPos = Camera.CFrame.Position

    for PetModel, ESP in pairs(ESP_Objects) do
        
        if not ESP_Enabled or not PetModel or not PetModel.Parent then
            for _, Corner in ipairs(ESP.Corners) do Corner.Visible = false end
            ESP.PanelBG.Visible = false
            ESP.PanelBorder.Visible = false
            for _, Row in ipairs(ESP.Rows) do
                Row.BG.Visible = false
                Row.Label.Visible = false
                Row.Value.Visible = false
            end
            if not PetModel or not PetModel.Parent then RemovePetESP(PetModel) end
            continue
        end


        local Species, Mutation, MPS, NumMPS = GetPetData(PetModel)

       
        if NumMPS < ESP_Config.MinMPS then
            for _, Corner in ipairs(ESP.Corners) do Corner.Visible = false end
            ESP.PanelBG.Visible = false
            ESP.PanelBorder.Visible = false
            for _, Row in ipairs(ESP.Rows) do
                Row.BG.Visible = false
                Row.Label.Visible = false
                Row.Value.Visible = false
            end
            continue
        end

      
        local TierColor = GetTierColor(NumMPS)

    
        local RootPart = PetModel:FindFirstChild("HumanoidRootPart") 
                      or PetModel:FindFirstChildWhichIsA("BasePart")
        if not RootPart then
            for _, Corner in ipairs(ESP.Corners) do Corner.Visible = false end
            ESP.PanelBG.Visible = false
            continue
        end

        local Distance = (CameraPos - RootPart.Position).Magnitude
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)

       
        if Distance > ESP_Config.MaxDistance or not OnScreen then
            for _, Corner in ipairs(ESP.Corners) do Corner.Visible = false end
            ESP.PanelBG.Visible = false
            ESP.PanelBorder.Visible = false
            for _, Row in ipairs(ESP.Rows) do
                Row.BG.Visible = false
                Row.Label.Visible = false
                Row.Value.Visible = false
            end
            continue
        end

        -- No ownership check needed here because owned pets were never added.
        local BoxColor = TierColor

        local BoxSize = 2.5 * ESP_Config.CornerSize
        local Corners = {
            {Vector2.new(ScreenPos.X - BoxSize, ScreenPos.Y - BoxSize), Vector2.new(ScreenPos.X + BoxSize, ScreenPos.Y - BoxSize)},
            {Vector2.new(ScreenPos.X - BoxSize, ScreenPos.Y - BoxSize), Vector2.new(ScreenPos.X - BoxSize, ScreenPos.Y + BoxSize)},
            {Vector2.new(ScreenPos.X + BoxSize, ScreenPos.Y - BoxSize), Vector2.new(ScreenPos.X + BoxSize, ScreenPos.Y + BoxSize)},
            {Vector2.new(ScreenPos.X - BoxSize, ScreenPos.Y + BoxSize), Vector2.new(ScreenPos.X + BoxSize, ScreenPos.Y + BoxSize)}
        }
        for i = 1, 4 do
            ESP.Corners[i].From = Corners[i][1]
            ESP.Corners[i].To = Corners[i][2]
            ESP.Corners[i].Color = BoxColor
            ESP.Corners[i].Visible = true
        end

    
        local PanelX = ScreenPos.X - ESP_Config.PanelWidth / 2
        local PanelY = ScreenPos.Y + 20
        local TotalHeight = (ESP_Config.RowHeight + ESP_Config.RowPadding) * 1 + 4

        ESP.PanelBG.Position = Vector2.new(PanelX, PanelY)
        ESP.PanelBG.Size = Vector2.new(ESP_Config.PanelWidth, TotalHeight)
        ESP.PanelBG.Visible = true

        ESP.PanelBorder.Position = ESP.PanelBG.Position
        ESP.PanelBorder.Size = ESP.PanelBG.Size
        ESP.PanelBorder.Color = BoxColor 
        ESP.PanelBorder.Visible = true

        local InfoRows = {
            {"MPS", MPS}
        }

        local RowY = PanelY + 4
        for Index, Data in ipairs(InfoRows) do
            local Row = ESP.Rows[Index]
            local Label, Value = Data[1], Data[2]

            Row.BG.Position = Vector2.new(PanelX + 2, RowY)
            Row.BG.Size = Vector2.new(ESP_Config.PanelWidth - 4, ESP_Config.RowHeight)
            Row.BG.Color = ESP_Config.RowColors[1]
            Row.BG.Visible = true

            Row.Label.Text = Label
            Row.Label.Position = Vector2.new(PanelX + 6, RowY + 2)
            Row.Label.Color = ESP_Config.LabelColor
            Row.Label.Visible = true

           
            Row.Value.Text = Value
            Row.Value.Position = Vector2.new(PanelX + ESP_Config.PanelWidth/2 + 10, RowY + 1)
            Row.Value.Color = TierColor
            Row.Value.Visible = true

            RowY += ESP_Config.RowHeight + ESP_Config.RowPadding
        end
    end
end)


UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then return end
    if Input.KeyCode == Enum.KeyCode.Q then
        ESP_Enabled = not ESP_Enabled
    end
end)


task.spawn(function()
    local RuntimePets = workspace:WaitForChild("RuntimePets", 10)
    if not RuntimePets then return end

    for _, Child in ipairs(RuntimePets:GetChildren()) do
        if Child.Name == "Character" then
            task.wait(0.1)
            AddPetESP(Child) -- now checks ownership inside
        end
    end

    RuntimePets.ChildAdded:Connect(function(Child)
        task.wait(0.1)
        if Child.Name == "Character" then
            AddPetESP(Child) -- ownership check inside
        end
    end)

    RuntimePets.ChildRemoved:Connect(RemovePetESP)
end)
