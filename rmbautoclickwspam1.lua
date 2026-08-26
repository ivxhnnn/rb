--[[
Auto Clicker - RMB ONLY + Press 1x2 on Release
- Hold RMB = Auto Click
- Release RMB = Press key "1" TWO TIMES instantly
- Adjustable Clicks Per Second
]]

-- Services
local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Player Setup
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

-- Remove old UI if exists
if PlayerGui:FindFirstChild("AutoClickerUI") then
    PlayerGui.AutoClickerUI:Destroy()
end

-- Create Screen GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoClickerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- --------------------------
-- SETTINGS
-- --------------------------
local Settings = {
    ClicksPerSecond = 100,        -- Default speed (was 999999)
    KeyHeld = false,
    PressKeyOnRelease = Enum.KeyCode.One,
    PressCount = 2,
    PressDelay = 0.0000000000000000000000000001             -- Increased to a reliable value
}

local Colors = {
    Background = Color3.fromRGB(25, 25, 30),
    Header = Color3.fromRGB(40, 40, 45),
    Accent = Color3.fromRGB(0, 160, 255),
    Text = Color3.fromRGB(240, 240, 240),
    Green = Color3.fromRGB(46, 204, 113),
    Red = Color3.fromRGB(231, 76, 60),
    Input = Color3.fromRGB(55, 55, 60)
}

-- --------------------------
-- CREATE UI
-- --------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = Colors.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(10, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "RMB Auto Clicker + 1x2"
Title.TextColor3 = Colors.Text
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Helper functions
local function Label(text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.9, 0, 0, 25)
    lbl.Position = UDim2.new(0.05, 0, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.SourceSansSemibold
    lbl.TextSize = 14
    lbl.Parent = MainFrame
    return lbl
end

local function Input(y, default)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.9, 0, 0, 32)
    box.Position = UDim2.new(0.05, 0, 0, y)
    box.BackgroundColor3 = Colors.Input
    box.BorderSizePixel = 0
    box.Text = tostring(default)
    box.TextColor3 = Colors.Text
    box.Font = Enum.Font.SourceSans
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = MainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    return box
end

-- UI Elements
Label("Clicks Per Second:", 45)
local ClicksBox = Input(72, Settings.ClicksPerSecond)

Label("On Release: Press 1 × 2", 110)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 25)
Status.Position = UDim2.new(0.05, 0, 0, 145)
Status.BackgroundTransparency = 1
Status.Text = "Status: OFF"
Status.TextColor3 = Colors.Red
Status.Font = Enum.Font.SourceSansBold
Status.TextSize = 14
Status.Parent = MainFrame

-- --------------------------
-- LOGIC
-- --------------------------
local function RefreshSettings()
    Settings.ClicksPerSecond = math.clamp(tonumber(ClicksBox.Text) or 15, 1, 50)
end

-- Simulate mouse click
local function DoClick()
    local mousePos = UserInputService:GetMouseLocation()
    local insetY = GuiService:GetGuiInset().Y
    local x, y = mousePos.X, mousePos.Y + insetY
    VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 1) -- 0 = LMB
    task.wait(0.0003)
    VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- Debounce for key‑press sequence
local isPressingKeys = false

-- Simulate pressing a keyboard key (twice) with reliable delays
local function PressKeyTwice(keyCode)
    if isPressingKeys then return end      -- Prevent overlapping runs
    isPressingKeys = true

    for i = 1, Settings.PressCount do
        -- Press down
        VirtualInput:SendKeyEvent(true, keyCode, false, game)
        task.wait(Settings.PressDelay)     -- Let the game register the down event

        -- Release up
        VirtualInput:SendKeyEvent(false, keyCode, false, game)
        task.wait(Settings.PressDelay)     -- Wait before next press

        -- Additional small wait between presses (already included above)
    end

    isPressingKeys = false
end

-- Main click loop
task.spawn(function()
    while true do
        task.wait()
        RefreshSettings()

        if Settings.KeyHeld then
            Status.Text = "Status: ON"
            Status.TextColor3 = Colors.Green
            local delay = 1 / Settings.ClicksPerSecond
            DoClick()
            task.wait(delay)
        else
            Status.Text = "Status: OFF"
            Status.TextColor3 = Colors.Red
        end
    end
end)

-- Input detection
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- RMB pressed
        Settings.KeyHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- RMB released
        Settings.KeyHeld = false
        -- Press key "1" two times right after releasing
        task.spawn(function()
            PressKeyTwice(Settings.PressKeyOnRelease)
        end)
    end
end)
