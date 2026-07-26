-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-- Player refs
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ⚙️ CONFIG — EDIT THESE VALUES
local TOGGLE_KEY = Enum.KeyCode.F            -- Key to press to turn glide ON/OFF (try F, G, Q, LeftAlt, etc.)
local MAX_GLIDE_SPEED = -6                   -- Fall speed when glide is ON: -2 = very slow, -5 = gentle, -8 = barely slowed
local GLIDE_DELAY_AFTER_JUMP = 0.2          -- Wait after jumping so you still go UP fully before gliding kicks in
local SHOW_TOGGLE_MESSAGE = true             -- Show "Glide ON/OFF" in chat when you press the key

-- Internal states (don't touch)
local GLIDE_SYSTEM_ACTIVE = false            -- Start with glide OFF by default
local jumpStartTime = 0

-- Re-bind everything properly when you respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	jumpStartTime = 0
end)

-- ✅ TOGGLE LOGIC: Press key once = flip ON/OFF
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore if Roblox is using the input (e.g. typing in chat)
	if input.KeyCode ~= TOGGLE_KEY then return end

	-- Flip the glide system state
	GLIDE_SYSTEM_ACTIVE = not GLIDE_SYSTEM_ACTIVE

	-- Show feedback so you know what happened
	if SHOW_TOGGLE_MESSAGE then
		local stateText = GLIDE_SYSTEM_ACTIVE and "<font color='#50fa7b'>✅ GLIDE: ON</font>" or "<font color='#ff6b6b'>❌ GLIDE: OFF</font>"
		StarterGui:SetCore("SendNotification", {
			Title = "Glide System",
			Text = GLIDE_SYSTEM_ACTIVE and "Auto-glide enabled on all jumps" or "Auto-glide disabled (normal fall)",
			Duration = 1.5
		})
	end
end)

-- Track when you jump (to add the small delay)
humanoid.Jumping:Connect(function(isJumping)
	if isJumping then
		jumpStartTime = os.clock()
	end
end)

-- 🚀 Glide physics (runs every physics frame)
RunService.Heartbeat:Connect(function()
	-- Do NOTHING if glide system is toggled OFF
	if not GLIDE_SYSTEM_ACTIVE then return end
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local isFallingDown = rootPart.Velocity.Y < 0
	local pastJumpUpPhase = (os.clock() - jumpStartTime) >= GLIDE_DELAY_AFTER_JUMP

	-- Only slow fall when all conditions are true
	if isAirborne and isFallingDown and pastJumpUpPhase then
		local currentVelocity = rootPart.Velocity
		rootPart.Velocity = Vector3.new(
			currentVelocity.X,
			math.max(currentVelocity.Y, MAX_GLIDE_SPEED), -- Lock fall speed to our limit
			currentVelocity.Z
		)
	end
end)
