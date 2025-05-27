local Platform = require(script.Parent.Platform)

local Lane = {}
Lane.__index = Lane

local PLATFORM_DIM = 30
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50
local SPAWN_INTERVAL = 2

function Lane.new(onGateTouch, onPlayerScoreUpdate)
	local self = setmetatable({}, Lane)
	
	self.platformCount = 0
	self.activePlatforms = {}
	self.gateCooldowns = {}
	self.onGateTouch = onGateTouch or function() end
	self.onPlayerScoreUpdate = onPlayerScoreUpdate or function() end
	self.isRunning = false
	self.spawnerTask = nil
	
	return self
end

function Lane:Start()
	if self.isRunning then
		return
	end
	
	self.isRunning = true
	
	if self.spawnerTask then
		task.cancel(self.spawnerTask)
	end
	
	-- Spawner loop
	self.spawnerTask = task.spawn(function()
		while self.isRunning do
			local platform = Platform.new(
				self.platformCount * PLATFORM_DIM, 
				self.platformCount % 2 == 0 and self.platformCount > 0,
				self.platformCount
			)
			
			-- Show gates on every platform
			platform:ShowGates()
			
			-- Set up collision detection for the gates
			self:setupGateCollision(platform)
			
			-- Store platform reference
			table.insert(self.activePlatforms, platform)
			
			-- Clean up old platforms (keep only last 10 for performance)
			if #self.activePlatforms > 10 then
				local oldPlatform = table.remove(self.activePlatforms, 1)
				-- Platform will clean itself up through its lifecycle
			end
			
			self.platformCount = self.platformCount + 1
			task.wait(SPAWN_INTERVAL)
		end
	end)
end

function Lane:RestartWithPlayer(player)
	-- Set up player character spawning (this will handle both initial spawn and respawns)
	player.CharacterAdded:Connect(function(character)
		-- Reset the lane every time the player spawns (including respawns)
		self:resetLane()
		
		-- Initialize player score
		self.onPlayerScoreUpdate(player, 10)
		
		-- Handle player spawning and rotation
		local root = character:WaitForChild("HumanoidRootPart")
		-- Defer to next frame to avoid race condition with default spawner
		task.defer(function()
			root.CFrame = CFrame.new(0, PLATFORM_HEIGHT + PLATFORM_FALL * 2, -PLATFORM_DIM / 4) * CFrame.Angles(0, math.pi, 0)
		end)
	end)
	
	self:Start()
end

function Lane:resetLane()
	self:Stop()
	
	-- Reset platform count and clear platforms
	self.platformCount = 0
	self.activePlatforms = {}
	self.gateCooldowns = {}
	
	-- Restart the lane
	self:Start()
	
	print("Lane reset - platforms cleared and spawning restarted")
end

function Lane:Stop()
	self.isRunning = false
	
	if self.spawnerTask then
		task.cancel(self.spawnerTask)
		self.spawnerTask = nil
	end
	
	-- Clean up all active platforms
	for _, platform in ipairs(self.activePlatforms) do
		platform:Destroy()
	end
	self.activePlatforms = {}
	self.gateCooldowns = {}
end

function Lane:setupGateCollision(platform)
	if platform.GateLeft and platform.GateLeft.Plane then
		platform.GateLeft.Plane.Touched:Connect(function(hit)
			self:handleGateTouch(hit, platform.GateLeft)
		end)
	end
	
	if platform.GateRight and platform.GateRight.Plane then
		platform.GateRight.Plane.Touched:Connect(function(hit)
			self:handleGateTouch(hit, platform.GateRight)
		end)
	end
end

function Lane:handleGateTouch(hit, gate)
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end
	
	-- Create cooldown key for this player and gate combination
	local cooldownKey = player.Name .. "_" .. tostring(gate)
	
	-- Check if this gate is on cooldown for this player
	if self.gateCooldowns[cooldownKey] and tick() - self.gateCooldowns[cooldownKey] < 2 then
		return -- Still on cooldown, ignore this touch
	end
	
	-- Set cooldown for this player and gate
	self.gateCooldowns[cooldownKey] = tick()
	
	-- Call the provided callback function
	self.onGateTouch(player, gate)
	
	-- Hide the gate after use
	gate:Hide()
end



-- Cleanup method for when lane is no longer needed
function Lane:Destroy()
	self:Stop()
end

return Lane 