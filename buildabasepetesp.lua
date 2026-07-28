
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
    PanelWidth = 140,
    RowHeight = 16,
    RowPadding = 1,
    OwnPetColor = Color3.fromRGB(100, 255, 100),
    OtherPetColor = Color3.fromRGB(255, 100, 100),
    RowColors = {
        Color3.fromRGB(40, 30, 60),
        Color3.fromRGB(30, 40, 65)
    },
    LabelColors = {
        Color3.fromRGB(180, 150, 255),
        Color3.fromRGB(130, 180, 255)
    },
    ValueColor = Color3.new(1,1,1)
}


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
    if ESP_Objects[PetModel] then return end

    local ESP = {Corners = {}}
    for i = 1, 4 do
        ESP.Corners[i] = DrawLine(ESP_Config.OtherPetColor, ESP_Config.BoxThickness)
    end
    ESP.PanelBG = DrawSquare(Color3.fromRGB(12,12,18), 1, true, 0.35)
    ESP.PanelBorder = DrawSquare(Color3.fromRGB(80,80,120), 1, false, 0.7)
    ESP.Rows = {}
    for i = 1, 2 do
        ESP.Rows[i] = {
            BG = DrawSquare(),
            Label = DrawText(11),
            Value = DrawText(12)
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


local function HasCosmicUnicorn()
    for PetModel, _ in pairs(ESP_Objects) do
        if PetModel and PetModel.Parent then
            local Species = PetModel:GetAttribute("Species") or "Unknown"
            local Mutation = PetModel:GetAttribute("Mutation") or "None"

            if Species == "Unicorn" and Mutation == "Cosmic" then
                return true
            end
        end
    end
    return false
end


RunService.RenderStepped:Connect(function()
    local CameraPos = Camera.CFrame.Position
    local FilterToCosmic = HasCosmicUnicorn() -- Only filter if Cosmic Unicorn exists

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

   
        if FilterToCosmic then
            local Species = PetModel:GetAttribute("Species") or "Unknown"
            local Mutation = PetModel:GetAttribute("Mutation") or "None"
          
            if not (Species == "Unicorn" and Mutation == "Cosmic") then
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
        end

       
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

     
        local OwnerId = PetModel:GetAttribute("OwnerUserId")
        local IsOwned = OwnerId == LocalPlayer.UserId
        local BoxColor = IsOwned and ESP_Config.OwnPetColor or ESP_Config.OtherPetColor
        local Species = PetModel:GetAttribute("Species") or "Unknown"
        local Mutation = PetModel:GetAttribute("Mutation") or "None"

        -- Draw box
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
        local RowY = PanelY + 4

        ESP.PanelBG.Position = Vector2.new(PanelX, PanelY)
        ESP.PanelBG.Size = Vector2.new(ESP_Config.PanelWidth, 40)
        ESP.PanelBG.Visible = true

        ESP.PanelBorder.Position = ESP.PanelBG.Position
        ESP.PanelBorder.Size = ESP.PanelBG.Size
        ESP.PanelBorder.Color = BoxColor
        ESP.PanelBorder.Visible = true

        local InfoRows = {
            {"SPECIES", Species},
            {"MUTATION", Mutation}
        }

        for Index, Data in ipairs(InfoRows) do
            local Row = ESP.Rows[Index]
            local Label, Value = Data[1], Data[2]

            Row.BG.Position = Vector2.new(PanelX + 2, RowY)
            Row.BG.Size = Vector2.new(ESP_Config.PanelWidth - 4, ESP_Config.RowHeight)
            Row.BG.Color = ESP_Config.RowColors[Index]
            Row.BG.Visible = true

            Row.Label.Text = Label
            Row.Label.Position = Vector2.new(PanelX + 6, RowY + 1)
            Row.Label.Color = ESP_Config.LabelColors[Index]
            Row.Label.Visible = true

            Row.Value.Text = Value
            Row.Value.Position = Vector2.new(PanelX + ESP_Config.PanelWidth/2 + 10, RowY + 1)
            Row.Value.Color = ESP_Config.ValueColor
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

-- =====================
-- AUTO-DETECT PETS
-- =====================
task.spawn(function()
    local RuntimePets = workspace:WaitForChild("RuntimePets", 10)
    if not RuntimePets then return end

    for _, Child in ipairs(RuntimePets:GetChildren()) do
        if Child.Name == "Character" then
            task.wait(0.1)
            AddPetESP(Child)
        end
    end

    RuntimePets.ChildAdded:Connect(function(Child)
        task.wait(0.1)
        if Child.Name == "Character" then
            AddPetESP(Child)
        end
    end)

    RuntimePets.ChildRemoved:Connect(RemovePetESP)
end)
