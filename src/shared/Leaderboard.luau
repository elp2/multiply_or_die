local Leaderboard = {}
Leaderboard.__index = Leaderboard

local Constants = require(script.Parent.Constants)

function Leaderboard.new(position)
	local self = setmetatable({}, Leaderboard)
	
	-- Use constants for positioning if no position provided
	if not position then
		local billboardHeight = 60 -- Height of the billboard (2x bigger)
		local centerY = Constants.LEADERBOARD_BOTTOM_Y + (billboardHeight / 2)
		position = Vector3.new(Constants.LEADERBOARD_X, centerY, Constants.LEADERBOARD_Z)
	end
	
	self.Position = position
	self.Billboard = nil
	self.ScreenGui = nil
	self.ScoreEntries = {}
	
	self:CreateBillboard()
	
	return self
end

function Leaderboard:CreateBillboard()
	-- Create the billboard part
	self.Billboard = Instance.new("Part")
	self.Billboard.Name = "LeaderboardBillboard"
	self.Billboard.Size = Vector3.new(50, 60, 1) -- Keep original width, keep 2x height
	self.Billboard.Position = self.Position
	self.Billboard.Anchored = true
	self.Billboard.CanCollide = false
	self.Billboard.Material = Enum.Material.Neon
	self.Billboard.BrickColor = BrickColor.new("Really black")
	self.Billboard.Parent = workspace
	
	-- Create the surface GUI
	self.ScreenGui = Instance.new("SurfaceGui")
	self.ScreenGui.Face = Enum.NormalId.Front
	self.ScreenGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	self.ScreenGui.PixelsPerStud = 10 -- Half of previous for 2x bigger text (was 20)
	self.ScreenGui.Parent = self.Billboard
	
	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2) -- Dark blue background
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = self.ScreenGui
	
	-- Add gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(0.2, 0.2, 0.4)),
		ColorSequenceKeypoint.new(1, Color3.new(0.1, 0.1, 0.2))
	}
	gradient.Rotation = 45
	gradient.Parent = mainFrame
	
	-- Create title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.09, 0) -- Smaller title to fit 11 lines total
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🏆 HIGH SCORES 🏆"
	titleLabel.TextColor3 = Color3.new(1, 0.8, 0) -- Gold color
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = mainFrame
	
	-- Create scrolling frame for scores
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -10, 0.91, 0) -- Take up most of the space
	scrollFrame.Position = UDim2.new(0, 5, 0.09, 0) -- Start right after title
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = mainFrame
	
	-- Store references
	self.MainFrame = mainFrame
	self.ScrollFrame = scrollFrame
	
	print("Leaderboard billboard created at", self.Position)
end

function Leaderboard:UpdateScores(scoreArray)
	-- Sort scores in descending order
	table.sort(scoreArray, function(a, b)
		return a[2] > b[2] -- Compare scores (second element)
	end)
	
	-- Clear existing score entries
	for _, entry in pairs(self.ScoreEntries) do
		entry:Destroy()
	end
	self.ScoreEntries = {}
	
	-- Create new score entries
	for i, scoreData in ipairs(scoreArray) do
		local username = scoreData[1]
		local score = scoreData[2]
		
		-- Limit to top 10 scores
		if i > 10 then
			break
		end
		
		local entryFrame = Instance.new("Frame")
		entryFrame.Size = UDim2.new(1, 0, 0, 50) -- Slightly smaller entries
		entryFrame.Position = UDim2.new(0, 0, 0, (i-1) * 55) -- Tighter spacing
		entryFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
		entryFrame.BorderSizePixel = 0
		entryFrame.Parent = self.ScrollFrame
		
		-- Add corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6) -- Smaller corners
		corner.Parent = entryFrame
		
		-- Rank number
		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0.12, 0, 1, 0) -- Slightly smaller rank
		rankLabel.Position = UDim2.new(0, 0, 0, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = tostring(i)
		rankLabel.TextColor3 = i <= 3 and Color3.new(1, 0.8, 0) or Color3.new(0.8, 0.8, 0.8) -- Gold for top 3
		rankLabel.TextScaled = true
		rankLabel.Font = Enum.Font.SourceSansBold
		rankLabel.Parent = entryFrame
		
		-- Username
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 1, 0) -- Wider name area
		nameLabel.Position = UDim2.new(0.12, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = username
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entryFrame
		
		-- Score
		local scoreLabel = Instance.new("TextLabel")
		scoreLabel.Size = UDim2.new(0.33, 0, 1, 0) -- Wider score area
		scoreLabel.Position = UDim2.new(0.67, 0, 0, 0) -- Closer to name
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.Text = tostring(score)
		scoreLabel.TextColor3 = Color3.new(0.5, 1, 0.5) -- Light green
		scoreLabel.TextScaled = true
		scoreLabel.Font = Enum.Font.SourceSansBold
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
		scoreLabel.Parent = entryFrame
		
		table.insert(self.ScoreEntries, entryFrame)
	end
	
	-- Update scroll frame canvas size
	self.ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#scoreArray, 10) * 55)
	
	print("Updated leaderboard with", #scoreArray, "scores")
end

function Leaderboard:Destroy()
	if self.Billboard then
		self.Billboard:Destroy()
	end
end

return Leaderboard 