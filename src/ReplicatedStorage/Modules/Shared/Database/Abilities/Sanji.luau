return {

	["Swing"] = {
		Name = "Swing",

		Chargeable = false,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 5,
		Range = 6.5,

		--> State Statistics
		Cooldown = .35,  --.6
		Stamina = 0,

		Endlag =  .15, --.25
		--StunTime = .75,


		--> Level
		Mastery = 1,

		--> Action Flag
		ActionFlag = "Ability"
	},
	["Grip"] = {
		Name = "Grip",

		Chargeable = false,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		--Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Level = 1,
		Mastery = 1,

		Stationary = false,

		--> Action Flag
		ActionFlag = "Ability",
	},
	
	
	
	["Block"] = {
		Name = "Block",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		--Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Level = 1,
		Mastery = 1,

		Stationary = false,

		--> Action Flag
		ActionFlag = "Block",
	},
	
	["FirstAbility"] = {
		Name = "Party Table",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Mastery = 1,

		Stationary = true,

		--> Action Flag
		ActionFlag = "Ability",
	},
	
	["SecondAbility"] = {
		Name = "Coussier",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Mastery = 10,

		Stationary = true,

		--> Action Flag
		ActionFlag = "Ability",
	},
	
	["ThirdAbility"] = {
		Name = "Veal Shot",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Mastery = 25,

		Stationary = false,

		--> Action Flag
		ActionFlag = "Ability",
	},
	
	["FourthAbility"] = {
		Name = "Diable Jiambe",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 2,
		--Range = 5,

		--> State Statistics
		Cooldown = 1, 
		Stamina = 5,

		--> Level
		Mastery = 50,

		Stationary = false,

		--> Action Flag
		ActionFlag = "Ability",
	},
	--[[
	["Dash"] = {
		Name = "Dash",

		Chargeable = false,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		 --> nan

		--> State Statistics
		Cooldown = 3,  --.6
		Stamina = 8,

		Endlag = .2, --.25
		--> Level
		Level = 1,

		--> Action Flag
		ActionFlag = "Ability"
	},
	--]]

	--[[
	["FirstAbility"] = {
		--> Name Id
		Name = "Ground Pound",

		Chargeable = true,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 18,
		Range = 5,

		--> State Statistics
		Cooldown = 10, 
		Stamina = 5,

		--> Level
		Level = 1,
		
		Mastery = 5,
		
		--> Action Flag
		ActionFlag = "Ability"
	},
	--]]


}