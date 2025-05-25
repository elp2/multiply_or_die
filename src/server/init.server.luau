local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Platform = require(ReplicatedStorage.Shared.Platform)

local PLATFORM_DIM = 30
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50

local platformCount = 0

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

-- When a player spawns, drop them onto it
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Defer to next frame to avoid race condition with default spawner
        task.defer(function()
            root.CFrame = CFrame.new(0, PLATFORM_HEIGHT + PLATFORM_FALL * 2, 0)
        end)
	end)
end)
