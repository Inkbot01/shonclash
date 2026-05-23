local CodeDatabase = {}
local SpreadsheetParser = require(script["SpreadSheet Parser"])

local Sheets = SpreadsheetParser:GetSpreadSheet("1Htav6dFwZRfvHmha5DxCRmUu0hDtRtHL576n6PlCxF8")
local Twod = SpreadsheetParser:To2DArray(Sheets, "Alphabetical")

function CodeDatabase.GetCodesInRotation()
	local CodeRewards = {}

	for i,v in pairs(Twod) do 
		--	print(i,v)

		if v["A"] ~= nil then CodeRewards[v["A"]] = {} end

		if v["B"] ~= nil then CodeRewards[v["A"]]["x2Exp"] = v["B"] end 

		if v["C"] ~= nil then CodeRewards[v["A"]]["Gem"] = v["C"] end



	end

	--print(CodeRewards)

	return CodeRewards
end

coroutine.wrap(function()
	while task.wait(300) do
		Sheets = SpreadsheetParser:GetSpreadSheet("1Htav6dFwZRfvHmha5DxCRmUu0hDtRtHL576n6PlCxF8")
		Twod = SpreadsheetParser:To2DArray(Sheets, "Alphabetical")

		--print(CodeDatabase.GetCodesInRotation())
	end
end)()


return CodeDatabase