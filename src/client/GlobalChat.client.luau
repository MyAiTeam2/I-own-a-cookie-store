-- Global Chat Client Script
-- Shows jeff_buttercup's messages to everyone, but only jeff_buttercup can send
-- Also shows jeff_buttercup all chat messages from all servers in an admin panel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Debug: Print player name
print("GlobalChat: Player name is:", player.Name)

local isJeffButtercup = (player.Name == "jeff_buttercup")

if isJeffButtercup then
	print("GlobalChat: jeff_buttercup detected, full features enabled...")
else
	print("GlobalChat: Regular player, can only see messages...")
end

-- Wait for RemoteEvents
print("GlobalChat: Waiting for GlobalChat folder...")
local globalChatFolder = ReplicatedStorage:WaitForChild("GlobalChat", 10)
if not globalChatFolder then
	warn("GlobalChat folder not found!")
	return
end
print("GlobalChat: Found GlobalChat folder")

print("GlobalChat: Waiting for RemoteEvents...")
local sendGlobalMessageRemote = globalChatFolder:WaitForChild("SendGlobalMessage", 5)
local receiveGlobalMessageRemote = globalChatFolder:WaitForChild("ReceiveGlobalMessage", 5)
local receiveChatMessageRemote = globalChatFolder:WaitForChild("ReceiveChatMessage", 5)

if not sendGlobalMessageRemote or not receiveGlobalMessageRemote or not receiveChatMessageRemote then
	warn("Global chat remotes not found!")
	return
end
print("GlobalChat: Found all RemoteEvents")

-- GUI Variables
local globalMessageGUI = nil
local inputBox = nil
local sendButton = nil
local messageDisplay = nil
local adminChatGUI = nil
local chatScrollFrame = nil
local chatMessages = {}
local maxChatMessages = 100

-- Create admin chat panel (only for jeff_buttercup)
local function createAdminChatPanel()
	if not isJeffButtercup then return end
	
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("AdminChatGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminChatGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main admin panel (right side of screen)
	local adminFrame = Instance.new("Frame")
	adminFrame.Name = "AdminFrame"
	adminFrame.Size = UDim2.new(0, 350, 0, 400)
	adminFrame.Position = UDim2.new(1, -360, 0.5, -200)
	adminFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	adminFrame.BorderSizePixel = 2
	adminFrame.BorderColor3 = Color3.new(0.8, 0.2, 0.2) -- Red admin border
	adminFrame.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = adminFrame

	-- Admin title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2) -- Red admin color
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = "🔴 ADMIN CHAT MONITOR"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = adminFrame

	-- Add rounded corners to title
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleLabel

	-- Chat scroll frame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ChatScroll"
	scrollFrame.Size = UDim2.new(1, -10, 1, -40)
	scrollFrame.Position = UDim2.new(0, 5, 0, 35)
	scrollFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
	scrollFrame.BorderSizePixel = 1
	scrollFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = adminFrame

	-- Messages layout
	local messagesLayout = Instance.new("UIListLayout")
	messagesLayout.Name = "MessagesLayout"
	messagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	messagesLayout.Padding = UDim.new(0, 2)
	messagesLayout.Parent = scrollFrame

	-- Toggle button
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleButton"
	toggleBtn.Size = UDim2.new(0, 80, 0, 25)
	toggleBtn.Position = UDim2.new(1, -90, 0, 5)
	toggleBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
	toggleBtn.BorderSizePixel = 1
	toggleBtn.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	toggleBtn.Text = "HIDE"
	toggleBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleBtn.TextSize = 12
	toggleBtn.Font = Enum.Font.SourceSans
	toggleBtn.Parent = screenGui

	-- Store references
	adminChatGUI = screenGui
	chatScrollFrame = scrollFrame

	-- Toggle functionality
	local isVisible = true
	toggleBtn.MouseButton1Click:Connect(function()
		isVisible = not isVisible
		adminFrame.Visible = isVisible
		toggleBtn.Text = isVisible and "HIDE" or "SHOW"
	end)

	return screenGui
end

