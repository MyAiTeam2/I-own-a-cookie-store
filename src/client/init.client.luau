-- Sprint System Client
-- This handles the user interface and input for sprinting

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the shared sprint module
local SprintModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SprintModule"))

-- Wait for sprint remotes with timeout protection
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

-- Sprint State
local currentStamina = SprintModule.MAX_STAMINA
local isSprinting = false
local canSprint = true
local isShiftHeld = false
local isButtonPressed = false

-- GUI References
local sprintGUI = nil
local staminaBarFill = nil
local staminaText = nil

-- Visual Effects
local sprintEffect = nil
local sprintSound = nil

-- Create Sprint GUI
local function createSprintGUI()
	-- Remove existing GUI if it exists
	local existingGUI = playerGui:FindFirstChild("SprintGUI")
	if existingGUI then
		existingGUI:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SprintGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main stamina bar frame
	local staminaFrame = Instance.new("Frame")
	staminaFrame.Name = "StaminaFrame"
	staminaFrame.Size = UDim2.new(0, 200, 0, 20)
	staminaFrame.Position = UDim2.new(0, 20, 1, -40) -- Bottom left of screen
	staminaFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	staminaFrame.BorderSizePixel = 2
	staminaFrame.BorderColor3 = Color3.new(0.3, 0.3, 0.3)
	staminaFrame.Parent = screenGui

	-- Stamina bar background
	local staminaBackground = Instance.new("Frame")
	staminaBackground.Name = "StaminaBackground"
	staminaBackground.Size = UDim2.new(1, -4, 1, -4)
	staminaBackground.Position = UDim2.new(0, 2, 0, 2)
	staminaBackground.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	staminaBackground.BorderSizePixel = 0
	staminaBackground.Parent = staminaFrame

	-- Stamina bar fill
	local staminaFill = Instance.new("Frame")
	staminaFill.Name = "StaminaFill"
	staminaFill.Size = UDim2.new(1, 0, 1, 0)
	staminaFill.Position = UDim2.new(0, 0, 0, 0)
	staminaFill.BackgroundColor3 = Color3.new(0, 0.8, 0.2) -- Green color
	staminaFill.BorderSizePixel = 0
	staminaFill.Parent = staminaBackground

	-- Sprint button (clickable)
	local sprintButton = Instance.new("TextButton")
	sprintButton.Name = "SprintButton"
	sprintButton.Size = UDim2.new(1, 0, 1, 0)
	sprintButton.Position = UDim2.new(0, 0, 0, 0)
	sprintButton.BackgroundTransparency = 1
	sprintButton.Text = "SPRINT"
	sprintButton.TextColor3 = Color3.new(1, 1, 1)
	sprintButton.TextScaled = true
	sprintButton.Font = Enum.Font.SourceSansBold
	sprintButton.Parent = staminaFrame

	-- Sprint indicator
	local sprintIndicator = Instance.new("TextLabel")
	sprintIndicator.Name = "SprintIndicator"
	sprintIndicator.Size = UDim2.new(0, 150, 0, 20)
	sprintIndicator.Position = UDim2.new(0, 20, 1, -65) -- Above stamina bar
	sprintIndicator.BackgroundTransparency = 1
	sprintIndicator.Text = ""
	sprintIndicator.TextColor3 = Color3.new(1, 1, 0) -- Yellow
	sprintIndicator.TextScaled = true
	sprintIndicator.Font = Enum.Font.SourceSansBold
	sprintIndicator.Visible = false
	sprintIndicator.Parent = screenGui

	-- Store references
	sprintGUI = screenGui
	staminaBarFill = staminaFill
	staminaText = sprintButton

	return screenGui, sprintIndicator, sprintButton
end

-- Create visual sprint effects
local function createSprintEffects(character)
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local rootPart = character.HumanoidRootPart

	-- Clean up any existing effects first
	local existingAttachment = rootPart:FindFirstChild("SprintAttachment")
	if existingAttachment then
		existingAttachment:Destroy()
	end

	-- Speed lines effect
	local attachment = Instance.new("Attachment")
	attachment.Name = "SprintAttachment"
	attachment.Parent = rootPart

	-- Create particle effect for speed
	local speedParticles = Instance.new("ParticleEmitter")
	speedParticles.Name = "SpeedParticles"
	speedParticles.Parent = attachment
	speedParticles.Enabled = false
	speedParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	speedParticles.Lifetime = NumberRange.new(0.3, 0.6)
	speedParticles.Rate = 50
	speedParticles.SpreadAngle = Vector2.new(45, 45)
	speedParticles.Speed = NumberRange.new(5, 10)
	speedParticles.Color = ColorSequence.new(Color3.new(0.8, 0.8, 1)) -- Light blue
	speedParticles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	}
	speedParticles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.1)
	}

	return speedParticles
end

