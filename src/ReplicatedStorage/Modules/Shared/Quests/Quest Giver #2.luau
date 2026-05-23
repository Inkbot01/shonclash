return {
	
	["Monkey"] = {
		Level = 17,

		QuestTitle = "Defeat those Monkeys!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 250,
			Exp = 4500,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat 6 Monkeys",
				QuestProgress = 0,
				QuestMax = 6,

				QuestTarget = "Monkey"
			}
		}
	},
	
	["Gorilla King"] = {
		Level = 25,

		QuestTitle = "Defeat the Gorilla King!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 650,
			Exp = 8500,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat the Gorilla King ",
				QuestProgress = 0,
				QuestMax = 1,

				QuestTarget = "Gorilla King"
			}
		}
	},
	
}