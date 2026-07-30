
local BLOCKS_URL = "https://raw.githubusercontent.com/ivxhnnn/rb/refs/heads/main/blocks.lua"
local FOLDER_NAME = "S0ft_Underground"
local RAISE_BY = 40

local UNDERGROUND_DOWN = 20   
local UNDERGROUND_UP   = 35   

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer


local existingTora = CoreGui:FindFirstChild("ToraScript")
if existingTora then existingTora:Destroy() end


local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/liebertsx/Tora-Library/main/src/librarynew",
    true
))()


local MainWindow = Library:CreateWindow("Underground")

-- ------------------------------------------------------------
-- BUTTON 1: BLOCK SPAWNER
-- ------------------------------------------------------------
local spawnButton = nil
spawnButton = MainWindow:AddButton({
    text = "Block Spawner",
    flag = "blockspawner",
    callback = function()
        if spawnButton._cooldown then return end
        spawnButton._cooldown = true

        spawnButton.Text = "⏳ PATCHING CODE..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(80, 60, 0)

        -- 1. DELETE OLD + MAKE FOLDER
        if workspace:FindFirstChild(FOLDER_NAME) then workspace[FOLDER_NAME]:Destroy() end
        local Folder = Instance.new("Folder")
        Folder.Name = FOLDER_NAME
        Folder.Parent = workspace
        print("✅ Folder ready: Workspace > " .. FOLDER_NAME)

        -- 2. DOWNLOAD RAW CODE
        local rawCode = game:HttpGet(BLOCKS_URL, true)
        print("✅ Downloaded code (" .. #rawCode .. " chars)")

        -- 3. AUTO-PATCH
        spawnButton.Text = "⏳ REMOVING WAIT..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(80, 60, 0)
        rawCode = rawCode:gsub(
            'ReplicatedStorage:WaitForChild%("UndergroundSpawnEvent"%)',
            '{OnServerEvent = {Connect = function(_,f) task.spawn(f) end}}'
        )
        rawCode = rawCode:gsub('%.Parent = workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = Workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = game%.Workspace', '.Parent = ' .. FOLDER_NAME)
        rawCode = rawCode:gsub('%.Parent = game:GetService%("Workspace"%)', '.Parent = ' .. FOLDER_NAME)
        rawCode = 'local ' .. FOLDER_NAME .. ' = workspace:FindFirstChild("' .. FOLDER_NAME .. '")\n' .. rawCode
        rawCode = rawCode:gsub('if not game:IsServer%(%).-end', '')
        print("✅ Code patched — removed server waits")

        -- 4. SAFELY CATCH EXTRA BLOCKS
        local extraBlocks = {}
        local catch = workspace.DescendantAdded:Connect(function(o)
            if o:IsA("BasePart") and not o:IsDescendantOf(CoreGui) and not o:IsDescendantOf(Folder) then
                table.insert(extraBlocks, o)
            end
        end)

        -- 5. RUN PATCHED CODE
        spawnButton.Text = "⏳ SPAWNING BLOCKS..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(0, 60, 120)
        local ok, err = pcall(function()
            local fn, loadErr = loadstring(rawCode)
            if not fn then error("loadstring failed: " .. tostring(loadErr)) end
            fn()
        end)
        task.wait(0.8)
        catch:Disconnect()

        -- 6. MOVE LEFTOVER BLOCKS INTO FOLDER
        for _, o in ipairs(extraBlocks) do
            if o and o.Parent and not o:IsDescendantOf(Folder) then
                local isNested = false
                for _, other in ipairs(extraBlocks) do
                    if other ~= o and o:IsDescendantOf(other) then isNested = true break end
                end
                if not isNested then o.Parent = Folder end
            end
        end

        -- 7. AUTO-RAISE
        spawnButton.Text = "⏳ LIFTING BLOCKS +" .. RAISE_BY .. "..."
        spawnButton.BackgroundColor3 = Color3.fromRGB(60, 0, 120)
        local movedCount = 0
        for _, part in ipairs(Folder:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = part.CFrame + Vector3.new(0, RAISE_BY, 0)
                movedCount += 1
            end
        end
        print(`✅ Lifted {movedCount} blocks UP by {RAISE_BY} studs automatically`)

        -- 8. COUNT + FINISH
        local totalBlocks = #Folder:GetDescendants()
        if not ok or totalBlocks == 0 then
            spawnButton.Text = "❌ STILL NO BLOCKS"
            spawnButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            warn("❌ Run error: " .. tostring(err) .. " | Total blocks: " .. totalBlocks)
        else
            spawnButton.Text = `✅ +{RAISE_BY} · {totalBlocks} BLOCKS`
            spawnButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
            print("🎉 DONE! " .. totalBlocks .. " blocks lifted +" .. RAISE_BY .. " → Workspace > " .. FOLDER_NAME)
        end

        task.delay(4, function()
            spawnButton.Text = "Block Spawner"
            spawnButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            spawnButton._cooldown = false
        end)
    end
})

-- ------------------------------------------------------------
-- BUTTON 2: GO UNDERGROUND (toggle with noclip)
-- ------------------------------------------------------------
local isUnderground = false   -- track current state
local noclipConnection = nil  -- store the RunService connection

-- Noclip functions (from your code, slightly adjusted)
local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    -- Restore collision on all parts (optional but good practice)
    local char = LocalPlayer.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
    end
end

-- The underground button
local undergroundButton = MainWindow:AddButton({
    text = "Go Underground",
    flag = "gounderground",
    callback = function()
        local char = LocalPlayer.Character
        if not char then
            warn("No character found!")
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            warn("HumanoidRootPart not found!")
            return
        end

        if not isUnderground then
            -- Go DOWN
            hrp.CFrame = hrp.CFrame + Vector3.new(0, -UNDERGROUND_DOWN, 0)
            enableNoclip()
            isUnderground = true
            undergroundButton.Text = "Return to Surface"  -- update button text
            undergroundButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
            print("🔽 Went underground (noclip ON)")
        else
            -- Go UP
            hrp.CFrame = hrp.CFrame + Vector3.new(0, UNDERGROUND_UP, 0)
            disableNoclip()
            isUnderground = false
            undergroundButton.Text = "Go Underground"
            undergroundButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)  -- reset to default
            print("🔼 Returned to surface (noclip OFF)")
        end
    end
})

Library:Init()
if Library.base then
    Library.base.ResetOnSpawn = false
end

-- (Optional) auto-disable noclip on respawn to avoid stuck states
LocalPlayer.CharacterAdded:Connect(function()
    if isUnderground then
        -- If we were underground, we might want to reset state? 
        -- Better to disable noclip and reset flag to avoid confusion.
        disableNoclip()
        isUnderground = false
        undergroundButton.Text = "Go Underground"
        undergroundButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
end)
