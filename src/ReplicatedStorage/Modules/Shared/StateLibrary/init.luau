--|| Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local Global = require(ReplicatedStorage.Global)
local StatePresets = require(script.StatePresets)
local Directory = require(ReplicatedStorage.Directory)

local RagdollManager = Directory.Import("Ragdoll_Manager", "Shared")

local AnimationService = Directory.Import("AnimationService", "Shared")
local NetworkStream = Directory.Import("NetworkStream", "Shared")


local StateLibrary = {}


local ComparisonMethods = {
	["NormalInteger"] = function(BranchTree,PathIndex)
		
	
		
		if workspace:GetServerTimeNow() - BranchTree.Begin.Value >= BranchTree.Duration.Value then
			
			BranchTree.Base.Value = true
			return true
		else
			
			BranchTree.Base.Value = false
			return false
		end
	end,
	
	["SpecialInteger"] = function(BranchTree,PathIndex)
		
		if workspace:GetServerTimeNow() - BranchTree.Begin.Value <= BranchTree.Duration.Value then
	
			BranchTree.Base.Value = true
			
			return true
		else
			
			BranchTree.Base.Value = false
	
			return false
		end
	end,
	
	["Boolean"] = function(BranchTree, PathIndex)
		return BranchTree.Base.Value
	end,
}

if RunService:IsServer() then
	function StateLibrary.CreateStates(Player)
		local StateFolder = Instance.new("Folder")
		StateFolder.Name = "States"
		StateFolder.Parent = Player

		
		
		Global.LoadInstancesFromTable(StateFolder, StatePresets.States, Player)
		
		
	end
	
	function StateLibrary.RefreshStates(Player)
		if not Player or not Player:FindFirstChild("States") then warn("did not find states in player") return false end

		Player.States:Destroy()

		StateLibrary.CreateStates(Player)
	end
end


function StateLibrary.IsValidAction(Player, Action)
	local AttemptedAction = StatePresets.ActionFlags[Action]

	if AttemptedAction and Player:FindFirstChild("States") then 
		---
		
		for _, StateData in ipairs(Player.States:GetChildren()) do
			if AttemptedAction[StateData.Name] == nil then continue end
		
			if StateLibrary.CheckState(Player, StateData.Name) ~= AttemptedAction[StateData.Name] then  return false end
		end

		return true
	end
end


function StateLibrary.CheckState(Player, State)
	if not Player or not Player:FindFirstChild("States") then  return false end
	

	if not Player.States:FindFirstChild(State)  then  return end

	return ComparisonMethods[Player.States[State].Category.Value](Player.States[State])
end

function StateLibrary.ModifyState(Player, State, NewValue, ModificationData)
	
	if not Player or not Player:FindFirstChild("States") then return false end

	if not Player.States:FindFirstChild(State)  then return end

	local SelectedState = Player.States:FindFirstChild(State)
	
	
	if SelectedState == nil then return end
	

	
	

	if SelectedState.Category.Value == "Boolean" then
		SelectedState.Duration.Value = 1e5
		SelectedState.Base.Value =  NewValue
	else
		SelectedState.Duration.Value =   NewValue
		SelectedState.Base.Value =  ComparisonMethods[SelectedState.Category.Value](SelectedState)
		
		
	end
	
	SelectedState.Begin.Value = workspace:GetServerTimeNow()
	
	--	print(BranchDictionary[SelectedState.Category](SelectedState))
	--print("modifying state", SelectedState)	

	if ModificationData then

		for _, Value in ipairs(SelectedState:GetChildren()) do
			if ModificationData[Value.Name] then
				SelectedState[Value.Name].Value = ModificationData[Value.Name]
			end

		end

	end


end


if game["Run Service"]:IsServer() then
	
	StateLibrary.CreateStates(workspace.World.Entities.BlockDummy)
	StateLibrary.CreateStates(workspace.World.Entities.TestDummy)
	--StateLibrary.CreateStates(workspace.World.Entities.KnockedDummy)
	
	StateLibrary.ModifyState(workspace.World.Entities.BlockDummy, "Blocking", true, {BlockAmount = 5, MaxBlocks = 5})
	AnimationService.PlayAnimation(workspace.World.Entities.BlockDummy, "NormalBlock", "Play", {Loop = true})
	
	task.delay(10, function()
		NetworkStream.FireAllClients(workspace.World.Entities.BlockDummy, "Effect", 100, {
			Character = workspace.World.Entities.BlockDummy,

			Category = "Misc",

			Function = "Block",

			Status = "Charge",

			BlockAmount = 6,
			MaxBlocks = 6,

			AbilityData = {Chargeable = true},
		})

	end)
	
	
	
	--[[
	
	local Humanoid = workspace.World.Entities.TestDummy.Humanoid
	BuildRagdoll(Humanoid)
	
	workspace.World.Entities.TestDummy.Humanoid.HealthChanged:Connect(function()
		
	
		if Humanoid.Health < (Humanoid.MaxHealth / 6) then
		
			AnimationService.PlayAnimation(workspace.World.Entities.TestDummy, "KnockedIdle","Play", {Loop = true})
			
			StateLibrary.ModifyState(workspace.World.Entities.TestDummy, "Knocked", true)
	
		elseif Humanoid.Health >= (Humanoid.MaxHealth / 6) and StateLibrary.CheckState(workspace.World.Entities.TestDummy, "Knocked") then

			StateLibrary.ModifyState(workspace.World.Entities.TestDummy, "Knocked", false)
	
		end
	end)
	
	
	workspace.World.Entities.TestDummy.States.Ragdoll.Base.Changed:Connect(function()
		if workspace.World.Entities.TestDummy.States.Ragdoll.Base.Value == true then
			


			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

			if  Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then

				coroutine.wrap(function()

					while  Humanoid:GetState() ~= Enum.HumanoidStateType.Dead do
						
					
						if  not StateLibrary.CheckState(workspace.World.Entities.TestDummy, "Ragdoll")  then


							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
							Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
							Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
							
						
							break
						end

						task.wait()
					end



				end)()

			end
		end



	end)
	--]]
end
--]]
return StateLibrary