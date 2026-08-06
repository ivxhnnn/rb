local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local EMOTE_ID = 89115363544461

-- Cache: resolve animation ID only once
local cachedAnimationId = nil

local function resolveAnimationId(assetId)
	if not assetId or assetId == "" then return nil end
	local idNum = tonumber(assetId)
	if not idNum then return nil end

	local objects, success
	local url = "rbxassetid://" .. idNum
	success, objects = pcall(function() return game:GetObjects(url) end)
	if not success or not objects or #objects == 0 then
		return nil
	end

	local function findAnimation(obj)
		if obj:IsA("Animation") then
			local animId = obj.AnimationId
			if animId and animId ~= "" then
				local num = tonumber(animId:match("%d+"))
				if num and num > 0 then return num end
			end
		end
		for _, child in ipairs(obj:GetChildren()) do
			local found = findAnimation(child)
			if found then return found end
		end
		return nil
	end

	local root = objects[1]
	if root then
		local animId = findAnimation(root)
		-- Destroy objects immediately to free memory
		for _, obj in ipairs(objects) do
			pcall(function() obj:Destroy() end)
		end
		if animId then
			return animId
		end
	end
	return nil
end

-- Get the real animation ID (cached)
local function getAnimId()
	if cachedAnimationId then return cachedAnimationId end
	cachedAnimationId = resolveAnimationId(EMOTE_ID) or EMOTE_ID
	return cachedAnimationId
end

-- Play the emote
local function playEmote()
	local char = Player.Character
	if not char then return false, "No character" end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return false, "No humanoid" end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then return false, "No animator" end

	-- Stop existing tracks
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	local animId = getAnimId()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. animId
	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if success and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		return true, "Playing"
	else
		return false, "Failed to load animation"
	end
end

-- Create the standalone GUI (clean connections)
local function createGUI()
	-- Destroy old GUI and disconnect old input connections
	local old = CoreGui:FindFirstChild("PlayDeadButton")
	if old then
		-- If we stored connections inside the old GUI, disconnect them
		if old:GetAttribute("InputBeganConn") then
			old:GetAttribute("InputBeganConn"):Disconnect()
		end
		if old:GetAttribute("InputChangedConn") then
			old:GetAttribute("InputChangedConn"):Disconnect()
		end
		if old:GetAttribute("InputEndedConn") then
			old:GetAttribute("InputEndedConn"):Disconnect()
		end
		old:Destroy()
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "PlayDeadButton"
	screen.Parent = CoreGui
	screen.ResetOnSpawn = false

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 200, 0, 80)
	main.Position = UDim2.new(0.5, -100, 0.5, -40)
	main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	main.BorderSizePixel = 0
	main.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = main

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 30))
	})
	gradient.Rotation = 45
	gradient.Parent = main

	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0.8, 0, 0, 45)
	playBtn.Position = UDim2.new(0.1, 0, 0.5, -22.5)
	playBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	playBtn.BorderSizePixel = 0
	playBtn.Text = "Play Dead"
	playBtn.TextColor3 = Color3.new(1, 1, 1)
	playBtn.Font = Enum.Font.GothamBold
	playBtn.TextSize = 18
	playBtn.Parent = main

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = playBtn

	-- Hover
	playBtn.MouseEnter:Connect(function()
		playBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
	end)
	playBtn.MouseLeave:Connect(function()
		playBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	end)

	-- Click handler (now uses cached animation)
	playBtn.MouseButton1Click:Connect(function()
		playBtn.Text = "⏳"
		playBtn.Active = false

		local ok, msg = playEmote()
		if ok then
			playBtn.Text = "✅ Done"
			task.wait(1.2)
		else
			playBtn.Text = "❌ Fail"
			task.wait(1.2)
		end
		playBtn.Text = "Play Dead"
		playBtn.Active = true
	end)

	-- Close button
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 25, 0, 25)
	close.Position = UDim2.new(1, -30, 0, 5)
	close.BackgroundTransparency = 1
	close.Text = "✕"
	close.TextColor3 = Color3.fromRGB(180, 180, 180)
	close.Font = Enum.Font.Gotham
	close.TextSize = 16
	close.Parent = main
	close.MouseEnter:Connect(function()
		close.TextColor3 = Color3.new(1, 1, 1)
	end)
	close.MouseLeave:Connect(function()
		close.TextColor3 = Color3.fromRGB(180, 180, 180)
	end)

	-- Store connections so we can disconnect them later
	local inputBeganConn
	local inputChangedConn
	local inputEndedConn

	-- Dragging
	local dragging, dragStart, startPos
	inputBeganConn = main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)

	inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	-- Save connections to the screen so we can disconnect them when destroying
	screen:SetAttribute("InputBeganConn", inputBeganConn)
	screen:SetAttribute("InputChangedConn", inputChangedConn)
	screen:SetAttribute("InputEndedConn", inputEndedConn)

	-- Clean up everything when the close button is clicked
	close.MouseButton1Click:Connect(function()
		inputBeganConn:Disconnect()
		inputChangedConn:Disconnect()
		inputEndedConn:Disconnect()
		screen:Destroy()
	end)
end

createGUI()