-- Add chat message to admin panel
local function addChatMessage(playerName, message, serverId, timestamp, messageType)
	if not isJeffButtercup or not chatScrollFrame then return end

	-- Create message frame
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "ChatMessage"
	messageFrame.Size = UDim2.new(1, -10, 0, 0) -- Height will be calculated
	messageFrame.BackgroundTransparency = 1
	messageFrame.LayoutOrder = #chatMessages + 1
	messageFrame.Parent = chatScrollFrame

	-- Format timestamp and server
	local timeStr = os.date("%H:%M:%S", timestamp)
	local serverStr = serverId and string.sub(serverId, 1, 6) or "???"
	
	-- Different colors for different message types
	local textColor = Color3.new(0.9, 0.9, 0.9) -- Default white
	local prefix = ""
	
	if messageType == "chat" then
		if playerName == "jeff_buttercup" then
			textColor = Color3.new(0.9, 0.7, 1) -- Light purple for jeff_buttercup's own chat
			prefix = "💭"
		else
			textColor = Color3.new(0.7, 0.9, 1) -- Light blue for regular chat
			prefix = "💬"
		end
	else
		textColor = Color3.new(1, 0.8, 0.2) -- Gold for global messages
		prefix = "📢"
	end
	
	-- Create message text
	local fullMessage = string.format("%s [%s][%s] %s: %s", prefix, timeStr, serverStr, playerName, message)
	
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, 0, 1, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = fullMessage
	messageLabel.TextColor3 = textColor
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.Parent = messageFrame

	-- Calculate text height
	local textBounds = TextService:GetTextSize(fullMessage, 12, Enum.Font.SourceSans, Vector2.new(chatScrollFrame.AbsoluteSize.X - 20, math.huge))
	local textHeight = math.max(16, textBounds.Y + 4)
	
	messageFrame.Size = UDim2.new(1, -10, 0, textHeight)
	
	-- Add to messages list
	table.insert(chatMessages, messageFrame)
	
	-- Remove old messages if too many
	if #chatMessages > maxChatMessages then
		local oldMessage = table.remove(chatMessages, 1)
		if oldMessage and oldMessage.Parent then
			oldMessage:Destroy()
		end
	end
	
	-- Update canvas size and scroll to bottom
	local layout = chatScrollFrame:FindFirstChild("MessagesLayout")
	if layout then
		chatScrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		chatScrollFrame.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
	end
end

-- Create input GUI (only for jeff_buttercup)
local function createInputGUI()
	if not isJeffButtercup then return end
	
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("GlobalInputGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlobalInputGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Input frame (bottom of screen)
	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(0, 400, 0, 40)
	inputFrame.Position = UDim2.new(0.5, -200, 1, -50)
	inputFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	inputFrame.BorderSizePixel = 2
	inputFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	inputFrame.Parent = screenGui

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 15)
	titleLabel.Position = UDim2.new(0, 0, 0, -17)
	titleLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = "🌍 GLOBAL MESSAGE"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 12
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Parent = inputFrame

	-- Input text box
	local textBox = Instance.new("TextBox")
	textBox.Name = "InputBox"
	textBox.Size = UDim2.new(1, -80, 1, -4)
	textBox.Position = UDim2.new(0, 2, 0, 2)
	textBox.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	textBox.BorderSizePixel = 1
	textBox.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	textBox.Text = ""
	textBox.PlaceholderText = "Type message to show everyone..."
	textBox.TextColor3 = Color3.new(1, 1, 1)
	textBox.PlaceholderColor3 = Color3.new(0.7, 0.7, 0.7)
	textBox.TextSize = 16
	textBox.Font = Enum.Font.SourceSans
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.Parent = inputFrame

	-- Send button
	local sendBtn = Instance.new("TextButton")
	sendBtn.Name = "SendButton"
	sendBtn.Size = UDim2.new(0, 75, 1, -4)
	sendBtn.Position = UDim2.new(1, -77, 0, 2)
	sendBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
	sendBtn.BorderSizePixel = 1
	sendBtn.BorderColor3 = Color3.new(0.1, 0.6, 0.1)
	sendBtn.Text = "SEND"
	sendBtn.TextColor3 = Color3.new(1, 1, 1)
	sendBtn.TextSize = 14
	sendBtn.Font = Enum.Font.SourceSansBold
	sendBtn.Parent = inputFrame

	-- Store references
	globalMessageGUI = screenGui
	inputBox = textBox
	sendButton = sendBtn

	return screenGui
end

