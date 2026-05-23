return {
	
	["Bandits"] = {
		Level = 1,

		QuestTitle = "Defeat those Bandits!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 150,
			Exp = 300,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat 5 Bandits",
				QuestProgress = 0,
				QuestMax = 5,

				QuestTarget = "Bandit"
			}
		}
	},
	
	--[[
	["Bandit Boss"] = {
		Level = 10,

		QuestTitle = "Defeat the bandit boss!",
		QuestTimer = 500,

		-- Add Rewards Later
		Rewards = {
			Beli = 300,
			Exp = 150,
		},

		Objectives = {
			--[1] = {
			--	QuestObjective = "Defeat 5 Bandits",
			--	QuestProgress = 0,
			--	QuestMax = 5,

			--	QuestTarget = "Bandit",
			--},
			[1] = {
				QuestObjective = "Defeat the bandit boss ",
				QuestProgress = 0,
				QuestMax = 1,

				QuestTarget = "Bandit Boss"
			}
		}
	},
	--]]
}