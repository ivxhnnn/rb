local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer


local existingTora = CoreGui:FindFirstChild("ToraScript")
if existingTora then existingTora:Destroy() end

-- Load library ONCE
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()


local MiscWindow = Library:CreateWindow("MISC")

-- Anti Fall
MiscWindow:AddButton({
    text = "Anti Fall",
    flag = "antifall",
    callback = function()
        local existingPlatform = workspace:FindFirstChild("wow")
        if existingPlatform then
            existingPlatform:Destroy()
            return
        end
        local platform = Instance.new("Part")
        platform.Name = "wow"
        platform.Anchored = true
        platform.CanCollide = true
        platform.Transparency = 0
        platform.Material = Enum.Material.SmoothPlastic
        platform.Color = Color3.fromRGB(0, 170, 255)
        platform.Size = Vector3.new(500, 5, 500)
        platform.CFrame = workspace.Map["island-middle"].Base.CFrame * CFrame.new(0, -1, 0)
        platform.Parent = workspace
    end
})

-- Walk Speed (with persistent apply)
local wsConnections = {}
local desiredWalkSpeed = 40 

local function applyWalkSpeed(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end

    if wsConnections.maintainLoop then wsConnections.maintainLoop:Disconnect() end
    if wsConnections.propertyGuard then wsConnections.propertyGuard:Disconnect() end

    humanoid.WalkSpeed = desiredWalkSpeed

    wsConnections.maintainLoop = RunService.RenderStepped:Connect(function()
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local current = tonumber(Library.flags.walkspeed) or desiredWalkSpeed
            humanoid.WalkSpeed = current
        end
    end)

    wsConnections.propertyGuard = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if math.abs(humanoid.WalkSpeed - desiredWalkSpeed) > 0.1 then
            humanoid.WalkSpeed = desiredWalkSpeed
        end
    end)
end

MiscWindow:AddSlider({
    text = "Walk Speed",
    flag = "walkspeed",
    value = 40,
    min = 30,
    max = 49,
    callback = function(newValue)
        desiredWalkSpeed = tonumber(newValue)
        Library.flags.walkspeed = desiredWalkSpeed
        applyWalkSpeed(LocalPlayer.Character)
    end
})

wsConnections.respawnListener = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(1.5)
    applyWalkSpeed(newCharacter)
end)

if LocalPlayer.Character then
    task.spawn(function() applyWalkSpeed(LocalPlayer.Character) end)
end

-- Vertical Teleport
MiscWindow:AddLabel({ text = "Vertical Teleport" })

local StudInput = MiscWindow:AddBox({
    text = "Stud Amount",
    flag = "studAmount",
    value = "20",
    callback = function() end
})

MiscWindow:AddButton({
    text = "Above",
    flag = "tpUp",
    callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local studs = tonumber(StudInput.value) or 20
        if studs <= 0 then studs = 20 end
        hrp.CFrame = hrp.CFrame + Vector3.new(0, studs, 0)
    end
})

MiscWindow:AddButton({
    text = "Below",
    flag = "tpDown",
    callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local studs = tonumber(StudInput.value) or 20
        if studs <= 0 then studs = 20 end
        hrp.CFrame = hrp.CFrame + Vector3.new(0, -studs, 0)
    end
})

-- Freeze
local isFrozen = false
local freezeLoop = nil

local function setFreeze(state)
    isFrozen = state
    local char = LocalPlayer.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if state then
        if animate then animate.Disabled = true end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(0)
        end
        freezeLoop = RunService.RenderStepped:Connect(function()
            if humanoid and humanoid.Parent then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Speed > 0 then track:AdjustSpeed(0) end
                end
            end
        end)
    else
        if freezeLoop then freezeLoop:Disconnect(); freezeLoop = nil end
        if animate then animate.Disabled = false end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(1)
        end
        applyWalkSpeed(char) 
    end
end

local FreezeToggle = MiscWindow:AddToggle({
    text = "Freeze",
    flag = "freeze",
    state = false,
    callback = function(enabled)
        setFreeze(enabled)
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        FreezeToggle:SetState(not FreezeToggle.state)  -- toggles the UI and triggers the callback
    end
end)



LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if isFrozen then setFreeze(true) end
end)

