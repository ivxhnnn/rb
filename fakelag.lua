
local Players = game:GetService("Players")
local player = Players.LocalPlayer


if game.CoreGui:FindFirstChild("FakeLagGUI") then
    game.CoreGui.FakeLagGUI:Destroy()
end


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FakeLagGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false


local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Parent = ScreenGui
MainPanel.Size = UDim2.new(0, 200, 0, 280)
MainPanel.Position = UDim2.new(0.5, -100, 0.5, -140)
MainPanel.BackgroundColor3 = Color3.new(0, 0, 0)
MainPanel.BackgroundTransparency = 0.1
MainPanel.Active = true
MainPanel.Draggable = true 

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = MainPanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainPanel
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding")
UIPadding.Parent = MainPanel
UIPadding.PaddingTop = UDim.new(0, 18)
UIPadding.PaddingBottom = UDim.new(0, 18)
UIPadding.PaddingLeft = UDim.new(0, 10)
UIPadding.PaddingRight = UDim.new(0, 10)


local function CreateButton(name, text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = MainPanel
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.AutoButtonColor = false
    btn.Active = true
    btn.Draggable = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateTextBox(name, placeholder, default, order)
    local tb = Instance.new("TextBox")
    tb.Name = name
    tb.Parent = MainPanel
    tb.LayoutOrder = order
    tb.Size = UDim2.new(1, -20, 0, 35)
    tb.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    tb.BackgroundTransparency = 0.2
    tb.PlaceholderText = placeholder
    tb.Text = default
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Font = Enum.Font.SourceSans
    tb.TextSize = 15
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
    return tb
end


local FakeLagBtn = CreateButton("FakeLagBtn", "FakeLag: OFF", 1, nil)
local WaitBox = CreateTextBox("WaitBox", "Update Rate", "0.3", 2)
local DelayBox = CreateTextBox("DelayBox", "Freeze Length", "0.3", 3)
local FallBtn = CreateButton("FallBtn", "Toggle Fall", 4, nil)
local DestroyBtn = CreateButton("DestroyBtn", "Close GUI", 5, function()
    ScreenGui:Destroy()
end)


local FakeLagEnabled = false
local WaitTime = 0.3  -- Update Rate
local DelayTime = 0.3 -- Freeze Length
local FallEnabled = false


FakeLagBtn.MouseButton1Click:Connect(function()
    FakeLagEnabled = not FakeLagEnabled
    FakeLagBtn.Text = FakeLagEnabled and "FakeLag: ON" or "FakeLag: OFF"
    FakeLagBtn.BackgroundColor3 = FakeLagEnabled and Color3.new(0, 0.55, 0) or Color3.new(0.1, 0.1, 0.1)
end)


WaitBox.FocusLost:Connect(function()
    WaitTime = math.clamp(tonumber(WaitBox.Text) or 0.3, 0.01, 1)
    WaitBox.Text = string.format("%.1f", WaitTime)
end)

DelayBox.FocusLost:Connect(function()
    DelayTime = math.clamp(tonumber(DelayBox.Text) or 0.3, 0.01, 1)
    DelayTime.Text = string.format("%.1f", DelayTime)
end)


coroutine.wrap(function()
    while task.wait(WaitTime) do
        if FakeLagEnabled then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if root and hum and hum.Health > 0 then
                root.Anchored = true
                task.wait(DelayTime)
                root.Anchored = false
            end
        end
    end
end)()


FallBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        FallEnabled = not FallEnabled
        hum.PlatformStand = FallEnabled
        FallBtn.Text = FallEnabled and "Stand Up" or "Toggle Fall"
        FallBtn.BackgroundColor3 = FallEnabled and Color3.new(0.55, 0, 0) or Color3.new(0.1, 0.1, 0.1)
        if FallEnabled then
            hum:Move(Vector3.new(0, -50, 0))
        end
    end
end)
