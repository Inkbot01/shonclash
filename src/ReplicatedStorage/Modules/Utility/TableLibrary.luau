local TableLibrary = {}

function TableLibrary.GetDeepCopy(Table)
	local Copy = {}

	for Index, Value in pairs(Table) do
		local IndexType, ValueType = type(Index), type(Value)

		if IndexType == "table" and ValueType == "table" then
			Index, Value = TableLibrary.GetDeepCopy(Index), TableLibrary.GetDeepCopy(Value)
		elseif ValueType == "table" then
			Value = TableLibrary.GetDeepCopy(Value)
		elseif IndexType == "table" then
			Index = TableLibrary.GetDeepCopy(Index)
		end

		Copy[Index] = Value
	end

	return Copy
end 


return TableLibrary