-- Update stamina bar visual
local function updateStaminaBar()
	if not staminaBarFill then return end

	local staminaPercent = currentStamina / SprintModule.MAX_STAMINA
	staminaBarFill.Size = UDim2.new(staminaPercent, 0, 1, 0)

	-- Change color based on stamina level
	if staminaPercent > 0.6 then
		staminaBarFill.BackgroundColor3 = Color3.new(0, 0.8, 0.2) -- Green
	elseif staminaPercent > 0.3 then
		staminaBarFill.BackgroundColor3 = Color3.new(1, 0.8, 0) -- Yellow
	else
		staminaBarFill.BackgroundColor3 = Color3.new(1, 0.2, 0.2) -- Red
	end

	-- Update text
	if staminaText then
		if isSprinting then
			staminaText.Text = string.format("SPRINTING (+%d)", SprintModule.BASE_SPRINT_BONUS)
		elseif currentStamina < SprintModule.MAX_STAMINA then
			staminaText.Text = string.format("SPRINT %.0f%%", staminaPercent * 100)
		else
			staminaText.Text = "SPRINT"
		end
	end
end

-- Start sprinting
local function startSprint()
	if not canSprint or currentStamina < SprintModule.MIN_STAMINA_TO_START or isSprinting then return end

	local character = player.Character
	if not character then return end

	isSprinting = true

	-- Tell server to start sprinting (with error protection)
	if startSprintRemote then
		local success, err = pcall(function()
			startSprintRemote:FireServer()
		end)
		if not success then
			warn("Failed to fire StartSprint remote:", err)
		end
	end

	-- Create visual effects
	if not sprintEffect then
		sprintEffect = createSprintEffects(character)
	end
	
	if sprintEffect then
		sprintEffect.Enabled = true
	end

	-- Show sprint indicator
	local sprintIndicator = sprintGUI:FindFirstChild("SprintIndicator")
	if sprintIndicator then
		sprintIndicator.Visible = true
		sprintIndicator.Text = string.format(">> SPRINTING (+%d) <<", SprintModule.BASE_SPRINT_BONUS)

		-- Pulsing effect
		local pulseInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local pulseTween = TweenService:Create(sprintIndicator, pulseInfo, {TextTransparency = 0.3})
		pulseTween:Play()
	end
end

-- Stop sprinting
local function stopSprint()
	if not isSprinting then return end

	isSprinting = false

	-- Tell server to stop sprinting (with error protection)
	if stopSprintRemote then
		local success, err = pcall(function()
			stopSprintRemote:FireServer()
		end)
		if not success then
			warn("Failed to fire StopSprint remote:", err)
		end
	end

	-- Disable visual effects
	if sprintEffect then
		sprintEffect.Enabled = false
	end

	-- Hide sprint indicator
	local sprintIndicator = sprintGUI:FindFirstChild("SprintIndicator")
	if sprintIndicator then
		sprintIndicator.Visible = false
		TweenService:Create(sprintIndicator, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	end
end

-- Handle stamina logic
local function updateStamina(deltaTime)
	if isSprinting and (isShiftHeld or isButtonPressed) then
		-- Drain stamina while sprinting
		currentStamina = math.max(0, currentStamina - (SprintModule.STAMINA_DRAIN_RATE * deltaTime))

		-- Stop sprinting if out of stamina
		if currentStamina <= 0 then
			stopSprint()
			canSprint = false
		end
	else
		-- Regenerate stamina when not sprinting
		if currentStamina < SprintModule.MAX_STAMINA then
			currentStamina = math.min(SprintModule.MAX_STAMINA, currentStamina + (SprintModule.STAMINA_REGEN_RATE * deltaTime))
		end

		-- Allow sprinting again when stamina is sufficient
		if currentStamina >= SprintModule.MIN_STAMINA_TO_START then
			canSprint = true
		end
	end

	updateStaminaBar()
end

-- Input handling
local function onKeyPress(key, gameProcessed)
	if gameProcessed then return end

	if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
		isShiftHeld = true
		startSprint()
	end
end

local function onKeyRelease(key, gameProcessed)
	if gameProcessed then return end

	if key.KeyCode == Enum.KeyCode.LeftShift or key.KeyCode == Enum.KeyCode.RightShift then
		isShiftHeld = false
		stopSprint()
	end
end

-- Setup function
local function setupSprintSystem()
	local gui, sprintIndicator, sprintButton = createSprintGUI()

	-- Connect button events for mobile/desktop clicking
	if sprintButton then
		sprintButton.MouseButton1Down:Connect(function()
			isButtonPressed = true
			startSprint()
		end)

		sprintButton.MouseButton1Up:Connect(function()
			isButtonPressed = false
			stopSprint()
		end)
	end

	-- Connect stamina update loop
	RunService.Heartbeat:Connect(updateStamina)

	-- Connect input events
	UserInputService.InputBegan:Connect(onKeyPress)
	UserInputService.InputEnded:Connect(onKeyRelease)

	-- Initial stamina bar update
	updateStaminaBar()
end

-- Initialize the system
setupSprintSystem()

-- Recreate system when player spawns
player.CharacterAdded:Connect(function(character)
	wait(1) -- Wait for character to fully load

	-- Reset sprint state
	isSprinting = false
	currentStamina = SprintModule.MAX_STAMINA
	canSprint = true
	isButtonPressed = false
	sprintEffect = nil

	-- Recreate GUI
	setupSprintSystem()
end)

