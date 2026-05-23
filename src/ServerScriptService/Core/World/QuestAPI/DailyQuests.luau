return {

	["Progress"] = {
		
		QuestTitle = "Gain levels!",
		
		-- Add Rewards Later
		Rewards = {
			Gem = 100,
		},
		
		QuestData = {
			QuestObjective = "Level up",
			QuestProgress = 0,
			QuestMax = math.random(5, 10),


			QuestTarget = "Player"
		}
		
	},
	
	["Kill"] = {

		QuestTitle = "Kill Players!",

		-- Add Rewards Later
		Rewards = {
			Gem = 100,
		},

		QuestData = {
			QuestObjective = "Kill Players",
			QuestProgress = 0,
			QuestMax = math.random(5, 10),

			QuestTarget = "Exp"
		}

	},

	
	
}