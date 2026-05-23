--|| Services ||--
local Players = game:GetService("Players")

--|| Modules ||--
local StarterData = require(script.Parent.Data.ProfileData)

local DataTypeConversion = {
	["string"] = "StringValue",
	["number"] = "NumberValue",
	["boolean"] = "BoolValue"
}

local function LoadInstancesFromTable(Parent, Table)
	for Index, Value in next, Table do
		if typeof(Value) == "table" then
			local Folder = Instance.new("Folder")
			Folder.Name = Index
			Folder.Parent = Parent
			LoadInstancesFromTable(Folder, Value)
		else
			local NewValue = Instance.new(DataTypeConversion[typeof(Value)])
			NewValue.Value = Value
			NewValue.Name = Index
			NewValue.Parent = Parent
		end
	end
end

function LoadValuesToInstanceFromTable(Directory, Table)
	for Index, Value in next, Table do
		local SubDirectory = Directory:FindFirstChild(Index)
		if SubDirectory then
			if typeof(Value) == "table" then
				LoadValuesToInstanceFromTable(SubDirectory, Value)
			else
				SubDirectory.Value = Value					
			end
		else
			if typeof(Value) == "table" then
				local NewDir = Instance.new("Folder")
				NewDir.Name = Index
				NewDir.Parent = Directory
				LoadValuesToInstanceFromTable(NewDir, Value)
			else
				local NewValue = Instance.new(DataTypeConversion[typeof(Value)])
				NewValue.Value = Value
				NewValue.Name = Index
				NewValue.Parent = Directory
			end
		end
	end
end

function DestroyNullValuesFromTable(Directory, Table)
	for _, Value in ipairs(Directory:GetChildren()) do
		local index = (tonumber(Value.Name) or Value.Name)
		if Value:IsA("Folder") and Table[index] then
			DestroyNullValuesFromTable(Value,Table[index])	
		elseif Value:IsA("Folder") and Table[index] == nil then
			Value:Destroy()
		elseif Table[index] == nil then
			Value:Destroy()
		end
	end
end

return function(UserId, Cache)
	if not Cache then return end
	for Index, Value in next, Cache do
		--> Replicating Data
		local Player = typeof(UserId) == "number" and Players:GetPlayerByUserId(UserId)
		if Player then

			if StarterData[Index] then
				local Directory = Player:FindFirstChild(Index)
				if Directory then				
					LoadValuesToInstanceFromTable(Directory, Value)
					DestroyNullValuesFromTable(Directory, Value)
				else
					local NewDirectory = Instance.new("Folder")
					NewDirectory.Name = Index
					NewDirectory.Parent = Player
					LoadInstancesFromTable(NewDirectory, Value)
				end
			end				

		end
	end
end