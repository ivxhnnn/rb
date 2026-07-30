
-- YOUR BLOCKS LINK (KEEP THIS)
local BLOCKS_URL = "https://raw.githubusercontent.com/ivxhnnn/rb/refs/heads/main/blocks.lua"
local FOLDER_NAME = "S0ft_Underground"
-- ✅ AUTO-RAISE HEIGHT (change this number if you want more/less than 40)
local RAISE_BY = 40

local CoreGui = game:GetService("CoreGui")

-- Clean old GUI
if CoreGui:FindFirstChild("FinalBlockSpawner") then CoreGui.FinalBlockSpawner:Destroy() end

-- Make 1 Button
local Gui = Instance.new("ScreenGui")
Gui.Name = "FinalBlockSpawner"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(0, 220, 0, 60)
Btn.Position = UDim2.new(0, 20, 0, 20)
Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Btn.TextColor3 = Color3.new(1,1,1)
Btn.TextScaled = true
Btn.Font = Enum.Font.GothamBold
Btn.Text = "SPAWN BLOCKS"
Btn.BorderSizePixel = 0
Btn.Parent = Gui
Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 12)

-- ==============================================
-- MAGIC: AUTO-PATCH + SPAWN + AUTO-RAISE 40 UP
-- ==============================================
local cooldown = false
Btn.MouseButton1Click:Connect(function()
    if cooldown then return end
    cooldown = true
    Btn.Text = "⏳ PATCHING CODE..."
    Btn.BackgroundColor3 = Color3.fromRGB(80, 60, 0)

    -- 1. DELETE OLD + MAKE FOLDER FIRST
    if workspace:FindFirstChild(FOLDER_NAME) then workspace[FOLDER_NAME]:Destroy() end
    local Folder = Instance.new("Folder")
    Folder.Name = FOLDER_NAME
    Folder.Parent = workspace
    print("✅ Folder ready: Workspace > " .. FOLDER_NAME)

    -- 2. DOWNLOAD YOUR RAW CODE
    local rawCode = game:HttpGet(BLOCKS_URL, true)
    print("✅ Downloaded code (" .. #rawCode .. " chars)")

    -- 3. 🧩 AUTO-PATCH THE CODE (CUT OUT SERVER STUFF)
    Btn.Text = "⏳ REMOVING WAIT..."
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

    -- 4. SAFELY CATCH EXTRA BLOCKS (backup)
    local extraBlocks = {}
    local catch = workspace.DescendantAdded:Connect(function(o)
        if o:IsA("BasePart") and not o:IsDescendantOf(CoreGui) and not o:IsDescendantOf(Folder) then
            table.insert(extraBlocks, o)
        end
    end)

    -- 5. RUN PATCHED CODE
    Btn.Text = "⏳ SPAWNING BLOCKS..."
    Btn.BackgroundColor3 = Color3.fromRGB(0, 60, 120)
    local ok, err = pcall(function() loadstring(rawCode)() end)
    task.wait(0.8) -- Give it time to spawn everything
    catch:Disconnect()

    -- 6. MOVE ANY LEFTOVER BLOCKS INTO FOLDER
    for _, o in ipairs(extraBlocks) do
        if o and o.Parent and not o:IsDescendantOf(Folder) then
            local isNested = false
            for _, other in ipairs(extraBlocks) do
                if other ~= o and o:IsDescendantOf(other) then isNested = true break end
            end
            if not isNested then o.Parent = Folder end
        end
    end

    -- ⬆️⬆️⬆️ AUTO-RAISE ALL BLOCKS +40 STUDS (INTEGRATED STEP)
    Btn.Text = "⏳ LIFTING BLOCKS +" .. RAISE_BY .. "..."
    Btn.BackgroundColor3 = Color3.fromRGB(60, 0, 120)
    local movedCount = 0
    for _, part in ipairs(Folder:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CFrame = part.CFrame + Vector3.new(0, RAISE_BY, 0)
            movedCount += 1
        end
    end
    print(`✅ Lifted {movedCount} blocks UP by {RAISE_BY} studs automatically`)

    -- 7. COUNT + FINISH
    local totalBlocks = #Folder:GetDescendants()
    if not ok or totalBlocks == 0 then
        Btn.Text = "❌ STILL NO BLOCKS"
        Btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        warn("❌ Run error: " .. tostring(err))
    else
        Btn.Text = `✅ +{RAISE_BY} · {totalBlocks} BLOCKS`
        Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        print("🎉 DONE! " .. totalBlocks .. " blocks lifted +" .. RAISE_BY .. " → Workspace > " .. FOLDER_NAME)
    end

    task.delay(4, function()
        Btn.Text = "SPAWN BLOCKS"
        Btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
        cooldown = false
    end)
end)
