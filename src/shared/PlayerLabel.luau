local PlayerLabel = {}
PlayerLabel.__index = PlayerLabel

function PlayerLabel.new(player, text)
	local self = setmetatable({}, PlayerLabel)
	
	self.Player = player
	self.Text = text or player.Name
	self.IsDestroyed = false
	
	print("Creating PlayerLabel for", player.Name, "with text:", self.Text)
	
	-- Better character checking with retry logic
	local function tryCreateLabel()
		local character = player.Character
		if character and character:FindFirstChild("Head") then
			print("Character and head found, creating label immediately")
			self:CreateLabel()
		else
			print("Waiting for character to spawn...")
			-- Wait for character with timeout
			local connection
			local timeoutConnection
			
			connection = player.CharacterAdded:Connect(function(character)
				print("Character spawned for", player.Name)
				connection:Disconnect()
				if timeoutConnection then
					timeoutConnection:Disconnect()
				end
				
				-- Wait a bit for head to be ready
				task.wait(0.1)
				
				if not self.IsDestroyed and character:FindFirstChild("Head") then
					self:CreateLabel()
				else
					print("Head not ready, retrying...")
					task.wait(0.2)
					if not self.IsDestroyed and character:FindFirstChild("Head") then
						self:CreateLabel()
					end
				end
			end)
			
			-- Timeout after 10 seconds
			timeoutConnection = task.delay(10, function()
				print("Timeout waiting for character for", player.Name)
				connection:Disconnect()
			end)
		end
	end
	
	tryCreateLabel()
	
	return self
end

function PlayerLabel:CreateLabel()
	local character = self.Player.Character
	if not character or not character:FindFirstChild("Head") then
		print("ERROR: No character or head found for", self.Player.Name)
		return
	end
	
	local head = character.Head
	print("Creating BillboardGui for", self.Player.Name, "attached to head")
	
	-- Clean up any existing label first
	if self.BillboardGui then
		self.BillboardGui:Destroy()
	end
	
	-- Create BillboardGui for the floating label
	self.BillboardGui = Instance.new("BillboardGui")
	self.BillboardGui.Name = "PlayerFloatingLabel_" .. self.Player.Name  -- Distinctive name
	self.BillboardGui.Size = UDim2.new(6, 0, 2, 0)  -- Large size like gate labels
	self.BillboardGui.StudsOffset = Vector3.new(0, 3, 0)  -- Float 3 studs above head
	self.BillboardGui.AlwaysOnTop = true
	self.BillboardGui.LightInfluence = 0
	self.BillboardGui.Parent = head
	
	print("BillboardGui created and parented to head")
	
	-- Create the text label
	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Size = UDim2.new(1, 0, 1, 0)
	self.TextLabel.Position = UDim2.new(0, 0, 0, 0)
	self.TextLabel.BackgroundTransparency = 1  -- Transparent background
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = Color3.new(0, 1, 0)  -- Green text
	self.TextLabel.TextScaled = true  -- Scale text to fit like gate labels
	self.TextLabel.Font = Enum.Font.SourceSansBold  -- Same font as gate labels
	self.TextLabel.TextStrokeTransparency = 0.5  -- Add stroke for better visibility
	self.TextLabel.TextStrokeColor3 = Color3.new(0, 0, 0)  -- Black stroke
	self.TextLabel.Parent = self.BillboardGui
	
	print("TextLabel created with text:", self.Text, "- Label should now be visible!")
	
	-- Start rotation animation
	self:StartRotation()
	
	-- Handle character respawning (fix the duplicate connection issue)
	if self.CharacterAddedConnection then
		self.CharacterAddedConnection:Disconnect()
	end
	self.CharacterAddedConnection = self.Player.CharacterAdded:Connect(function(newCharacter)
		print("Character respawned for", self.Player.Name, "- recreating label")
		if not self.IsDestroyed then
			task.wait(0.1)  -- Small delay for character to fully load
			self:CreateLabel()
		end
	end)
end

function PlayerLabel:StartRotation()
	if self.IsDestroyed or not self.TextLabel then
		return
	end
	
	-- Continuous rotation animation
	task.spawn(function()
		local rotation = 0
		while not self.IsDestroyed and self.TextLabel and self.TextLabel.Parent do
			rotation = rotation + 1
			-- Slowly rotate left and right (-30 to +30 degrees)
			local rotationAngle = math.sin(rotation * 0.02) * 30
			self.TextLabel.Rotation = rotationAngle
			task.wait(0.1)  -- Smooth animation
		end
	end)
end

function PlayerLabel:SetText(newText)
	self.Text = newText
	if self.TextLabel then
		self.TextLabel.Text = newText
	end
end

function PlayerLabel:Destroy()
	self.IsDestroyed = true
	
	if self.BillboardGui then
		self.BillboardGui:Destroy()
	end
	
	if self.CharacterAddedConnection then
		self.CharacterAddedConnection:Disconnect()
	end
end

return PlayerLabel 