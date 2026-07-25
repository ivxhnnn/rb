-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Player refs
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ⚙️ CONFIG — TWEAK THESE
local MAX_GLIDE_SPEED = -4   -- Slower fall: -2 = very slow, -5 = gentle, -8 = mild
local GLIDE_DELAY = 0.15     -- Small delay after jumping so you still go UP first (seconds)

local jumpStartTime = 0

-- Re-bind on respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Detect when player jumps
humanoid.Jumping:Connect(function(isJumping)
	if isJumping then
		jumpStartTime = os.clock()
	end
end)

-- Auto-glide logic (every physics frame)
RunService.Heartbeat:Connect(function()
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local isFalling = rootPart.Velocity.Y < 0
	local enoughTimePassed = (os.clock() - jumpStartTime) >= GLIDE_DELAY

	-- Auto-glide WHILE falling in air (after the jump's upward part)
	if isAirborne and isFalling and enoughTimePassed then
		local vel = rootPart.Velocity
		rootPart.Velocity = Vector3.new(
			vel.X,
			math.max(vel.Y, MAX_GLIDE_SPEED), -- Clamp fall speed
			vel.Z
		)
	end
end)
