-- ===================================================
--  Auto Grab Button (Original Panel Z Logic)
--  Draggable • One Click = One Grab
-- ===================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")  -- as in original

-- ========== EXACT findNearestGrabPrompt from Panel Z ==========
local function findNearestGrabPrompt(range)
    range = range or 30
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestPrompt = nil
    local bestDist = range
    local seen = {}

    local containers = {Workspace:FindFirstChild("RuntimePets"), Workspace}
    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and not seen[obj] then
                    seen[obj] = true
                    local model = obj.Parent
                    local partPos
                    if model:IsA("BasePart") then
                        partPos = model.Position
                    elseif model:IsA("Model") then
                        local prim = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                        if prim then partPos = prim.Position end
                    end
                    if partPos then
                        local dist = (root.Position - partPos).Magnitude
                        if dist < bestDist then
                            local txt = obj.Name .. " " .. tostring(obj.ActionText) .. " " .. tostring(obj.ObjectText)
                            local lower = txt:lower()
                            if lower:find("steal") or lower:find("grab") or lower:find("pick") or lower:find("take") then
                                bestDist = dist
                                bestPrompt = obj
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPrompt
end

-- ========== EXACT doAutoGrab from Panel Z ==========
local function doAutoGrab()
    local prompt = findNearestGrabPrompt(30)
    if not prompt then
        -- Optional: print("[Auto Grab] No prompt nearby")
        return
    end

    -- Cancel any ongoing steal (exact same as original)
    pcall(function()
        remoteEvent:FireServer("steal_cancel", remoteEvent)
    end)
    pcall(function()
        remoteEvent:FireServer("steal_cancel")
    end)

    -- Modify prompt for instant activation
    pcall(function()
        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 50
    end)

    -- Fire the prompt multiple times (original logic)
    task.spawn(function()
        for i = 1, 4 do
            if prompt and prompt.Parent then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                end)
            end
            task.wait(0.02)
        end
    end)
end

-- ========== UI: Draggable Button ==========
local gui = Instance.new("ScreenGui")
gui.Name = "AutoGrabButton"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 140, 0, 42)
frame.Position = UDim2.new(0.05, 0, 0.5, -21)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke")
stroke.Parent = frame
stroke.Color = Color3.fromRGB(140, 70, 255)
stroke.Thickness = 1.5

local button = Instance.new("TextButton")
button.Parent = frame
button.Size = UDim2.new(1, 0, 1, 0)
button.BackgroundTransparency = 1
button.Font = Enum.Font.GothamBold
button.Text = "Auto Grab"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 14
button.TextScaled = true
button.TextWrapped = true

-- ========== Dragging Logic ==========
local dragging = false
local dragStart = nil
local dragOrigin = nil

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        dragOrigin = frame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not dragOrigin then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        dragOrigin.X.Scale,
        dragOrigin.X.Offset + delta.X,
        dragOrigin.Y.Scale,
        dragOrigin.Y.Offset + delta.Y
    )
end)

-- ========== Click Action ==========
local clickCooldown = 0
button.MouseButton1Click:Connect(function()
    if tick() - clickCooldown < 0.2 then return end
    clickCooldown = tick()

    -- Visual feedback
    button.Text = "Grabbing..."
    button.TextColor3 = Color3.fromRGB(0, 255, 0)
    task.delay(0.45, function()
        if button and button.Parent then
            button.Text = "Auto Grab"
            button.TextColor3 = Color3.new(1, 1, 1)
        end
    end)

    -- Perform the grab
    doAutoGrab()
end)

-- Also support touch
button.TouchTap:Connect(function()
    if tick() - clickCooldown < 0.2 then return end
    clickCooldown = tick()
    button.Text = "Grabbing..."
    button.TextColor3 = Color3.fromRGB(0, 255, 0)
    task.delay(0.45, function()
        if button and button.Parent then
            button.Text = "Auto Grab"
            button.TextColor3 = Color3.new(1, 1, 1)
        end
    end)
    doAutoGrab()
end)

print("[Auto Grab Button] Loaded. Click to grab the nearest pet.")
