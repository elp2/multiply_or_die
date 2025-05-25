local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Platform = require(ReplicatedStorage.Shared.Platform)

-- Create RemoteEvent for updating player labels
local updatePlayerLabelEvent = Instance.new("RemoteEvent")
updatePlayerLabelEvent.Name = "UpdatePlayerLabel"
updatePlayerLabelEvent.Parent = ReplicatedStorage

local PLATFORM_DIM = 30
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50

local platformCount = 0
local playerScores = {}  -- Track player scores
local activePlatforms = {}  -- Track active platforms for collision detection
local gateCooldowns = {}  -- Track gate cooldowns per player

-- Function to update a player's label with their score
local function updatePlayerScore(player, score)
	playerScores[player] = score
	local labelText = tostring(score)  -- Show only the score, not the name
	updatePlayerLabelEvent:FireAllClients(player, labelText)
	print("Updated", player.Name, "score to", score)
end

-- Function to handle gate collision with cooldown
local function onGateTouch(hit, gate)
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or not playerScores[player] then
		return
	end
	
	-- Create cooldown key for this player and gate combination
	local cooldownKey = player.Name .. "_" .. tostring(gate)
	
	-- Check if this gate is on cooldown for this player
	if gateCooldowns[cooldownKey] and tick() - gateCooldowns[cooldownKey] < 2 then
		return -- Still on cooldown, ignore this touch
	end
	
	-- Set cooldown for this player and gate
	gateCooldowns[cooldownKey] = tick()
	
	-- Apply the math operation
	local currentScore = playerScores[player]
	local newScore = gate:ApplyMathOperation(currentScore)
	
	print(player.Name, "passed through gate:", gate.Text, "Score:", currentScore, "->", newScore)
	updatePlayerScore(player, newScore)
	
	-- Hide the gate after use
	gate:Hide()
end

-- Function to set up gate collision detection
local function setupGateCollision(platform)
	if platform.GateLeft and platform.GateLeft.Plane then
		platform.GateLeft.Plane.Touched:Connect(function(hit)
			onGateTouch(hit, platform.GateLeft)
		end)
	end
	
	if platform.GateRight and platform.GateRight.Plane then
		platform.GateRight.Plane.Touched:Connect(function(hit)
			onGateTouch(hit, platform.GateRight)
		end)
	end
end

-- Spawner loop
task.spawn(function()
	while true do
		local platform = Platform.new(platformCount * PLATFORM_DIM, platformCount % 2 == 0, platformCount)
		
		-- Show gates on every platform (not just every 3rd)
		platform:ShowGates()
		
		-- Set up collision detection for the gates
		setupGateCollision(platform)
		
		-- Store platform reference
		activePlatforms[#activePlatforms + 1] = platform
		
		platformCount += 1
		task.wait(2)
	end
end)

-- When a player spawns, drop them onto platform and initialize their score
Players.PlayerAdded:Connect(function(player)
	-- Initialize player score to 10
	updatePlayerScore(player, 10)
	
	player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Defer to next frame to avoid race condition with default spawner
        task.defer(function()
            root.CFrame = CFrame.new(0, PLATFORM_HEIGHT + PLATFORM_FALL * 2, -PLATFORM_DIM / 4)
        end)
	end)
end)

-- Clean up player scores when they leave
Players.PlayerRemoving:Connect(function(player)
	playerScores[player] = nil
end)
