--|| Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Global = require(ReplicatedStorage.Global)

local DailyQuests = require(script.DailyQuests)

local TableUtility = require(ReplicatedStorage.Modules.Utility.TableLibrary)

local QuestLocations = workspace.World.Quests
--|| Remote

local EffectRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect")

local Animation = ReplicatedStorage.Remotes.Animation

local NetworkStream = require(ReplicatedStorage.Modules.Utility:WaitForChild("NetworkStream"))
local NotifyRemote = ReplicatedStorage.Remotes.Notify

local QuestAPI = {}

local QuestCache = {}

local CollectableRespawnTime = 10
local MAX_DAILY_QUESTS = 3

for _, QuestGiver in ipairs(ReplicatedStorage.Modules.Shared.Quests:GetChildren()) do
	if QuestGiver:IsA("ModuleScript") then
		QuestCache[QuestGiver.Name] = require(QuestGiver)
	end
end

local DataTypeConversion = {
	["string"] = "StringValue",
	["number"] = "NumberValue",
	["boolean"] = "BoolValue",
	["DateTime"] = "NumberValue"
}



local function SpawnCollectable(Folder, Location)
	local StartPosition = Location.Position
	local RandomX, RandomZ = math.random(-Location.Size.X/2, Location.Size.X/2), math.random(-Location.Size.Z/2, Location.Size.Z/2) 
	local RandomPoint = StartPosition + Vector3.new(RandomX,0,RandomZ)

	local CollectableFormat = ReplicatedStorage.Assets.Models[Folder.Name.."Format"]:Clone()
	CollectableFormat.CFrame = CFrame.new(RandomPoint) * CFrame.new(0, CollectableFormat.Size.Y, 0)
	CollectableFormat.Parent = Location
	
	CollectableFormat.ProximityPrompt.PromptButtonHoldBegan:Connect(function(Player)
		Animation:FireClient(Player,"TrashPick","Play",{Looped = true})
	end)
	
	CollectableFormat.ProximityPrompt.PromptButtonHoldEnded:Connect(function(Player)
		Animation:FireClient(Player,"TrashPick","Stop")
	end)
	
	CollectableFormat.ProximityPrompt.Triggered:Connect(function(Player)
		QuestAPI.AddItem(Player, Folder.Name)
		Animation:FireClient(Player,"TrashPick","Stop")
		
		local Collect = ReplicatedStorage.Assets.Sounds.Collect:Clone()
		Collect.Parent = Player.Character.HumanoidRootPart
		Collect:Play() 
		game.Debris:AddItem(Collect, 1)
		
		CollectableFormat:Destroy()
	end)
end


function QuestAPI.NotifyForNextIsland(Player)
	for _, QuestData in pairs(QuestCache) do 
		for QuestGiver, Metadata in pairs(QuestData) do

			if Metadata.Level == Player.Data.Level.Value then
				NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Purple><AnimateStepFrequency=.3> You have unlocked the next quest!", Duration = 9})
			end
		end
	end 
end


function QuestAPI.GiveQuest(Player, QuestGiver, SelectedQuest)
	if not QuestCache[QuestGiver] then return print("Quest Giver was not found for "..QuestGiver) end
	
	if not QuestCache[QuestGiver][SelectedQuest] then return print("Selected Quest"..SelectedQuest.."  not found for "..QuestGiver) end
	
	local QuestData = Player.Data["QuestData"]
	
	--> Has a quest already
	if QuestData.QuestTitle.Value ~= "" then QuestAPI.RemoveQuest(Player) task.wait(.1) end --NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Red><AnimateStyle=Rainbow><AnimateStepFrequency=.3> You have an active quest!", Duration = 2}) return print("You already have a quest")  end
	
	
	local QuestGiverData = QuestCache[QuestGiver][SelectedQuest]
	
	if Player.Data.Level.Value < QuestGiverData.Level then NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Red><AnimateStyle=Rainbow><AnimateStepFrequency=.3> You are below level requirement!", Duration = 2}) return end
	
	QuestData.QuestTitle.Value = QuestGiverData.QuestTitle
	QuestData.QuestTimer.Value = QuestGiverData.QuestTimer
	
	for Index, QuestObjectiveData in pairs(QuestGiverData.Objectives) do 
		local Folder = Instance.new("Folder")
		Folder.Name = Index
		
		Global.LoadInstancesFromTable(Folder, QuestObjectiveData)
		
		Folder.Parent = QuestData.Objectives
	end
	
	NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Green><AnimateStepFrequency=.3> Quest has been accepted!", Duration = 2})
