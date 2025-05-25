local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Wait for PlayerLabel module to be available
local PlayerLabel
repeat
	local success, result = pcall(function()
		return require(ReplicatedStorage.Shared.PlayerLabel)
	end)
	if success then
		PlayerLabel = result
		print("PlayerLabel module loaded on client")
		break
	end
	task.wait(0.1)
until PlayerLabel

-- Wait for RemoteEvent to be available
local updatePlayerLabelEvent
repeat
	updatePlayerLabelEvent = ReplicatedStorage:FindFirstChild("UpdatePlayerLabel")
	if not updatePlayerLabelEvent then
		task.wait(0.1)
	end
until updatePlayerLabelEvent

local playerLabels = {}

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

-- Clean up labels when players leave
Players.PlayerRemoving:Connect(function(player)
	if playerLabels[player] then
		playerLabels[player]:Destroy()
		playerLabels[player] = nil
		print("Cleaned up client-side PlayerLabel for", player.Name)
	end
end)