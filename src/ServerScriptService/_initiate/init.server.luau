local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")


local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetData = ReplicatedStorage.Remotes.GetData

local ProfileData = require(script.Modules.Data.ProfileData)
local ProfileService = require(script.Modules.ProfileService)

local ProfileKey = "SHONENCLASH_0006"
local ProfileStorage = ProfileService.GetProfileStore(
	ProfileKey,

	ProfileData
)

local Replicate = require(script.Modules.Replicate)

local Profiles = {}

local DataRetrievalTimeout = 10

_G.GetData = function(Player)
	local StartTimeStamp = os.clock()
	
	repeat task.wait() until os.clock() - StartTimeStamp >= DataRetrievalTimeout or Profiles[Player].Data
	

	return Profiles[Player].Data
end


local DataTypeConversion = {
	["string"] = "StringValue",
	["number"] = "NumberValue",
	["boolean"] = "BoolValue"
}


local function LoadValuesToInstanceFromTable(Directory, Table)
	for Index, Value in next, Table do
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

local function LoadTableFromInstanceValues(Folder, Table)
	for _,Instances in ipairs(Folder:GetChildren()) do
		if Instances:IsA("Folder") then
			Table[Instances.Name] = {}
			
			LoadTableFromInstanceValues(Instances, Table[Instances.Name])
			
			--module:To_Table(Instances,Add_In_Table[Instances.Name])
		else
			
			Table[Instances.Name] = Instances.Value
		end
	end
end



