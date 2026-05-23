--|| Services ||--
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

PhysicsService:CreateCollisionGroup("Uncollideable NPCS")
PhysicsService:CollisionGroupSetCollidable("Uncollideable NPCS", "Uncollideable NPCS", false)

local NotifyRemote = ReplicatedStorage.Remotes.Notify

--|| Modules ||--
local Properties = require(script.Parent.Properties)
local Database = require(script.Parent.Database)

local StateLibrary = require(ReplicatedStorage.Modules.Shared.StateLibrary)
-- this is outside of the system
local DamageAPI = require(ServerScriptService.Core.Mechanics["Damage API"])
local QuestAPI = require(ServerScriptService.Core.World.QuestAPI)
local StatApi = require(ServerScriptService.Core.World["Stat API"])

local Global = require(ReplicatedStorage.Global)
local LootLibrary = require(ServerScriptService.Core.World.LootLibrary)

local RegisteredItems = require(ReplicatedStorage.Modules.Shared.RegisteredItems)
--|| Localise ||--
local Clock = os.clock

local NPC = {}
local NPCS = {}
NPC.__index = NPC

--local replicateEffects = ReplicatedStorage.Remotes.replicateEffects

local function SetCollisionGroup(Model, Group)
	for _, Desc in ipairs(Model:GetDescendants()) do
		if Desc:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(Desc, Group)
		end
	end
end

if not Properties.PLAYER_COLLISION then
	Players.PlayerAdded:Connect(function(Player)
		local Character = Player.Character or Player.CharacterAdded:Wait()
		SetCollisionGroup(Player.Character,"Uncollideable NPCS")
		
		Player.CharacterAdded:Connect(function(Character)
			SetCollisionGroup(Character, "Uncollideable NPCS")
		end)
	end)
end

local function Halt(n, Quantity)
	n = n or 1/60
	local Begin = Clock()
	while Clock() - Begin < n  do
		RunService.Stepped:Wait()
	end
end

local function Debug(Msg, Warn)
	if Properties.DEBUG then
		if Warn then
			warn("[AI HANDLER]: "..Msg)
		else
			print("[AI HANDLER]: "..Msg)
		end
	end
end

