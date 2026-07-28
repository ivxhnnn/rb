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


local TOGGLE_KEY = Enum.KeyCode.F            
local MAX_GLIDE_SPEED = -6                  
local GLIDE_DELAY_AFTER_JUMP = 0.2          
local SHOW_TOGGLE_MESSAGE = true             


local GLIDE_SYSTEM_ACTIVE = false            
local jumpStartTime = 0


player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	jumpStartTime = 0
end)


UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 
	if input.KeyCode ~= TOGGLE_KEY then return end

	
	GLIDE_SYSTEM_ACTIVE = not GLIDE_SYSTEM_ACTIVE

	if SHOW_TOGGLE_MESSAGE then
		local stateText = GLIDE_SYSTEM_ACTIVE and "<font color='#50fa7b'>✅ GLIDE: ON</font>" or "<font color='#ff6b6b'>❌ GLIDE: OFF</font>"
		StarterGui:SetCore("SendNotification", {
			Title = "Glide System",
			Text = GLIDE_SYSTEM_ACTIVE and "Auto-glide enabled on all jumps" or "Auto-glide disabled (normal fall)",
			Duration = 1.5
		})
	end
end)


humanoid.Jumping:Connect(function(isJumping)
	if isJumping then
		jumpStartTime = os.clock()
	end
end)


RunService.Heartbeat:Connect(function()
	
	if not GLIDE_SYSTEM_ACTIVE then return end
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
	local isFallingDown = rootPart.Velocity.Y < 0
	local pastJumpUpPhase = (os.clock() - jumpStartTime) >= GLIDE_DELAY_AFTER_JUMP


	if isAirborne and isFallingDown and pastJumpUpPhase then
		local currentVelocity = rootPart.Velocity
		rootPart.Velocity = Vector3.new(
			currentVelocity.X,
			math.max(currentVelocity.Y, MAX_GLIDE_SPEED), 
			currentVelocity.Z
		)
	end
end)
