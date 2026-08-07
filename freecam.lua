
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Variables
local freecamEnabled = false
local camPart = nil
local camConnection = nil
local freecamSpeed = 40

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleFreecam"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false


local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 45)
button.Position = UDim2.new(1, -170, 0, 20) 
button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Freecam: OFF"
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.AutoButtonColor = true
button.Parent = screenGui

-- 3. Toggle Logic
local function toggleFreecam(state)
    if state then
        -- [ENABLE FREECAM]
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        
        -- Anchor the character so it doesn't fall down or move
        local root = player.Character.HumanoidRootPart
        root.Anchored = true
        
        -- Create an invisible part to act as the camera anchor
        camPart = Instance.new("Part")
        camPart.Name = "FreecamPart"
        camPart.Anchored = true
        camPart.Transparency = 1
        camPart.CanCollide = false
        camPart.Size = Vector3.new(1, 1, 1)
        camPart.Parent = workspace
        camPart.CFrame = camera.CFrame 
        
       
        camera.CameraSubject = camPart
        
        
        camConnection = RunService.RenderStepped:Connect(function()
            if not camPart then return end
            
            -- Get Directions
            local lookVector = camera.CFrame.LookVector
            local rightVector = camera.CFrame.RightVector
            local upVector = Vector3.new(0, 1, 0) -- World up
            
        
            local movement = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement = movement + lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement = movement - lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement = movement - rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement = movement + rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then movement = movement + upVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then movement = movement - upVector end
            
            
            if movement.Magnitude > 0 then
                camPart.CFrame = camPart.CFrame + (movement.Unit * freecamSpeed * 0.1) -- 0.1 adjusts for framerate
            end
        end)
        
        button.Text = "Freecam: ON"
        freecamEnabled = true
        
    else
    
        if camConnection then camConnection:Disconnect() camConnection = nil end
        if camPart then camPart:Destroy() camPart = nil end
        
    
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
  
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
        
        button.Text = "Freecam: OFF"
        freecamEnabled = false
    end
end


button.MouseButton1Click:Connect(function()
    toggleFreecam(not freecamEnabled)
end)


player.CharacterAdded:Connect(function()
    if freecamEnabled then
        toggleFreecam(false)
    end
end)

