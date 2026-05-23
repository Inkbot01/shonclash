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


local Superhuman = {
	["FirstAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			--print("Started Holding Key")
			
			StateLibrary.ModifyState(Player, "Charging", true)
			
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			--print("Released Held Key")
			local Character = Player.Character

			local ValidEntities = HitboxLibrary.GetEntitiesInPart(Character.PrimaryPart.CFrame * CFrame.new(0, 0, -20), Vector3.new(7, 10, 45), {workspace.World.Visuals, Character})

			for EntityName, EntityObject in pairs(ValidEntities) do 
				if EntityObject == Character then continue end

				DamageAPI.InflictDamage(Character, EntityObject, AbilityData, script.Name)
			end

			NetworkStream.FireAllClients(Character, "Effect", 700, {
				Character = Character,

				Category = "Dual Katana",
				Function = "72 Caliber Phoenix",

				AbilityData = AbilityData,

				TargetCFrame = ExtraData.Hit,
				Range = AbilityData.Range,
				--[[
				RaycastSettings = {
					Velocity = 100, 
					Lifetime = 6,

					HikenSpawn = HikenSpawn,
					Direction = Direction
				},
--]]
				Status = "Release"
			})

			StateLibrary.ModifyState(Player, "Charging", false)
			DebounceAPI.ApplyCooldown(Player, script.Name, "FirstAbility")
			
		end,
	},
	
	["SecondAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			--print("Started Holding Key")
			
			local Character = Player.Character
			
			StateLibrary.ModifyState(Player, "Charging", true)

			NetworkStream.FireAllClients(Character, "Effect", 700, {
				Character = Character,

				Category = "Dual Katana",
				Function = "Nitoryu Strike",

				AbilityData = AbilityData,

				TargetCFrame = ExtraData.Hit,
				Range = AbilityData.Range,
				--[[
				RaycastSettings = {
					Velocity = 100, 
					Lifetime = 6,

					HikenSpawn = HikenSpawn,
					Direction = Direction
				},
--]]
				Status = "Charge"
			})
		end,

		["Release"] = function(Player, AbilityData, ExtraData)
			--print("Released Held Key")
			local Character = Player.Character

			local ValidEntities = HitboxLibrary.GetEntitiesInPart(Character.PrimaryPart.CFrame * CFrame.new(0, 0, -20), Vector3.new(7, 10, 45), {workspace.World.Visuals, Character})

			for EntityName, EntityObject in pairs(ValidEntities) do 
				if EntityObject == Character then continue end

				DamageAPI.InflictDamage(Character, EntityObject, AbilityData, script.Name)
			end

			NetworkStream.FireAllClients(Character, "Effect", 700, {
				Character = Character,

				Category = "Dual Katana",
				Function = "Nitoryu Strike",

				AbilityData = AbilityData,

				TargetCFrame = ExtraData.Hit,
				Range = AbilityData.Range,
				--[[
				RaycastSettings = {
					Velocity = 100, 
					Lifetime = 6,

					HikenSpawn = HikenSpawn,
					Direction = Direction
				},
--]]
				Status = "Release"
			})

			StateLibrary.ModifyState(Player, "Charging", false)
			DebounceAPI.ApplyCooldown(Player, script.Name, "SecondAbility")

		end,
	},
	
	
	["Haki"] = function(Player, AbilityData, ExtraData)
		if not StateLibrary.CheckState(Player, "Haki") then 
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Dual Katana",

				Function = "Haki",

				Status = "Create",

				WeaponCategory = script.Name,

				AbilityData = AbilityData,
			})
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Misc",

				Function = "Haki",

				Status = "Create",

				WeaponCategory = "Melee",

				AbilityData = AbilityData,
			})
			
			
			StateLibrary.ModifyState(Player, "Haki", true)
		else

			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Dual Katana",

				Function = "Haki",

				Status = "Remove",

				AbilityData = AbilityData,
			})
			

			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Misc",

				Function = "Haki",

				Status = "Remove",

				AbilityData = AbilityData,
			})
			
			StateLibrary.ModifyState(Player, "Haki", false)
		end
		DebounceAPI.ApplyCooldown(Player, script.Name, "Haki")
	end,
	["Swing"] = function(Player, AbilityData, ExtraData)
	
		
		local Character = Player.Character
		local GlobalInformation  = Database.GetCategoryData(Player, "GlobalInformation")
		
		GlobalInformation.KeysLogged = os.clock() - GlobalInformation.LastPressed <= 2 and GlobalInformation.KeysLogged or 0

		--> If Keys are less 

		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged >= 5 and 0 or GlobalInformation.KeysLogged

		--> Add Keys
		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged + 1
		
		AnimationService.PlayAnimation(Player, "Slash"..GlobalInformation.KeysLogged, "Play")
		
		local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
		
		for _, ValidEntity in ipairs(ValidEntities) do 
			local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
			
			if Harmed then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
				BodyVelocity.Parent = ValidEntity.HumanoidRootPart
				BodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * (GlobalInformation.KeysLogged == 5 and 25 or 5)
				Debris:AddItem(BodyVelocity, .25)
			end
			
		
			
		end
		
	
		
		GlobalInformation.LastPressed = os.clock()
		
		
		DebounceAPI.ApplyCooldown(Player, script.Name, "Swing")
	end,
}

return Superhuman