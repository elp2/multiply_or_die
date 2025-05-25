local Gate = {}
Gate.__index = Gate

-- Math operations for gates
local MATH_OPERATIONS = {
	{text = "8+", operation = "add", value = 8},
	{text = "4+", operation = "add", value = 4},
	{text = "1+", operation = "add", value = 1},
	{text = "2x", operation = "multiply", value = 2},
	{text = "4x", operation = "multiply", value = 4},
	{text = "2÷", operation = "divide", value = 2},
	{text = "3÷", operation = "divide", value = 3},
	{text = "2-", operation = "subtract", value = 2},
	{text = "5-", operation = "subtract", value = 5},
}

function Gate.new(position, text, mathOperation)
	local self = setmetatable({}, Gate)
	
	-- If no math operation provided, use the text as-is or generate a random one
	if mathOperation then
		self.MathOperation = mathOperation
		self.Text = mathOperation.text
	elseif text and text ~= "" then
		self.Text = text
		self.MathOperation = nil
	else
		-- Generate random math operation
		self.MathOperation = MATH_OPERATIONS[math.random(1, #MATH_OPERATIONS)]
		self.Text = self.MathOperation.text
	end
	
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
	self.Plane.CanCollide = false
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
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = Color3.new(1, 1, 1)  -- White text
	self.TextLabel.TextScaled = true  -- Scale text to fit
	self.TextLabel.Font = Enum.Font.SourceSansBold
	self.TextLabel.Parent = surfaceGui
	
	return self
end

function Gate:ApplyMathOperation(currentScore)
	if not self.MathOperation then
		return currentScore -- No math operation, return unchanged
	end
	
	local operation = self.MathOperation.operation
	local value = self.MathOperation.value
	
	if operation == "add" then
		return currentScore + value
	elseif operation == "subtract" then
		return math.max(0, currentScore - value) -- Don't go below 0
	elseif operation == "multiply" then
		return currentScore * value
	elseif operation == "divide" then
		return math.floor(currentScore / value)
	end
	
	return currentScore
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