end

function QuestAPI.RemoveQuest(Player)
	local QuestData = Player.Data["QuestData"]
	
	if QuestData.QuestTitle.Value == "" then return end
	
	QuestData.QuestTitle.Value = ""
	QuestData.QuestTimer.Value = 0
	
	QuestData.Objectives:ClearAllChildren()
end



function QuestAPI.GiveDailyQuests(Player)
	if not Player:FindFirstChild("Data") then return end 
	
	local DailyQuestData = Player.Data["DailyQuests"]
	
	if os.time() - DailyQuestData.InitialTime.Value <= 86400 then return end 
	print("top")

	--> Has a quest already
	
	if #DailyQuestData.Quests:GetChildren() >= MAX_DAILY_QUESTS then return end 
	print("here")
	--if QuestData.QuestTitle.Value ~= "" then QuestAPI.RemoveQuest(Player) task.wait(.1) end --NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Red><AnimateStyle=Rainbow><AnimateStepFrequency=.3> You have an active quest!", Duration = 2}) return print("You already have a quest")  end


	--if Player.Data.Level.Value < QuestGiverData.Level then NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Red><AnimateStyle=Rainbow><AnimateStepFrequency=.3> You are below level requirement!", Duration = 2}) return end
	
	local NewDailyQuestData = TableUtility.GetDeepCopy(DailyQuests)
	
	for Index, QuestTypeData in pairs(NewDailyQuestData) do 
		print(Index, QuestTypeData)
		for SubIndex, SubObjective in pairs(QuestTypeData) do 
			
		
			--> Randomize Rewards
			if SubIndex == "Rewards" then print('changed gem') SubObjective.Gem = math.random(500, 1000) end
			
			if SubIndex == "QuestData" then
				for InnerIndex, InnerValue in pairs(SubObjective) do
					if InnerIndex == "QuestMax" then 
					
						if Index == "Kill" then InnerValue = math.random(5, 10)  end
						if Index == "Progress" then InnerValue = math.random(10, 15)   end 
					end
				end
				
			end
			
		end
	end
	
	for Index, QuestObjectiveData in pairs(NewDailyQuestData) do 
		
		local Folder = Instance.new("Folder")
		Folder.Name = Index
		
		Global.LoadInstancesFromTable(Folder, QuestObjectiveData)

		Folder.Parent = DailyQuestData.Quests
	end
	
	DailyQuestData.InitialTime.Value = os.time() 
end

