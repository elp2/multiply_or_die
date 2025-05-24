local Players = game:GetService("Players")

local PLATFORM_DIM = 30
local PLATFORM_SIZE = Vector3.new(PLATFORM_DIM, 1, PLATFORM_DIM)
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50
local START_Z = 0

local currentZ = START_Z

local function createHoveringPlatform(zPos)
	local platform = Instance.new("Part")
	platform.Size = PLATFORM_SIZE
	platform.Anchored = false
	platform.Position = Vector3.new(0, PLATFORM_HEIGHT + PLATFORM_FALL, zPos)
	platform.Name = "SkyPlatform"
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = workspace

	-- Let physics settle it at PLATFORM_HEIGHT
	local att = Instance.new("Attachment", platform)
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.Position = Vector3.new(0, PLATFORM_HEIGHT, zPos)
	align.Responsiveness = 50
	align.MaxForce = 100000
	align.RigidityEnabled = true
	align.Parent = platform

	-- Freeze in place after settling
	task.delay(2.5, function()
		platform.Anchored = true
		align:Destroy()
		att:Destroy()
	end)
end

createHoveringPlatform(currentZ)
currentZ += PLATFORM_DIM

-- Spawner loop
task.spawn(function()
	while true do
		createHoveringPlatform(currentZ)
		currentZ += PLATFORM_DIM
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
