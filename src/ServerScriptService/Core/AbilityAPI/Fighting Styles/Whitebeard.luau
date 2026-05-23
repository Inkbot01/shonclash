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

local StatAPI = require(ServerScriptService.Core.World["Stat API"])
local Global = require(ReplicatedStorage.Global)

--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> Player State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")

local StateLibrary = Directory.Import("StateLibrary", "Shared")

local AnimationService = Directory.Import("AnimationService", "Shared")

local RagdollManager = Directory.Import("Ragdoll_Manager", "Shared")
local RaycastService = require(ReplicatedStorage.Modules.Shared.RaycastService)
local MouseRemote = ReplicatedStorage.Remotes.GetMouse

--> Utility
local Utility = Directory.Import("Utility", "Shared")

local NetworkStream = Directory.Import("NetworkStream", "Shared")
local HitboxLibrary = Directory.Import("HitboxLibrary", "Shared")

--|| Networking ||--
local AbilityRequest = Remotes.Ability
local Effect = Remotes.Effect

local CameraRemote = Remotes.Camera


local DashDirections = {
	["W"] = "Forward",
	["D"] = "Right",
	["S"] = "Back",
	["A"] = "Left"
}

local start_time = 0

local Superhuman = {
	
	["Swing"] = function(Player, AbilityData, ExtraData)
		local Character = Player.Character
		local GlobalInformation  = Database.GetCategoryData(Player, "GlobalInformation")

		GlobalInformation.KeysLogged = os.clock() - GlobalInformation.LastPressed <= 2 and GlobalInformation.KeysLogged or 0
		StateLibrary.ModifyState(Player, "Casting", .2)



		CameraRemote:FireClient(Player,{
			Function = "SwayCamera"
		})

		--> If Keys are less 

		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged >= 5 and 0 or GlobalInformation.KeysLogged

		--> Add Keys
		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged + 1

		

		AnimationService.PlayAnimation(Player, "BisentoSlash"..GlobalInformation.KeysLogged, "Play")

		local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})


		StateLibrary.ModifyState(Player, "Speed", .85, {
			Priority = 1,

			WalkSpeed = 8,
			JumpPower = 0
		})
		

		local SwingTime = ReplicatedStorage.Assets.Sounds.Swing:Clone()
		SwingTime.Parent = workspace.World.SFX

		SwingTime:Play()
		game.Debris:AddItem(SwingTime, SwingTime.TimeLength)
		
		for _, ValidEntity in ipairs(ValidEntities) do 
			local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
			
			
			
			if Harmed and Global.IsAlive(ValidEntity) then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
				BodyVelocity.Parent = ValidEntity.HumanoidRootPart
				BodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * (GlobalInformation.KeysLogged == 5 and 50 or 5)
				Debris:AddItem(BodyVelocity, .25)
				
				
				if not StateLibrary.CheckState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Blocking")  and GlobalInformation.KeysLogged == 5 then
					RagdollManager.DurationRagdoll(ValidEntity, 2)
				else
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", .75)
					

					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", 1, {
						Priority = 1,

						WalkSpeed = 8,
						JumpPower = 0
					})
					
				--	local TargetTrack = ValidEntity.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Shared.HitReaction["HitReaction"..GlobalInformation.KeysLogged])
					--TargetTrack:Play()
				end
			end

		end





		GlobalInformation.LastPressed = os.clock()


		if GlobalInformation.KeysLogged == 5 then 
			StateLibrary.ModifyState(Player, "Attacking", 1)

			local CantDash = Instance.new("IntValue")
			CantDash.Name = "CantDash"
			CantDash.Parent = Character
			Debris:AddItem(CantDash, .25)


			GlobalInformation.KeysLogged = 0
		else

			local CantDash = Instance.new("IntValue")
			CantDash.Name = "CantDash"
			CantDash.Parent = Character
			Debris:AddItem(CantDash, .75)

			StateLibrary.ModifyState(Player, "Attacking", AbilityData.Endlag)
		end



	

		DebounceAPI.ApplyCooldown(Player, script.Name, "Swing")
	end,
	
	
	
	
	["Block"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)

			AnimationService.PlayAnimation(Player, "NormalBlock", "Play", {Loop = true})

			StateLibrary.ModifyState(Player, "Blocking", true, {BlockAmount = 6, MaxBlocks = 6})
			
			StateLibrary.ModifyState(Player, "Speed", 100000, {
				Priority = 1.1,

				JumpPower = 0,
				WalkSpeed = 2,
			})
			
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
			
			StateLibrary.ModifyState(Player, "Speed", 0, {
				Priority = 1.1,

				JumpPower = 0,
				WalkSpeed = 16,
			})
			
		end,

	},
	
	
	["FirstAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			local Character = Player.Character

		--	local anim = AnimationService.PlayAnimation(Player, "ChidoriStartUp", "Play")
			
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			
		end,
	},
	
	["SecondAbility"] = function(Player, AbilityData, ExtraData)
		

	end,
	
	["ThirdAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			

			StateLibrary.ModifyState(Player, "Charging", true)

		end,

		["Release"] = function(Player, AbilityData, ExtraData)

			DebounceAPI.ApplyCooldown(Player, script.Name, "ThirdAbility")
			StateLibrary.ModifyState(Player, "Charging", false)
		end,
	},

	["FourthAbility"] = function(Player, AbilityData, ExtraData)
		
		local Character = Player.Character
		
	
		
		DebounceAPI.ApplyCooldown(Player, script.Name, "FourthAbility")
	end,
	

	
	["Haki"] = function(Player, AbilityData, ExtraData)
		if not StateLibrary.CheckState(Player, "Haki") then 
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,



				Category = "Misc",

				Function = "Haki",

				Status = "Create",
				
				WeaponCategory = "Black Leg",
				
				AbilityData = AbilityData,
			})
			
			StateLibrary.ModifyState(Player, "Haki", true)
		else
			
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
	
	
}

return Superhuman