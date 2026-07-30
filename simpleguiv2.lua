local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer


-- Clean up old Tora instance
local existingTora = CoreGui:FindFirstChild("ToraScript")
if existingTora then existingTora:Destroy() end

-- Load library ONCE
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()


-- ============================================================
--  TAB 1 : MISC (original features)
-- ============================================================
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


-- Remove Legs (Fixed R15)
local legsEnabled = true
local legRespawnConn = nil

local function removeLegsProperly(char)
    if not char then return end
    local humanoid = char:WaitForChild("Humanoid", 3)
    local rootPart = char:WaitForChild("HumanoidRootPart", 3)
    if not humanoid or not rootPart then return end

    local r15PartsToDelete = {
        "LeftUpperLeg", "RightUpperLeg",
        "LeftLowerLeg", "RightLowerLeg",
        "LeftFoot", "RightFoot"
    }
    local r6PartsToDelete = {"Left Leg", "Right Leg"}
    local allParts = table.clone(r15PartsToDelete)
    for _, p in r6PartsToDelete do table.insert(allParts, p) end

    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local partName = joint.Part1 and joint.Part1.Name or ""
            if table.find(allParts, partName) then
                joint:Destroy()
            end
        end
    end

    for _, partName in ipairs(allParts) do
        local part = char:FindFirstChild(partName) or char:WaitForChild(partName, 1)
        if part then part:Destroy() end
    end

    humanoid.HipHeight = 0.4
    task.wait()
    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -1.6, 0)

    local existingBase = char:FindFirstChild("NoLegsCollision")
    if not existingBase then
        local collisionBase = Instance.new("Part")
        collisionBase.Name = "NoLegsCollision"
        collisionBase.Size = Vector3.new(2, 0.2, 1)
        collisionBase.Transparency = 1
        collisionBase.CanCollide = true
        collisionBase.CanTouch = false
        collisionBase.CanQuery = false
        collisionBase.Massless = true
        collisionBase.Parent = char

        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = collisionBase
        weld.C0 = CFrame.new(0, -1.1, 0)
        weld.Parent = rootPart
    end

    humanoid.AutoRotate = true
    task.wait(0.05)
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
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
