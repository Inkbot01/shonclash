return {
	["ActionFlags"] = {
		["Ability"] = {
			Blocking = false,
			Stunned = false,
			Knocked = false,
			
			Attacking = false,
		
			Endlag = false,
			
			Swimming = false,
			Charging = false,
			Casting = false,
		},
		
		--[[
		["Combat"] = {
			Casting = false,
			Endlag = false,

			Stunned = false,
			Knocked = false,
		},
	--]]
		["Block"] = {
			Casting = false,
			Endlag = false,
			Knocked = false,
			
			Stunned = false,
		}
		--]]
	},


	["States"] = {
		
		
		["Speed"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,


			Base = false,

			JumpPower = 50,
			WalkSpeed = 16,

			Priority = 0,

			Category = "SpecialInteger"
		},
	
		
		["Safezone"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,
			Category = "Boolean",
		},
		
		
		["Charging"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,
			Category = "Boolean",
		},
		
		["Blocking"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,
			
			BlockAmount = 0,
			MaxBlocks = 6,
			
			Base = false,
			
			Category = "Boolean"
		},
		
		["Attacking"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,

			Category = "SpecialInteger"
		},
		["IFrame"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,

			Category = "SpecialInteger"
		},
		["Endlag"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,

			Category = "SpecialInteger"
		},
		
		["CombatLog"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			LastAttackedBy = "",

			Base = false,

			Category = "SpecialInteger"
		},
		
		["Casting"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,
			Category = "SpecialInteger",
		},


		
		["Stamina"] = {
			Begin = workspace:GetServerTimeNow(),
			Base = false,
			
			CurrentStamina = 100,
			MaxStamina = 100,
			
		},
		
		["Knocked"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,

			Category = "SpecialInteger"
		},
		
		["Stunned"] = {
			Begin = workspace:GetServerTimeNow(),
			Duration = 0,

			Base = false,
			Category = "SpecialInteger"
		},

	}
}