-- Glide
local TOGGLE_KEY = Enum.KeyCode.F
local MAX_GLIDE_SPEED = -7
local GLIDE_DELAY_AFTER_JUMP = 0.2
local SHOW_TOGGLE_MESSAGE = true

local GLIDE_SYSTEM_ACTIVE = false
local jumpStartTime = 0
local glideChar = nil
local glideHumanoid = nil
local glideRoot = nil
local glideConnections = {}

local GlideToggle = MiscWindow:AddToggle({
    text = "Glide",
    flag = "glide",
    state = false,
    callback = function(enabled)
        GLIDE_SYSTEM_ACTIVE = enabled
        if SHOW_TOGGLE_MESSAGE then
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Glide System",
                    Text = enabled and "Auto-glide enabled on all jumps" or "Auto-glide disabled (normal fall)",
                    Duration = 1.5
                })
            end)
        end
    end
})

local function bindGlideToCharacter(newChar)
    if glideConnections.jumping then glideConnections.jumping:Disconnect() end
    glideChar = newChar
    glideHumanoid = newChar:WaitForChild("Humanoid", 10)
    glideRoot = newChar:WaitForChild("HumanoidRootPart", 10)
    if not glideHumanoid or not glideRoot then return end
    jumpStartTime = 0
    glideConnections.jumping = glideHumanoid.Jumping:Connect(function(isJumping)
        if isJumping then
            jumpStartTime = os.clock()
        end
    end)
end



RunService.Heartbeat:Connect(function()
    if not GLIDE_SYSTEM_ACTIVE then return end
    if not glideHumanoid or not glideRoot or glideHumanoid.Health <= 0 then return end
    local isAirborne = glideHumanoid.FloorMaterial == Enum.Material.Air
    local isFallingDown = glideRoot.Velocity.Y < 0
    local pastJumpUpPhase = (os.clock() - jumpStartTime) >= GLIDE_DELAY_AFTER_JUMP
    if isAirborne and isFallingDown and pastJumpUpPhase then
        local currentVelocity = glideRoot.Velocity
        glideRoot.Velocity = Vector3.new(
            currentVelocity.X,
            math.max(currentVelocity.Y, MAX_GLIDE_SPEED),
            currentVelocity.Z
        )
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    bindGlideToCharacter(newChar)
end)

if LocalPlayer.Character then
    task.spawn(function() bindGlideToCharacter(LocalPlayer.Character) end)
end

-- Remove Legs (Fixed R15)
local legsEnabled = true
local legRespawnConn = nil

local function removeLegsProperly(char)
    if not char then return end
    local humanoid = char:WaitForChild("Humanoid", 3)
    local rootPart = char:WaitForChild("HumanoidRootPart", 3)
    if not humanoid or not rootPart then return end

    -- 1. Delete all leg parts and their Motor6Ds (R15 + R6)
    local legParts = {
        "LeftUpperLeg", "RightUpperLeg",
        "LeftLowerLeg", "RightLowerLeg",
        "LeftFoot", "RightFoot",
        "Left Leg", "Right Leg"
    }
    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local partName = joint.Part1 and joint.Part1.Name or ""
            if table.find(legParts, partName) then
                joint:Destroy()
            end
        end
    end
    for _, partName in ipairs(legParts) do
        local part = char:FindFirstChild(partName) or char:WaitForChild(partName, 1)
        if part then part:Destroy() end
    end

    -- 2. Move the root down (your original look)
    humanoid.HipHeight = 0.4
    task.wait()
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -1.6, 0)

    -- 3. Create a smooth collision base (cylinder to avoid edge snagging)
    local collisionPart = char:FindFirstChild("NoLegsCollision")
    if not collisionPart then
        collisionPart = Instance.new("Part")
        collisionPart.Name = "NoLegsCollision"
        collisionPart.Size = Vector3.new(2, 0.2, 1)  -- same size you had
        collisionPart.Shape = Enum.PartType.Cylinder   -- softer contact
        collisionPart.Transparency = 1
        collisionPart.CanCollide = true
        collisionPart.CanTouch = false
        collisionPart.CanQuery = false
        collisionPart.Massless = true

        -- 4. **CRUCIAL:** Weld it so the bottom sits exactly at the HipHeight plane
        --    HipHeight = 0.4 → bottom at -0.4 below root
        --    Part height = 0.2 → center offset = -0.4 + 0.1 = -0.3
        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = collisionPart
        weld.C0 = CFrame.new(0, -0.3, 0)   -- CORRECTED OFFSET
        weld.Parent = rootPart

        -- 5. Set physics to zero friction / zero bounce (prevents micro‑jitter)
        local physProps = Instance.new("CustomPhysicalProperties")
        physProps.Density = 0.01
        physProps.Friction = 0
        physProps.Elasticity = 0
        physProps.FrictionWeight = 0
        physProps.ElasticityWeight = 0
        collisionPart.CustomPhysicalProperties = physProps

        collisionPart.Parent = char
    end

    -- 6. Disable automatic jumping (often adds upward spikes)
    humanoid.AutoJumpEnabled = false
    humanoid.JumpPower = 0
    humanoid.UseJumpPower = false

    -- 7. Let the humanoid settle naturally – no forced state change
    task.wait(0.05)
    humanoid.PlatformStand = false
    humanoid:Move(Vector3.new(0,0,0), false)
