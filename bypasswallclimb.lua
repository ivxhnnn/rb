local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Always get fresh character reference
local function getCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    return char, char:WaitForChild("Humanoid")
end

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = true -- Auto-clean on respawn
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0, 10)
button.BackgroundColor3 = Color3.new(0.2, 0.5, 0.8)
button.Text = "Toggle Ragdoll"
button.Parent = screenGui

local isRagdoll = false

-- Safe enable: CLEAN UP FIRST before adding new
local function enableRagdoll()
    local character, humanoid = getCharacter()
    if not humanoid or humanoid.Health <= 0 then return end

    -- First delete ANY leftover ragdoll objects
    for _, obj in pairs(character:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or obj:IsA("Attachment") then
            obj:Destroy()
        end
    end

    -- Now build fresh ragdoll
    for _, joint in pairs(character:GetDescendants()) do
        if joint:IsA("Motor6D") then
            local att0 = Instance.new("Attachment", joint.Part0)
            att0.Position = joint.C0.Position

            local att1 = Instance.new("Attachment", joint.Part1)
            att1.Position = joint.C1.Position

            local constraint = Instance.new("BallSocketConstraint")
            constraint.Attachment0 = att0
            constraint.Attachment1 = att1
            constraint.Parent = joint.Part1

            joint.Enabled = false
        end
    end

    humanoid.PlatformStand = true
end

-- Safe disable: restore motors properly
local function disableRagdoll()
    local character, humanoid = getCharacter()
    if not humanoid then return end

    -- Re-enable all motors first
    for _, joint in pairs(character:GetDescendants()) do
        if joint:IsA("Motor6D") then
            joint.Enabled = true
        end
    end

    -- Remove all ragdoll physics objects
    for _, obj in pairs(character:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or obj:IsA("Attachment") then
            obj:Destroy()
        end
    end

    humanoid.PlatformStand = false
end

local function toggleRagdoll()
    isRagdoll = not isRagdoll
    if isRagdoll then
        enableRagdoll()
    else
        disableRagdoll()
    end
end

button.MouseButton1Click:Connect(toggleRagdoll)

-- Reset state on respawn
player.CharacterAdded:Connect(function()
    isRagdoll = false
end)
