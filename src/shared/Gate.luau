local Gate = {}
Gate.__index = Gate

function Gate.new(position, text)
	local self = setmetatable({}, Gate)
	
	-- Create main gate model to hold all parts
	self.Model = Instance.new("Model")
	self.Model.Name = "Gate"
	
	-- Create left vertical bar
	self.LeftBar = Instance.new("Part")
	self.LeftBar.Size = Vector3.new(1, 10, 1)
	self.LeftBar.Position = position + Vector3.new(-7, 5, 0)  -- 7 units to the left
	self.LeftBar.BrickColor = BrickColor.new("Bright red")
	self.LeftBar.Anchored = false
	self.LeftBar.Name = "LeftBar"
	self.LeftBar.Parent = self.Model
	
	-- Create right vertical bar
	self.RightBar = Instance.new("Part")
	self.RightBar.Size = Vector3.new(1, 10, 1)
	self.RightBar.Position = position + Vector3.new(7, 5, 0)  -- 7 units to the right
	self.RightBar.BrickColor = BrickColor.new("Bright red")
	self.RightBar.Anchored = false
	self.RightBar.Name = "RightBar"
	self.RightBar.Parent = self.Model
	
	-- Create transparent red plane between bars
	self.Plane = Instance.new("Part")
	self.Plane.Size = Vector3.new(14, 10, 0.1)  -- 14 units wide to span platform half
	self.Plane.Position = position + Vector3.new(0, 5, 0)  -- Centered between bars, 5 units up
	self.Plane.BrickColor = BrickColor.new("Bright red")
	self.Plane.Transparency = 0.7  -- Semi-transparent
	self.Plane.Anchored = false
	self.Plane.CanCollide = false  -- Don't want it to block movement
	self.Plane.Name = "Plane"
	self.Plane.Parent = self.Model
	
	-- Weld all gate parts together (LeftBar as the main part)
	local rightBarWeld = Instance.new("WeldConstraint")
	rightBarWeld.Part0 = self.LeftBar
	rightBarWeld.Part1 = self.RightBar
	rightBarWeld.Parent = self.LeftBar
	
	local planeWeld = Instance.new("WeldConstraint")
	planeWeld.Part0 = self.LeftBar
	planeWeld.Part1 = self.Plane
	planeWeld.Parent = self.LeftBar
	
	-- Create text label on the plane
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = self.Plane
	
	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Size = UDim2.new(1, 0, 1, 0)  -- Fill the entire surface
	self.TextLabel.Position = UDim2.new(0, 0, 0, 0)
	self.TextLabel.BackgroundTransparency = 1  -- Transparent background
	self.TextLabel.Text = text or "ABC"  -- Default text or provided text
	self.TextLabel.TextColor3 = Color3.new(1, 1, 1)  -- White text
	self.TextLabel.TextScaled = true  -- Scale text to fit
	self.TextLabel.Font = Enum.Font.SourceSansBold
	self.TextLabel.Parent = surfaceGui
	
	-- Store reference to the text for easy updates
	self.Text = text or "ABC"
	
	return self
end

function Gate:SetText(newText)
	self.Text = newText
	self.TextLabel.Text = newText
end

function Gate:Show()
	self.LeftBar.Transparency = 0
	self.LeftBar.CanCollide = true
	self.RightBar.Transparency = 0
	self.RightBar.CanCollide = true
	self.Plane.Transparency = 0.7  -- Keep semi-transparent
	-- Show the text label
	if self.Plane:FindFirstChild("SurfaceGui") then
		self.Plane.SurfaceGui.Enabled = true
	end
end

function Gate:Hide()
	self.LeftBar.Transparency = 1
	self.LeftBar.CanCollide = false
	self.RightBar.Transparency = 1
	self.RightBar.CanCollide = false
	self.Plane.Transparency = 1
	-- Hide the text label
	if self.Plane:FindFirstChild("SurfaceGui") then
		self.Plane.SurfaceGui.Enabled = false
	end
end

function Gate:SetPosition(newPosition)
	-- Update positions of all parts relative to new position
	self.LeftBar.Position = newPosition + Vector3.new(-7, 5, 0)
	self.RightBar.Position = newPosition + Vector3.new(7, 5, 0)
	self.Plane.Position = newPosition + Vector3.new(0, 5, 0)
end

function Gate:SetParent(parent)
	self.Model.Parent = parent
end

function Gate:Destroy()
	if self.Model then
		self.Model:Destroy()
	end
end

return Gate 