end

MiscWindow:AddToggle({
    text = "Remove Legs",
    flag = "removeLegs",
    state = false,
    callback = function(enabled)
        legsEnabled = not enabled
        if not legsEnabled then
            if LocalPlayer.Character then
                task.spawn(function() removeLegsProperly(LocalPlayer.Character) end)
            end
            legRespawnConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(1.2)
                removeLegsProperly(newChar)
            end)
        else
            if legRespawnConn then
                legRespawnConn:Disconnect()
                legRespawnConn = nil
            end
        end
    end
})

-- ==================== PLAYER ESP ====================
local espObjects = {}
local espRenderConn = nil
local espPlayerAddedConn = nil
local espCharAddedConns = {}
local espCharRemovingConns = {}
local espEnabled = false

local function addESP(character)
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end
    if espObjects[character] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Adornee = character
    highlight.Parent = character

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Distance"
    billboard.Adornee = character:FindFirstChild("Head") or rootPart
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextStrokeTransparency = 0.4
    text.Parent = billboard

    espObjects[character] = {highlight, billboard, text}

    humanoid.Died:Once(function()
        removeESP(character)
    end)
end

local function removeESP(character)
    if not espObjects[character] then return end
    for _, obj in ipairs(espObjects[character]) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects[character] = nil
end

local function clearAllESP()
    for char, _ in pairs(espObjects) do
        removeESP(char)
    end
    for _, conn in pairs(espCharAddedConns) do conn:Disconnect() end
    for _, conn in pairs(espCharRemovingConns) do conn:Disconnect() end
    espCharAddedConns = {}
    espCharRemovingConns = {}
    if espRenderConn then espRenderConn:Disconnect() end
    if espPlayerAddedConn then espPlayerAddedConn:Disconnect() end
end

