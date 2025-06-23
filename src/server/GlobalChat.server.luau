-- Global Chat Server Script
-- Only allows jeff_buttercup to use global chat

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

-- Configuration
local AUTHORIZED_USER = "jeff_buttercup"
local GLOBAL_CHAT_TOPIC = "GlobalChat_JeffButtercup"
local CHAT_MONITOR_TOPIC = "ChatMonitor_JeffButtercup"

-- Create RemoteEvents
local globalChatFolder = Instance.new("Folder")
globalChatFolder.Name = "GlobalChat"
globalChatFolder.Parent = ReplicatedStorage

local sendGlobalMessageRemote = Instance.new("RemoteEvent")
sendGlobalMessageRemote.Name = "SendGlobalMessage"
sendGlobalMessageRemote.Parent = globalChatFolder

local receiveGlobalMessageRemote = Instance.new("RemoteEvent")
receiveGlobalMessageRemote.Name = "ReceiveGlobalMessage"
receiveGlobalMessageRemote.Parent = globalChatFolder

local receiveChatMessageRemote = Instance.new("RemoteEvent")
receiveChatMessageRemote.Name = "ReceiveChatMessage"
receiveChatMessageRemote.Parent = globalChatFolder

-- Handle sending global messages
sendGlobalMessageRemote.OnServerEvent:Connect(function(player, message)
	-- Only allow jeff_buttercup to send global messages
	if player.Name ~= AUTHORIZED_USER then
		return
	end
	
	-- Validate message
	if type(message) ~= "string" or message == "" or #message > 200 then
		return
	end
	
	-- Create message data
	local messageData = {
		player = player.Name,
		message = message,
		timestamp = os.time(),
		serverId = game.JobId
	}
	
	-- Send to all servers via MessagingService
	local success, err = pcall(function()
		MessagingService:PublishAsync(GLOBAL_CHAT_TOPIC, messageData)
	end)
	
	if not success then
		warn("Failed to send global message:", err)
	end
end)

-- Listen for global messages from other servers
local function onGlobalMessageReceived(message)
	local data = message.Data
	
	-- Send to ALL players in this server (everyone will see jeff_buttercup's messages)
	for _, player in pairs(Players:GetPlayers()) do
		receiveGlobalMessageRemote:FireClient(player, data)
	end
end

-- Function to send chat message to all servers for jeff_buttercup to see
local function broadcastChatMessage(playerName, message, serverId)
	local chatData = {
		player = playerName,
		message = message,
		timestamp = os.time(),
		serverId = serverId,
		messageType = "chat"
	}
	
	-- Send to all servers via MessagingService
	local success, err = pcall(function()
		MessagingService:PublishAsync(CHAT_MONITOR_TOPIC, chatData)
	end)
	
	if not success then
		warn("Failed to broadcast chat message:", err)
	end
end

-- Listen for chat messages from other servers
local function onChatMessageReceived(message)
	local data = message.Data
	
	-- Send only to jeff_buttercup in this server
	for _, player in pairs(Players:GetPlayers()) do
		if player.Name == AUTHORIZED_USER then
			receiveChatMessageRemote:FireClient(player, data)
		end
	end
end

-- Test function - jeff_buttercup can type "/testchat" to send a test message
local function handleTestCommand(player, message)
	if player.Name == AUTHORIZED_USER and message:lower() == "/testchat" then
		-- Send a test chat message as if it came from a regular player
		local testData = {
			player = "TestPlayer",
			message = "This is a test chat message to verify the system works!",
			timestamp = os.time(),
			serverId = game.JobId,
			messageType = "chat"
		}
		
		receiveChatMessageRemote:FireClient(player, testData)
		print("GlobalChat Server: Sent test chat message to", player.Name)
		return true
	end
	return false
end

-- Enhanced chat monitoring that also handles test commands
local function setupChatMonitoring(player)
	print("GlobalChat Server: Setting up chat monitoring for", player.Name)
	
	player.Chatted:Connect(function(message)
		print("GlobalChat Server: Chat detected from", player.Name, ":", message)
		
		-- Handle test commands first
		if handleTestCommand(player, message) then
			return
		end
		
		-- For jeff_buttercup, only show his chat in his admin panel (don't broadcast to other servers)
		if player.Name == AUTHORIZED_USER then
			print("GlobalChat Server: Adding jeff_buttercup's chat to his admin panel")
			local chatData = {
				player = player.Name,
				message = message,
				timestamp = os.time(),
				serverId = game.JobId,
				messageType = "chat"
			}
			receiveChatMessageRemote:FireClient(player, chatData)
			return
		end
		
		print("GlobalChat Server: Broadcasting chat message from", player.Name)
		
		-- Broadcast this chat message to all servers
		broadcastChatMessage(player.Name, message, game.JobId)
		
		-- Also send to jeff_buttercup in this server immediately
		local jeffPlayer = Players:FindFirstChild(AUTHORIZED_USER)
		if jeffPlayer then
			print("GlobalChat Server: Sending chat to jeff_buttercup in this server")
			local chatData = {
				player = player.Name,
				message = message,
				timestamp = os.time(),
				serverId = game.JobId,
				messageType = "chat"
			}
			receiveChatMessageRemote:FireClient(jeffPlayer, chatData)
		else
			print("GlobalChat Server: jeff_buttercup not found in this server")
		end
	end)
	
	-- Also try to connect to PlayerChatted if it exists (alternative method)
	local success, err = pcall(function()
		local StarterGui = game:GetService("StarterGui")
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end)
	
	if not success then
		print("GlobalChat Server: Could not ensure chat is enabled:", err)
	end
end

-- Set up chat monitoring for existing players
print("GlobalChat Server: Setting up chat monitoring for existing players...")
for _, player in pairs(Players:GetPlayers()) do
	setupChatMonitoring(player)
	print("GlobalChat Server: Chat monitoring set up for existing player:", player.Name)
end

-- Set up chat monitoring for new players
Players.PlayerAdded:Connect(function(player)
	print("GlobalChat Server: New player joined:", player.Name)
	setupChatMonitoring(player)
end)

-- Subscribe to global chat messages
local success, connection = pcall(function()
	return MessagingService:SubscribeAsync(GLOBAL_CHAT_TOPIC, onGlobalMessageReceived)
end)

if not success then
	warn("Failed to subscribe to global chat:", connection)
end

-- Subscribe to chat monitoring messages
local success2, connection2 = pcall(function()
	return MessagingService:SubscribeAsync(CHAT_MONITOR_TOPIC, onChatMessageReceived)
end)

if not success2 then
	warn("Failed to subscribe to chat monitoring:", connection2)
end

print("Global Chat Server initialized for", AUTHORIZED_USER)
print("GlobalChat Server: RemoteEvents created in ReplicatedStorage.GlobalChat")
print("GlobalChat Server: Listening for messages...")
print("GlobalChat Server: Chat monitoring active for all players") 