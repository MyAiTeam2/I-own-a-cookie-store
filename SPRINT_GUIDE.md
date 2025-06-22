# Sprint System Guide

## What This System Does
This sprint system lets players run faster by holding Shift, with a stamina bar that drains and regenerates.

## How It's Organized (Modular Structure)

### 📁 `src/client/init.client.luau` - **Client Side**
**What it does:** Handles the player's screen (GUI), input (keyboard), and visual effects
- Creates the stamina bar you see on screen
- Listens for Shift key presses
- Shows particle effects when sprinting
- Manages stamina drain/regeneration
- Communicates with the server when you start/stop sprinting

### 📁 `src/server/init.server.luau` - **Server Side** 
**What it does:** Handles the actual speed changes and validates requests
- Creates the communication system (RemoteEvents)
- Changes your character's walk speed when you sprint
- Keeps track of who is sprinting
- Prevents cheating by validating on the server

### 📁 `src/shared/SprintModule.luau` - **Shared Settings**
**What it does:** Contains all the settings both client and server need
- Sprint speed bonus (how much faster you go)
- Stamina amounts and drain/regen rates
- Easy to modify all settings in one place!

## How They Work Together

1. **Player presses Shift** → Client detects this
2. **Client checks stamina** → If enough stamina, tells server to start sprinting
3. **Server receives request** → Changes player's walk speed
4. **Client shows effects** → Stamina bar, particles, "SPRINTING" text
5. **Stamina drains** → Client tracks this and stops when empty
6. **Player releases Shift** → Client tells server to stop, speed returns to normal

## Easy Customization

Want to change how the sprint works? Just edit `src/shared/SprintModule.luau`:

```lua
-- Make sprinting faster
SprintModule.BASE_SPRINT_BONUS = 20 -- was 12

-- Make stamina last longer
SprintModule.STAMINA_DRAIN_RATE = 10 -- was 20

-- Make stamina regenerate faster
SprintModule.STAMINA_REGEN_RATE = 25 -- was 15
```

## Why This Structure is Good

- **Modular:** Each part has a specific job
- **Secure:** Server validates everything, prevents cheating
- **Reusable:** Easy to copy to other games
- **Maintainable:** Settings are in one place
- **Expandable:** Easy to add features like sound effects, different sprint types, etc.

## Testing It

1. Open Roblox Studio
2. Make sure Rojo is running and synced
3. Press Play
4. Hold Shift to sprint!
5. Watch the stamina bar in the bottom-left corner 