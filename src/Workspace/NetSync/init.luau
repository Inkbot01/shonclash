-- Made by Weeve. Still in experimental stage, if you have issues, DM me on Roblox, or Weeve#9132

local Module = {}
local Utility = require(game.ReplicatedStorage:WaitForChild("Utility"))

local IsServer = game:GetService("RunService"):IsServer()

local GetData = script:WaitForChild("GetData")
local DataChanged = script:WaitForChild("DataChanged")

local AllowClientDataChanges = false -- Toggle this based on the rules you want for data management. Will throw a warning on misuse

local HandleTag = "_Handle"
local DefaultTag = "_Default"

local NetSyncMetatable; NetSyncMetatable = {
	__index = function(self,Index)
		return self.InternalData[Index]
	end,
	__tostring = function(self)
		return "(NetSync)"..Utility.TableToString(self.InternalData)
	end,

	-- Implemented, but only a solution for direct iteration (for i,v in {} do):
	__iter = function(self)
		return next, self.InternalData
	end,

	--NOTE: Roblox does not support these:
	__len = function(self) 
		return #self.InternalData
	end,
	__next = function(self,Index)
		return next(self.InternalData,Index)
	end,
	__pairs = function(self)
		return next, self.InternalData, nil
	end,
	__call = function(self)
		return next, self.InternalData, nil
	end
}

local function FactoryNetSync(Data,FilterList,FilterDefault)
	-- FilterList defaults to a list where everything networks
	-- If the FilterList is set without declaring a FilterDefault, then the filter acts like a whitelist
	-- Descendant tables will inherit the filter that their parent has set for their index
	-- If you pass the optional FilterDefault as truey, you can make the filter a blacklist, though I suspect this has little use
	
	local Metatable = getmetatable(Data)
	if Metatable == nil then
		FilterList = FilterList or {[DefaultTag] = true}
		if FilterDefault then
			FilterList[DefaultTag] = FilterDefault
		end
		
		for Index,Value in Data do
			local NetworkFilter = FilterList[Index]
			if NetworkFilter == nil then
				NetworkFilter = FilterList[DefaultTag]
			end

			if type(Index) == "table" then
				Index = FactoryNetSync(Index,{[DefaultTag] = NetworkFilter})
			end
			if type(Value) == "table" then
				Value = FactoryNetSync(Value,{[DefaultTag] = NetworkFilter})
			end

			Data[Index] = Value
		end

		return setmetatable({
			InternalData = Data or {},
			FilterList = FilterList,
			Changed = Utility.NewEvent("NetSync ChangedEvent"),
		},NetSyncMetatable)
	elseif Metatable == NetSyncMetatable then
		return Data
	else
		warn("Cannot set a Metatable to be NetSync")
	end
end

function Module.GetRaw(Table,SubSet)
	local NewTable = {}

	for Index,Value in Table do
		if SubSet == nil or SubSet[Index] then
			if type(Value) == "table" then
				Value = Module.GetRaw(Value)
			end
			
			if type(Index) == "table" then
				Index = Module.GetRaw(Index)
			end
			
			NewTable[Index] = Value
		end
	end

	return NewTable
end

