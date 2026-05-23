return {
	["Dash"] = {
		Name = "Dash",

		Chargeable = false,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 5,
		Range = 9,

		--> State Statistics
		Cooldown = .35,  --.6
		Stamina = 7,

		Endlag =  .15, --.25
		--StunTime = .75,


		--> Level
		Level = 1,
		Mastery = 1,

		--> Action Flag
		ActionFlag = "Ability"
	},
	
	["Geppo"] = {
		Name = "Geppo",

		Chargeable = false,
		InitTimeStamp = os.clock(),

		--> Damage Statistics
		Damage = 15,
		Range = 9,

		--> State Statistics
		Cooldown = .35,  --.6
		Stamina = 7,

		Endlag =  .15, --.25
		--StunTime = .75,


		--> Level
		Level = 1,
		Mastery = 1,

		--> Action Flag
		ActionFlag = "Ability"
	},
	
}