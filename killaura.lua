
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, RootPart


local RANGE        = 20     
local ATTACK_SPEED = 0.00000000000000000000001   
local AUTO_EQUIP   = true  


local function GetWeapon()
    if not Character then return nil end
   
    for _, t in Character:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
    end
    
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in bp:GetChildren() do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
        end
    end
    return nil
end

local function RefreshChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end
RefreshChar()
LocalPlayer.CharacterAdded:Connect(RefreshChar)


task.spawn(function()
    print("[KillAura] Loaded · Range: "..RANGE.." studs")
    while task.wait(ATTACK_SPEED) do
        if not (Character and Humanoid and RootPart and Humanoid.Health > 0) then continue end

        local weapon = GetWeapon()
        if not weapon then continue end
        if AUTO_EQUIP and weapon.Parent ~= Character then
            pcall(function() weapon.Parent = Character end)
            task.wait(0.03)
        end

        local myPos = RootPart.Position
        local hitAny = false
        for _, plr in pairs(Players:GetPlayers()) do
            if plr == LocalPlayer or not plr.Character then continue end
            local eHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local eHum = plr.Character:FindFirstChild("Humanoid")
            if not (eHrp and eHum and eHum.Health > 0) then continue end

            
            if (myPos - eHrp.Position).Magnitude <= RANGE then
                hitAny = true
            
                pcall(function() weapon:Activate() end)
                
            end
        end

        
        if hitAny then pcall(function() if weapon then weapon:Activate() end end) end
    end
end)


_G.KA_ON = true
game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.P then
        _G.KA_ON = not _G.KA_ON
        print("[KillAura]", _G.KA_ON and "✅ ON" or "❌ OFF")
    end
end)
