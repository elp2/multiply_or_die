local Gate = require(script.Parent.Gate)

local Platform = {}
Platform.__index = Platform

local PLATFORM_DIM = 30
local PLATFORM_SIZE = Vector3.new(PLATFORM_DIM, 1, PLATFORM_DIM)
local PLATFORM_HEIGHT = 50
local PLATFORM_FALL = 50

function Platform.new(zPos, divided, platformNumber)
	local self = setmetatable({}, Platform)
	
	-- Create main platform part
	self.Part = Instance.new("Part")
	self.Part.Size = PLATFORM_SIZE
	self.Part.Anchored = false
	self.Part.Position = Vector3.new(0, PLATFORM_HEIGHT + PLATFORM_FALL, zPos)
	self.Part.Name = "SkyPlatform"
	self.Part.TopSurface = Enum.SurfaceType.Smooth
	self.Part.BottomSurface = Enum.SurfaceType.Smooth
	self.Part.Parent = workspace

	-- Create dividing wall
	self.Wall = Instance.new("Part")
	self.Wall.Size = Vector3.new(1, 9, PLATFORM_DIM)
	self.Wall.Name = "DividingWall"
	self.Wall.TopSurface = Enum.SurfaceType.Smooth
	self.Wall.BottomSurface = Enum.SurfaceType.Smooth
	self.Wall.BrickColor = BrickColor.new("Really black")
	self.Wall.Anchored = false
	self.Wall.Parent = self.Part
	
	self.Wall.CFrame = self.Part.CFrame * CFrame.new(0, 5, 0)
	
	-- Weld wall to platform
	local wallWeld = Instance.new("WeldConstraint")
	wallWeld.Part0 = self.Part
	wallWeld.Part1 = self.Wall
	wallWeld.Parent = self.Part
	
	-- Set wall visibility based on divided parameter
	if divided then
		self.Wall.Transparency = 0
		self.Wall.CanCollide = true
	else
		self.Wall.Transparency = 1
		self.Wall.CanCollide = false
	end

	-- Create gates
	self.GateLeft = Gate.new(Vector3.new(-7.5, PLATFORM_HEIGHT + PLATFORM_FALL + 0.5, zPos), tostring(platformNumber) .. "L")
	self.GateRight = Gate.new(Vector3.new(7.5, PLATFORM_HEIGHT + PLATFORM_FALL + 0.5, zPos), tostring(platformNumber) .. "R")
	
	self.GateLeft:SetParent(self.Part)
	self.GateRight:SetParent(self.Part)
	
	-- Hide gates by default
	self.GateLeft:Hide()
	self.GateRight:Hide()
	
	-- Weld gates to platform
	local gateLeftWeld = Instance.new("WeldConstraint")
	gateLeftWeld.Part0 = self.Part
	gateLeftWeld.Part1 = self.GateLeft.LeftBar
	gateLeftWeld.Parent = self.Part
	
	local gateRightWeld = Instance.new("WeldConstraint")
	gateRightWeld.Part0 = self.Part
	gateRightWeld.Part1 = self.GateRight.LeftBar
	gateRightWeld.Parent = self.Part

	-- Set up physics
	local att = Instance.new("Attachment", self.Part)
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.Position = Vector3.new(0, PLATFORM_HEIGHT, zPos)
	align.Responsiveness = 50
	align.MaxForce = 100000
	align.RigidityEnabled = true
	align.Parent = self.Part

	-- Store references for cleanup
	self.Attachment = att
	self.AlignPosition = align
	
	-- Start lifecycle
	self:StartLifecycle()
	
	return self
end

function Platform:ShowGates()
	self.GateLeft:Show()
	self.GateRight:Show()
end

function Platform:HideGates()
	self.GateLeft:Hide()
	self.GateRight:Hide()
end

function Platform:StartLifecycle()
	-- Freeze in place after settling
	task.delay(2.5, function()
		if self.Part and self.Part.Parent then
			self.Part.Anchored = true
			if self.AlignPosition then
				self.AlignPosition:Destroy()
			end
			if self.Attachment then
				self.Attachment:Destroy()
			end
		end
	end)

	-- Drop and disappear 5 seconds after freezing
	task.delay(7.5, function()
		if self.Part and self.Part.Parent then
			self.Part.Anchored = false
			-- Wait a bit for it to drop, then destroy
			task.delay(3, function()
				self:Destroy()
			end)
		end
	end)
end

function Platform:Destroy()
	if self.Part then
		self.Part:Destroy()
	end
	-- Gates will be destroyed automatically as children of the platform
end

return Platform 