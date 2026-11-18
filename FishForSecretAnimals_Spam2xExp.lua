-- [ Auto Farm & Auto Train Script ]
-- Target: Fish for Secret Animals!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Fetch Remotes
local StartTraining = Remotes:WaitForChild("StartTraining")
local DoubleRep = Remotes:WaitForChild("DoubleRep")
local CastBegin = Remotes:WaitForChild("CastBegin")
local Cast = Remotes:WaitForChild("Cast")
local ClaimCatch = Remotes:WaitForChild("ClaimCatch")

-- Configuration
local AUTO_TRAIN_ENABLED = true
local AUTO_FARM_ENABLED = true
local TRAIN_DELAY = 0.5 -- Delay between training reps
local FARM_DELAY = 2.5  -- Delay between fishing casts

-- =====================
-- AUTO TRAINING LOGIC
-- =====================
task.spawn(function()
    while AUTO_TRAIN_ENABLED do
        pcall(function()
            -- Fire the training remote
            StartTraining:FireServer()
            
            -- Spam the 2x remote (the server handles whether the popup is actually visible/active)
            DoubleRep:FireServer()
        end)
        task.wait(TRAIN_DELAY)
    end
end)

-- =====================
-- AUTO FARMING LOGIC
-- =====================
task.spawn(function()
    while AUTO_FARM_ENABLED do
        pcall(function()
            -- 1. Begin the cast sequence
            local beginSuccess, beginData = CastBegin:InvokeServer()
            
            if beginSuccess then
                task.wait(0.6) -- Brief pause for server sync/animation
                
                -- 2. Execute the cast 
                -- Arg 1: Power (1 = Perfect Cast, or use your 0.9867... value)
                -- Arg 2: Cast Power multiplier (1 = normal)
                local castSuccess, catchData = Cast:InvokeServer(1, 1) 
                
                if castSuccess and catchData and catchData.Id then
                    task.wait(0.8) -- Brief pause before claiming
                    
                    -- 3. Claim the catch using the dynamic ID returned by the Cast remote
                    local claimSuccess, claimMsg = ClaimCatch:InvokeServer(catchData.Id)
                    
                    if not claimSuccess then
                        warn("Failed to claim catch: " .. tostring(claimMsg))
                    end
                else
                    warn("Cast failed or no catch data returned.")
                end
            else
                warn("CastBegin failed: " .. tostring(beginData))
            end
        end)
        
        task.wait(FARM_DELAY)
    end
end)

print("[Fish for Secret Animals] Auto Farm & Auto Train Loaded!")
