-- Standalone Distance ESP | No GUI | Instant Activate
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}

-- Apply ESP to a character
local function AddESP(Character)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    if ESP_Objects[Character] then return end

    -- Body Highlight
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "ESP_Highlight"
    Highlight.FillTransparency = 1
    Highlight.OutlineTransparency = 0
    Highlight.OutlineColor = Color3.new(1, 1, 1) -- White outline
    Highlight.Adornee = Character
    Highlight.Parent = Character

    -- Distance Text Only
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP_Distance"
    Billboard.Adornee = Character:FindFirstChild("Head")
    Billboard.Size = UDim2.new(0, 120, 0, 30)
    Billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    Billboard.AlwaysOnTop = true
    Billboard.Parent = Character

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 1, 0)
    Text.BackgroundTransparency = 1
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.Font = Enum.Font.GothamBold
    Text.TextSize = 12
    Text.TextStrokeTransparency = 0.4
    Text.Parent = Billboard

    ESP_Objects[Character] = {Highlight, Billboard, Text}
end

-- Remove ESP from a character
local function RemoveESP(Character)
    if not ESP_Objects[Character] then return end
    for _, Obj in pairs(ESP_Objects[Character]) do
        Obj:Destroy()
    end
    ESP_Objects[Character] = nil
end

-- Update every frame
RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local MyRoot = LocalPlayer.Character.HumanoidRootPart

    -- Add/Update ESP for all players
    for _, Player in pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if Player.Character then
            AddESP(Player.Character)
            local Char = Player.Character
            local Data = ESP_Objects[Char]
            if Data and Char:FindFirstChild("HumanoidRootPart") then
                local Dist = (Char.HumanoidRootPart.Position - MyRoot.Position).Magnitude
                Data[3].Text = string.format("%.1fm", Dist) -- Only distance
            end
        else
            RemoveESP(Player.Character)
        end
    end

    -- Clean up old ESP
    for Char in pairs(ESP_Objects) do
        if not Char:IsDescendantOf(workspace) then
            RemoveESP(Char)
        end
    end
end)

-- Auto-update when players respawn
Players.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(AddESP)
    Player.CharacterRemoving:Connect(RemoveESP)
end)

-- Initialize for existing players on inject
for _, Player in pairs(Players:GetPlayers()) do
    if Player ~= LocalPlayer and Player.Character then
        task.spawn(AddESP, Player.Character)
    end
end
