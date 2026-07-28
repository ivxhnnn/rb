-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Player refs
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local MAX_GLIDE_SPEED = -4   
local GLIDE_DELAY = 0.15     

local jumpStartTime = 0


player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end)


humanoid.Jumping:Connect(function(isJumping)
	if isJumping then
		jumpStartTime = os.clock()
	end
end)


RunService.Heartbeat:Connect(function()
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local isFalling = rootPart.Velocity.Y < 0
	local enoughTimePassed = (os.clock() - jumpStartTime) >= GLIDE_DELAY

	
	if isAirborne and isFalling and enoughTimePassed then
		local vel = rootPart.Velocity
		rootPart.Velocity = Vector3.new(
			vel.X,
			math.max(vel.Y, MAX_GLIDE_SPEED), 
			vel.Z
		)
	end
end)
