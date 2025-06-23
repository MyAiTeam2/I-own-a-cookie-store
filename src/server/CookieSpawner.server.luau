-- Cookie Spawner Server Script
-- Spawns cookies on Ground parts that players can collect for money
-- Supports owner payments when other players collect cookies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for required modules
local Stat = require(ReplicatedStorage:WaitForChild("Stat"))
local Multipliers = require(ReplicatedStorage:WaitForChild("Multipliers"))

-- Create RemoteEvents
local cookieFolder = Instance.new("Folder")
cookieFolder.Name = "CookieSystem"
cookieFolder.Parent = ReplicatedStorage

local cookieCollectedRemote = Instance.new("RemoteEvent")
cookieCollectedRemote.Name = "CookieCollected"
cookieCollectedRemote.Parent = cookieFolder

-- Configuration
local MAX_COOKIES_PER_GROUND = 5 -- Maximum cookies per Ground part
local SPAWN_INTERVAL = 1 -- Spawn every 1 second
local COOKIE_VALUE = 5 -- Base value of each cookie
local COOKIE_LIFETIME = 30 -- Cookies despawn after 30 seconds
local OWNER_SHARE = 0.5 -- Owner gets 50% when someone else collects their cookie

-- Create cookie model with owner support
local function createCookieModel(ownerPlayer)
	local cookie = Instance.new("Part")
	cookie.Name = "Cookie"
	cookie.Shape = Enum.PartType.Cylinder
	cookie.Size = Vector3.new(0.5, 2, 2)
	cookie.Material = Enum.Material.Neon
	cookie.BrickColor = BrickColor.new("Bright orange")
	cookie.CanCollide = false
	cookie.Anchored = false
	
	-- Add a slight glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.new(1, 0.6, 0.2)
	pointLight.Brightness = 0.5
	pointLight.Range = 5
	pointLight.Parent = cookie
	
	-- Add spinning effect
	local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
	bodyAngularVelocity.AngularVelocity = Vector3.new(0, 5, 0)
	bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
	bodyAngularVelocity.Parent = cookie
	
	-- Add floating effect
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	bodyPosition.P = 3000
	bodyPosition.D = 500
	bodyPosition.Parent = cookie
	
	-- Add worth value
	local worth = Instance.new("NumberValue")
	worth.Name = "Worth"
	worth.Value = COOKIE_VALUE
	worth.Parent = cookie
	
	-- Add owner value (like in your dropper script)
	local owner = Instance.new("ObjectValue")
	owner.Name = "Owner"
	owner.Value = ownerPlayer
	owner.Parent = cookie
	
	-- Add billboard GUI
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 50, 0, 25)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.Parent = cookie
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "🍪 $" .. COOKIE_VALUE
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Parent = billboardGui
	
	-- Add owner name to billboard if there's an owner
	if ownerPlayer then
		local ownerLabel = Instance.new("TextLabel")
		ownerLabel.Size = UDim2.new(1, 0, 0, 15)
		ownerLabel.Position = UDim2.new(0, 0, 1, 0)
		ownerLabel.BackgroundTransparency = 1
		ownerLabel.Text = ownerPlayer.Name .. "'s"
		ownerLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
		ownerLabel.TextSize = 8
		ownerLabel.Font = Enum.Font.SourceSans
		ownerLabel.TextStrokeTransparency = 0
		ownerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		ownerLabel.Parent = billboardGui
	end
	
	return cookie
end

