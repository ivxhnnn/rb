
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, RootPart


local BREAK_RANGE       = 7    
local BREAK_SPEED       = 0.12  
local ONLY_ENEMY_WALLS  = true  
local TOGGLE_KEY        = Enum.KeyCode.O
local DEBUG_PRINTS      = true  



local function GetHeldWeapon()
    if not Character then return nil end
    for _, t in Character:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
    end
    return nil
end

local function IsEnemyBuildsBlock(part)
    if not part or not part:IsA("BasePart") then return false end
    if Character and part:IsDescendantOf(Character) then return false end

    
    local current = part
    while current and current ~= Workspace do
    
        if current.Name == "Builds" then
         
            local plotModel = current.Parent
            if not plotModel or not plotModel.Parent or plotModel.Parent.Name ~= "Plots" then
                return false
            end

          
            local ownerId = tonumber(plotModel.Name) or plotModel:GetAttribute("Owner")
            if not ownerId then return false end

            if ONLY_ENEMY_WALLS and ownerId == LocalPlayer.UserId then
                return false
            end

            return true
        end
        current = current.Parent
    end
    return false
end


local function EnemyWallAimed()
    if not RootPart then return false end
    local myPos = RootPart.Position

    local PlotsFolder = Workspace:FindFirstChild("Plots")
    if not PlotsFolder then return false end

    for _, plot in pairs(PlotsFolder:GetChildren()) do
        local Builds = plot:FindFirstChild("Builds")
        if not Builds then continue end

     
        local ownerId = tonumber(plot.Name) or plot:GetAttribute("Owner")
        if ONLY_ENEMY_WALLS and ownerId == LocalPlayer.UserId then continue end

      
        for _, blockModel in pairs(Builds:GetChildren()) do
        
            if not blockModel:IsA("Model") or not blockModel.Name:find("Block") then continue end
            local handle = blockModel:FindFirstChild("Handle") or blockModel.PrimaryPart
            if not handle or not handle:IsA("BasePart") then continue end

          
            local dist = (myPos - handle.Position).Magnitude
            if dist > BREAK_RANGE then continue end

          
            local dirToBlock = (handle.Position - myPos).Unit
            local aimDot = RootPart.CFrame.LookVector:Dot(dirToBlock)
            if aimDot > 0.45 then 
                if DEBUG_PRINTS then
                    print(string.format("[BreakAura] 🎯 Target: %s | Plot: %s | Dist: %.1f | Aim: %.2f",
                        blockModel.Name, plot.Name, dist, aimDot))
                end
                return true
            end
        end
    end
    return false
end

local function RefreshChar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end
RefreshChar()
LocalPlayer.CharacterAdded:Connect(RefreshChar)


_G.BREAK_AURA = true
task.spawn(function()
    print("[BreakAura] ✅ LOADED · Target: Plots[N].Builds.*Block")
    print("[BreakAura] ✅ Zero movement mode · Press O to toggle")
    if not Workspace:FindFirstChild("Plots") then warn("[BreakAura] ❌ Workspace.Plots not found!") return end

    while task.wait(BREAK_SPEED) do
        if not _G.BREAK_AURA then continue end
        if not (RootPart and Character and Humanoid and Humanoid.Health > 0) then continue end

     
        local weapon = GetHeldWeapon()
        if not weapon then continue end

        if not EnemyWallAimed() then continue end

   
        pcall(function() weapon:Activate() end)
    end
end)


game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == TOGGLE_KEY then
        _G.BREAK_AURA = not _G.BREAK_AURA
        print("[BreakAura]", _G.BREAK_AURA and "✅ ON" or "❌ OFF")
    end
end)
