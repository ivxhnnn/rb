-- ============================================================
--  Configuration
-- ============================================================
local Config = {
    Categories = {
        MOVEMENT = {
            WallClimb = {
                Enabled = false
            }
        }
    }
}

-- ============================================================
--  Core Wall Climb Logic (runs every frame)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

RunService.Heartbeat:Connect(function()
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    if Config.Categories.MOVEMENT.WallClimb.Enabled then
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0.1 then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { character }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local hit = workspace:Raycast(
                rootPart.Position,
                moveDir * 3,
                rayParams
            )

            if hit then
                rootPart.AssemblyLinearVelocity = Vector3.new(
                    rootPart.AssemblyLinearVelocity.X,
                    45,
                    rootPart.AssemblyLinearVelocity.Z
                )
            end
        end
    end
end)

-- ============================================================
--  GUI Creation
-- ============================================================
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WallClimbGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 60)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "Wall Climb [T]"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.Arcade
    title.TextSize = 18
    title.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 120, 0, 30)
    toggle.Position = UDim2.new(0.5, -60, 0, 25)
    toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    toggle.BorderSizePixel = 1
    toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.Arcade
    toggle.TextSize = 16
    toggle.Parent = frame

    -- Update button appearance and Config state
    local function updateToggle()
        local enabled = Config.Categories.MOVEMENT.WallClimb.Enabled
        toggle.Text = enabled and "ON" or "OFF"
        toggle.BackgroundColor3 = enabled and Color3.fromRGB(150, 0, 255) or Color3.fromRGB(45, 45, 45)
    end

    toggle.MouseButton1Click:Connect(function()
        Config.Categories.MOVEMENT.WallClimb.Enabled = not Config.Categories.MOVEMENT.WallClimb.Enabled
        updateToggle()
    end)

    -- Return the update function so we can call it from outside (keybind)
    return updateToggle
end

-- ============================================================
--  Create GUI and store the update function
-- ============================================================
local guiUpdate = nil
pcall(function()
    guiUpdate = createGUI()
end)

-- ============================================================
--  Keybind: Press 'T' to toggle
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end  -- ignore if typing in chat, etc.
    if input.KeyCode == Enum.KeyCode.T then
        Config.Categories.MOVEMENT.WallClimb.Enabled = not Config.Categories.MOVEMENT.WallClimb.Enabled
        if guiUpdate then
            guiUpdate()   -- refresh the GUI button
        end
    end
end)
