local FormulaAPI = {}

local HakiLevels = {
	[1] = {HitsNeeded = 300, DamageBoost = 5},--%} -- hits  300
	[2] = {HitsNeeded = 1200, DamageBoost = 10}, --450
	[3] = {HitsNeeded = 3000, DamageBoost = 15}, -- hits 765
	[4] = {HitsNeeded = 5500, DamageBoost = 15}, -- hits 1000
	[5] = {HitsNeeded = 8500, DamageBoost = 20}, -- hits 1550
	[6] = {HitsNeeded = 15000, DamageBoost = 25}, --2000
}

local MasteryScaling = 20 --every X points is 2 mastery

function FormulaAPI.CalculateMaxExperience(Level)
	return 42 + math.ceil(1.9 * Level ^ 2.5 + 36)
end

function FormulaAPI.CalculateMaxHealth(Defense)
	return 100 + Defense * 5
end

function FormulaAPI.CalculateMaxStamina(Stamina)
	return 100 + Stamina * 5
end


function FormulaAPI.CalculateMaxMastery(MasteryLevel)
	return 48 + math.ceil((1.2 * MasteryLevel ^ 1.5 + 24) * 0.45);
end


function FormulaAPI.CalculateMaxHakiHits(HakiLevel)
	return HakiLevels[HakiLevel].HitsNeeded or nil
end

function FormulaAPI.CalculateHakiBuff(HakiLevel)
	return HakiLevels[HakiLevel].DamageBoost or 25
end
function FormulaAPI.ConvertMasterytoStat(Player, MasteryAmount)
	return (MasteryAmount / 4) + (Player.Data.Level.Value * (MasteryAmount / 600) * .1)
end

function FormulaAPI.CalculateDamage(Player, BaseDamage, MasteryAmount)
--	MasteryAmount =  MasteryAmount and FormulaAPI.ConvertMasterytoStat(Player, MasteryAmount) or 0
	
	--math.ceil(BaseDamage + (MasteryAmount * .5))
	
	return math.ceil(BaseDamage)
end

return FormulaAPI