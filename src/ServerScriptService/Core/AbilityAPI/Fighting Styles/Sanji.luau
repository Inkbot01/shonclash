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

--> Utility
local Utility = Directory.Import("Utility", "Shared")

local NetworkStream = Directory.Import("NetworkStream", "Shared")
local HitboxLibrary = Directory.Import("HitboxLibrary", "Shared")

--|| Networking ||--
local AbilityRequest = Remotes.Ability
local Effect = Remotes.Effect

local CameraRemote = Remotes.Camera

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



		AnimationService.PlayAnimation(Player, "Punch"..GlobalInformation.KeysLogged, "Play")

		--local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})

		StateLibrary.ModifyState(Player, "Speed", 1, {
			Priority = 1,

			WalkSpeed = 8,
			JumpPower = 0
		})

		local ValidEntities = HitboxLibrary.GetEntitiesInPart(Character.PrimaryPart.CFrame * CFrame.new(0, 0, -5), Vector3.new(5.75,5.75,5.75), {[Character] = true}, true)



		--	local HitboxWhitelist = {}

		for _, ValidEntity in pairs(ValidEntities) do 


			if ValidEntity == Character then continue end 



			local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)



			if Harmed and Global.IsAlive(ValidEntity) then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(1,1,1) * 65000
				BodyVelocity.Parent = ValidEntity.HumanoidRootPart
				BodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * (GlobalInformation.KeysLogged == 5 and 55 or 5)
				Debris:AddItem(BodyVelocity, .25)


				if not StateLibrary.CheckState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Blocking")  and GlobalInformation.KeysLogged == 5 then
					RagdollManager.DurationRagdoll(ValidEntity, 2)
					--AnimationService.PlayAnimation(ValidEntity, "HitReaction"..GlobalInformation.KeysLogged, "Play")


					if Global.IsWallbreak(Character) and  ValidEntity ~= Character then 
						print('wall break')
						--[[
						NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
							Character = ValidEntity,


							Category = "Misc",

							Function = "WallBreak",


							AbilityData = AbilityData,
						})
--]]
					end

				else
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", .75)
					--[[
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", .75, {
						Priority = 1,

						WalkSpeed = 0,
						JumpPower = 0
					})
