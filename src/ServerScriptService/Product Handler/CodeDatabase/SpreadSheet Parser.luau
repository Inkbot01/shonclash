local CodeDatabase = {}
local HttpsService = game:GetService("HttpService")

function CodeDatabase:GetSpreadSheet(Key)
	local GetData = HttpsService:GetAsync("https://docs.google.com/spreadsheet/tq?key="..Key)
	local StartLocation = string.find(GetData, "setResponse") + 12
	local EndLocation = string.len(GetData) - 2
	local JSONData = string.sub(GetData, StartLocation, EndLocation)

	return HttpsService:JSONDecode(JSONData)
end

function CodeDatabase:To2DArray(SpreadSheet, ColumnScheme)
	local Table = {}

	for i = 1, #SpreadSheet.table.rows do 
		local RowTable = {}
		local Columns = SpreadSheet.table.rows[i].c
		for j = 1, #Columns do 
			local Index = j

			if ColumnScheme == "Alphabetical" then 
				Index = SpreadSheet.table.cols[j].id 
			elseif ColumnScheme == "Labels" then
				Index = SpreadSheet.table.cols[j].label
			end

			if Columns[j] then
				RowTable[Index] = Columns[j].v
			end

		end
		Table[i] = RowTable
	end

	return Table
end

return CodeDatabase