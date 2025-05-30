local GameOver = {}
GameOver.__index = GameOver

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function GameOver.new(player, finalScore)
	local self = setmetatable({}, GameOver)
	
	self.Player = player
	self.FinalScore = finalScore
	self.IsActive = false
	self.ScreenGui = nil
	
	return self
end

function GameOver:Show()
	if self.IsActive then
		return -- Already showing
	end
	
	self.IsActive = true
	
	-- Create the screen GUI
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "GameOverScreen"
	self.ScreenGui.ResetOnSpawn = false -- Keep the screen when respawning
	self.ScreenGui.Parent = self.Player.PlayerGui
	
	-- Create main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.Position = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	mainFrame.BackgroundTransparency = 0.3 -- Semi-transparent dark overlay
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = self.ScreenGui
	
	-- Create content frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(0, 400, 0, 300)
	contentFrame.Position = UDim2.new(0.5, -200, 0.5, -150) -- Center the frame
	contentFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = mainFrame
	
	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = contentFrame
	
	-- Create "You Died" title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 80)
	titleLabel.Position = UDim2.new(0, 0, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "YOU DIED"
	titleLabel.TextColor3 = Color3.new(1, 0.2, 0.2) -- Red color
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = contentFrame
	
	-- Create score label
	local scoreLabel = Instance.new("TextLabel")
	scoreLabel.Size = UDim2.new(1, 0, 0, 60)
	scoreLabel.Position = UDim2.new(0, 0, 0, 120)
	scoreLabel.BackgroundTransparency = 1
	scoreLabel.Text = "Score: " .. tostring(self.FinalScore)
	scoreLabel.TextColor3 = Color3.new(1, 1, 1) -- White color
	scoreLabel.TextScaled = true
	scoreLabel.Font = Enum.Font.SourceSans
	scoreLabel.Parent = contentFrame
	
	-- Create replay button
	local replayButton = Instance.new("TextButton")
	replayButton.Size = UDim2.new(0, 200, 0, 50)
	replayButton.Position = UDim2.new(0.5, -100, 0, 200)
	replayButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2) -- Green color
	replayButton.Text = "REPLAY"
	replayButton.TextColor3 = Color3.new(1, 1, 1)
	replayButton.TextScaled = true
	replayButton.Font = Enum.Font.SourceSansBold
	replayButton.BorderSizePixel = 0
	replayButton.Parent = contentFrame
	
	-- Add rounded corners to button
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = replayButton
	
	-- Add button hover effects
	replayButton.MouseEnter:Connect(function()
		replayButton.BackgroundColor3 = Color3.new(0.3, 0.9, 0.3)
	end)
	
	replayButton.MouseLeave:Connect(function()
		replayButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	end)
	
	-- Handle replay button click
	replayButton.MouseButton1Click:Connect(function()
		self:OnReplayClicked()
	end)
	
	print("GameOver screen shown for", self.Player.Name, "with score", self.FinalScore)
end

function GameOver:OnReplayClicked()
	print("Replay button clicked for", self.Player.Name)
	
	-- Hide the game over screen
	self:Hide()
	
	-- Fire a remote event to tell the server to respawn the player
	local respawnPlayerEvent = ReplicatedStorage:FindFirstChild("RespawnPlayer")
	if respawnPlayerEvent then
		respawnPlayerEvent:FireServer()
	end
end

function GameOver:Hide()
	if not self.IsActive then
		return -- Already hidden
	end
	
	self.IsActive = false
	
	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
	
	print("GameOver screen hidden for", self.Player.Name)
end

function GameOver:Destroy()
	self:Hide()
end

return GameOver 