--]]


					local TargetTrack = ValidEntity.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Shared.HitReaction["HitReaction"..GlobalInformation.KeysLogged])
					TargetTrack:Play()

					--AnimationService.PlayAnimation(ValidEntity, "HitReaction"..GlobalInformation.KeysLogged, "Play")
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
	
	--[[
	['Grip'] = function(Player, AbilityData, AdditionalData)
		
		local Character = Player.Character
		
		local PrimaryPart = Character.PrimaryPart
		local Humanoid = Character.Humanoid
		
		local KnockedEntities = HitboxLibrary.GetEntitiesInRadius(PrimaryPart.Position, 5, false, {[Character] = true})
		
		local CurrentPlayingAnimations = Humanoid:GetPlayingAnimationTracks()
		
		for _, Track in pairs(CurrentPlayingAnimations) do
			if Track.Name == "KnockedGrip" then
				
				Track:Stop()
				return
			end
			
		end
		
		for _, KnockedEntity in ipairs(KnockedEntities) do
			if StateLibrary.CheckState(KnockedEntity, "Knocked")  then
				
				
				local GripAnimation = ReplicatedStorage.Assets.Animations.Shared.Mechanics.AttackerGrip
				local TargetGripAnimation = ReplicatedStorage.Assets.Animations.Shared.Mechanics.TargetGrip
	
				local Track = Character.Humanoid:LoadAnimation(GripAnimation)
				
				Track:Play()
				
				local TargetTrack = KnockedEntity.Humanoid:LoadAnimation(TargetGripAnimation)
				TargetTrack:Play()
				
				RagdollManager.EndRagdoll(KnockedEntity)
				
				KnockedEntity.PrimaryPart.CFrame = Character.PrimaryPart.CFrame * CFrame.new(0, 0, -1)
				KnockedEntity.PrimaryPart.CFrame = CFrame.lookAt(KnockedEntity.PrimaryPart.Position, Character.PrimaryPart.Position)
				
				--> Adjust later
			--	PrimaryPart.CFrame = KnockedEntity.UpperTorso.CFrame * CFrame.new(0, 1, 0)
				
				--AnimationService.PlayAnimation(Character, "KnockedGrip", "Play")
				
				
				StateLibrary.ModifyState(Character, "Speed", 2, true, {
					Priority = 1,
					
					JumpPower = 0,
					WalkSpeed = 0,
				})
				
				local AnimationMarkerReached = nil
				local AnimationStopped = nil
				
				AnimationMarkerReached = Track:GetMarkerReachedSignal("ThirdGrip"):Connect(function()
					KnockedEntity.Humanoid:TakeDamage(KnockedEntity.Humanoid.MaxHealth)
					
					AnimationMarkerReached:Disconnect()
					
				end)
				
				AnimationStopped = Track.Stopped:Connect(function()
					AnimationStopped:Disconnect()
					AnimationMarkerReached:Disconnect()
					
				end)
				
				--KnockedEntity:BreakJoints()
				
				
				
			end
		end
		
		
	end,
	--]]
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
	
	
	["FirstAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
		
			
			StateLibrary.ModifyState(Player, "Charging", true)
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			
		--	AnimationService.PlayAnimation(Player, "Kick"..GlobalInformation.KeysLogged, "Play", {Speed = 1.75})
			local Character = Player.Character
			
			local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
			
			for _, ValidEntity in ipairs(ValidEntities) do 
				

				if Global.IsAlive(ValidEntity) then
					local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
					
					
					NetworkStream.FireAllClients(Character, "Effect", 700, {
						Character = Character,
						
						Target = ValidEntity,
						
						Category = "Black Leg",
						Function = "Colier",

						AbilityData = AbilityData,

						TargetCFrame = ExtraData.Hit,
						Range = AbilityData.Range,
						
						Status = "Release"
					})
				end

			

			end
			
			
			StatAPI.GiveMastery(Player, script.Name, 50)
		
			DebounceAPI.ApplyCooldown(Player, script.Name, "FirstAbility")
			StateLibrary.ModifyState(Player, "Charging", false)
		end,
	},
	
	["SecondAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			
			local Character = Player.Character
			
			StateLibrary.ModifyState(Player, "Charging", true)
			
			AnimationService.PlayAnimation(Player, "Party Table", "Play", {Loop = true})
			
			NetworkStream.FireAllClients(Character, "Effect", 700, {
				Character = Character,

				Category = "Black Leg",
				Function = "Party Table",

				AbilityData = AbilityData,

				TargetCFrame = ExtraData.Hit,
				Range = AbilityData.Range,

				Status = "Release"
			})
			
			for Index = 1,15 do
				local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
				
				if not StateLibrary.CheckState(Player, "Charging")  then return end 
				
				for _, ValidEntity in ipairs(ValidEntities) do 

					if Global.IsAlive(ValidEntity) then
						local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)


						local VRoot,VHum = ValidEntity:FindFirstChild("HumanoidRootPart"),ValidEntity:FindFirstChild("Humanoid")

						if not VRoot or not VHum then continue end
						
						--[[]]
						local BodyVelocity = Instance.new("BodyVelocity")
						BodyVelocity.MaxForce = Vector3.new(1e4,1e4,1e4);
						BodyVelocity.Velocity = (VRoot.CFrame.p - Character.PrimaryPart.CFrame.p).Unit * 8
						BodyVelocity.Parent = Character.PrimaryPart
						Debris:AddItem(BodyVelocity,.25)					

						local Look = CFrame.new(VRoot.Position,Character.PrimaryPart.Position).lookVector

						local BodyVelocity = Instance.new("BodyVelocity")
						BodyVelocity.MaxForce = Vector3.new(1e4,1e4,1e4)
						BodyVelocity.Velocity = Look * -10
						BodyVelocity.Parent = VRoot
						Debris:AddItem(BodyVelocity,.2)		

					end
				end

				wait(.125)
			end
			
			AnimationService.PlayAnimation(Player, "Party Table", "Stop")
			
		end,

		["Release"] = function(Player, AbilityData, ExtraData)

			AnimationService.PlayAnimation(Player, "Party Table", "Stop")
			
			DebounceAPI.ApplyCooldown(Player, script.Name, "SecondAbility")
			StateLibrary.ModifyState(Player, "Charging", false)
		end,
	},
	
	["ThirdAbility"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)
			local Character = Player.Character
			

			StateLibrary.ModifyState(Player, "Charging", true)

			NetworkStream.FireAllClients(Character, "Effect", 700, {
				Character = Character,

				Category = "Black Leg",
				Function = "Spectre",

				AbilityData = AbilityData,

				TargetCFrame = ExtraData.Hit,
				Range = AbilityData.Range,

				Status = "Release"
			})
			
			for Index = 1,15 do
				local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})

				if not StateLibrary.CheckState(Player, "Charging")  then return end 

				for _, ValidEntity in ipairs(ValidEntities) do 

					if Global.IsAlive(ValidEntity) then
						local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)


						local VRoot,VHum = ValidEntity:FindFirstChild("HumanoidRootPart"),ValidEntity:FindFirstChild("Humanoid")

						if not VRoot or not VHum then continue end

						local BodyVelocity = Instance.new("BodyVelocity")
						BodyVelocity.MaxForce = Vector3.new(4e4,4e4,4e4);
						BodyVelocity.Velocity = (VRoot.CFrame.p - Character.PrimaryPart.CFrame.p).Unit * 8
						BodyVelocity.Parent = Character.PrimaryPart
						Debris:AddItem(BodyVelocity,.25)					

						local Look = CFrame.new(VRoot.Position,Character.PrimaryPart.Position).lookVector

						local BodyVelocity = Instance.new("BodyVelocity")
						BodyVelocity.MaxForce = Vector3.new(4e4,0,4e4)
						BodyVelocity.Velocity = Look * -10
						BodyVelocity.Parent = VRoot
						Debris:AddItem(BodyVelocity,.2)		

					end
				end

				wait(.1)
			end
			

			StateLibrary.ModifyState(Player, "Charging", true)

		end,

		["Release"] = function(Player, AbilityData, ExtraData)

			DebounceAPI.ApplyCooldown(Player, script.Name, "ThirdAbility")
			StateLibrary.ModifyState(Player, "Charging", false)
		end,
	},

	["FourthAbility"] = function(Player, AbilityData, ExtraData)
		
		local Character = Player.Character
		
		NetworkStream.FireAllClients(Character, "Effect", 100000, {
			Character = Character,

			Category = "Black Leg",
			Function = "Diambe Jiambe",

			AbilityData = AbilityData,

			TargetCFrame = ExtraData.Hit,
			Range = AbilityData.Range,

			Status = "Charge"
		})
		
		
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