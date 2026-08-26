-- Load Tora's Library (UI style from the sample)
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()

-- Create the only window/tab named "Fight in a School"
local FightWindow = Library:CreateWindow("Fight in a School")

-- ============================================================
-- ORIGINAL HITBOX & MACRO LOGIC (unchanged)
-- ============================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local sizeValue = 10
local transparencyValue = 1
local seeHitbox = false

local animSpeedEnabled = false
local animSpeedMultiplier = 3
local isAnimating = false

-- Custom locomotion IDs from your game (excluded from speed-up)
local locomotionIds = {
    "17819453109", "17791965866", "17791968544", "127576302225448",
    "17843420785", "18149335682", "93440471136854", "17837722603",
    "18362264385", "17843420785", "18377436533", "18377445949",
    "17855214456", "17855239745", "17819453109"
}

-- Hitbox functions
local function setAllPartsNonCollidable(character)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CanTouch = true
            part.CanQuery = true
        end
    end
end

local function UpdatePlayers()
    if not enabled then return end
    local trans = seeHitbox and 0 or transparencyValue
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local Root = player.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                Root.Size = Vector3.new(sizeValue, sizeValue, sizeValue)
                Root.Transparency = trans
                Root.CanCollide = false
                Root.CanTouch = true
                Root.CanQuery = true
            end
            setAllPartsNonCollidable(player.Character)
        end
    end
end

-- Anim Speed
local function modifyAnimationSpeed()
    spawn(function()
        while isAnimating do
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    for _, anim in pairs(humanoid:GetPlayingAnimationTracks()) do
                        local animId = anim.Animation.AnimationId:match("%d+")
                        if animId and not table.find(locomotionIds, animId) then
                            anim:AdjustSpeed(animSpeedMultiplier)
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function toggleAnimation(on)
    if on then
        if not isAnimating then
            isAnimating = true
            modifyAnimationSpeed()
        end
    else
        isAnimating = false
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, anim in pairs(humanoid:GetPlayingAnimationTracks()) do
                    local animId = anim.Animation.AnimationId:match("%d+")
                    if animId and not table.find(locomotionIds, animId) then
                        anim:AdjustSpeed(1)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AUTO-CLICKER LOGIC (merged from the second script)
-- ============================================================
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

-- Auto-clicker settings (defaults from the new script)
local autoClickerEnabled = false
local clicksPerSecond = 100          -- default CPS
local keyHeld = false
local pressKeyOnRelease = Enum.KeyCode.One
local pressCount = 2
local pressDelay = 0.000000000000000000000000000001

-- Debounce for key press sequence
local isPressingKeys = false

-- Simulate mouse click (LMB)
local function DoClick()
    local mousePos = UserInputService:GetMouseLocation()
    local insetY = GuiService:GetGuiInset().Y
    local x, y = mousePos.X, mousePos.Y + insetY
    VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 1) -- 0 = LMB
    task.wait(0.0003)
    VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- Simulate pressing a keyboard key (twice)
local function PressKeyTwice(keyCode)
    if isPressingKeys then return end
    isPressingKeys = true
    for i = 1, pressCount do
        VirtualInput:SendKeyEvent(true, keyCode, false, game)
        task.wait(pressDelay)
        VirtualInput:SendKeyEvent(false, keyCode, false, game)
        task.wait(pressDelay)
    end
    isPressingKeys = false
end

-- Main click loop (runs in background)
task.spawn(function()
    while true do
        task.wait()
        if autoClickerEnabled and keyHeld then
            local delay = 1 / clicksPerSecond
            DoClick()
            task.wait(delay)
        end
    end
end)

-- Input detection for RMB
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if autoClickerEnabled then
            keyHeld = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        keyHeld = false
        if autoClickerEnabled then
            task.spawn(function()
                PressKeyTwice(pressKeyOnRelease)
            end)
        end
    end
end)

-- ============================================================
-- UI CONTROLS (Tora style)
-- ============================================================

-- Hitbox Expander Toggle
FightWindow:AddToggle({
    text = "Enable Hitbox Expander",
    flag = "EnableHitbox",
    state = true,
    callback = function(Value)
        enabled = Value
        if enabled then
            UpdatePlayers()
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local Root = player.Character:FindFirstChild("HumanoidRootPart")
                    if Root then
                        Root.Size = Vector3.new(4,2,1)
                        Root.Transparency = 1
                        Root.CanCollide = true
                    end
                end
            end
        end
    end
})

-- Hitbox Size Slider
FightWindow:AddSlider({
    text = "Hitbox Size (studs)",
    flag = "HitboxSize",
    value = 9,
    min = 1,
    max = 15,
    callback = function(Value)
        sizeValue = Value
        UpdatePlayers()
    end
})

-- Hitbox Transparency Slider
FightWindow:AddSlider({
    text = "Hitbox Transparency",
    flag = "HitboxTransparency",
    value = 1,
    min = 0,
    max = 1,
    increment = 0.1,
    callback = function(Value)
        transparencyValue = Value
        UpdatePlayers()
    end
})

-- See Hitbox Toggle
FightWindow:AddToggle({
    text = "See Hitbox (Visible)",
    flag = "SeeHitbox",
    state = false,
    callback = function(Value)
        seeHitbox = Value
        UpdatePlayers()
    end
})

-- Macro Toggle (Animation Speed)
FightWindow:AddToggle({
    text = "Macro",
    flag = "AnimSpeed",
    state = true,
    callback = function(Value)
        animSpeedEnabled = Value
        toggleAnimation(Value)
    end
})

-- Macro Speed Slider
FightWindow:AddSlider({
    text = "Macro Speed",
    flag = "AnimMultiplier",
    value = 2.5,
    min = 1,
    max = 2,
    increment = 0.1,
    callback = function(Value)
        animSpeedMultiplier = Value
    end
})

-- ============================================================
-- NEW: AUTO-CLICKER CONTROLS
-- ============================================================

-- Master toggle for auto-clicker
FightWindow:AddToggle({
    text = "Auto Clicker (RMB)",
    flag = "AutoClicker",
    state = true,
    callback = function(Value)
        autoClickerEnabled = Value
        if not Value then
            keyHeld = false   -- prevent stuck clicks
        end
    end
})

-- Text box for Clicks Per Second
FightWindow:AddBox({
    text = "CPS (clicks per second)",
    flag = "CPS",
    value = "100",   -- default as string
    callback = function(Value)
        local num = tonumber(Value)
        if num then
            clicksPerSecond = math.clamp(num, 1, 50)
        else
            clicksPerSecond = 100
        end
    end
})

-- ============================================================
-- ORIGINAL BACKGROUND TASKS (hitbox update, FPS cap)
-- ============================================================

-- Auto hitbox updates
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        UpdatePlayers()
    end)
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    UpdatePlayers()
end)

spawn(function()
    while true do
        task.wait(5)
        UpdatePlayers()
    end
end)

setfpscap(1000000)

-- Initialize Tora library
Library:Init()  
