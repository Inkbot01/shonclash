-- Made by Weeve. Still in experimental stage, if you have issues, DM me on Roblox, or Weeve#9132

local Module = {}
local Utility = require(game.ReplicatedStorage:WaitForChild("Utility"))
local NetSync = require(game.ReplicatedStorage:WaitForChild("NetSync"))
local RunService = game:GetService("RunService")

Module.PlayerData = {}
function Module.GetData(Player) -- Accepts a Name or a Player
	if type(Player) == "userdata" and Player:IsA("Player") then
		while Module.PlayerData[Player] == nil do wait() end
		return Module.PlayerData[Player]
	else
		warn("Requested PlayerData of something that is not a Player:",Player)
	end
end


if RunService:IsServer() then
	Module.PlayerData = NetSync.Add("PlayerData")
	
	local PlayerDataStore = require(script:WaitForChild("DataStore")).new("PlayerData")
	Module.Tainted = {} -- Player = true -- This is true if a player's data couldn't load. Don't save, and don't sell this player anything
	
	local Initialized = false
	function Module.Initialize(InitializationData) --[[
	
		Takes a table of this format:
		PlayerData.Initialize({
			Index = {
				Default = DefaultValue || FunctionThatReturnsDefaultValue,
				Networked = "Public" || "Private" || nil,
				Saved = true || false,
			}
		})
		
		--]]
		if not Initialized then
			Initialized = true
			
			-- Create SavedData from InitializationData
			local SavedData = {}
			for Index,Settings in InitializationData do
				SavedData[Index] = Settings.Saved
			end
			
			local function PlayerAdded(Player)
				if not RunService:IsStudio() then wait(5) end -- Delay for the ~4s DataStore cache delay (Prevents data exploitation via rapid server-changes)
				
				-- Setup the Default Data, as well as the networking Filter
				local Data,Filter = {},{}
				for Index,Settings in InitializationData do
					local DefaultValue = Settings.Default
					if type(DefaultValue) == "function" then
						Data[Index] = DefaultValue()
					elseif type(DefaultValue) == "table" then
						Data[Index] = Utility.TableCopy(DefaultValue)
					elseif DefaultValue ~= nil then
						Data[Index] = DefaultValue
					end
					
					local NetworkedValue = Settings.Networked
					if NetworkedValue == "Public" then
						Filter[Index] = true
					elseif NetworkedValue == "Private" then
						Filter[Index] = Player
					end
				end
				
				-- Load the Data from DS
				local Success,DSLoad = PlayerDataStore:Get(Player.UserId)
				if DSLoad ~= nil then
					for Index,Value in DSLoad do
						Data[Index] = Value
					end
				elseif not Success then
					Module.Tainted[Player] = true
					warn("Could not load PlayerData for:",Player)
				end
				
				-- Assign Data to the Module
				Module.PlayerData[Player] = NetSync.new(Data,Filter)
			end
			
			game.Players.PlayerRemoving:Connect(function(Player)
				Module.SaveData(Player)
				Module.PlayerData[Player] = nil
			end)
		
			game.Players.PlayerAdded:Connect(PlayerAdded)
			for _,Player in game.Players:GetPlayers() do
				task.defer(PlayerAdded,Player)
			end
			
			if not RunService:IsStudio() then
				game:BindToClose(function()
					for Player,DataOfPlayer in Module.PlayerData do
						Module.SaveData(Player)
					end
				end)
			end
			
			function Module.SaveData(Player)
				local DataOfPlayer = Module.PlayerData[Player]
				if DataOfPlayer and not Module.Tainted[Player] then
					local Success = PlayerDataStore:Set(Player.UserId, NetSync.GetRaw(DataOfPlayer,SavedData))
					return Success
				end
				return false
			end
		else
			warn("Attempted to Initialize PlayerData twice. Attempt refused as PlayerData is a singleton")
		end
	end

elseif RunService:IsClient() then
	Module.PlayerData = NetSync.WaitFor("PlayerData")
end

return Module