-- Spawn a cookie on a Ground part (with optional owner)
local function spawnCookie(groundPart, ownerPlayer)
	-- Check if we've reached the maximum cookies for this ground
	local currentCookies = 0
	for _, child in pairs(groundPart:GetChildren()) do
		if child.Name == "Cookie" then
			currentCookies = currentCookies + 1
		end
	end
	
	if currentCookies >= MAX_COOKIES_PER_GROUND then
		return
	end
	
	-- Create new cookie with owner
	local newCookie = createCookieModel(ownerPlayer)
	
	-- Calculate random position on the ground part
	local groundSize = groundPart.Size
	local groundPos = groundPart.Position
	
	local randomX = math.random(-groundSize.X/2, groundSize.X/2) + groundPos.X
	local randomZ = math.random(-groundSize.Z/2, groundSize.Z/2) + groundPos.Z
	local spawnY = groundPos.Y + groundSize.Y/2 + 3 -- Spawn 3 studs above the ground
	
	local spawnPosition = Vector3.new(randomX, spawnY, randomZ)
	newCookie.Position = spawnPosition
	
	-- Set floating target position
	local bodyPosition = newCookie:FindFirstChild("BodyPosition")
	if bodyPosition then
		bodyPosition.Position = Vector3.new(randomX, spawnY, randomZ)
	end
	
	-- Parent to the ground part
	newCookie.Parent = groundPart
	
	local isCollected = false
	
	-- Handle cookie collection with owner payments
	newCookie.Touched:Connect(function(hitPart)
		if isCollected then return end
		
		-- Check if a player touched it
		if hitPart.Parent:FindFirstChild("Humanoid") then
			local character = hitPart.Parent
			local collector = Players:GetPlayerFromCharacter(character)
			
			if collector then
				isCollected = true
				
				-- Get cookie info
				local worth = newCookie:FindFirstChild("Worth")
				local owner = newCookie:FindFirstChild("Owner")
				local cookieValue = worth and worth.Value or COOKIE_VALUE
				local ownerPlayer = owner and owner.Value
				
				-- Calculate payments
				local collectorAmount = cookieValue
				local ownerAmount = 0
				
				-- If someone else collected the owner's cookie, split the payment
				if ownerPlayer and ownerPlayer ~= collector and Players:FindFirstChild(ownerPlayer.Name) then
					ownerAmount = math.floor(cookieValue * OWNER_SHARE)
					collectorAmount = cookieValue - ownerAmount
				end
				
				-- Pay the collector
				local success, collectorCurrency = pcall(function()
					return Stat.Get(collector, "Money")
				end)
				
				if success and collectorCurrency then
					local collectorMultiplier = Multipliers.GetMoneyMultiplier(collector)
					local finalCollectorAmount = collectorAmount * collectorMultiplier
					collectorCurrency.Value = collectorCurrency.Value + finalCollectorAmount
					
					-- Send UI notification to collector
					local collectorData = {
						amount = finalCollectorAmount,
						owner = ownerPlayer and ownerPlayer.Name or collector.Name,
						collector = collector.Name
					}
					cookieCollectedRemote:FireClient(collector, collectorData)
					
					print("Cookie collected by", collector.Name, "for $" .. finalCollectorAmount)
				end
				
				-- Pay the owner if applicable
				if ownerPlayer and ownerAmount > 0 and Players:FindFirstChild(ownerPlayer.Name) then
					local ownerSuccess, ownerCurrency = pcall(function()
						return Stat.Get(ownerPlayer, "Money")
					end)
					
					if ownerSuccess and ownerCurrency then
						local ownerMultiplier = Multipliers.GetMoneyMultiplier(ownerPlayer)
						local finalOwnerAmount = ownerAmount * ownerMultiplier
						ownerCurrency.Value = ownerCurrency.Value + finalOwnerAmount
						
						-- Send UI notification to owner
						local ownerData = {
							amount = finalOwnerAmount,
							owner = ownerPlayer.Name,
							collector = collector.Name
						}
						cookieCollectedRemote:FireClient(ownerPlayer, ownerData)
						
						print("Owner", ownerPlayer.Name, "received $" .. finalOwnerAmount, "from", collector.Name .. "'s collection")
					end
				end
				
				-- Destroy the cookie
				newCookie:Destroy()
			end
		end
	end)
	
	-- Auto-despawn after lifetime
	task.spawn(function()
		task.wait(COOKIE_LIFETIME)
		if newCookie and newCookie.Parent then
			newCookie:Destroy()
		end
	end)
	
	-- Make cookie fall and then float after a short delay
	task.spawn(function()
		task.wait(2.5)
		if newCookie and newCookie.Parent then
			newCookie.Anchored = false
			newCookie.CanCollide = false
		end
	end)
end

-- Find all Ground parts in the workspace
local function findGroundParts()
	local groundParts = {}
	
	-- Look for parts named "Ground" in workspace
	local function searchForGround(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("BasePart") and child.Name:lower():find("ground") then
				table.insert(groundParts, child)
			elseif child:IsA("Model") or child:IsA("Folder") then
				searchForGround(child)
			end
		end
	end
	
	searchForGround(workspace)
	return groundParts
end

-- Get random player to be the owner of spawned cookies
local function getRandomPlayer()
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[math.random(1, #players)]
	end
	return nil
end

-- Main spawning loop
local function startCookieSpawning()
	print("Cookie Spawner: Starting cookie spawning system...")
	
	while true do
		task.wait(SPAWN_INTERVAL)
		
		local groundParts = findGroundParts()
		
		if #groundParts == 0 then
			warn("Cookie Spawner: No Ground parts found in workspace!")
			task.wait(5) -- Wait longer if no ground parts found
			continue
		end
		
		-- Spawn cookies on each ground part with random owners
		for _, groundPart in pairs(groundParts) do
			task.spawn(function()
				local randomOwner = getRandomPlayer() -- Assign random player as owner
				spawnCookie(groundPart, randomOwner)
			end)
		end
	end
end

-- Initialize the system
print("Cookie Spawner: Initializing...")
print("Cookie Spawner: Configuration:")
print("  - Max cookies per ground:", MAX_COOKIES_PER_GROUND)
print("  - Spawn interval:", SPAWN_INTERVAL, "seconds")
print("  - Cookie value: $" .. COOKIE_VALUE)
print("  - Cookie lifetime:", COOKIE_LIFETIME, "seconds")
print("  - Owner share:", (OWNER_SHARE * 100) .. "%")
print("Cookie Spawner: RemoteEvents created in ReplicatedStorage.CookieSystem")

-- Start the spawning system
startCookieSpawning() 