--|| Services
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Global = require(ReplicatedStorage.Global)

--local DailyQuests = require(script.DailyQuests)

local TableUtility = require(ReplicatedStorage.Modules.Utility.TableLibrary)
local OutfitData = require(ReplicatedStorage.Modules.Shared.OutfitData)

local GlobalData = ReplicatedStorage.GlobalData

local VotingTimer = GlobalData.VotingTimer
local RoundTimer = GlobalData.RoundTimer

--|| Remote

local MapRemote = ReplicatedStorage.Remotes.VoteMap

local NetworkStream = require(ReplicatedStorage.Modules.Utility:WaitForChild("NetworkStream"))
local NotifyRemote = ReplicatedStorage.Remotes.Notify

local RoundSystem = {
	Players = {}
}

local RoundDuration = 400

local MapVotingPeriod = 15

local CurrentMap = ""

local MapVotes = {}
local PlayerStats = {}

local function RespawnPlayers()
	for _, Player in ipairs(Players:GetPlayers()) do
		--> improve function
		
		if Player.Character then
			Player.Character:BreakJoints()
		end
		
	end
end


local function SortMatchData()
	local GatheredPoints = {}

	for Index, PlayerData in pairs(RoundSystem.Players) do
		GatheredPoints[#GatheredPoints + 1] = PlayerData.Points
	end

	table.sort(GatheredPoints, function(a, b)
		return a > b
	end)

	local WinningList = {}

	--> check for ties later
	for Index, Amount in ipairs(GatheredPoints) do 

		for PlayerIndex, PlayerData in pairs(RoundSystem.Players) do 
			if PlayerData.Points == Amount then 
				WinningList[Index] = PlayerIndex
			end	
		end

	end
	
	print(WinningList)
	
	return WinningList, RoundSystem.Players
end

local function HasLastVote(Player, VoteData)
	for Index, MapData in pairs(VoteData) do 
		if table.find(MapData.Players, Player) then
			return Index
		end
	end
end


function RoundSystem.InitiatePlayers()
	for _, Player in ipairs(Players:GetPlayers()) do 
		if RoundSystem.Players[Player.Name] then continue end 
		
		RoundSystem.Players[Player.Name] = {
			Kills = 0,
			Deaths = 0,
			Points = 0,
		}
	end
end

function RoundSystem.IncrementData(Player, Index, Amount)
	if RoundSystem.Players[Player.Name] then
		local CachedPlayer = RoundSystem.Players[Player.Name]
		
		if not CachedPlayer[Index]  then return end 
		
		CachedPlayer[Index] = CachedPlayer[Index] + Amount
		
	end
end

function RoundSystem.ClearData()
	for _, Value in pairs(PlayerStats) do 
		RoundSystem.Players[Value] = nil
		
		--> clear points off leaderstats
	end
end

local function VoteMap(Player, ChosenMap)
	if MapVotes[ChosenMap] then
		print('valid map')
		--> chosen map is current map
		if table.find(MapVotes[ChosenMap].Players, Player) then return end 
		
		local PreviousVote = HasLastVote(Player, MapVotes)
		
		--> remove previous vote
		if PreviousVote then
			table.remove(MapVotes[PreviousVote].Players, table.find(MapVotes[PreviousVote].Players, Player))
		end
		
		MapVotes[ChosenMap].Players[#MapVotes[ChosenMap].Players + 1] = Player
		
		MapRemote:FireAllClients(MapVotes)
		--> update client
	end
end

local function SelectMap()
	local Votes = {}
	
	for MapName, MapData in pairs(MapVotes) do
		Votes[MapName] = #MapData.Players
	end
	
	local CurrentHighestMap = ""
	local CurrentHighestVote = 0
	
	local TieList = {}
	
	for MapName, VoteAmount in pairs(Votes) do 
		
		if VoteAmount > CurrentHighestVote then
			CurrentHighestVote = VoteAmount
			CurrentHighestMap = MapName
		elseif CurrentHighestVote == VoteAmount and CurrentHighestVote > 0 then
		
			if not table.find(TieList, CurrentHighestMap) then
				TieList[#TieList + 1] = CurrentHighestMap
			end
			TieList[#TieList + 1] = MapName
			
			
			CurrentHighestVote = VoteAmount
			CurrentHighestMap = CurrentHighestMap
			
		end
	end
	
	local RandomSelectedMap = #TieList > 0 and TieList[math.random(1, #TieList)] or (CurrentHighestMap == "" and "Cell Arena") or CurrentHighestMap
	
	return RandomSelectedMap
end



coroutine.wrap(function()
	while task.wait(1) do 
		if (RoundTimer.Value) <= 0 then
			
			
			
			RespawnPlayers()
			RoundSystem.ClearData()
			
			--> select map
			VotingTimer.Value = MapVotingPeriod
			
			if workspace.World.Maps:FindFirstChild(CurrentMap) then
				workspace.World.Maps[CurrentMap].Parent = ReplicatedStorage.Maps
			end
			
			
			MapVotes = {
				["Hueco Mundo"] = {
					Players = {},
				},
				["Hyperbolic Time Chamber"] = {
					Players = {},
				},
				["Cell Arena"] = {
					Players = {},
				}
			}
			
			MapRemote:FireAllClients(MapVotes)
			
	
			
			while VotingTimer.Value > 0 do
				
				
				VotingTimer.Value = VotingTimer.Value - 1
				task.wait(1)
			end
			
			local SelectedMap = SelectMap()
			
			
			
			print(SelectedMap)
			
			ReplicatedStorage.Maps[SelectedMap].Parent = workspace.World.Maps
			
			RoundTimer.Value = RoundDuration
			
			CurrentMap = SelectedMap
			
			RoundSystem.InitiatePlayers()
		else
			RoundTimer.Value = RoundTimer.Value - 1
		end
		
	
	end
end)()

MapRemote.OnServerEvent:Connect(function(Player, SelectedMap)
	if VotingTimer.Value < 0 then return end 
	
	VoteMap(Player, SelectedMap)
end)

ReplicatedStorage.Remotes.RequestMatchStats.OnServerInvoke = SortMatchData

return RoundSystem