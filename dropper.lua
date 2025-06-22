local Dropper = {}

local Stat = require(game.ReplicatedStorage.Stat)
local Multipliers = require(game.ReplicatedStorage.Multipliers)

function Dropper.Spawn(Player, Pos, Amount, MeshName)
	local NewPart = game.ReplicatedStorage.Money[MeshName]:Clone()
	NewPart.Position = Pos
	NewPart.Parent = workspace.DropperParts[Player.Name.."-DropperParts"]
	
	local Worth = Instance.new("NumberValue")
	Worth.Name = "Worth"
	Worth.Value = Amount
	Worth.Parent = NewPart
	
	local Billboard = script.BillboardGui:Clone()
	Billboard.TextLabel.Text = "$"..Worth.Value
	Billboard.Parent = NewPart
	
	-- Add owner value to track who can collect this
	local Owner = Instance.new("ObjectValue")
	Owner.Name = "Owner"
	Owner.Value = Player
	Owner.Parent = NewPart
	
	-- Add collection sound
	local CollectSound = Instance.new("Sound")
	CollectSound.Name = "CollectSound"
	CollectSound.SoundId = "rbxassetid://5613553529"
	CollectSound.Volume = 1
	CollectSound.Parent = NewPart
	
	Worth.Changed:Connect(function()
		Billboard.TextLabel.Text = "$"..Worth.Value
	end)
	
	task.spawn(function() -- Despawn after 30 seconds
		task.wait(30)
		NewPart:Destroy()
	end)
	
	local Currency = Stat.Get(Player, "Money")
	local Rebirth = Stat.Get(Player, "Rebirth")
	
	NewPart.Touched:Connect(function(Hit)
		if Hit.Name == "Furnace" then
			Currency.Value += Worth.Value * Multipliers.GetMoneyMultiplier(Player)
			NewPart:Destroy()
		elseif Hit.Parent:FindFirstChild("Humanoid") then
			-- Check if the player touching it is the owner
			local TouchingPlayer = game.Players:GetPlayerFromCharacter(Hit.Parent)
			if TouchingPlayer and TouchingPlayer == Player then
				-- Play collection sound
				CollectSound:Play()
				-- Add money to player
				Currency.Value += Worth.Value * Multipliers.GetMoneyMultiplier(Player)
				-- Destroy the part
				NewPart:Destroy()
			end
		end
	end)
end

return Dropper