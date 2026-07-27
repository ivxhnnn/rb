-- Tora Script | MISC ONLY (100% Working Walk Speed + All Features)
-- Library: https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew

-- =============================================
-- SERVICES
-- =============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local LocalPlayer = Players.LocalPlayer

-- =============================================
-- LOAD TORA UI LIBRARY
-- =============================================
local existingTora = CoreGui:FindFirstChild("ToraScript")
if existingTora then existingTora:Destroy() end

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()

-- =============================================
-- ONLY WINDOW: MISC
-- =============================================
local MiscWindow = Library:CreateWindow("MISC")

-- =============================================
-- 1. ANTI FALL BUTTON
-- =============================================
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

-- =============================================
-- 2. 100% PERMANENT WALK SPEED (FIXED!)
-- =============================================
local wsConnections = {}
local desiredWalkSpeed = 30 -- Syncs with slider

-- Core apply function (impossible for game to overwrite)
local function applyWalkSpeed(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not hrp then return end

    -- Clear old loops to prevent duplicates
    if wsConnections.maintainLoop then wsConnections.maintainLoop:Disconnect() end
    if wsConnections.propertyGuard then wsConnections.propertyGuard:Disconnect() end

    -- Set speed immediately
    humanoid.WalkSpeed = desiredWalkSpeed
    print("[WS] Set to: " .. desiredWalkSpeed)

    -- ✅ FIX 1: Use RenderStepped (RUNS LAST - game can't overwrite after this)
    wsConnections.maintainLoop = RunService.RenderStepped:Connect(function()
        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            -- Always read latest value from library flag + our variable
            local current = tonumber(Library.flags.walkspeed) or desiredWalkSpeed
            humanoid.WalkSpeed = current
        end
    end)

    -- ✅ FIX 2: Instantly revert if game tries to change WalkSpeed
    wsConnections.propertyGuard = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if math.abs(humanoid.WalkSpeed - desiredWalkSpeed) > 0.1 then
            humanoid.WalkSpeed = desiredWalkSpeed
        end
    end)
end

-- Walk Speed Slider
MiscWindow:AddSlider({
    text = "Walk Speed",
    flag = "walkspeed",
    value = 30,
    min = 30,
    max = 49,
    callback = function(newValue)
        desiredWalkSpeed = tonumber(newValue)
        Library.flags.walkspeed = desiredWalkSpeed -- Force sync library flag
        applyWalkSpeed(LocalPlayer.Character)
    end
})

-- ✅ FIX 3: Re-apply on respawn + keep values
wsConnections.respawnListener = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    task.wait(1.5) -- Wait for character to fully load
    applyWalkSpeed(newCharacter)
end)

-- Apply on first script load
if LocalPlayer.Character then
    task.spawn(function() applyWalkSpeed(LocalPlayer.Character) end)
end

-- =============================================
-- 3. VERTICAL TELEPORT
-- =============================================
MiscWindow:AddLabel({ text = "Vertical Teleport" })

local StudInput = MiscWindow:AddBox({
    text = "Stud Amount",
    flag = "studAmount",
    value = "20",
    callback = function() end
})

MiscWindow:AddButton({
    text = "⬆ Teleport Above",
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
    text = "⬇ Teleport Below",
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

-- =============================================
-- 4. FREEZE (FIXED - no longer breaks Walk Speed)
-- =============================================
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
        -- Only stop ANIMATIONS - never touch WalkSpeed or Humanoid states
        if animate then animate.Disabled = true end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(0)
        end
        -- Keep new animations frozen too
        freezeLoop = RunService.RenderStepped:Connect(function()
            if humanoid and humanoid.Parent then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Speed > 0 then track:AdjustSpeed(0) end
                end
            end
        end)
    else
        -- Restore everything fully
        if freezeLoop then freezeLoop:Disconnect(); freezeLoop = nil end
        if animate then animate.Disabled = false end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:AdjustSpeed(1)
        end
        -- Force refresh WalkSpeed after unfreezing
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

-- Keep freeze state through death
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if isFrozen then setFreeze(true) end
end)

-- =============================================
-- INITIALIZE UI + FINAL WS FIX
-- =============================================
Library:Init()

-- ✅ FIX 4: OVERRIDE TORA LIBRARY BUG - never reset GUI on death
if Library.base then
    Library.base.ResetOnSpawn = false
end

-- =============================================
-- AUTO-FIRE PROXIMITY PROMPTS
-- =============================================
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    fireproximityprompt(prompt)
end)
