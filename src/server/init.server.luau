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

-- Function to update a player's label with their score
local function updatePlayerScore(player, score)
	playerScores[player] = score
	local labelText = player.Name .. ": " .. score
	updatePlayerLabelEvent:FireAllClients(player, labelText)
	print("Updated", player.Name, "score to", score)
end

-- Spawner loop
task.spawn(function()
	while true do
		local platform = Platform.new(platformCount * PLATFORM_DIM, platformCount % 2 == 0, platformCount)
		
		-- Show gates on every 3rd platform (for testing)
		if platformCount % 3 == 0 then
			platform:ShowGates()
		end
		
		platformCount += 1
		task.wait(2)
	end
end)

-- When a player spawns, drop them onto platform and initialize their score
Players.PlayerAdded:Connect(function(player)
	-- Initialize player score
	updatePlayerScore(player, 0)
	
	-- Demo: Increase score every 5 seconds
	task.spawn(function()
		while player.Parent do
			task.wait(5)
			if playerScores[player] then
				updatePlayerScore(player, playerScores[player] + 10)
			end
		end
	end)
	
	player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Defer to next frame to avoid race condition with default spawner
        task.defer(function()
            root.CFrame = CFrame.new(0, PLATFORM_HEIGHT + PLATFORM_FALL * 2, 0)
        end)
	end)
end)

-- Clean up player scores when they leave
Players.PlayerRemoving:Connect(function(player)
	playerScores[player] = nil
end)
