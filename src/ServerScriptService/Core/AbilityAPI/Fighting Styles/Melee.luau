--|| Services ||--
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debris = game:GetService("Debris")

local RunService = game:GetService("RunService")

--|| Directories
local Remotes = ReplicatedStorage.Remotes

--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)
local DamageAPI = require(ServerScriptService.Core.Mechanics["Damage API"])

local Global = require(ReplicatedStorage.Global)

--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> Player State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")

local StateLibrary = Directory.Import("StateLibrary", "Shared")

local AnimationService = Directory.Import("AnimationService", "Shared")

--> Utility
local Utility = Directory.Import("Utility", "Shared")

local NetworkStream = Directory.Import("NetworkStream", "Shared")
local HitboxLibrary = Directory.Import("HitboxLibrary", "Shared")

--|| Networking ||--
local AbilityRequest = Remotes.Ability
local Effect = Remotes.Effect

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {}
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

local DashDirections = {
	["W"] = "Forward",
	["D"] = "Right",
	["S"] = "Back",
	["A"] = "Left"
}
local Superhuman = {
	["FirstAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			
			
			StateLibrary.ModifyState(Player, "Charging", true)
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			
			
			StateLibrary.ModifyState(Player, "Charging", false)
		end,
	},
	
	

	["Block"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			
			AnimationService.PlayAnimation(Player, "NormalBlock", "Play", {Loop = true})
			
			StateLibrary.ModifyState(Player, "Blocking", true, {BlockAmount = 6, MaxBlocks = 6})
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,

				Category = "Misc",

				Function = "Block",

				Status = "Charge",
				
				BlockAmount = 6,
				MaxBlocks = 6,
				
				AbilityData = AbilityData,
			})
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			
			AnimationService.PlayAnimation(Player, "NormalBlock", "Stop")
			
			StateLibrary.ModifyState(Player, "Blocking", false)
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Misc",

				Function = "Block",

				Status = "Release",

				AbilityData = AbilityData,
			})
			
		end,
		
	},
	
	
	["Swing"] = function(Player, AbilityData, ExtraData)
	
		
		local Character = Player.Character
		local GlobalInformation  = Database.GetCategoryData(Player, "GlobalInformation")
		
		GlobalInformation.KeysLogged = os.clock() - GlobalInformation.LastPressed <= 2 and GlobalInformation.KeysLogged or 0

		--> If Keys are less 

		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged >= 5 and 0 or GlobalInformation.KeysLogged

		--> Add Keys
		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged + 1
		
		AnimationService.PlayAnimation(Player, "Punch"..GlobalInformation.KeysLogged, "Play")
		
		local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
		
		
		StateLibrary.ModifyState(Player, "Speed", 1, {
			Priority = 1,
			
			WalkSpeed = 8,
			JumpPower = 0
		})
		
		for _, ValidEntity in ipairs(ValidEntities) do 
			local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
			
			if Harmed and Global.IsAlive(ValidEntity) then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
				BodyVelocity.Parent = ValidEntity.HumanoidRootPart
				BodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * (GlobalInformation.KeysLogged == 5 and 25 or 5)
				Debris:AddItem(BodyVelocity, .25)

			end

		end
		
	
		
		GlobalInformation.LastPressed = os.clock()
		
		
		if GlobalInformation.KeysLogged == 5 then 
			StateLibrary.ModifyState(Player, "Attacking", 1.25)
			GlobalInformation.KeysLogged = 0
		else
			StateLibrary.ModifyState(Player, "Attacking", AbilityData.Endlag)
		end

		
		
		DebounceAPI.ApplyCooldown(Player, script.Name, "Swing")
	end,
	
	
}

return Superhuman