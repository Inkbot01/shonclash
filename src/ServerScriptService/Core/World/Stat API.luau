--|| Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Directory = require(ReplicatedStorage.Directory)

local StatAPI = {}

local Settings = Directory.Import("Settings", "Shared")
local FormulaLibrary = Directory.Import("FormulaAPI", "Shared")

local RegisteredItems = Directory.Import("RegisteredItems", "Shared")

local StatTimeout = 5

local NotifyRemote = ReplicatedStorage.Remotes.Notify


function StatAPI.GetMasteryBonus(Player, Amount)
	return ((Player.Data.Boosts.x2Exp.Value > 0 and Amount * 2 or Amount) * Settings.GLOBAL_XP_MULTIPLIER)
end



function StatAPI.GiveMastery(Player, Category, Amount)
	local IndexedToolData = Player.Data.Mastery:FindFirstChild(Category)

	if not IndexedToolData then return end 


	IndexedToolData.MasteryExperience.Value = IndexedToolData.MasteryExperience.Value + StatAPI.GetMasteryBonus(Player, Amount)

	local TimeoutBeginStamp = os.clock()

	local MasteryCap = RegisteredItems[Category] and RegisteredItems[Category].MasteryCap or 100


	while IndexedToolData.MasteryExperience.Value >= FormulaLibrary.CalculateMaxMastery(IndexedToolData.MasteryLevel.Value) or os.clock() - TimeoutBeginStamp >= StatTimeout do 
		IndexedToolData.MasteryExperience.Value = IndexedToolData.MasteryExperience.Value - FormulaLibrary.CalculateMaxMastery(IndexedToolData.MasteryLevel.Value) 
		IndexedToolData.MasteryLevel.Value = math.clamp(IndexedToolData.MasteryLevel.Value + 1, 0, MasteryCap)



	end
end


return StatAPI