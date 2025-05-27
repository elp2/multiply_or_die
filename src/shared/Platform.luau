local Gate = require(script.Parent.Gate)
local Constants = require(script.Parent.Constants)

local Platform = {}
Platform.__index = Platform

local PLATFORM_SIZE = Vector3.new(Constants.PLATFORM_DIM, 1, Constants.PLATFORM_DIM)

function Platform.new(zPos, divided, platformNumber, xPos)
	local self = setmetatable({}, Platform)
	
	local xPosition = xPos or 0
	
	-- Create main platform part
	self.Part = Instance.new("Part")
	self.Part.Size = PLATFORM_SIZE
	self.Part.Anchored = false
	self.Part.Position = Vector3.new(xPosition, Constants.PLATFORM_HEIGHT + Constants.PLATFORM_FALL, zPos)
	self.Part.Name = "SkyPlatform"
	self.Part.TopSurface = Enum.SurfaceType.Smooth
	self.Part.BottomSurface = Enum.SurfaceType.Smooth
	self.Part.Parent = workspace

	-- Create dividing wall
	self.Wall = Instance.new("Part")
	self.Wall.Size = Vector3.new(1, 9, Constants.PLATFORM_DIM)
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

	self.GateLeft = Gate.new(Vector3.new(xPosition - 7.5, Constants.PLATFORM_HEIGHT + Constants.PLATFORM_FALL + 0.5, zPos))
	self.GateRight = Gate.new(Vector3.new(xPosition + 7.5, Constants.PLATFORM_HEIGHT + Constants.PLATFORM_FALL + 0.5, zPos))
	
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
	
	-- Position constraint
	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPos.Attachment0 = att
	alignPos.Position = Vector3.new(xPosition, Constants.PLATFORM_HEIGHT, zPos)
	alignPos.Responsiveness = 50
	alignPos.MaxForce = 100000
	alignPos.RigidityEnabled = true
	alignPos.Parent = self.Part
	
	-- Orientation constraint to prevent spinning
	local alignOrient = Instance.new("AlignOrientation")
	alignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrient.Attachment0 = att
	alignOrient.CFrame = CFrame.new() -- Keep default orientation (no rotation)
	alignOrient.Responsiveness = 50
	alignOrient.MaxTorque = 100000
	alignOrient.RigidityEnabled = true
	alignOrient.Parent = self.Part

	-- Store references for cleanup
	self.Attachment = att
	self.AlignPosition = alignPos
	self.AlignOrientation = alignOrient
	
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
			if self.AlignOrientation then
				self.AlignOrientation:Destroy()
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