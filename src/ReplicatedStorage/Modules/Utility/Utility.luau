
local Utility = {}


function Utility.DictionarySelectRandom(dictionary)
	local keys = {}

	for key, _ in pairs(dictionary) do
		table.insert(keys, key)
	end

	if #keys == 1 then
		local onlyKey = keys[1]
		return dictionary[onlyKey]
	end

	local position = Random.new():NextInteger(1, #keys)
	local key = keys[position]

	return dictionary[key], key
end

function Utility:deepSearchFolder(Folder,Type,InfoTable)
	local NewTable = InfoTable or {}
	Type = Type or "ModuleScript"

	local Children = Folder:GetChildren()

	for i,Object in ipairs(Children) do
		if Object:IsA(Type) then
			NewTable[#NewTable + 1] = Object
		elseif Object:IsA("Folder") or Object:IsA("ModuleScript") then
			self:deepSearchFolder(Object,Type,NewTable)
		end
	end

	return NewTable
end

--| Requires all the modules under
function Utility:requireModules(Table, Parent)

	for _, Child in ipairs(Parent:GetChildren()) do
		if Child:IsA("ModuleScript") then
			coroutine.wrap(function()
				Table[Child.Name] = require(Child)
			end)()

		elseif Child:IsA("Folder") then
			Utility:requireModules(Table, Child)
		end
	end


	return Table
end


function Utility:YieldWithCallback(Yield, Callback)
	Yield = Yield or 3

	local StartTime = os.clock()

	while os.clock() - StartTime <= Yield do
		task.wait()
	end

	Callback()
end

return Utility