function QuestAPI.AddItem(Player, Target)
	local DailyQuestData = Player.Data["DailyQuests"]
	
	if #DailyQuestData.Quests:GetChildren() == 0 then return end 
	
	for FolderIndex, DailyQuestObjectiveData in pairs(DailyQuestData.Quests:GetChildren()) do
		if DailyQuestObjectiveData.QuestTarget.Value == Target then 
			DailyQuestObjectiveData.QuestProgress.Value = math.clamp(DailyQuestObjectiveData.QuestProgress + 1, 0, DailyQuestObjectiveData.QuestMax.Value)
		end
		
		if DailyQuestObjectiveData.QuestProgress.Value == DailyQuestObjectiveData.QuestMax.Value then
			local QuestRewards = QuestAPI.GetQuestRewards(Player)

			if QuestRewards then
				for RewardName, RewardValue in pairs(QuestRewards) do

					if RewardName == "Gem" then
						Player.Data.Gem.Value = Player.Data.Gem.Value + RewardValue
					end
					--if RewardName == "Exp" then StatAPI.GiveExp(Player, RewardValue) NotifyRemote:FireClient(Player, {Text = string.format("<Font=GothamBold><Color=Yellow><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Rewarded %d Exp from Quest!", StatAPI.GetExpBonus(Player, RewardValue)), Duration = 2})
					--		 end

					--if RewardName == "Beli" then Player.Data.Beli.Value = Player.Data.Beli.Value + StatAPI.GetBeliBonus(Player, RewardValue)  NotifyRemote:FireClient(Player, {Text = string.format("<Font=GothamBold><Color=Green><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Rewarded %d Beli from Quest!", StatAPI.GetBeliBonus(Player, RewardValue)),  Duration = 2}) end
				end
			end

			QuestAPI.RemoveQuest(Player)
		end
	end
	--[[
	if QuestData.QuestTitle.Value == "" then return end
	
	local MaxCompletionStatus = 0
	
	for _, QuestObjectiveData in pairs(QuestData.Objectives:GetChildren()) do 
		if QuestObjectiveData.QuestTarget.Value == Target then
			QuestObjectiveData.QuestProgress.Value = math.clamp(QuestObjectiveData.QuestProgress.Value + 1, 0, QuestObjectiveData.QuestMax.Value)
			
		end
		if QuestObjectiveData.QuestProgress.Value == QuestObjectiveData.QuestMax.Value then MaxCompletionStatus = MaxCompletionStatus + 1  end
	end

	if MaxCompletionStatus == #QuestData.Objectives:GetChildren() then
		--> REWARD PLAYER
		
		local QuestRewards = QuestAPI.GetQuestRewards(Player)
		
		if QuestRewards then
			for RewardName, RewardValue in pairs(QuestRewards) do
				
				if RewardName == "Gem" then
					Player.Data.Gem.Value = Player.Data.Gem.Value + RewardValue
				end
				--if RewardName == "Exp" then StatAPI.GiveExp(Player, RewardValue) NotifyRemote:FireClient(Player, {Text = string.format("<Font=GothamBold><Color=Yellow><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Rewarded %d Exp from Quest!", StatAPI.GetExpBonus(Player, RewardValue)), Duration = 2})
			--		 end
				
				--if RewardName == "Beli" then Player.Data.Beli.Value = Player.Data.Beli.Value + StatAPI.GetBeliBonus(Player, RewardValue)  NotifyRemote:FireClient(Player, {Text = string.format("<Font=GothamBold><Color=Green><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Rewarded %d Beli from Quest!", StatAPI.GetBeliBonus(Player, RewardValue)),  Duration = 2}) end
			end
		end

		QuestAPI.RemoveQuest(Player)
		
		--NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Yellow><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Quest COMPLETE!", Duration = 2})
		
		
		--local Coin = ReplicatedStorage.Assets.Sounds.Coin:Clone()
		--Coin.Parent = Player.Character.HumanoidRootPart
		--Coin:Play() 
		--game.Debris:AddItem(Coin, 1)
	end
	--]]
end

function QuestAPI.GetQuestRewards(Player)
	for _, QuestCacheData in pairs(QuestCache) do 
		
		for _, SubQuestData in pairs(QuestCacheData) do
		
			if SubQuestData.QuestTitle == Player.Data["QuestData"].QuestTitle.Value then
				return SubQuestData.Rewards
			end
		end
		
	end
end

function QuestAPI.GenerateDailyQuests()
	
end
--[[
function QuestAPI.InitiateCollectables()
	for _, Folder in ipairs(QuestLocations:GetChildren()) do 
		local Location = Folder.Location
		
		if #Location:GetChildren() < 5 then
			
			local MaxDifference = 5 - #Location:GetChildren()
			
			for Amount = 0, MaxDifference, 1 do 
				SpawnCollectable(Folder, Location)
			end
			
		end
		
		Location.ChildRemoved:Connect(function()
			if #Location:GetChildren() < 5 then
				coroutine.wrap(function()
					task.wait(CollectableRespawnTime)

					if #Location:GetChildren() < 5 then	SpawnCollectable(Folder, Location) end
				end)()
			end
		end)
		
	end
end
--]]

--[[
QuestRemote.OnServerEvent:Connect(function(Player, Task, NpcName, SelectedQuest)
	if Task == "Assign" then
		
		
		QuestAPI.GiveQuest(Player, NpcName, SelectedQuest)
		
		
	elseif Task == "Abandon" then
		QuestAPI.RemoveQuest(Player)
		
		NotifyRemote:FireClient(Player, {Text = "<Font=GothamBold><Color=Red><AnimateStepFrequency=.3> Quest has been abandoned!", Duration = 2})
	end
end)
--]]
--QuestAPI.InitiateCollectables()

return QuestAPI