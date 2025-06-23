-- Cookie Collection UI Client Script
-- Shows fun animations when collecting cookies
-- Now with stacking system to prevent UI spam

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local cookieFolder = ReplicatedStorage:WaitForChild("CookieSystem", 10)
if not cookieFolder then
	warn("CookieSystem folder not found!")
	return
end

local cookieCollectedRemote = cookieFolder:WaitForChild("CookieCollected", 5)
if not cookieCollectedRemote then
	warn("CookieCollected remote not found!")
	return
end

-- GUI Variables
local collectionGUI = nil
local notificationQueue = {}
local isShowingNotification = false

-- Stacking system variables
local STACK_TIME_WINDOW = 2 -- Stack collections within 2 seconds
local stackingData = {
	isStacking = false,
	totalAmount = 0,
	collectionCount = 0,
	ownCookies = 0,
	othersCookies = 0,
	lastOwnerName = "",
	stackStartTime = 0
}

-- Create collection notification GUI
local function createCollectionGUI()
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("CookieCollectionGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CookieCollectionGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Notification frame (left side, initially hidden)
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "NotificationFrame"
	notificationFrame.Size = UDim2.new(0, 280, 0, 100) -- Made slightly larger for stacking info
	notificationFrame.Position = UDim2.new(0, -290, 0, 100) -- Start off-screen left
	notificationFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	notificationFrame.BackgroundTransparency = 0.1
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = screenGui

	-- Add rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notificationFrame

	-- Add gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0.2)), -- Gold
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.6, 0.1))  -- Orange
	}
	gradient.Rotation = 45
	gradient.Parent = notificationFrame

	-- Add glow effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 0.5)
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = notificationFrame

	-- Cookie icon
	local cookieIcon = Instance.new("TextLabel")
	cookieIcon.Name = "CookieIcon"
	cookieIcon.Size = UDim2.new(0, 50, 0, 50)
	cookieIcon.Position = UDim2.new(0, 10, 0, 10)
	cookieIcon.BackgroundTransparency = 1
	cookieIcon.Text = "🍪"
	cookieIcon.TextColor3 = Color3.new(1, 1, 1)
	cookieIcon.TextScaled = true
	cookieIcon.Font = Enum.Font.SourceSansBold
	cookieIcon.Parent = notificationFrame

	-- Stack counter (shows x5, x10, etc.)
	local stackCounter = Instance.new("TextLabel")
	stackCounter.Name = "StackCounter"
	stackCounter.Size = UDim2.new(0, 30, 0, 20)
	stackCounter.Position = UDim2.new(0, 30, 0, 5)
	stackCounter.BackgroundColor3 = Color3.new(1, 0.2, 0.2)
	stackCounter.BorderSizePixel = 0
	stackCounter.Text = "x1"
	stackCounter.TextColor3 = Color3.new(1, 1, 1)
	stackCounter.TextSize = 12
	stackCounter.Font = Enum.Font.SourceSansBold
	stackCounter.TextXAlignment = Enum.TextXAlignment.Center
	stackCounter.Visible = false
	stackCounter.Parent = notificationFrame

	-- Add rounded corners to stack counter
	local stackCorner = Instance.new("UICorner")
	stackCorner.CornerRadius = UDim.new(0, 6)
	stackCorner.Parent = stackCounter

	-- Main text
	local mainText = Instance.new("TextLabel")
	mainText.Name = "MainText"
	mainText.Size = UDim2.new(1, -70, 0, 25)
	mainText.Position = UDim2.new(0, 65, 0, 5)
	mainText.BackgroundTransparency = 1
	mainText.Text = "COOKIES COLLECTED!"
	mainText.TextColor3 = Color3.new(1, 1, 1)
	mainText.TextSize = 16
	mainText.Font = Enum.Font.SourceSansBold
	mainText.TextXAlignment = Enum.TextXAlignment.Left
	mainText.TextStrokeTransparency = 0
	mainText.TextStrokeColor3 = Color3.new(0, 0, 0)
	mainText.Parent = notificationFrame

	-- Money text
	local moneyText = Instance.new("TextLabel")
	moneyText.Name = "MoneyText"
	moneyText.Size = UDim2.new(1, -70, 0, 30)
	moneyText.Position = UDim2.new(0, 65, 0, 25)
	moneyText.BackgroundTransparency = 1
	moneyText.Text = "+$0"
	moneyText.TextColor3 = Color3.new(0.2, 1, 0.2) -- Bright green
	moneyText.TextSize = 22
	moneyText.Font = Enum.Font.SourceSansBold
	moneyText.TextXAlignment = Enum.TextXAlignment.Left
	moneyText.TextStrokeTransparency = 0
	moneyText.TextStrokeColor3 = Color3.new(0, 0, 0)
	moneyText.Parent = notificationFrame

	-- Details text (shows breakdown)
	local detailsText = Instance.new("TextLabel")
	detailsText.Name = "DetailsText"
	detailsText.Size = UDim2.new(1, -70, 0, 20)
	detailsText.Position = UDim2.new(0, 65, 0, 55)
	detailsText.BackgroundTransparency = 1
	detailsText.Text = ""
	detailsText.TextColor3 = Color3.new(0.8, 0.8, 1) -- Light blue
	detailsText.TextSize = 11
	detailsText.Font = Enum.Font.SourceSans
	detailsText.TextXAlignment = Enum.TextXAlignment.Left
	detailsText.TextStrokeTransparency = 0
	detailsText.TextStrokeColor3 = Color3.new(0, 0, 0)
	detailsText.Visible = false
	detailsText.Parent = notificationFrame

	-- Owner text (for when collecting someone else's cookie)
	local ownerText = Instance.new("TextLabel")
	ownerText.Name = "OwnerText"
	ownerText.Size = UDim2.new(1, -70, 0, 15)
	ownerText.Position = UDim2.new(0, 65, 0, 75)
	ownerText.BackgroundTransparency = 1
	ownerText.Text = ""
	ownerText.TextColor3 = Color3.new(0.8, 0.8, 1) -- Light blue
	ownerText.TextSize = 10
	ownerText.Font = Enum.Font.SourceSans
	ownerText.TextXAlignment = Enum.TextXAlignment.Left
	ownerText.TextStrokeTransparency = 0
	ownerText.TextStrokeColor3 = Color3.new(0, 0, 0)
	ownerText.Visible = false
	ownerText.Parent = notificationFrame

	-- Store reference
	collectionGUI = notificationFrame

	return screenGui
end

-- Show collection notification with stacking support
local function showCollectionNotification(totalAmount, collectionCount, ownCookies, othersCookies, lastOwnerName)
	if not collectionGUI then return end

	local cookieIcon = collectionGUI:FindFirstChild("CookieIcon")
	local stackCounter = collectionGUI:FindFirstChild("StackCounter")
	local mainText = collectionGUI:FindFirstChild("MainText")
	local moneyText = collectionGUI:FindFirstChild("MoneyText")
	local detailsText = collectionGUI:FindFirstChild("DetailsText")
	local ownerText = collectionGUI:FindFirstChild("OwnerText")

	if not cookieIcon or not mainText or not moneyText then return end

	-- Set text based on collection data
	if collectionCount == 1 then
		-- Single collection
		if ownCookies == 1 then
			mainText.Text = "YOUR COOKIE COLLECTED!"
		else
			mainText.Text = "COOKIE COLLECTED!"
		end
		stackCounter.Visible = false
		detailsText.Visible = false
		
		if othersCookies > 0 then
			ownerText.Text = "Owner: " .. lastOwnerName .. " gets paid too!"
			ownerText.Visible = true
		else
			ownerText.Visible = false
		end
	else
		-- Multiple collections (stacked)
		mainText.Text = "COOKIES COLLECTED!"
		stackCounter.Text = "x" .. collectionCount
		stackCounter.Visible = true
		
		-- Show breakdown
		if ownCookies > 0 and othersCookies > 0 then
			detailsText.Text = string.format("Yours: %d | Others: %d", ownCookies, othersCookies)
			detailsText.Visible = true
			ownerText.Text = "Owners get paid too!"
			ownerText.Visible = true
		elseif ownCookies > 0 then
			detailsText.Text = "All your cookies!"
			detailsText.Visible = true
			ownerText.Visible = false
		else
			detailsText.Text = "All from other players"
			detailsText.Visible = true
			ownerText.Text = "Owners get paid too!"
			ownerText.Visible = true
		end
	end

	moneyText.Text = "+$" .. totalAmount

	-- Reset position and transparency
	collectionGUI.Position = UDim2.new(0, -290, 0, 100)
	collectionGUI.BackgroundTransparency = 0.1
	cookieIcon.TextTransparency = 0
	mainText.TextTransparency = 0
	moneyText.TextTransparency = 0
	if detailsText.Visible then detailsText.TextTransparency = 0 end
	if ownerText.Visible then ownerText.TextTransparency = 0 end
	if stackCounter.Visible then stackCounter.BackgroundTransparency = 0 end

	-- Animate in from left
	local slideIn = TweenService:Create(collectionGUI,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 10, 0, 100)}
	)
	slideIn:Play()

	-- Cookie bounce animation (bigger bounce for stacked collections)
	local bounceSize = collectionCount > 1 and 70 or 60
	local bounceUp = TweenService:Create(cookieIcon,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, bounceSize, 0, bounceSize)}
	)
	local bounceDown = TweenService:Create(cookieIcon,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 50, 0, 50)}
	)

	bounceUp:Play()
	bounceUp.Completed:Connect(function()
		bounceDown:Play()
	end)

	-- Money text pop animation (bigger for larger amounts)
	local popSize = math.min(28, 22 + (collectionCount * 0.5))
	local moneyPop = TweenService:Create(moneyText,
		TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{TextSize = popSize}
	)
	local moneyReturn = TweenService:Create(moneyText,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextSize = 22}
	)

	task.wait(0.2)
	moneyPop:Play()
	moneyPop.Completed:Connect(function()
		moneyReturn:Play()
	end)

	-- Stack counter bounce if visible
	if stackCounter.Visible then
		local stackBounce = TweenService:Create(stackCounter,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 35, 0, 25)}
		)
		local stackReturn = TweenService:Create(stackCounter,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 30, 0, 20)}
		)
		
		task.wait(0.1)
		stackBounce:Play()
		stackBounce.Completed:Connect(function()
			stackReturn:Play()
		end)
	end

	-- Wait then slide out (longer for stacked collections)
	local displayTime = collectionCount > 1 and 4 or 3
	task.spawn(function()
		task.wait(displayTime)

		local slideOut = TweenService:Create(collectionGUI,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0, -290, 0, 100),
				BackgroundTransparency = 1
			}
		)

		local fadeElements = {cookieIcon, mainText, moneyText}
		if detailsText.Visible then table.insert(fadeElements, detailsText) end
		if ownerText.Visible then table.insert(fadeElements, ownerText) end
		
		for _, element in pairs(fadeElements) do
			local fadeProperty = element:IsA("TextLabel") and "TextTransparency" or "BackgroundTransparency"
			TweenService:Create(element,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{[fadeProperty] = 1}
			):Play()
		end

		if stackCounter.Visible then
			TweenService:Create(stackCounter,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{BackgroundTransparency = 1}
			):Play()
		end

		slideOut:Play()
		slideOut.Completed:Connect(function()
			isShowingNotification = false
			-- Process next notification in queue
			if #notificationQueue > 0 then
				local nextNotification = table.remove(notificationQueue, 1)
				showCollectionNotification(
					nextNotification.totalAmount,
					nextNotification.collectionCount,
					nextNotification.ownCookies,
					nextNotification.othersCookies,
					nextNotification.lastOwnerName
				)
			end
		end)
	end)
