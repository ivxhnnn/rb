
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer


local existingTora = CoreGui:FindFirstChild("ToraScript")
if existingTora then existingTora:Destroy() end

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()


local MiscWindow = Library:CreateWindow("MISC")


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
        local studs = tonumber(StudInput.value) or 35
        if studs <= 0 then studs = 35 end
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
        local studs = tonumber(StudInput.value) or 35
        if studs <= 0 then studs = 35 end
        hrp.CFrame = hrp.CFrame + Vector3.new(0, -studs, 0)
    end
})


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

MiscWindow:AddToggle({
    text = "Freeze",
    flag = "freeze",
    state = false,
    callback = function(enabled)
        setFreeze(enabled)
    end
})


LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if isFrozen then setFreeze(true) end
end)



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
    text = "Glide [Press F]",
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


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= TOGGLE_KEY then return end
    
    local newState = not GLIDE_SYSTEM_ACTIVE
    GlideToggle:SetState(newState)
end)


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


Library:Init()

if Library.base then
    Library.base.ResetOnSpawn = false
end


ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    fireproximityprompt(prompt)
end)
