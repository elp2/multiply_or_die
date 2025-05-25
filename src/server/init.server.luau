local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Gate = require(ReplicatedStorage.Shared.Gate)

local PLATFORM_DIM = 30
local PLATFORM_SIZE = Vector3.new(PLATFORM_DIM, 1, PLATFORM_DIM)
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50
local START_Z = 0

local platformCount = 0

local function createHoveringPlatform(zPos, divided)
	local platform = Instance.new("Part")
	platform.Size = PLATFORM_SIZE
	platform.Anchored = false
	platform.Position = Vector3.new(0, PLATFORM_HEIGHT + PLATFORM_FALL, zPos)
	platform.Name = "SkyPlatform"
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = workspace

	-- Always create dividing wall as child of platform
	local wall = Instance.new("Part")
	wall.Size = Vector3.new(1, 9, PLATFORM_DIM)
	wall.Name = "DividingWall"
	wall.TopSurface = Enum.SurfaceType.Smooth
	wall.BottomSurface = Enum.SurfaceType.Smooth
	wall.BrickColor = BrickColor.new("Really black")
	wall.Anchored = false  -- Let the WeldConstraint handle attachment
	wall.Parent = platform
	
	wall.CFrame = platform.CFrame * CFrame.new(0, 5, 0)
	
	-- Create weld to attach wall to platform
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = platform
	weld.Part1 = wall
	weld.Parent = platform
	
	-- Set visibility and collision based on divided parameter
	if divided then
		wall.Transparency = 0
		wall.CanCollide = true
	else
		wall.Transparency = 1
		wall.CanCollide = false
	end

	-- Always create two gates per platform
	local gateLeft = Gate.new(Vector3.new(-7.5, PLATFORM_HEIGHT + PLATFORM_FALL + 0.5, zPos), tostring(platformCount) .. "L")
	local gateRight = Gate.new(Vector3.new(7.5, PLATFORM_HEIGHT + PLATFORM_FALL + 0.5, zPos), tostring(platformCount) .. "R")
	
	gateLeft:SetParent(platform)
	gateRight:SetParent(platform)
	
	-- Hide gates by default
	gateLeft:Hide()
	gateRight:Hide()
	
	-- Show gates on every 3rd platform (for testing)
	if platformCount % 3 == 0 then
		gateLeft:Show()
		gateRight:Show()
	end
	
	-- Weld both gates to the platform
	local gateLeftWeld = Instance.new("WeldConstraint")
	gateLeftWeld.Part0 = platform
	gateLeftWeld.Part1 = gateLeft.LeftBar
	gateLeftWeld.Parent = platform
	
	local gateRightWeld = Instance.new("WeldConstraint")
	gateRightWeld.Part0 = platform
	gateRightWeld.Part1 = gateRight.LeftBar
	gateRightWeld.Parent = platform

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

	-- Drop and disappear 5 seconds after freezing
	task.delay(7.5, function()
		platform.Anchored = false
		-- Wait a bit for it to drop, then destroy
		task.delay(3, function()
			platform:Destroy()
			if gateLeft then
				gateLeft:Destroy()
			end
			if gateRight then
				gateRight:Destroy()
			end
		end)
	end)
end


-- Spawner loop
task.spawn(function()
	while true do
		createHoveringPlatform(platformCount * PLATFORM_DIM, platformCount % 2 == 0)
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
