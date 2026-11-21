--!nonstrict
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local MODE          = "fling"
local ENABLED       = false
local FLING_SPEED   = 6500
local DRIVE_SECONDS = 1.1
local DRIVE_STEP    = 14

local tracked  = {}
local launched = {}

local Theme = {
    Bg       = Color3.fromRGB(18, 18, 24),
    Panel    = Color3.fromRGB(26, 26, 34),
    Raised   = Color3.fromRGB(38, 38, 50),
    Stroke   = Color3.fromRGB(58, 58, 74),
    Text     = Color3.fromRGB(245, 245, 250),
    Muted    = Color3.fromRGB(150, 150, 170),
    Accent   = Color3.fromRGB(139, 92, 246),
    Accent2  = Color3.fromRGB(56, 189, 248),
    Danger   = Color3.fromRGB(248, 68, 68),
    Success  = Color3.fromRGB(52, 211, 153),
}

local function make(class, props)
    local inst = Instance.new(class)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            inst[key] = value
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function round(parent, radius)
    local corner = make("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
    return corner
end

local function stroke(parent, color, thickness)
    local s = make("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    return s
end

local function pad(parent, top, bottom, left, right)
    return make("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        Parent = parent,
    })
end

for _, old in ipairs(PlayerGui:GetChildren()) do
    if old.Name == "ChaserControlGui" then
        old:Destroy()
    end
end

local ScreenGui = make("ScreenGui", {
    Name = "ChaserControlGui",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
    Parent = PlayerGui,
})

local Window = make("Frame", {
    Name = "Window",
    BackgroundColor3 = Theme.Bg,
    Position = UDim2.new(0, 24, 0.5, -110),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 250, 0, 220),
    Parent = ScreenGui,
})
round(Window, 12)
stroke(Window, Theme.Stroke, 1)

local TitleBar = make("Frame", {
    Name = "TitleBar",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 42),
    Parent = Window,
})

local Title = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "CHASER CONTROL",
    TextColor3 = Theme.Text,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 14, 0, 5),
    Size = UDim2.new(1, -28, 0, 18),
    Parent = TitleBar,
})

local Subtitle = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "PAS_DoorCopy · client-owned",
    TextColor3 = Theme.Muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 14, 0, 23),
    Size = UDim2.new(1, -28, 0, 14),
    Parent = TitleBar,
})

local CloseButton = make("TextButton", {
    BackgroundColor3 = Theme.Raised,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Theme.Muted,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.new(0, 24, 0, 24),
    AutoButtonColor = false,
    Parent = TitleBar,
})
round(CloseButton, 6)

local Content = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 46),
    Size = UDim2.new(1, -24, 1, -58),
    Parent = Window,
})
local List = make("UIListLayout", {
    Padding = UDim.new(0, 8),
    Parent = Content,
})

local StatusFrame = make("Frame", {
    BackgroundColor3 = Theme.Panel,
    Size = UDim2.new(1, 0, 0, 34),
    Parent = Content,
})
round(StatusFrame, 8)
stroke(StatusFrame, Theme.Stroke, 1)

local StatusDot = make("Frame", {
    BackgroundColor3 = Theme.Danger,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 12, 0.5, 0),
    Size = UDim2.new(0, 10, 0, 10),
    Parent = StatusFrame,
})
round(StatusDot, 5)
local DotStroke = stroke(StatusDot, Theme.Danger, 2)
DotStroke.Transparency = 0.4

local StatusLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "OFF",
    TextColor3 = Theme.Text,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 30, 0, 0),
    Size = UDim2.new(1, -42, 1, 0),
    Parent = StatusFrame,
})

local TrackedLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "tracked: 0 · launched: 0",
    TextColor3 = Theme.Muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, -12, 1, 0),
    Parent = StatusFrame,
})

local function makeButton(text, callback, color)
    local button = make("TextButton", {
        BackgroundColor3 = color or Theme.Raised,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, 34),
        Parent = Content,
    })
    round(button, 8)
    button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            warn("[ChaserControl] " .. tostring(err))
        end
    end)
    return button
end

local ToggleButton = makeButton("ENABLE", function()
    ENABLED = not ENABLED
    if not ENABLED then
        for model, part in pairs(tracked) do
            pcall(function()
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        launched = {}
    end
    refreshUI()
end, Theme.Accent)

local ModeFrame = make("Frame", {
    BackgroundColor3 = Theme.Panel,
    Size = UDim2.new(1, 0, 0, 34),
    Parent = Content,
})
round(ModeFrame, 8)
stroke(ModeFrame, Theme.Stroke, 1)
local modeList = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    Parent = ModeFrame,
})
pad(ModeFrame, 0, 0, 6, 6)

local function makeModeButton(name)
    local button = make("TextButton", {
        BackgroundColor3 = Theme.Raised,
        Text = name:upper(),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Muted,
        AutoButtonColor = false,
        Size = UDim2.new(0.5, -3, 0, 24),
        Parent = ModeFrame,
    })
    round(button, 6)
    button.MouseButton1Click:Connect(function()
        MODE = name
        launched = {}
        refreshUI()
    end)
    return button
end

local FlingButton = makeModeButton("fling")
local FreezeButton = makeModeButton("freeze")

