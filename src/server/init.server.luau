-- Sprint System Server
-- This handles the server-side logic for sprinting (speed changes, validation)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the shared sprint module
local SprintModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SprintModule"))

-- Wait for existing remote events with timeout protection
local sprintRemotes = ReplicatedStorage:WaitForChild("SprintRemotes", 10)
if not sprintRemotes then
	warn("SprintRemotes folder not found! Make sure it exists in ReplicatedStorage.")
	return
end

local startSprintRemote = sprintRemotes:WaitForChild("StartSprint", 5)
local stopSprintRemote = sprintRemotes:WaitForChild("StopSprint", 5)

if not startSprintRemote or not stopSprintRemote then
	warn("Sprint RemoteEvents not found! Make sure StartSprint and StopSprint exist in SprintRemotes folder.")
	return
end

-- Track sprinting players
local sprintingPlayers = {}

-- Apply sprint bonus to player
local function applySprintBonus(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	-- Store original walkspeed if not already stored
	if not sprintingPlayers[player] then
		sprintingPlayers[player] = {
			originalWalkSpeed = humanoid.WalkSpeed,
			startTime = tick()
		}
	end

	-- Apply sprint bonus
	humanoid.WalkSpeed = sprintingPlayers[player].originalWalkSpeed + SprintModule.BASE_SPRINT_BONUS

	return true
end

-- Remove sprint bonus from player
local function removeSprintBonus(player)
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false end

	-- Restore original walkspeed
	if sprintingPlayers[player] then
		humanoid.WalkSpeed = sprintingPlayers[player].originalWalkSpeed
		sprintingPlayers[player] = nil
	end

	return true
end

-- Handle start sprint requests
startSprintRemote.OnServerEvent:Connect(function(player)
	local success = applySprintBonus(player)
	if success then
		print(string.format("%s started sprinting (speed bonus: +%d)", player.Name, SprintModule.BASE_SPRINT_BONUS))
	end
end)

-- Handle stop sprint requests
stopSprintRemote.OnServerEvent:Connect(function(player)
	local success = removeSprintBonus(player)
	if success then
		print(string.format("%s stopped sprinting", player.Name))
	end
end)

-- Clean up sprint bonuses when player leaves
Players.PlayerRemoving:Connect(function(player)
	removeSprintBonus(player)
	sprintingPlayers[player] = nil
end)

-- Clean up sprint bonuses when character is removed/respawns
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		sprintingPlayers[player] = nil
	end)
end)

print("Sprint System Server loaded! Using existing SprintRemotes with timeout protection.")