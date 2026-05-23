return {
	
	["Buggy Pirate"] = {
		Level = 40,

		QuestTitle = "Defeat those Buggy Pirates!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 700,
			Exp = 25000,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat 5 Buggy Pirates",
				QuestProgress = 0,
				QuestMax = 5,

				QuestTarget = "Buggy Pirate"
			}
		}
	},
	
	["Strong Buggy Pirate"] = {
		Level = 60,

		QuestTitle = "Defeat the Strong Buggy Pirates!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 950,
			Exp = 45000,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat 5 Strong Buggy Pirates",
				QuestProgress = 0,
				QuestMax = 5,

				QuestTarget = "Strong Buggy Pirate"
			}
		}
	},
	
	
	["Buggy"] = {
		Level = 75,

		QuestTitle = "Defeat Buggy!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 1500,
			Exp = 95400,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat Buggy",
				QuestProgress = 0,
				QuestMax = 1,

				QuestTarget = "Buggy"
			}
		}
	},
	
}