local Database = {
	Bandit = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 70, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = false,
			AttackLog = {},

			Rewards = {
				Beli = 50,
				Exp = 34,
				Bounty = 100,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 3,
		RespawnTime = 10,
		PassiveAgressive = false,
		Quantity = 8, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	Monkey = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 200, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = false,
			AttackLog = {},

			Rewards = {
				Beli = 120,
				Exp = 76,
				Bounty = 200,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .75,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 7,
		RespawnTime = 10,
		PassiveAgressive = false,
		Quantity = 6, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	
	["Gorilla King"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 600, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = true,
			AttackLog = {},

			Rewards = {
				Beli = 450,
				Exp = 400,
				Bounty = 250,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 22,
		RespawnTime = 50,
		PassiveAgressive = true,
		Quantity = 1, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	["Buggy Pirate"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 500, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = false,
			AttackLog = {},

			Rewards = {
				Beli = 250,
				Exp = 100,
				Bounty = 150,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 17,
		RespawnTime = 10,
		PassiveAgressive = false,
		Quantity = 6, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	["Strong Buggy Pirate"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 780, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = false,
			AttackLog = {},

			Rewards = {
				Beli = 700,
				Exp = 700,
				Bounty = 500,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 35,
		RespawnTime = 10,
		PassiveAgressive = false,
		Quantity = 6, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	["Buggy"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 1400, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = true,
			AttackLog = {},

			Rewards = {
				Beli = 1150,
				Exp = 1400,
				Bounty = 1100,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 45,
		RespawnTime = 50,
		PassiveAgressive = true,
		Quantity = 1, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	["Snow Pirate"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 1250, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = false,
			AttackLog = {},

			Rewards = {
				Beli = 950,
				Exp = 850,
				Bounty = 700,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 55,
		RespawnTime = 10,
		PassiveAgressive = false,
		Quantity = 6, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	["Yeti"] = {
		HumanoidProperties = { -- Put any humanoid properties you want set in here
			WalkSpeed = 18,
			MaxHealth = 2000, -- Make sure to put MaxHealth before Health
		},

		MiscData = { -- This is data for your own game
			Haki = true,
			AttackLog = {},

			Rewards = {
				Beli = 1450,
				Exp = 1850,
				Bounty = 1500,
				Drops = {},
			}
		},

		--| Other Essential Data
		AttackDistance = 5,
		AttackCooldown = .5,
		ChaseRange = 100,
		AggroRange = 40,

		AttackDamage = 70,
		RespawnTime = 50,
		PassiveAgressive = true,
		Quantity = 1, -- Per Spawner
		Animations = {
			Idle = "rbxassetid://10747932367",
			Chase = "rbxassetid://10747912595",
			Attack = {"rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917", "rbxassetid://10561266690", "rbxassetid://10561247917"},
		},
		RandomAttack = false, -- If false it will iterate in order

		--[[
		
		If you want a custom attack function list make a index called Attack with a function
		
		]]
		--Attack = function(NPC, Target) -- This would have custom attack

		--end,
		--Die = function(NPC) -- This would have a custom death

		--end,

	},
	
	
}

return Database