end

-- Process stacked collection
local function processStackedCollection()
	if stackingData.collectionCount > 0 then
		isShowingNotification = true
		showCollectionNotification(
			stackingData.totalAmount,
			stackingData.collectionCount,
			stackingData.ownCookies,
			stackingData.othersCookies,
			stackingData.lastOwnerName
		)
		
		-- Reset stacking data
		stackingData = {
			isStacking = false,
			totalAmount = 0,
			collectionCount = 0,
			ownCookies = 0,
			othersCookies = 0,
			lastOwnerName = "",
			stackStartTime = 0
		}
	end
end

-- Handle new collection with stacking
local function handleCollection(amount, ownerName, collectorName)
	local isOwnerCollection = (collectorName == player.Name and ownerName == player.Name)
	local currentTime = tick()
	
	-- Check if we should start/continue stacking
	if not stackingData.isStacking then
		-- Start new stacking window
		stackingData.isStacking = true
		stackingData.stackStartTime = currentTime
		stackingData.totalAmount = amount
		stackingData.collectionCount = 1
		stackingData.ownCookies = isOwnerCollection and 1 or 0
		stackingData.othersCookies = isOwnerCollection and 0 or 1
		stackingData.lastOwnerName = ownerName
		
		-- Set timer to process stack
		task.spawn(function()
			task.wait(STACK_TIME_WINDOW)
			if stackingData.isStacking and (tick() - stackingData.stackStartTime) >= STACK_TIME_WINDOW then
				processStackedCollection()
			end
		end)
	elseif (currentTime - stackingData.stackStartTime) <= STACK_TIME_WINDOW then
		-- Add to existing stack
		stackingData.totalAmount = stackingData.totalAmount + amount
		stackingData.collectionCount = stackingData.collectionCount + 1
		if isOwnerCollection then
			stackingData.ownCookies = stackingData.ownCookies + 1
		else
			stackingData.othersCookies = stackingData.othersCookies + 1
			stackingData.lastOwnerName = ownerName -- Update to latest owner
		end
	else
		-- Process current stack and start new one
		processStackedCollection()
		task.wait(0.1) -- Small delay to prevent overlap
		handleCollection(amount, ownerName, collectorName) -- Recursively handle this collection
	end
end

-- Setup GUI and connections
local function setupCollectionUI()
	createCollectionGUI()

	-- Connect to cookie collection events
	cookieCollectedRemote.OnClientEvent:Connect(function(data)
		local amount = data.amount or 0
		local ownerName = data.owner or "Unknown"
		local collectorName = data.collector or "Unknown"

		print("Cookie collected - Amount:", amount, "Owner:", ownerName, "Collector:", collectorName)
		
		-- Handle with stacking system
		if not isShowingNotification then
			handleCollection(amount, ownerName, collectorName)
		else
			-- Queue it if notification is already showing
			table.insert(notificationQueue, {
				amount = amount,
				ownerName = ownerName,
				collectorName = collectorName
			})
		end
	end)

	print("Cookie Collection UI initialized with stacking system")
	print("Stack time window:", STACK_TIME_WINDOW, "seconds")
end

-- Initialize the system
setupCollectionUI()

-- Recreate system when player spawns
player.CharacterAdded:Connect(function()
	wait(1)
	setupCollectionUI()
end) 