--[[
local function LoadInstancesFromTable(Parent, Table, Player)
	for Index, Value in pairs(Table) do 
		if typeof(Value) == "table" then
			local Folder = Instance.new("Folder")
			Folder.Name = Index
			Folder.Parent = Parent
			
			
			Folder.ChildAdded:Connect(function(Child)
			
			end)
			LoadInstancesFromTable(Folder, Value, Player)
			
		
			
		end
	end
end
--]]
--[[

local function LoadInstancesFromTable(Parent, Table, Player)
	for Index, Value in next, Table do
		if typeof(Value) == "table" then
			local Folder = Instance.new("Folder")
			Folder.Name = Index
			Folder.Parent = Parent
			LoadInstancesFromTable(Folder, Value, Player)
			
			
			Folder.ChildAdded:Connect(function(Child)
			
				if _G.GetData(Player) and Child:IsA("Folder")  then 
				
					
					
					if Parent.Name == Player.Name then
						_G.GetData(Player)[Index][Child.Name] = {}
					else
						_G.GetData(Player)[Parent.Name][Index][Child.Name] = {}
					end
					
					--_G.GetData(Player)[Parent.Name][#Index + 1] = {}
				
					for SubIndex, SubValue in ipairs(Child:GetChildren()) do 
				
						
						if Parent.Name == Player.Name then
							_G.GetData(Player)[Index][Child.Name][SubValue.Name] = SubValue.Value
							
						else
							_G.GetData(Player)[Parent.Name][Index][Child.Name][SubValue.Name] = SubValue.Value
						end
						
						
						SubValue.Changed:Connect(function(CurrentValue)
							if _G.GetData(Player)  then 
								

								if Parent.Name == Player.Name then
									_G.GetData(Player)[Index][Child.Name][SubValue.Name] = SubValue.Value

								else
									_G.GetData(Player)[Parent.Name][Index][Child.Name][SubValue.Name] = SubValue.Value
								end

							end
						end)
						
					end
				elseif _G.GetData(Player) and Child:IsA("NumberValue") or Child:IsA("StringValue") then 
					if Parent.Name == Player.Name then
						_G.GetData(Player)[Index][Child.Name] = Child.Value
					else
						_G.GetData(Player)[Parent.Name][Index][Child.Name] = Child.Value
					end

				end
			end)
			
			Folder.ChildRemoved:Connect(function(Child)
				
				if Folder.Name == "Inventory" then 
					_G.GetData(Player)[Folder.Name][Child.Name] = nil
					
					return
				end
				
				if _G.GetData(Player) and _G.GetData(Player)[Parent.Name] then 
					table.clear(_G.GetData(Player)[Parent.Name][Index])
				else
					table.clear(_G.GetData(Player)[Parent.Parent.Name][Parent.Name])
				end
			end)
		
		else
			local NewValue = Instance.new(DataTypeConversion[typeof(Value)])
			NewValue.Value = Value
			NewValue.Name = Index
			NewValue.Parent = Parent
	
			
			NewValue.Changed:Connect(function(CurrentValue)
			
				
				if _G.GetData(Player)  then 
					if  _G.GetData(Player)[Index] then
						_G.GetData(Player)[Index] = CurrentValue
						
					--elseif Parent.Parent.Name == "Mastery" then 
					--	print("start"..Index)
					
						--_G.GetData(Player)[Parent.Parent.Name][Parent.Name][Index] = Value
					elseif string.find(Index, "Quest") then
					--	print(Parent.Parent.Name, Parent.Name, Index)
						--print(_G.GetData(Player)[Parent.Name][Index])
						--print(_G.GetData(Player)[Parent.Parent.Name][Parent.Name][Index])
					
						
						if Parent.Parent == Player then
							_G.GetData(Player)[Parent.Name][Index] = CurrentValue
						else
							
							_G.GetData(Player)[Parent.Parent.Parent.Name][Parent.Parent.Name][Parent.Name][Index] = CurrentValue
						end
						
						
					elseif _G.GetData(Player)[Parent.Name] then
						_G.GetData(Player)[Parent.Name][Index] = CurrentValue
					elseif _G.GetData(Player)[Parent.Parent.Name][Parent.Name] then 
						_G.GetData(Player)[Parent.Parent.Name][Parent.Name][Index] = CurrentValue
					elseif _G.GetData(Player)[Parent.Parent.Parent.Name][Parent.Parent.Name][Parent.Name] then
						_G.GetData(Player)[Parent.Parent.Parent.Name][Parent.Parent.Name][Parent.Name][Index] = CurrentValue
					end
					
				end
			end)
			
		end
	end
end

--]]

game:BindToClose(function()
	for _,Player in ipairs(PlayerService:GetPlayers()) do

		LoadTableFromInstanceValues(Player.Data,_G.GetData(Player) )
		warn("saved data in shutdown")
	end
end)

PlayerService.PlayerAdded:Connect(function(Player)
	local profile = ProfileStorage:LoadProfileAsync("Player_" .. Player.UserId)
	if profile ~= nil then
		profile:AddUserId(Player.UserId)
		profile:Reconcile()
		
		profile:ListenToRelease(function()
			Profiles[Player] = nil
			Player:Kick('failed to fetch data')
		end)
		if Player:IsDescendantOf(PlayerService) then
			Profiles[Player] = profile
			
			local DataFolder = Instance.new("Folder")
			DataFolder.Name = "Data"
			DataFolder.Parent = Player
			
			--> CHANGE LATER TO CURRENT SLOT
		
			--Do Something With A Loaded Profile
			LoadValuesToInstanceFromTable(DataFolder, Profiles[Player].Data)
		else
			profile:Release()
		end
	else
		Player:Kick('failed to fetch data') 
	end
end)

PlayerService.PlayerRemoving:Connect(function(Player)
	if Profiles[Player] ~= nil then
		
		LoadTableFromInstanceValues(Player.Data,_G.GetData(Player))
		
		Profiles[Player]:Release()
	end
end)




local StoredPlayersCache = {}

local function GetPlayerData(Player, RequestedPlayerId)
	if Profiles[PlayerService:GetPlayerByUserId(RequestedPlayerId)] then 
		return Profiles[PlayerService:GetPlayerByUserId(RequestedPlayerId)].Data
	end

	
	if StoredPlayersCache[RequestedPlayerId] then
		return StoredPlayersCache[RequestedPlayerId].Data
	else
		local ViewPlayerData = ProfileStorage:ViewProfileAsync("Player_"..RequestedPlayerId)
		
		StoredPlayersCache[RequestedPlayerId] = {
			Data = ViewPlayerData.Data,
			RefreshTimeStamp = os.clock()
		}
		
		return ViewPlayerData.Data
	end

	
end


GetData.OnServerInvoke = GetPlayerData

local function DictionaryCounter(Dictionary)
	local Counter = 0

	for _, _ in pairs(Dictionary) do
		Counter = Counter + 1
	end

	return Counter
end


coroutine.wrap(function()
	while task.wait(40) do 
		
		for Id, Metadata in pairs(StoredPlayersCache) do 
			if os.clock() - Metadata.RefreshTimeStamp >= 40 then
				StoredPlayersCache[Id] = nil
			end
		end
		
		for _, Player in ipairs(PlayerService:GetPlayers()) do 
			if Player:FindFirstChild("Data") then
				LoadTableFromInstanceValues(Player.Data, Profiles[Player].Data)
			end
			
		end
	end
end)()


--[[
coroutine.resume(coroutine.create(function()
	while true do
		task.wait(.2)
		for _, Player in ipairs(PlayerService:GetPlayers()) do
			Replicate(Player.UserId,_G.GetData(Player))
		end
	end
end))
--]]
--[[
ReplicatedStorage.GetData.OnServerInvoke = function(Player)
	return _G.GetData(Player)
end

ReplicatedStorage.GetData.OnServerInvoke = function(Player, Signal, Data)
	local Data = _G.GetData(Player)
	
	if Signal == "Get" then
		return Data
	elseif Signal == "Set" then
		Data[Data.Variable] = Data.Value
		return 1

	end
end--]]