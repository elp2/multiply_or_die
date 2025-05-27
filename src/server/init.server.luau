local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Terrain = workspace.Terrain

local Lane = require(ReplicatedStorage.Shared.Lane)

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


local playerScores = {}  -- Track player scores
local mainLane

-- Function to update a player's label with their score
local function updatePlayerScore(player, score)
	playerScores[player] = score
	local labelText = tostring(score)  -- Show only the score, not the name
	updatePlayerLabelEvent:FireAllClients(player, labelText)
	
	-- Scale player based on score.
	local MAX_PLAYER_SIZE = 10.0
	local sizeMultiplier = math.min(MAX_PLAYER_SIZE, math.max(1, 1 + (score / 200)))
	
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

-- Create the main lane
mainLane = Lane.new(onGateTouch, updatePlayerScore)

-- Single grass collision detection for all players
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and rootPart and humanoid.Health > 0 then
				local position = rootPart.Position
				if position.Y < 10 then
					print("Player", player.Name, "fell off and hit grass, resetting health to 0")
					humanoid.Health = 0
				end
			end
		end
	end
end)

-- When a player joins, restart the lane with that player
Players.PlayerAdded:Connect(function(player)
	mainLane:RestartWithPlayer(player)
end)

-- Clean up player scores when they leave
Players.PlayerRemoving:Connect(function(player)
	playerScores[player] = nil
end)
