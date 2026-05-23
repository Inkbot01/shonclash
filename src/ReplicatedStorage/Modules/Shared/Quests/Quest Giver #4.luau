return {
	
	["Snow Pirate"] = {
		Level = 90,

		QuestTitle = "Defeat those Snow Pirates!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 1250,
			Exp = 140000,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat 5 Snow Pirates",
				QuestProgress = 0,
				QuestMax = 5,

				QuestTarget = "Snow Pirate"
			}
		}
	},

	
	["Yeti"] = {
		Level = 120,

		QuestTitle = "Defeat the Yeti!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 1500,
			Exp = 320050,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat that Yeti",
				QuestProgress = 0,
				QuestMax = 1,

				QuestTarget = "Yeti"
			}
		}
	},
	
}