local function enableESP()
    if espEnabled then return end
    espEnabled = true

    espRenderConn = RunService.RenderStepped:Connect(function()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local charRoot = char:FindFirstChild("HumanoidRootPart")
            if not humanoid or not charRoot or humanoid.Health <= 0 then
                removeESP(char)
                continue
            end

            addESP(char)

            local data = espObjects[char]
            if data then
                local dist = (charRoot.Position - myRoot.Position).Magnitude
                data[3].Text = string.format("%.1fm", dist)
            end
        end

        for char, _ in pairs(espObjects) do
            if not char:IsDescendantOf(workspace) then
                removeESP(char)
            end
        end
    end)

    espPlayerAddedConn = Players.PlayerAdded:Connect(function(player)
        local charAddedConn = player.CharacterAdded:Connect(function(char)
            task.wait()
            addESP(char)
        end)
        local charRemovingConn = player.CharacterRemoving:Connect(function(char)
            removeESP(char)
        end)

        espCharAddedConns[player] = charAddedConn
        espCharRemovingConns[player] = charRemovingConn

        if player.Character then
            task.spawn(function() addESP(player.Character) end)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            task.spawn(function() addESP(player.Character) end)
        end
    end
end

local function disableESP()
    if not espEnabled then return end
    clearAllESP()
    espEnabled = false
end

MiscWindow:AddToggle({
    text = "Esp",
    flag = "esp",
    state = false,
    callback = function(enabled)
        if enabled then
            enableESP()
        else
            disableESP()
        end
    end
})

-- ==================== PET ESP ====================
local PetESP_Connections = {}
local PetESP_Active = false
local Camera = workspace.CurrentCamera

-- Pet ESP configuration & helpers (from provided code)
local ESP_Config = {
    MaxDistance = 9999,
    BoxThickness = 1.5,
    CornerSize = 0.25,
    Font = 2,
    PanelWidth = 110,
    RowHeight = 18,
    RowPadding = 1,
    MinMPS = 50000000,
    OwnPetBoxColor = Color3.fromRGB(100, 255, 100),
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
    if NumMPS >= 200000000 then return ESP_Config.TierColors[3]
    elseif NumMPS >= 100000000 then return ESP_Config.TierColors[2]
    else return ESP_Config.TierColors[1] end
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

local PetESP_Objects = {}
local PetESP_Enabled = true -- controlled by the RenderStepped loop check

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
    if PetESP_Objects[PetModel] then return end

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

    PetESP_Objects[PetModel] = ESP
end

local function RemovePetESP(PetModel)
    local ESP = PetESP_Objects[PetModel]
    if not ESP then return end
    for _, Corner in ipairs(ESP.Corners) do Corner:Remove() end
    ESP.PanelBG:Remove()
    ESP.PanelBorder:Remove()
    for _, Row in ipairs(ESP.Rows) do
        Row.BG:Remove()
        Row.Label:Remove()
        Row.Value:Remove()
    end
    PetESP_Objects[PetModel] = nil
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

local PetRenderStepConn = nil

local function StartPetESP()
    if PetESP_Active then return end
    PetESP_Active = true
    PetESP_Enabled = true

    -- RenderStepped loop
    PetRenderStepConn = RunService.RenderStepped:Connect(function()
        local CameraPos = Camera.CFrame.Position

        for PetModel, ESP in pairs(PetESP_Objects) do
            if not PetESP_Enabled or not PetModel or not PetModel.Parent then
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

            local OwnerId = PetModel:GetAttribute("OwnerUserId")
            local IsOwned = OwnerId == LocalPlayer.UserId
            local BoxColor = IsOwned and ESP_Config.OwnPetBoxColor or TierColor

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

            local InfoRows = {{"MPS", MPS}}

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

    -- RuntimePets watcher
    local RuntimePets = workspace:WaitForChild("RuntimePets", 10)
    if RuntimePets then
        for _, Child in ipairs(RuntimePets:GetChildren()) do
            if Child.Name == "Character" then
                task.wait(0.1)
                AddPetESP(Child)
            end
        end

        local childAddedConn = RuntimePets.ChildAdded:Connect(function(Child)
            task.wait(0.1)
            if Child.Name == "Character" then
                AddPetESP(Child)
            end
        end)
        local childRemovedConn = RuntimePets.ChildRemoved:Connect(RemovePetESP)

        table.insert(PetESP_Connections, childAddedConn)
        table.insert(PetESP_Connections, childRemovedConn)
    end
end

local function StopPetESP()
    if not PetESP_Active then return end
    PetESP_Active = false
    PetESP_Enabled = false

    if PetRenderStepConn then
        PetRenderStepConn:Disconnect()
        PetRenderStepConn = nil
    end

    -- Remove all pet ESP objects
    for petModel, _ in pairs(PetESP_Objects) do
        RemovePetESP(petModel)
    end

    -- Disconnect RuntimePets watchers
    for _, conn in ipairs(PetESP_Connections) do
        conn:Disconnect()
    end
    PetESP_Connections = {}
end

MiscWindow:AddToggle({
    text = "Pet Esp",
    flag = "petesp",
    state = false,
    callback = function(enabled)
        if enabled then
            StartPetESP()
        else
            StopPetESP()
        end
    end
})

-- ============================================================
--  TAB 2 : UNDERGROUND (NEW buttons)
-- ============================================================
local UndergroundWindow = Library:CreateWindow("Underground")

-- ---------- Block Spawner ----------
local BLOCKS_URL = "https://raw.githubusercontent.com/ivxhnnn/rb/refs/heads/main/blocks.lua"
local FOLDER_NAME = "S0ft_Underground"
local RAISE_BY = 40

local spawnButton = nil
spawnButton = UndergroundWindow:AddButton({
    text = "Block Spawner",
    flag = "blockspawner",
    callback = function()
        if spawnButton._cooldown then return end
        spawnButton._cooldown = true

        spawnButton.Text = "⏳ PATCHING CODE..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(80, 60, 0)

        if workspace:FindFirstChild(FOLDER_NAME) then workspace[FOLDER_NAME]:Destroy() end
        local Folder = Instance.new("Folder")
        Folder.Name = FOLDER_NAME
        Folder.Parent = workspace

        local rawCode = game:HttpGet(BLOCKS_URL, true)

        spawnButton.Text = "⏳ REMOVING WAIT..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(80, 60, 0)
        rawCode = rawCode:gsub(
            'ReplicatedStorage:WaitForChild%("UndergroundSpawnEvent"%)',
            '{OnServerEvent = {Connect = function(_,f) task.spawn(f) end}}'
        )
        rawCode = rawCode:gsub('%.Parent = workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = Workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = game%.Workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = game:GetService%("Workspace"%)', '.Parent = ' .. FOLDER_NAME)
        rawCode = 'local ' .. FOLDER_NAME .. ' = workspace:FindFirstChild("' .. FOLDER_NAME .. '")\n' .. rawCode
        rawCode = rawCode:gsub('if not game:IsServer%(%).-end', '')

        local extraBlocks = {}
        local catch = workspace.DescendantAdded:Connect(function(o)
            if o:IsA("BasePart") and not o:IsDescendantOf(CoreGui) and not o:IsDescendantOf(Folder) then
                table.insert(extraBlocks, o)
            end
        end)

        spawnButton.Text = "⏳ SPAWNING BLOCKS..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(0, 60, 120)
        local ok, err = pcall(function()
            local fn, loadErr = loadstring(rawCode)
            if not fn then error("loadstring failed: " .. tostring(loadErr)) end
            fn()
        end)
        task.wait(0.8)
        catch:Disconnect()

        for _, o in ipairs(extraBlocks) do
            if o and o.Parent and not o:IsDescendantOf(Folder) then
                local isNested = false
                for _, other in ipairs(extraBlocks) do
                    if other ~= o and o:IsDescendantOf(other) then isNested = true break end
                end
                if not isNested then o.Parent = Folder end
            end
        end

        spawnButton.Text = "⏳ LIFTING BLOCKS +" .. RAISE_BY .. "..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(60, 0, 120)
        local movedCount = 0
        for _, part in ipairs(Folder:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = part.CFrame + Vector3.new(0, RAISE_BY, 0)
                movedCount += 1
            end
        end

        local totalBlocks = #Folder:GetDescendants()
        if not ok or totalBlocks == 0 then
            spawnButton.Text = "❌ STILL NO BLOCKS"
            spawnButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        else
            spawnButton.Text = `✅ +{RAISE_BY} · {totalBlocks} BLOCKS`
            spawnButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        end

        task.delay(4, function()
            spawnButton.Text = "Block Spawner"
            spawnButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            spawnButton._cooldown = false
        end)
    end
})

-- ---------- Go Underground (toggle with noclip) ----------
local UNDERGROUND_DOWN = 20   
local UNDERGROUND_UP   = 35   

local isUnderground = false
local noclipConnection = nil

local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

local undergroundButton = UndergroundWindow:AddButton({
    text = "Go Underground",
    flag = "gounderground",
    callback = function()
        local char = LocalPlayer.Character
        if not char then
            warn("No character found!")
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found!")
            return
        end

        if not isUnderground then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, -UNDERGROUND_DOWN, 0)
            enableNoclip()
            isUnderground = true
            undergroundButton.Text = "Return to Surface"
            undergroundButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        else
            hrp.CFrame = hrp.CFrame + Vector3.new(0, UNDERGROUND_UP, 0)
            disableNoclip()
            isUnderground = false
            undergroundButton.Text = "Go Underground"
            undergroundButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
    end
})

-- Reset underground state on respawn
LocalPlayer.CharacterAdded:Connect(function()
    if isUnderground then
        disableNoclip()
        isUnderground = false
        undergroundButton.Text = "Go Underground"
        undergroundButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)

-- ============================================================
--  FINAL INIT
-- ============================================================
Library:Init()
if Library.base then
    Library.base.ResetOnSpawn = false
end

-- Auto-fire proximity prompts (optional)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    fireproximityprompt(prompt)
end)
