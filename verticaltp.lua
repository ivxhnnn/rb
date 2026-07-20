--tp above and below script
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======================
-- CREATE ALL GUI ELEMENTS
-- ======================
local TeleportGui = Instance.new("ScreenGui")
TeleportGui.Name = "VerticalTeleport"
TeleportGui.ResetOnSpawn = false
TeleportGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
TeleportGui.Parent = playerGui

-- Main Frame (perfect size for your layout)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 180)
MainFrame.Position = UDim2.new(0.02, 0, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.15
MainFrame.ClipsDescendants = true
MainFrame.Parent = TeleportGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

local Shadow = Instance.new("UIStroke")
Shadow.Color = Color3.fromRGB(80, 80, 80)
Shadow.Thickness = 1
Shadow.Transparency = 0.4
Shadow.Parent = MainFrame

-- Title Bar (Close button fits perfectly)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Vertical Teleport"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button (matches your screenshot exactly)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 50, 0, 35)
CloseBtn.Position = UDim2.new(1, -70, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "Close"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- Input Box: SET DEFAULT TEXT TO 20
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.9, 0, 0, 55)
InputBox.Position = UDim2.new(0.05, 0, 0.28, 0)
InputBox.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
InputBox.PlaceholderText = "Enter studs"
InputBox.Text = "20" -- ✅ DEFAULT VALUE SET TO 20
InputBox.TextColor3 = Color3.new(1,1,1)
InputBox.TextScaled = true
InputBox.Font = Enum.Font.Gotham
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

-- ✅ Fixed Buttons: Equal size, proper spacing, match your look
local BtnUp = Instance.new("TextButton")
BtnUp.Size = UDim2.new(0.46, 0, 0, 60)
BtnUp.Position = UDim2.new(0.03, 0, 0.62, 0)
BtnUp.BackgroundColor3 = Color3.fromRGB(50, 170, 80)
BtnUp.Text = "⬆ Above"
BtnUp.TextColor3 = Color3.new(1,1,1)
BtnUp.TextScaled = true
BtnUp.Font = Enum.Font.GothamBold
BtnUp.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 10)
BtnCorner1.Parent = BtnUp

local BtnDown = Instance.new("TextButton")
BtnDown.Size = UDim2.new(0.46, 0, 0, 60)
BtnDown.Position = UDim2.new(0.51, 0, 0.62, 0)
BtnDown.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
BtnDown.Text = "⬇ Below"
BtnDown.TextColor3 = Color3.new(1,1,1)
BtnDown.TextScaled = true
BtnDown.Font = Enum.Font.GothamBold
BtnDown.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 10)
BtnCorner2.Parent = BtnDown

-- Open Button (toggle works same as before)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 100, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0, 70)
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 60)
OpenBtn.Text = "Teleport"
OpenBtn.TextColor3 = Color3.new(1,1,1)
OpenBtn.TextScaled = true
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Visible = false
OpenBtn.Parent = TeleportGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenBtn

-- ======================
-- DRAGGABLE LOGIC (unchanged)
-- ======================
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ======================
-- TELEPORT LOGIC (fixed to use default safely)
-- ======================
local function doTeleport(direction)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Use 20 as fallback if input is invalid
    local amount = tonumber(InputBox.Text) or 20
    if amount <= 0 then
        InputBox.Text = "Invalid!"
        task.wait(1.5)
        InputBox.Text = "20" -- Reset back to default
        return
    end

    hrp.CFrame = hrp.CFrame + Vector3.new(0, direction * amount, 0)
end

BtnUp.MouseButton1Click:Connect(function()
    doTeleport(1) -- Move UP
end)

BtnDown.MouseButton1Click:Connect(function()
    doTeleport(-1) -- Move DOWN
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)