local function makeSlider(labelText, minValue, maxValue, initialValue, onChange)
    local frame = make("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, 0, 0, 46),
        Parent = Content,
    })
    round(frame, 8)
    stroke(frame, Theme.Stroke, 1)

    local label = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = labelText,
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -86, 0, 16),
        Parent = frame,
    })

    local valueLabel = make("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(initialValue),
        TextColor3 = Theme.Accent2,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -10, 0, 5),
        Size = UDim2.new(0, 70, 0, 16),
        Parent = frame,
    })

    local track = make("Frame", {
        BackgroundColor3 = Theme.Raised,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 6),
        Parent = frame,
    })
    round(track, 3)

    local fill = make("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 1, 0),
        Parent = track,
    })
    round(fill, 3)

    local value = initialValue
    local dragging = false

    local function applyFromX(x)
        local relative = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local nextValue = minValue + (maxValue - minValue) * relative
        nextValue = math.floor(nextValue + 0.5)
        value = math.clamp(nextValue, minValue, maxValue)
        fill.Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0)
        valueLabel.Text = tostring(value)
        onChange(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            applyFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            applyFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return frame
end

makeSlider("FLING SPEED", 1000, 12000, FLING_SPEED, function(value)
    FLING_SPEED = value
end)
makeSlider("DRIVE TIME", 1, 30, DRIVE_SECONDS * 10, function(value)
    DRIVE_SECONDS = value / 10
end)

local Hint = make("TextLabel", {
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "drag title bar · targets need ReceiveAge == 0",
    TextColor3 = Theme.Muted,
    TextSize = 10,
    TextWrapped = true,
    Size = UDim2.new(1, 0, 0, 26),
    Parent = Content,
})

function refreshUI()
    ToggleButton.Text = ENABLED and "DISABLE" or "ENABLE"
    ToggleButton.BackgroundColor3 = ENABLED and Theme.Success or Theme.Accent

    StatusLabel.Text = ENABLED and (MODE:upper() .. " · ON") or "OFF"
    StatusDot.BackgroundColor3 = ENABLED and Theme.Success or Theme.Danger
    DotStroke.Color = StatusDot.BackgroundColor3

    FlingButton.BackgroundColor3 = MODE == "fling" and Theme.Accent or Theme.Raised
    FreezeButton.BackgroundColor3 = MODE == "freeze" and Theme.Accent or Theme.Raised
    FlingButton.TextColor3 = MODE == "fling" and Theme.Text or Theme.Muted
    FreezeButton.TextColor3 = MODE == "freeze" and Theme.Text or Theme.Muted
end

refreshUI()

local draggingWindow = false
local dragInput = nil
local dragStart = Vector2.new()
local startPosition = Window.Position

local function beginDrag(input)
    draggingWindow = true
    dragStart = input.Position
    startPosition = Window.Position
end

local function updateDrag(input)
    if not draggingWindow then
        return
    end

    local delta = input.Position - dragStart
    Window.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        beginDrag(input)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingWindow = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
        updateDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and draggingWindow then
        updateDrag(input)
    end
end)

local function isTarget(model)
    if not (model:IsA("Model") and model.Parent) then
        return false
    end

    local steer = model:GetAttribute("PAS_Steer")
    local runUser = model:GetAttribute("PAS_RunUser")

    return steer == LocalPlayer.UserId or runUser == LocalPlayer.UserId
end

local function partOf(model)
    local part = model.PrimaryPart

    if not (part and part:IsA("BasePart") and part.Parent) then
        return nil
    end

    return part
end

local function ownedByClient(part)
    return part.ReceiveAge == 0
end

local function stopSteering(model)
    pcall(function()
        model:SetAttribute("PAS_Steer", nil)
    end)
end

local function zeroMotion(part)
    pcall(function()
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end
    )
end

local function launchChaser(model, part)
    if launched[model] then
        return
    end

    launched[model] = true
    stopSteering(model)

    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")

    if not (myRoot and myRoot:IsA("BasePart")) then
        return
    end

    local delta = part.Position - myRoot.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)

    if flat.Magnitude < 0.5 then
        flat = Vector3.new(myRoot.CFrame.LookVector.X, 0, myRoot.CFrame.LookVector.Z)
    end

    if flat.Magnitude < 0.5 then
        flat = Vector3.new(1, 0, 0)
    end

    local direction = (flat.Unit + Vector3.new(0, 1.15, 0)).Unit
    local speed = FLING_SPEED
    local driveTime = DRIVE_SECONDS

    task.spawn(function()
        local started = os.clock()

        while part.Parent and ENABLED and os.clock() - started < driveTime do
            pcall(function()
                part.AssemblyLinearVelocity = direction * speed
                part.AssemblyAngularVelocity = Vector3.new(
                    math.random(-500, 500),
                    math.random(-500, 500),
                    math.random(-500, 500)
                )
                part.CFrame = part.CFrame + direction * DRIVE_STEP
            end)

            task.wait(0.03)
        end

        zeroMotion(part)
    end)
end

local uiClock = 0

RunService.PreSimulation:Connect(function()
    if not ENABLED then
        return
    end

    local trackedCount = 0

    for _, model in ipairs(CollectionService:GetTagged("PAS_DoorCopy")) do
        if isTarget(model) then
            local part = partOf(model)

            if part and ownedByClient(part) then
                tracked[model] = part
                trackedCount += 1

                if MODE == "freeze" then
                    stopSteering(model)
                    zeroMotion(part)
                elseif MODE == "fling" then
                    launchChaser(model, part)
                end
            end
        end
    end

    for model, part in pairs(tracked) do
        if not model.Parent or not part.Parent then
            tracked[model] = nil
            launched[model] = nil
        elseif MODE == "freeze" and ENABLED then
            stopSteering(model)
            zeroMotion(part)
        end
    end

    uiClock += 1
    if uiClock % 20 == 0 then
        local launchedCount = 0
        for _ in pairs(launched) do
            launchedCount += 1
        end
        TrackedLabel.Text = "tracked: " .. trackedCount .. " · launched: " .. launchedCount
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ENABLED = false
    for _, part in pairs(tracked) do
        zeroMotion(part)
    end
    launched = {}
    ScreenGui:Destroy()
end)
