local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local Platform = require(ReplicatedStorage.Shared.Platform)

-- Remove the default baseplate if it exists
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

-- Create infinite grass terrain
local function createGrassTerrain(centerX, centerZ)
	local region = Region3.new(
		Vector3.new(centerX - 256, -50, centerZ - 256),
		Vector3.new(centerX + 256, -30, centerZ + 256)
	)
	local material = Enum.Material.Grass
	local shape = Enum.PartType.Block
	
	Terrain:FillRegion(region, 4, material)
end

-- Create initial grass terrain area
createGrassTerrain(0, 0)

-- Track player positions to expand terrain as needed
local expandedAreas = {}
local function ensureTerrainAtPosition(x, z)
	-- Round to terrain chunk boundaries (512x512 chunks)
	local chunkX = math.floor(x / 512) * 512
	local chunkZ = math.floor(z / 512) * 512
	local chunkKey = chunkX .. "," .. chunkZ
	
	if not expandedAreas[chunkKey] then
		expandedAreas[chunkKey] = true
		createGrassTerrain(chunkX, chunkZ)
	end
end

-- Monitor all players and expand terrain as they move
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local pos = player.Character.HumanoidRootPart.Position
				ensureTerrainAtPosition(pos.X, pos.Z)
			end
		end
		task.wait(1) -- Check every second
	end
end)

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
	
	-- Scale player based on score (200 score = 2x size, minimum 1x size)
	local sizeMultiplier = math.min(4.0, math.max(1, 1 + (score / 200)))
	
	-- Apply scaling to player character if it exists
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		
		-- Scale the character proportionally
		humanoid.BodyDepthScale.Value = sizeMultiplier
		humanoid.BodyHeightScale.Value = sizeMultiplier
		humanoid.BodyWidthScale.Value = sizeMultiplier
		humanoid.HeadScale.Value = sizeMultiplier
		
		print("Scaled", player.Name, "to", sizeMultiplier .. "x size (score:", score .. ")")
	end
	
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
	
	player.CharacterAdded:Connect(function(character)        
		updatePlayerScore(player, 10)
        
        local root = character:WaitForChild("HumanoidRootPart")
		-- Defer to next frame to avoid race condition with default spawner
        task.defer(function()
            root.CFrame = CFrame.new(0, PLATFORM_HEIGHT + PLATFORM_FALL * 2, -PLATFORM_DIM / 4) * CFrame.Angles(0, math.pi, 0)
        end)
	end)
end)

-- Clean up player scores when they leave
Players.PlayerRemoving:Connect(function(player)
	playerScores[player] = nil
end)
