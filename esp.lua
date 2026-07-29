-- Standalone Distance ESP | No GUI | Auto-Clean On Death
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}

-- Add ESP to alive characters only
local function AddESP(Character)
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    -- Only apply if character is ALIVE and valid
    if not Humanoid or not RootPart or Humanoid.Health <= 0 then return end
    if ESP_Objects[Character] then return end

    -- White body outline
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "ESP_Highlight"
    Highlight.FillTransparency = 1
    Highlight.OutlineTransparency = 0
    Highlight.OutlineColor = Color3.new(1, 1, 1)
    Highlight.Adornee = Character
    Highlight.Parent = Character

    -- Distance text only
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP_Distance"
    Billboard.Adornee = Character:FindFirstChild("Head") or RootPart
    Billboard.Size = UDim2.new(0, 120, 0, 30)
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Character

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 1, 0)
    Text.BackgroundTransparency = 1
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.Font = Enum.Font.GothamBold
    Text.TextSize = 16
    Text.TextStrokeTransparency = 0.4
    Text.Parent = Billboard

    ESP_Objects[Character] = {Highlight, Billboard, Text}

    -- Auto-clean INSTANTLY when health hits 0
    Humanoid.Died:Once(function()
        RemoveESP(Character)
    end)
end

-- Safe ESP removal
local function RemoveESP(Character)
    if not ESP_Objects[Character] then return end
    for _, Obj in pairs(ESP_Objects[Character]) do
        if Obj and Obj.Parent then Obj:Destroy() end
    end
    ESP_Objects[Character] = nil
end

-- Main update loop
RunService.RenderStepped:Connect(function()
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end

    -- Process all players
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        local Char = Player.Character
        if not Char then
            RemoveESP(Char)
            continue
        end

        local Humanoid = Char:FindFirstChildOfClass("Humanoid")
        local CharRoot = Char:FindFirstChild("HumanoidRootPart")

        -- Clean up if DEAD or invalid
        if not Humanoid or not CharRoot or Humanoid.Health <= 0 then
            RemoveESP(Char)
            continue
        end

        -- Add ESP if missing
        AddESP(Char)

        -- Update distance (only if alive)
        local Data = ESP_Objects[Char]
        if Data then
            local Dist = (CharRoot.Position - MyRoot.Position).Magnitude
            Data[3].Text = string.format("%.1fm", Dist)
        end
    end

    -- Garbage collect orphaned ESP
    for Char in pairs(ESP_Objects) do
        if not Char:IsDescendantOf(workspace) then
            RemoveESP(Char)
        end
    end
end)

-- Handle respawns for new players
Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(AddESP)
    Player.CharacterRemoving:Connect(RemoveESP)
end)

-- Init existing players on inject
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer and Player.Character then
        task.spawn(AddESP, Player.Character)
    end
end
