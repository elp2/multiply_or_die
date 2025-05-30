print("=== MULTIPLY OR DIE SERVER STARTING ===")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Terrain = workspace.Terrain

-- Disable automatic character loading - we'll handle respawning manually
Players.CharacterAutoLoads = false

print("Services loaded successfully")

local Lane = require(ReplicatedStorage.Shared.Lane)
local Constants = require(ReplicatedStorage.Shared.Constants)

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

-- Create RemoteEvent for updating camera distance
local updateCameraEvent = Instance.new("RemoteEvent")
updateCameraEvent.Name = "UpdateCameraDistance"
updateCameraEvent.Parent = ReplicatedStorage

-- Create RemoteEvent for showing game over screen
local showGameOverEvent = Instance.new("RemoteEvent")
showGameOverEvent.Name = "ShowGameOver"
showGameOverEvent.Parent = ReplicatedStorage

-- Create RemoteEvent for respawning player
local respawnPlayerEvent = Instance.new("RemoteEvent")
respawnPlayerEvent.Name = "RespawnPlayer"
respawnPlayerEvent.Parent = ReplicatedStorage

local playerScores = {}  -- Track player scores
local playerGameOverScreens = {}  -- Track active game over screens
local mainLane

-- Function to update a player's label with their score
local function updatePlayerScore(player, score)
	playerScores[player] = score
	local labelText = tostring(score)  -- Show only the score, not the name
	updatePlayerLabelEvent:FireAllClients(player, labelText)
	
	-- Scale player based on score.
	local sizeMultiplier = math.min(Constants.MAX_PLAYER_SIZE, math.max(1, 1 + (score / Constants.SCORE_TO_SIZE_RATIO)))
	
	-- Apply scaling to player character if it exists
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		
		-- Scale the character proportionally
		humanoid.BodyDepthScale.Value = sizeMultiplier
		humanoid.BodyHeightScale.Value = sizeMultiplier
		humanoid.BodyWidthScale.Value = sizeMultiplier
		humanoid.HeadScale.Value = sizeMultiplier
	end
	
	-- Send camera distance update to the specific player
	updateCameraEvent:FireClient(player, sizeMultiplier)
	
	print("Updated", player.Name, "score to", score)
end

-- Function to handle gate collision
local function onGateTouch(player, gate)
	if not playerScores[player] then
		return
	end
	
	-- Apply the math operation
	local currentScore = playerScores[player]
	local newScore = gate:ApplyMathOperation(currentScore)
	
	print(player.Name, "passed through gate:", gate.Text, "Score:", currentScore, "->", newScore)
	updatePlayerScore(player, newScore)
end

-- Lane management system
local lanes = {}  -- Array of all lanes
local playerLanes = {}  -- Maps player to their lane
local LANE_SPACING = Constants.PLATFORM_DIM * Constants.LANE_SPACING_MULTIPLIER

-- Function to create a new lane at a specific position
local function createLane(laneIndex)
	local xPosition = (laneIndex - 1) * LANE_SPACING  -- 0-based positioning with spacing
	local lane = Lane.new(xPosition, onGateTouch, updatePlayerScore)
	lane.laneIndex = laneIndex
	return lane
end

-- Function to get or create a lane for a player
local function getLaneForPlayer(player)
	-- Check if player already has a lane
	if playerLanes[player] then
		return playerLanes[player]
	end
	
	-- Find the next unused lane
	for i = 1, Constants.MAX_LANES do
		if not lanes[i] then
			-- Create new lane
			lanes[i] = createLane(i)
			playerLanes[player] = lanes[i]
			print("Created new lane", i, "at X position", lanes[i].xPosition, "for player", player.Name)
			return lanes[i]
		end
	end
	
	-- If all lanes are in use, kick the player
	print("SERVER FULL: All", Constants.MAX_LANES, "lanes in use, kicking player", player.Name)
	player:Kick("Server is full! All " .. Constants.MAX_LANES .. " lanes are occupied. Please try again later.")
	return nil
end

-- Function to handle player falling (grass collision)
local function handlePlayerFell(player)
	local lane = playerLanes[player]
	if lane and player.Character then
		print("Player", player.Name, "fell off, showing game over screen...")
		
		-- Get the player's final score
		local finalScore = playerScores[player] or 0
		
		-- Show game over screen to the player
		showGameOverEvent:FireClient(player, finalScore)
		playerGameOverScreens[player] = true
		
		-- Kill the player but don't respawn yet
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

-- Handle respawn requests from clients
respawnPlayerEvent.OnServerEvent:Connect(function(player)
	print("Respawn requested for", player.Name)
	
	-- Clear the game over screen flag
	playerGameOverScreens[player] = nil
	
	-- Respawn the player
	player:LoadCharacter()
end)

-- Function to handle player spawning/respawning
local function handlePlayerSpawn(player, character)
	local lane = getLaneForPlayer(player)
	
	-- If no lane available (server full), player was kicked
	if not lane then
		return
	end
	
	-- Start the lane if it's not already running
	if not lane.isRunning then
		lane:Start()
	end
	
	-- Reset the lane and spawn the player
	lane:Reset()
	lane:SpawnPlayer(player, character)
end

-- Single grass collision detection for all players
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and rootPart and humanoid.Health > 0 then
				local position = rootPart.Position
				if position.Y < Constants.GRASS_Y_THRESHOLD then
					handlePlayerFell(player)
				end
			end
		end
	end
end)

-- When a player joins, set up their character handling
Players.PlayerAdded:Connect(function(player)
	print("=== PLAYER JOINED:", player.Name, "===")
	
	-- Load their character manually since CharacterAutoLoads is disabled

	player.CharacterAdded:Connect(function(character)
		print("Character spawned for", player.Name)
		handlePlayerSpawn(player, character)
	end)
	player:LoadCharacter()
end)

print("=== SERVER SETUP COMPLETE ===")
print("Waiting for players to join...")

-- Clean up player scores and lane assignments when they leave
Players.PlayerRemoving:Connect(function(player)
	playerScores[player] = nil
	playerGameOverScreens[player] = nil
	
	-- Stop and clean up the player's lane
	local playerLane = playerLanes[player]
	if playerLane then
		playerLane:Stop()
		
		-- Remove lane from lanes array
		for i, lane in pairs(lanes) do
			if lane == playerLane then
				lanes[i] = nil
				print("Stopped and removed lane", i, "for departing player", player.Name)
				break
			end
		end
	end
	
	playerLanes[player] = nil
	print("Player", player.Name, "left - cleaned up their data and lane")
end)