print("NetSync Started. IsServer:",IsServer)
if IsServer then	
	local function MakeNetworkable(Table)
		local NewTable = {
			[HandleTag] = tostring(Table.InternalData),
		}
		--print("Handle on server?",NewTable[HandleTag])

		for Index,Value in Table do
			if type(Index) == "table" then
				Index = MakeNetworkable(Index)
			elseif type(Index) == "number" then
				Index = tostring(Index)
			end
			if type(Value) == "table" then
				Value = MakeNetworkable(Value)
			end

			NewTable[Index] = Value
		end

		return NewTable
	end
	
	NetSyncMetatable.__newindex = function(self,Index,Value)
		if self[Index] ~= Value then
			local NetworkFilter = self.FilterList[Index]
			if NetworkFilter == nil then
				NetworkFilter = self.FilterList[DefaultTag]
			end
			
			local NetIndex,NetValue = Index,Value
			if type(Index) == "table" then
				Index = FactoryNetSync(Index,{[DefaultTag] = NetworkFilter})
				NetIndex = MakeNetworkable(Index)
			end
			if type(Value) == "table" then
				Value = FactoryNetSync(Value,{[DefaultTag] = NetworkFilter})
				NetValue = MakeNetworkable(Value)
			end
			
			local NetworkFilter = self.FilterList[Index] or self.FilterList[DefaultTag]
			if NetworkFilter == true then
				DataChanged:FireAllClients(tostring(self.InternalData),NetIndex,NetValue)
			elseif NetworkFilter then -- If NetworkFilter is truey, but not true, it assumes that it is set to a Player, and networks to just that Player
				DataChanged:FireClient(NetworkFilter,tostring(self.InternalData),NetIndex,NetValue)
			end

			self.Changed:Fire(
				Index, -- Index
				Value, -- NewValue
				self.InternalData[Index] -- OldValue
			)
			self.InternalData[Index] = Value
		end
	end
	
	-- NetSyncTables is local (to avoid interference), but is used to keep track of all current NetSync tables
	local NetSyncTables = FactoryNetSync({})
	GetData.OnServerInvoke = function()
		--print("SendingData:",NetSyncTables,MakeNetworkable(NetSyncTables))
		return MakeNetworkable(NetSyncTables)
	end
	
	function Module.Add(Index,Data, FilterList,FilterDefault)
		NetSyncTables[Index] = FactoryNetSync(Data or {},FilterList,FilterDefault)
		return NetSyncTables[Index]
	end
	
	Module.new = FactoryNetSync
	
else
	local Handles = {} -- TableID = ClientTable --TODO technically a data leak. Need to remove handles when de-referenced
	local DoubleSetWarnings = false
	
	local function RecieveNetworkable(Table)
		local TableHandle = Table[HandleTag]
		--print("Recieved Handle:",TableHandle)
		if TableHandle == nil then warn("Table is missing Network Handle",Table,debug.traceback()) end

		local LinkedTable = Handles[TableHandle]
		if LinkedTable == nil then
			local NewTable = {}
			for Index,Value in Table do
				if Index ~= HandleTag then
					if type(Index) == "table" then
						Index = RecieveNetworkable(Index)
					end
					if type(Value) == "table" then
						Value = RecieveNetworkable(Value)
					end
					
					NewTable[tonumber(Index) or Index] = Value
				end
			end

			NewTable = FactoryNetSync(NewTable)
			Handles[TableHandle] = NewTable
			return NewTable
		else
			if DoubleSetWarnings then
				warn("Table sent twice, or is cyclic:",LinkedTable,Table)
			end
			
			return LinkedTable
		end
	end
	
	NetSyncMetatable.__newindex = function(self,Index,Value)
		if self[Index] ~= Value then
			if AllowClientDataChanges then
				if type(Index) == "table" then
					Index = FactoryNetSync(Index)
				end
				if type(Value) == "table" then
					Value = FactoryNetSync(Value)
				end

				self.Changed:Fire(
					Index, -- Index
					Value, -- NewValue
					self.InternalData[Index] -- OldValue
				)
				self.InternalData[Index] = Value
			else
				warn("Attempt to modify NetSync table on the client:",debug.traceback())
			end
		end
	end
	
	local NetSyncTables = RecieveNetworkable(GetData:InvokeServer())
	DataChanged.OnClientEvent:Connect(function(ParentHandle,Index,Value)
		if type(Index) == "table" then
			Index = RecieveNetworkable(Index)
		end
		if type(Value) == "table" then
			Value = RecieveNetworkable(Value)
		end
		--print(Handles,ParentHandle)
		
		local ParentTable = Handles[ParentHandle]
		ParentTable.Changed:Fire(
			Index, -- Index
			Value, -- NewValue
			ParentTable.InternalData[Index] -- OldValue
		)
		ParentTable.InternalData[Index] = Value
	end); task.defer(function() DoubleSetWarnings = true end)
	
	function Module.WaitFor(Index)
		while NetSyncTables[Index] == nil do task.wait() end

		return NetSyncTables[Index]
	end
end

return Module