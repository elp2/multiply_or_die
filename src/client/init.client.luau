local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require modules directly since they're in ReplicatedStorage.Shared
local PlayerLabel = require(ReplicatedStorage.Shared.PlayerLabel)
local GameOver = require(ReplicatedStorage.Shared.GameOver)

-- Wait for RemoteEvents to be available (these are created by the server)
local updatePlayerLabelEvent
repeat
	updatePlayerLabelEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerLabel")
	if not updatePlayerLabelEvent then
		task.wait(0.1)
	end
until updatePlayerLabelEvent

-- Wait for ShowGameOver RemoteEvent to be available
local showGameOverEvent
repeat
	showGameOverEvent = ReplicatedStorage:FindFirstChild("ShowGameOver")
	if not showGameOverEvent then
		task.wait(0.1)
	end
until showGameOverEvent

local playerLabels = {}
local currentGameOverScreen = nil

-- Function to create label for a player
local function createLabelForPlayer(player)
	if playerLabels[player] then
		return -- Already has a label
	end
	
	print("Creating client-side PlayerLabel for", player.Name)
	
	-- Wait a moment for character to be ready if it just spawned
	task.spawn(function()
		-- Wait for character to exist and be ready
		local character = player.Character
		if not character then
			player.CharacterAdded:Wait()
		end
		
		-- Small delay to ensure character is fully loaded
		task.wait(0.2)
		
		-- Double check the player is still in the game
		if player.Parent and not playerLabels[player] then
			local label = PlayerLabel.new(player, player.Name)
			playerLabels[player] = label
		end
	end)
end

-- Create labels for existing players
for _, player in pairs(Players:GetPlayers()) do
	createLabelForPlayer(player)
end

-- Create labels for new players
Players.PlayerAdded:Connect(createLabelForPlayer)

-- Handle server updates to player label text
updatePlayerLabelEvent.OnClientEvent:Connect(function(targetPlayer, newText)
	if playerLabels[targetPlayer] then
		playerLabels[targetPlayer]:SetText(newText)
		print("Updated label for", targetPlayer.Name, "to:", newText)
	end
end)

-- Handle game over screen display
showGameOverEvent.OnClientEvent:Connect(function(finalScore)
	local localPlayer = Players.LocalPlayer
	print("Showing GameOver screen with score:", finalScore)
	
	-- Clean up any existing game over screen
	if currentGameOverScreen then
		currentGameOverScreen:Destroy()
	end
	
	-- Create and show new game over screen
	currentGameOverScreen = GameOver.new(localPlayer, finalScore)
	currentGameOverScreen:Show()
end)

-- Clean up labels when players leave
Players.PlayerRemoving:Connect(function(player)
	if playerLabels[player] then
		playerLabels[player]:Destroy()
		playerLabels[player] = nil
		print("Cleaned up client-side PlayerLabel for", player.Name)
	end
end)

-- Camera distance adjustment based on character size
local Camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local function adjustCameraDistance(sizeMultiplier)
	if Camera.CameraType ~= Enum.CameraType.Custom then
		return -- Only adjust for default camera mode
	end
	
	-- Calculate camera distance based on size (1/2 of the scaling factor)
	local cameraDistance = (sizeMultiplier / 2) * 8 + 12 -- Base distance + scaling
	
	-- Apply camera distance by modifying the CameraMinZoomDistance and CameraMaxZoomDistance
	if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
		local humanoid = localPlayer.Character.Humanoid
		humanoid.CameraOffset = Vector3.new(0, 2 * sizeMultiplier, 0)
	end
	
	-- Adjust the camera's zoom limits
	localPlayer.CameraMinZoomDistance = cameraDistance
	localPlayer.CameraMaxZoomDistance = math.max(cameraDistance, 25)
	
	print("Adjusted camera distance for size", sizeMultiplier, "to", cameraDistance)
end

-- Create RemoteEvent for camera distance updates
local updateCameraEvent
repeat
	updateCameraEvent = ReplicatedStorage:FindFirstChild("UpdateCameraDistance")
	if not updateCameraEvent then
		task.wait(0.1)
	end
until updateCameraEvent

-- Handle camera distance updates from server
updateCameraEvent.OnClientEvent:Connect(function(sizeMultiplier)
	adjustCameraDistance(sizeMultiplier)
end)

-- Set initial camera distance when character spawns
localPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5) -- Wait for character to be ready
	adjustCameraDistance(1.0) -- Start with default size
end)