local function GroupLikeNPCS()
	local Directory = Properties.NPC_STORAGE_DIRECTORY
	for NPC, NPCData in next, Database do
		NPCS[NPC] = {}
		for _, Child in ipairs(Directory:GetChildren()) do
			if NPC == Child.Name then
				
				local BodyGyro = Instance.new("BodyGyro")
				BodyGyro.MaxTorque = Vector3.new(0,0,0)
				BodyGyro.Name = "Rotater"
				BodyGyro.D = 200
				BodyGyro.P = 9000
				BodyGyro.Parent = Child:WaitForChild("HumanoidRootPart", 6)
				
				NPCS[NPC][#NPCS[NPC] + 1] = Child
			end
		end
	end
end
GroupLikeNPCS()

local DataValuesToObject = {
	["number"] = "NumberValue",
	["boolean"] = "BoolValue",
	["string"] = "StringValue"
}

function CreateMiscData(Folder, Table)
	for Index, Value in next, Table do
		if typeof(Value) ~= "table" then
			local NewObject = Instance.new(DataValuesToObject[typeof(Value)])
			NewObject.Name = Index
			NewObject.Value = Value
			NewObject.Parent = Folder
		else
			local NewFolder = Instance.new("Folder")
			NewFolder.Name = Index
			NewFolder.Parent = Folder
			CreateMiscData(NewFolder, Value)
		end
	end
end

function LoadAnimationFromTable(Humanoid, Table1, AnimTable)
	for Index, Value in next, AnimTable do
		if typeof(Value) == "table" then
			Table1[Index] = {}
			LoadAnimationFromTable(Humanoid, Table1[Index], Value)
		else
			local Animation = Instance.new("Animation")
			Animation.AnimationId = Value
			Table1[Index] = Humanoid:LoadAnimation(Animation)	
			Animation:Destroy()
		end	
	end
end

local function CreateNPCModel(Data)
	--| Main Data
	local Id = Data.Id
	local SpawnCFrame = Data.CFrame
	
	local RandomNPC = NPCS[Id][math.random(1, #NPCS[Id])]:Clone()
	local Humanoid = RandomNPC:FindFirstChild"Humanoid"
	
	if not Properties.NPC_COLLISION then
		SetCollisionGroup(RandomNPC, "Uncollideable NPCS")
	end
	
	if Properties.CREATE_MISC_DATA then
		local Folder = Instance.new("Folder")
		Folder.Name = "Data"
		Folder.Parent = RandomNPC
		
		CreateMiscData(Folder, Database[Id].MiscData)
	end
	
	if not Humanoid then
		Debug(RandomNPC:GetFullName().."["..Id.."] does not have a existing Humanoid!", true)
		return
	else
		for State, Value in next, Properties.HUMANOID_STATES do
			Humanoid:SetStateEnabled(State, Value)
		end
		--Humanoid.AutoRotate = true
		
		for Property, Value in next,Database[Id].HumanoidProperties do
			Humanoid[Property] = Value
		end
		Humanoid.Health = Humanoid.MaxHealth
		

		
	end
	
	if not RandomNPC.PrimaryPart then
		Debug(RandomNPC:GetFullName().."["..Id.."] does not have a existing PrimaryPart!", true)
	else
		RandomNPC:SetPrimaryPartCFrame(SpawnCFrame)
	end
	RandomNPC.Parent = ReplicatedStorage
	
	--| Load Animations
	LoadAnimationFromTable(Humanoid, Data.Animations, Database[Id].Animations)
	
	for _,part in pairs(RandomNPC:GetDescendants()) do
		if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(nil)
		end
	end
	
	StateLibrary.CreateStates(RandomNPC)
	--| Play Idle
	Data.Animations.Idle:Play()
	
	return RandomNPC
end

function NPC.new(Data)
	local Model = CreateNPCModel(Data)
	Data.Model = Model
	return setmetatable(Data, NPC)
end

function NPC:Die()
	if Database[self.Id].Die then
		Database[self.Id].Die(self.Model)
	end
	
	for _, RegisteredPlayer in ipairs(self.Model.Data.AttackLog:GetChildren()) do 
		local ConveretedPlayer = Players:FindFirstChild(RegisteredPlayer.Name) 
	
		if ConveretedPlayer then 
			--> add drops nd stuff later
		
			QuestAPI.AddItem(ConveretedPlayer, self.Model.Name)
			
			
			if (RegisteredPlayer.Value >= self.Model.Humanoid.Health * .10) then
				
				LootLibrary.AttemptDrop(ConveretedPlayer, self.Model.Name)
				
				for _, Reward in ipairs(self.Model.Data.Rewards:GetChildren()) do 
					
					
					if Reward.Name == "Exp" then 
						StatApi.GiveExp(ConveretedPlayer, Reward.Value)
						NotifyRemote:FireClient(ConveretedPlayer, {Text = string.format("<Font=GothamBold><Color=White><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Earned <Color=Yellow>%d Exp.<Color=/>", StatApi.GetExpBonus(ConveretedPlayer,Reward.Value) ), Duration = 2})
					elseif Reward.Name == "Beli" then
						ConveretedPlayer.Data.Beli.Value = ConveretedPlayer.Data.Beli.Value + StatApi.GetBeliBonus(ConveretedPlayer, Reward.Value)
						NotifyRemote:FireClient(ConveretedPlayer, {Text = string.format("<Font=GothamBold><Color=White><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Earned <Color=Green>%d Beli.<Color=/> ", StatApi.GetBeliBonus(ConveretedPlayer, Reward.Value)), Duration = 2})
					elseif Reward.Name == "Bounty" then
						ConveretedPlayer.Data.Bounty.Value = ConveretedPlayer.Data.Bounty.Value + Reward.Value
					end
					
				end
				
				local CurrentHeldTool = ConveretedPlayer.Character:FindFirstChildOfClass("Tool")
				
				
				if CurrentHeldTool and RegisteredItems[CurrentHeldTool.Name]  then
					
					local Type = RegisteredItems[CurrentHeldTool.Name].Type
			
					
					if Type ~= "Sword Style" and Type ~= "Fighting Style" and Type ~= "Gun Style" and Type ~= "Devil Fruit" then return end
					
				
					StatApi.GiveMastery(ConveretedPlayer, CurrentHeldTool.Name, math.floor(self.Model.Data.Rewards.Exp.Value/3.5)) --change later to scale
					NotifyRemote:FireClient(ConveretedPlayer, {Text = string.format("<Font=GothamBold><Color=White><AnimateStyle=Rainbow><AnimateStepFrequency=.3> Earned <Color=Yellow>%d Exp.<Color=/> (+ %s)", StatApi.GetMasteryBonus(ConveretedPlayer,math.floor(self.Model.Data.Rewards.Exp.Value/3.5)) , CurrentHeldTool.Name), Duration = 2})
				end
				
			end
		end
	end
	
	
	
	self.Model:Destroy()
	NPC.Respawn(self)
end

function NPC:Respawn()
	Halt(Database[self.Id].RespawnTime, Database[self.Id].Quantity)
	local NewModel = CreateNPCModel(self)
	self.Model = NewModel
	self.Animations.Idle:Play()
	
	--| Death Event
	local Death, AncestryChanged
	Death = self.Model.Humanoid.HealthChanged:Connect(function(Health)
		if Health <= 0 then
			
			
			Death:Disconnect()
			Death = nil
			
			AncestryChanged:Disconnect()
			AncestryChanged = nil
			
			self:Die()
		end
	end)
	
	AncestryChanged = self.Model.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			
			AncestryChanged:Disconnect()
			AncestryChanged = nil
			
			Death:Disconnect()
			Death = nil
			
			self:Die()
		end
	end)
end

function NPC:Attack(Target)
	if not Global.IsAlive(self.Model) then return end
	
	if Database[self.Id].Attack then
		Database[self.Id].Attack(self.Model, Target)
	else
		
		self.Model.HumanoidRootPart.Rotater.CFrame = CFrame.new(self.Model.HumanoidRootPart.Position, Target.HumanoidRootPart.Position)
		self.Model.HumanoidRootPart.Rotater.MaxTorque = Vector3.new(0,1,1) * 500000
		
		local Harmed 
		
		if Target:FindFirstChild"Humanoid" and Global.IsAlive(self.Model) then
			Harmed = DamageAPI.InflictDamage(self.Model, Target, {Damage = Database[self.Id].AttackDamage, Chargeable = false})
			
		
		end
		
		if Database[self.Id].RandomAttack then
			local AttackIndex = math.random(1, #self.Animations.Attack)
			self.Animations.Attack[AttackIndex]:Play()
		else
			
			self.LastAttackIndex = (self.LastAttackIndex + 1 > #self.Animations.Attack and 1 or self.LastAttackIndex + 1)
			self.Animations.Attack[self.LastAttackIndex]:Play()	
			
			--[[
			if Harmed then
				local BodyVelocity = Instance.new("BodyPosition")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 25000
				BodyVelocity.Velocity = self.Model.HumanoidRootPart.CFrame.LookVector * (self.LastAttackIndex + 1 > #self.Animations.Attack and 25 or 5)
				BodyVelocity.Parent = Target.HumanoidRootPart
				Debris:AddItem(BodyVelocity, .25)
			end
			-]]
			
			if Harmed and self.LastAttackIndex + 1 > #self.Animations.Attack and Global.IsAlive(self.Model) then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 25000
				BodyVelocity.Velocity = self.Model.HumanoidRootPart.CFrame.LookVector * 25
				BodyVelocity.Parent = Target.HumanoidRootPart
				Debris:AddItem(BodyVelocity, .25)
			end
			
		end
		
		if self.Animations.Chase.IsPlaying then
			self.Animations.Chase:Stop()
		end
	end
end

function NPC:Chase(Target)
	local EndGoal = Target.HumanoidRootPart.Position
	local StartPosition = self.Model.HumanoidRootPart.Position
	local Direction = (EndGoal - StartPosition).Unit
	local NewEndGoal = EndGoal + Direction * Database[self.Id].AttackDistance/2
	self.Model.Humanoid:MoveTo(NewEndGoal, Target.HumanoidRootPart)
	
	self.Model.HumanoidRootPart.Rotater.MaxTorque = Vector3.new(0,0,0)
	
	if Properties.NPC_CAN_JUMP then
		local RayData = RaycastParams.new()
		RayData.FilterDescendantsInstances = {Properties.NPC_DIRECTORY}
		RayData.FilterType = Enum.RaycastFilterType.Blacklist
		local Orgin = self.Model.HumanoidRootPart.Position
		local End = (self.Model.HumanoidRootPart.CFrame * CFrame.new(0,0,-5)).Position
		local Result = game.Workspace:Raycast(Orgin, (End - Orgin).Unit * 5, RayData)
		if Result then
			self.Model.Humanoid.Jump = true
		end
	end
	
	if not self.Animations.Chase.IsPlaying then
		self.Animations.Chase:Play()
	end
end

return NPC