-- Create message display GUI (for everyone)
local function createMessageDisplayGUI()
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("GlobalMessageDisplay")
	if existingGUI then
		existingGUI:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GlobalMessageDisplay"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Message display (upper center of screen, initially hidden)
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "MessageFrame"
	messageFrame.Size = UDim2.new(0, 500, 0, 80)
	messageFrame.Position = UDim2.new(0.5, -250, 0.25, -40) -- Moved up to 25% from top
	messageFrame.BackgroundColor3 = Color3.new(0.2, 0.6, 1) -- Friendly blue
	messageFrame.BackgroundTransparency = 0.1
	messageFrame.BorderSizePixel = 0
	messageFrame.Visible = false
	messageFrame.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = messageFrame

	-- Add subtle shadow/glow effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.Parent = messageFrame

	-- Friendly header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Name = "HeaderLabel"
	headerLabel.Size = UDim2.new(1, 0, 0, 20)
	headerLabel.Position = UDim2.new(0, 0, 0, 5)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = "💬 Message from jeff_buttercup"
	headerLabel.TextColor3 = Color3.new(1, 1, 1)
	headerLabel.TextSize = 14
	headerLabel.Font = Enum.Font.SourceSans
	headerLabel.TextXAlignment = Enum.TextXAlignment.Center
	headerLabel.Parent = messageFrame

	-- Message text
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, -20, 1, -30)
	messageLabel.Position = UDim2.new(0, 10, 0, 25)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = ""
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextSize = 20
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Center
	messageLabel.TextYAlignment = Enum.TextYAlignment.Center
	messageLabel.Parent = messageFrame

	-- Store reference
	messageDisplay = messageFrame

	return screenGui
end

-- Display message in center of screen for 5 seconds
local function displayMessage(playerName, message, serverId)
	if not messageDisplay then return end

	local messageLabel = messageDisplay:FindFirstChild("MessageLabel")
	if not messageLabel then return end

	-- Set the message text
	messageLabel.Text = message

	-- Show the message with gentle animation
	messageDisplay.Visible = true
	messageDisplay.Size = UDim2.new(0, 200, 0, 30) -- Start smaller
	messageDisplay.BackgroundTransparency = 1
	messageDisplay.Position = UDim2.new(0.5, -100, 0.2, -15) -- Start higher up

	-- Gentle animate in
	local animateIn = TweenService:Create(messageDisplay, 
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 500, 0, 80),
			BackgroundTransparency = 0.1,
			Position = UDim2.new(0.5, -250, 0.25, -40)
		}
	)
	animateIn:Play()

	-- Wait 5 seconds then gently fade out
	task.spawn(function()
		task.wait(5)
		
		local animateOut = TweenService:Create(messageDisplay,
			TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{
				Size = UDim2.new(0, 200, 0, 30),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, -100, 0.2, -15)
			}
		)
		animateOut:Play()
		
		animateOut.Completed:Connect(function()
			messageDisplay.Visible = false
		end)
	end)
end

-- Send message function (only for jeff_buttercup)
local function sendMessage()
	if not isJeffButtercup or not inputBox or not sendGlobalMessageRemote then return end
	
	local message = inputBox.Text:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
	if message == "" or #message > 200 then return end
	
	-- Send message to server
	local success, err = pcall(function()
		sendGlobalMessageRemote:FireServer(message)
	end)
	
	if not success then
		warn("Failed to send global message:", err)
		return
	end
	
	-- Clear input
	inputBox.Text = ""
	
	print("GlobalChat: Message sent:", message)
end

-- Setup GUI and connections
local function setupGlobalMessage()
	-- Create message display for everyone
	createMessageDisplayGUI()
	
	-- Create admin chat panel and input GUI only for jeff_buttercup
	if isJeffButtercup then
		createAdminChatPanel()
		createInputGUI()
		
		-- Connect button events
		if sendButton and inputBox then
			sendButton.MouseButton1Click:Connect(sendMessage)
			
			inputBox.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					sendMessage()
				end
			end)
		end
		
		print("GlobalChat: Admin panel and input GUI created for jeff_buttercup")
	end
	
	-- Connect to receive global messages (everyone gets this)
	receiveGlobalMessageRemote.OnClientEvent:Connect(function(data)
		print("GlobalChat: Received global message:", data.message)
		displayMessage(data.player, data.message, data.serverId)
		
		-- Also add to admin chat if jeff_buttercup
		if isJeffButtercup then
			addChatMessage(data.player, data.message, data.serverId, data.timestamp, "global")
		end
	end)
	
	-- Connect to receive chat messages (only jeff_buttercup gets this)
	if isJeffButtercup then
		print("GlobalChat: Setting up chat message receiver for jeff_buttercup")
		receiveChatMessageRemote.OnClientEvent:Connect(function(data)
			print("GlobalChat: Received chat message from server:", data.player, "said:", data.message, "from server:", data.serverId)
			addChatMessage(data.player, data.message, data.serverId, data.timestamp, "chat")
		end)
	else
		print("GlobalChat: Not jeff_buttercup, skipping chat message receiver setup")
	end
	
	print("GlobalChat: Message display ready for all players")
end

-- Initialize the system
setupGlobalMessage()

-- Recreate system when player spawns
player.CharacterAdded:Connect(function()
	wait(1)
	setupGlobalMessage()
end)

print("Global Chat Client initialized for jeff_buttercup")
print("GlobalChat: Setup complete! Messages will appear in center of screen.") 