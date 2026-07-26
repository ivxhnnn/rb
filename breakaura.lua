-- =============================================
-- FIXED BREAK AURA v5 | Build A Base And Steal
-- ✅ MATCHES EXACT PATH: Workspace.Plots[N].Builds.Wood Block
-- ✅ ZERO MOVEMENT · ZERO CFRAMES · NO KICKS (Error 267 PROOF)
-- ✅ Only breaks enemy Builds blocks · Never touches terrain
-- =============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, RootPart

-- ========== SAFE CONFIG ==========
local BREAK_RANGE       = 7    -- 6-8 = flamethrower natural range
local BREAK_SPEED       = 0.12  -- human click speed (don't go lower than 0.08)
local ONLY_ENEMY_WALLS  = true  -- never break your own plot
local TOGGLE_KEY        = Enum.KeyCode.O
local DEBUG_PRINTS      = true  -- set false to hide console spam
-- ==================================

-- Get weapon YOU ARE ALREADY HOLDING (no auto-equip = no flags)
local function GetHeldWeapon()
    if not Character then return nil end
    for _, t in Character:GetChildren() do
        if t:IsA("Tool") and t:FindFirstChild("Handle") then return t end
    end
    return nil
end

-- 🔑 EXACT CHECK: Is this part inside Plots[N].Builds ?
local function IsEnemyBuildsBlock(part)
    if not part or not part:IsA("BasePart") then return false end
    if Character and part:IsDescendantOf(Character) then return false end

    -- Walk UP the family tree looking for .Builds folder
    local current = part
    while current and current ~= Workspace do
        -- We found a folder/model named Builds
        if current.Name == "Builds" then
            -- Its parent MUST be a plot inside Workspace.Plots
            local plotModel = current.Parent
            if not plotModel or not plotModel.Parent or plotModel.Parent.Name ~= "Plots" then
                return false
            end

            -- Get plot owner ID (plot name is the number: "6" = user id 6)
            local ownerId = tonumber(plotModel.Name) or plotModel:GetAttribute("Owner")
            if not ownerId then return false end

            -- Skip your own plot if enabled
            if ONLY_ENEMY_WALLS and ownerId == LocalPlayer.UserId then
                return false
            end

            -- ✅ REAL ENEMY BUILDS BLOCK CONFIRMED
            return true
        end
        current = current.Parent
    end
    return false
end

-- Check if ANY enemy Builds block is IN FRONT of you (aim cone)
local function EnemyWallAimed()
    if not RootPart then return false end
    local myPos = RootPart.Position

    -- Scan all plots' Builds folders directly (most accurate)
    local PlotsFolder = Workspace:FindFirstChild("Plots")
    if not PlotsFolder then return false end

    for _, plot in pairs(PlotsFolder:GetChildren()) do
        local Builds = plot:FindFirstChild("Builds")
        if not Builds then continue end

        -- Skip your own plot
        local ownerId = tonumber(plot.Name) or plot:GetAttribute("Owner")
        if ONLY_ENEMY_WALLS and ownerId == LocalPlayer.UserId then continue end

        -- Check every block in this plot's Builds
        for _, blockModel in pairs(Builds:GetChildren()) do
            -- Must be a Model named like "Wood Block", "Stone Block", etc.
            if not blockModel:IsA("Model") or not blockModel.Name:find("Block") then continue end
            local handle = blockModel:FindFirstChild("Handle") or blockModel.PrimaryPart
            if not handle or not handle:IsA("BasePart") then continue end

            -- Range check
            local dist = (myPos - handle.Position).Magnitude
            if dist > BREAK_RANGE then continue end

            -- AIM CHECK: only trigger if you're looking AT the block
            local dirToBlock = (handle.Position - myPos).Unit
            local aimDot = RootPart.CFrame.LookVector:Dot(dirToBlock)
            if aimDot > 0.45 then -- ~60° cone in front of your camera
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

-- =============================================
-- MAIN LOOP — NO MOVEMENT CODE AT ALL
-- =============================================
_G.BREAK_AURA = true
task.spawn(function()
    print("[BreakAura] ✅ LOADED · Target: Plots[N].Builds.*Block")
    print("[BreakAura] ✅ Zero movement mode · Press O to toggle")
    if not Workspace:FindFirstChild("Plots") then warn("[BreakAura] ❌ Workspace.Plots not found!") return end

    while task.wait(BREAK_SPEED) do
        if not _G.BREAK_AURA then continue end
        if not (RootPart and Character and Humanoid and Humanoid.Health > 0) then continue end

        -- 1. Must be holding a weapon manually
        local weapon = GetHeldWeapon()
        if not weapon then continue end

        -- 2. Only fire if you're AIMING at an enemy Builds block
        if not EnemyWallAimed() then continue end

        -- 3. ✅ ONLY SPAM FIRE — EXACTLY LIKE A HUMAN CLICKING
        -- No CFrames, no teleport, no rotation, no handle movement
        pcall(function() weapon:Activate() end)
    end
end)

-- Toggle: Press O
game:GetService("UserInputService").InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == TOGGLE_KEY then
        _G.BREAK_AURA = not _G.BREAK_AURA
        print("[BreakAura]", _G.BREAK_AURA and "✅ ON" or "❌ OFF")
    end
end)
