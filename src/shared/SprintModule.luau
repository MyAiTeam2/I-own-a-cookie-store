-- Sprint Module (Shared Configuration)
-- This contains all the settings and constants for the sprint system
-- Both client and server can access these values

local SprintModule = {}

-- Sprint Configuration - Easy to modify!
SprintModule.BASE_SPRINT_BONUS = 12 -- How much faster you go when sprinting
SprintModule.MAX_STAMINA = 100 -- Maximum stamina you can have
SprintModule.STAMINA_DRAIN_RATE = 20 -- How fast stamina drains per second while sprinting
SprintModule.STAMINA_REGEN_RATE = 15 -- How fast stamina regenerates per second when not sprinting
SprintModule.MIN_STAMINA_TO_START = 10 -- Minimum stamina needed to start sprinting

-- You can easily add more settings here in the future!
-- For example:
-- SprintModule.SPRINT_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
-- SprintModule.PARTICLE_COLOR = Color3.new(0.8, 0.8, 1)

return SprintModule