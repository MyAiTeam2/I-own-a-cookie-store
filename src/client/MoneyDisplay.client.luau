-- Money Display Client Script
-- This script finds and updates the money display in StarterGui

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the Stat module (same one used by dropper)
local Stat = require(ReplicatedStorage:WaitForChild("Stat"))

-- References
local moneyLabel = nil
local currentMoney = 0

-- Function to format money with commas
local function formatMoney(amount)
	local formatted = tostring(amount)
	-- Add commas for thousands
	local k = 1
	while k < #formatted do
		if (k - 1) % 3 == 0 and k > 1 then
			formatted = formatted:sub(1, #formatted - k) .. "," .. formatted:sub(#formatted - k + 1)
			k = k + 1
		end
		k = k + 1
	end
	return "$" .. formatted
end

-- Function to find the money label using the exact path
local function findMoneyLabelDirect()
	-- Try to find: StarterGui.Interface.HUD.MoneyLabel.Main
	local success, result = pcall(function()
		local interface = playerGui:WaitForChild("Interface", 5)
		if not interface then
			return nil
		end
		
		local hud = interface:WaitForChild("HUD", 5)
		if not hud then
			return nil
		end
		
		local moneyLabelFrame = hud:WaitForChild("MoneyLabel", 5)
		if not moneyLabelFrame then
			return nil
		end
		
		local main = moneyLabelFrame:WaitForChild("Main", 5)
		if not main then
			return nil
		end
		
		return main
	end)
	
	if success and result then
		return result
	else
		return nil
	end
end

-- Function to search through all GUI elements recursively (fallback)
local function findAllTextElements(parent, results)
	results = results or {}
	
	for _, child in pairs(parent:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			table.insert(results, child)
		end
		
		-- Recursively search children
		if #child:GetChildren() > 0 then
			findAllTextElements(child, results)
		end
	end
	
	return results
end

-- Function to find the money label (fallback search)
local function findMoneyLabelFallback()
	local allTextElements = {}
	
	-- Search PlayerGui
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			findAllTextElements(gui, allTextElements)
		end
	end
	
	-- Look specifically for "Main" elements first
	for i, element in pairs(allTextElements) do
		if element.Name:lower() == "main" then
			local fullName = element:GetFullName()
			
			-- Check if it's in the right hierarchy
			if fullName:lower():find("interface") and fullName:lower():find("hud") and fullName:lower():find("moneylabel") then
				return element
			end
		end
	end
	
	-- Analyze all text elements with scoring system
	for i, element in pairs(allTextElements) do
		local name = element.Name:lower()
		local text = element.Text:lower()
		local fullName = element:GetFullName()
		
		-- Score each element based on how likely it is to be the money display
		local score = 0
		
		-- Check name
		if name:find("money") then score = score + 10 end
		if name:find("main") then score = score + 8 end
		if name:find("cash") then score = score + 10 end
		if name:find("currency") then score = score + 10 end
		if name:find("coin") then score = score + 8 end
		if name:find("label") then score = score + 2 end
		
		-- Check text content
		if text:find("$") then score = score + 15 end
		if text:find("0") and #text <= 5 then score = score + 8 end -- Short text with 0
		if text:find("money") then score = score + 10 end
		
		-- Check parent names
		local parent = element.Parent
		while parent and parent ~= game do
			local parentName = parent.Name:lower()
			if parentName:find("money") then score = score + 5 end
			if parentName:find("hud") then score = score + 5 end
			if parentName:find("interface") then score = score + 5 end
			if parentName:find("ui") then score = score + 3 end
			parent = parent.Parent
		end
		
		-- If this looks very likely to be the money display, use it
		if score >= 15 then
			return element
		end
	end
	
	-- If no high-scoring element found, try to find any element with $ in text
	for _, element in pairs(allTextElements) do
		if element.Text:find("$") then
			return element
		end
	end
	
	return nil
end

-- Main function to find the money label
local function findMoneyLabel()
	-- First try the direct path
	local directResult = findMoneyLabelDirect()
	if directResult then
		return directResult
	end
	
	-- If direct path fails, use fallback search
	return findMoneyLabelFallback()
end

-- Function to update the money display
local function updateMoneyDisplay()
	if not moneyLabel then return end
	
	-- Get current money from player's stats
	local success, moneyValue = pcall(function()
		return Stat.Get(player, "Money")
	end)
	
	if success and moneyValue then
		local newAmount = moneyValue.Value or 0
		if newAmount ~= currentMoney then
			currentMoney = newAmount
			local newText = formatMoney(currentMoney)
			moneyLabel.Text = newText
		end
	else
		-- Fallback display if Stat system isn't available yet
		moneyLabel.Text = "$0"
	end
end

-- Main setup function
local function setupMoneyDisplay()
	-- Try to find existing money label
	moneyLabel = findMoneyLabel()
	
	if moneyLabel then
		-- Initial update
		updateMoneyDisplay()
		
		-- Connect to regular updates (check every frame)
		RunService.Heartbeat:Connect(updateMoneyDisplay)
	end
end

-- Initialize when player spawns
local function onPlayerSpawned()
	-- Wait for GUIs to fully load
	wait(3)
	setupMoneyDisplay()
end

-- Setup when player spawns
if player.Character then
	spawn(onPlayerSpawned)
end

player.CharacterAdded:Connect(function()
	spawn(onPlayerSpawned)
end)

-- Also try to set up immediately in case character is already loaded
spawn(function()
	wait(2)
	if not moneyLabel then
		setupMoneyDisplay()
	end
end) 