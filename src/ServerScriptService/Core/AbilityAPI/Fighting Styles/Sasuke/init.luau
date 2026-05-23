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

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {}
raycastParams.FilterType = Enum.RaycastFilterType.Include
local Global = require(ReplicatedStorage.Global)


local function RaycastFunction(StartPosition, EndPosition, Distance, Object)
	local Raycast = Ray.new(StartPosition, CFrame.new(StartPosition, EndPosition).LookVector * Distance)
	local Target, Position, Surface = workspace:FindPartOnRayWithIgnoreList(Raycast, {
		workspace.World.Visuals,
		Object
	})
	return Target, Position, Surface
end

local function GetNearestFromMouse(Character, Range,Mouse)	
	local MouseHit = Mouse ~= nil and Mouse or MouseRemote:InvokeClient(Players:GetPlayerFromCharacter(Character))

	for _, Entity in ipairs(workspace.World.Entities:GetChildren()) do
		if Entity:IsA("Model") and Global.IsAlive(Entity) and Entity ~= Character then
			local EntityPrimary = Entity:FindFirstChild("HumanoidRootPart")
			local Distance = (MouseHit.Position - EntityPrimary.Position).Magnitude

			if Distance <= Range then 
				return Entity or nil
			end
		end
	end
end

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
	--	StateLibrary.ModifyState(Player, "Casting", .145)



		CameraRemote:FireClient(Player,{
			Function = "SwayCamera"
		})

		--> If Keys are less 

		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged >= 4 and 0 or GlobalInformation.KeysLogged

		--> Add Keys
		GlobalInformation.KeysLogged = GlobalInformation.KeysLogged + 1

		

		AnimationService.PlayAnimation(Player, Player.Data.EquippedWeapon.Value ~= "" and Player.Data.EquippedWeapon.Value..GlobalInformation.KeysLogged or "Punch"..GlobalInformation.KeysLogged, "Play", {Speed = 1.1})
		
		local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
	
		
		if GlobalInformation.KeysLogged < 4 then
			StateLibrary.ModifyState(Player, "Speed", .6, {
				Priority = 1,

				WalkSpeed = 12,
				JumpPower = 0
			})
			
		else
			StateLibrary.ModifyState(Player, "Speed", .75, {
				Priority = 1,

				WalkSpeed = 0,
				JumpPower = 0
			})
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,

				Category = "Sasuke",

				Function = "Swing",

				AbilityData = AbilityData,
			})

		end
		

		local SwingTime = ReplicatedStorage.Assets.Sounds.Swing:Clone()
		SwingTime.Parent = workspace.World.SFX

		SwingTime:Play()
		game.Debris:AddItem(SwingTime, SwingTime.TimeLength)
		
		
		
		for _, ValidEntity in ipairs(ValidEntities) do 
			local Harmed =	DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
	
			
			if Harmed and Global.IsAlive(ValidEntity) then
			
				
			
				
				if not StateLibrary.CheckState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Blocking")  and GlobalInformation.KeysLogged == 4 then
					RagdollManager.DurationRagdoll(ValidEntity, 1.2)
					
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "IFrame", 1.2)

					local ForwardVelocity = Instance.new("BodyVelocity")
					ForwardVelocity.MaxForce = Vector3.new(1,1,1) * 65000
					ForwardVelocity.Parent = ValidEntity.HumanoidRootPart
					ForwardVelocity.Velocity = ((Character.HumanoidRootPart.CFrame.LookVector * 8) + (Character.HumanoidRootPart.CFrame.upVector * 4.5)) * 4.2
					Debris:AddItem(ForwardVelocity, .2)

					
					
				else
					
					local PlayerBodyVelocity = Instance.new("BodyVelocity")
					PlayerBodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
					PlayerBodyVelocity.Parent = Character.HumanoidRootPart
					PlayerBodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * 5
					Debris:AddItem(PlayerBodyVelocity, .25)


					local EnemyBodyVelocity = Instance.new("BodyVelocity")
					EnemyBodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
					EnemyBodyVelocity.Parent = ValidEntity.HumanoidRootPart
					EnemyBodyVelocity.Velocity = Player.Character.HumanoidRootPart.CFrame.LookVector * 5
					Debris:AddItem(EnemyBodyVelocity, .25)
					
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", 1.125)
					

					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", 1.125, {
						Priority = 1,

						WalkSpeed = 4,
						JumpPower = 0
					})
				--	local TargetTrack = ValidEntity.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Shared.HitReaction["HitReaction"..GlobalInformation.KeysLogged])
					--TargetTrack:Play()
				end
			end

		end





		GlobalInformation.LastPressed = os.clock()


		if GlobalInformation.KeysLogged == 4 then 
			StateLibrary.ModifyState(Player, "Attacking", 1)

		--	local CantDash = Instance.new("IntValue")
		--	CantDash.Name = "CantDash"
		--	CantDash.Parent = Character
		--	Debris:AddItem(CantDash, .25)


			GlobalInformation.KeysLogged = 0
		else

			--local CantDash = Instance.new("IntValue")
			--CantDash.Name = "CantDash"
			--CantDash.Parent = Character
			--Debris:AddItem(CantDash, .75)

			StateLibrary.ModifyState(Player, "Attacking", AbilityData.Endlag)
		end



	

		DebounceAPI.ApplyCooldown(Player, script.Name, "Swing")
	end,
	
	
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
	
	["Block"] = {
		["Charge"] = function(Player, AbilityData, ExtraData)

			AnimationService.PlayAnimation(Player, Player.Data.EquippedWeapon.Value ~= "" and Player.Data.EquippedWeapon.Value.."Block" or "NormalBlock", "Play", {Loop = true})

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

			AnimationService.PlayAnimation(Player, Player.Data.EquippedWeapon.Value ~= "" and Player.Data.EquippedWeapon.Value.."Block" or "NormalBlock", "Stop")

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
			
			start_time = os.clock()
			local startAnim = ReplicatedStorage.Assets.Animations.Shared.Skills.Sasuke.ChidoriStartUp
			local Track = Character.Humanoid:LoadAnimation(startAnim)
			Track.Priority = Enum.AnimationPriority.Action
			Track:Play()
			local AnimationMarkerReached = nil
			local AnimationStopped = nil
			AnimationMarkerReached = Track:GetMarkerReachedSignal("Charge"):Connect(function()
				Track:AdjustSpeed(0)
				AnimationMarkerReached:Disconnect()

			end)
			AnimationStopped = Track.Stopped:Connect(function()
				AnimationStopped:Disconnect()
				AnimationMarkerReached:Disconnect()

			end)
			StateLibrary.ModifyState(Player, "Charging", true)
			StateLibrary.ModifyState(Player, "Speed", .85, {
				Priority = 1,
				WalkSpeed = 8,
				JumpPower = 0
			})
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,

				Category = "Sasuke",

				Function = "Chidori",

				Status = "Charge",


				AbilityData = AbilityData,
			})
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			repeat task.wait(.1) until os.clock() - start_time > script.ChargeTime.Value
		--	AnimationService.PlayAnimation(Player, "Kick"..GlobalInformation.KeysLogged, "Play", {Speed = 1.75})
			local Character = Player.Character
			local Humanoid = Character.Humanoid
			local root = Character.HumanoidRootPart
		--	local ValidEntities, HasEntities = HitboxLibrary.GetEntitiesInRadius(Character.PrimaryPart.Position, AbilityData.Range, false, {[Character] = true})
			local chidoriMovingCheck = Instance.new("NumberValue")
			chidoriMovingCheck.Value = 0
			local CurrentPlayingAnimations = Humanoid:GetPlayingAnimationTracks()
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,

				Category = "Sasuke",

				Function = "Chidori",

				Status = "Release",


				AbilityData = AbilityData,
			})
			for _, Track in pairs(CurrentPlayingAnimations) do
				if Track.Name == "ChidoriStartUp" then
					--Track:AdjustSpeed(1)
					task.spawn(function()
						task.wait(.3)
						StateLibrary.ModifyState(Player, "Speed", 4, {
							Priority = 1,

							WalkSpeed = 34,
							JumpPower = 0
						})
					local runAnim = ReplicatedStorage.Assets.Animations.Shared.Skills.Sasuke.ChidoriRun
					local Run = Character.Humanoid:LoadAnimation(runAnim)
						local ValueConnection; ValueConnection = chidoriMovingCheck:GetPropertyChangedSignal("Value"):Connect(function()
							if chidoriMovingCheck.Value == 1 then
								Track.Priority = Enum.AnimationPriority.Action
								Run:Stop()
							elseif chidoriMovingCheck.Value == 2 then
								Track.Priority = Enum.AnimationPriority.Core

								Run:Play()
							end
						end)
						local Clone = ReplicatedStorage.Assets.Models.ChidoriHitbox:Clone()
						Clone.Transparency = 1
						Clone.Parent = Character
						Clone.CFrame = root.CFrame * CFrame.new(0,0,-3)
						Clone.WeldConstraint.Part0 = root
						Debris:AddItem(Clone,4)
						local ChidoriHitVal = Instance.new("BoolValue")
						ChidoriHitVal.Name = "ChidoriHitVal"
						ChidoriHitVal.Value = false
						ChidoriHitVal.Parent = Character
						
						local chidoriVictim = Instance.new("StringValue")
						chidoriVictim.Name = "ChidoriVictim"
						chidoriVictim.Value = "None"
						chidoriVictim.Parent = ChidoriHitVal
						local Connection; Connection = Clone.Touched:Connect(function(Hit)
							if not Hit:IsDescendantOf(Character) and Hit:IsDescendantOf(workspace.World.Entities) then
								if Hit.Parent:FindFirstChild("Humanoid") and Hit.Parent.Humanoid.Health > 0 then
									local Victim = Hit.Parent
									local VHum,VRoot = Victim:FindFirstChild("Humanoid"), Victim:FindFirstChild("HumanoidRootPart")
									chidoriVictim.Value = Victim.Name
									ChidoriHitVal.Value = true
									Track:Stop()
									Run:Stop()
									Connection:Disconnect()
									Humanoid.AutoRotate = false
									local attackAnim = ReplicatedStorage.Assets.Animations.Shared.Skills.Sasuke.ChidoriHit
									local Attack = Character.Humanoid:LoadAnimation(attackAnim)
									Attack:AdjustSpeed(.8)
									Attack:Play()
									Clone:Destroy()
									task.delay(.2,function()
										DamageAPI.InflictDamage(Character, Victim, AbilityData, script.Name)

										if not StateLibrary.CheckState(Players:GetPlayerFromCharacter(Victim) or Victim, "Blocking") then
											RagdollManager.DurationRagdoll(Victim, 2)
											local BodyVelocity = Instance.new("BodyVelocity")
											BodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
											BodyVelocity.Parent = VRoot
											BodyVelocity.Velocity = root.CFrame.LookVector * 50
											Debris:AddItem(BodyVelocity, .25)
										end
										Humanoid.AutoRotate = true

									end)
									
								end
							end
						end)
						local runTime = os.clock()
						while os.clock() - runTime <= 4 and not (ChidoriHitVal.Value == true) do
							if Humanoid.MoveDirection == Vector3.new() then
								chidoriMovingCheck.Value = 1
							else
								chidoriMovingCheck.Value = 2
							end
							if ChidoriHitVal.Value == true then 
								break
							end	
							RunService.Heartbeat:Wait()
						end
						StateLibrary.ModifyState(Player, "Speed", .1, {
							Priority = 1,

							WalkSpeed = 16,
							JumpPower = 0
						})
						Track:Stop()
						Run:Stop()
						Debris:AddItem(ChidoriHitVal,1)
						chidoriMovingCheck:Destroy()
						StateLibrary.ModifyState(Player, "Charging", false)
						ValueConnection:Disconnect()
						ValueConnection = nil	
						Connection:Disconnect()
						Connection = nil
						task.delay(.4,function()
							ChidoriHitVal.Value = true
						end)

					end)
					return
				end

			end
			StatAPI.GiveMastery(Player, script.Name, 50)
		
			DebounceAPI.ApplyCooldown(Player, script.Name, "FirstAbility")
		end,
	},
	
	["SecondAbility"] = function(Player, AbilityData, ExtraData)
		local Character = Player.Character
		local Humanoid = Character.Humanoid
		local root = Character.HumanoidRootPart
		local startAnim = ReplicatedStorage.Assets.Animations.Shared.Skills.Sasuke.FumaShuriken
		local MouseHit = MouseRemote:InvokeClient(Player)
		local MousePos = MouseHit.p
		
		local Track = Character.Humanoid:LoadAnimation(startAnim)
		Track:Play()
		

		NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
			Character = Player.Character,

			Category = "Sasuke",

			Function = "Fuma Shuriken",
			
			Status = "Charge",

			AbilityData = AbilityData,
		})
		
		StateLibrary.ModifyState(Player, "Charging", true)
		StateLibrary.ModifyState(Player, "Speed", 1.35, {
			Priority = 1,
			WalkSpeed = 0,
			JumpPower = 0
		})
		
		local AnimationMarkerReached1 = nil
		local AnimationMarkerReached2 = nil
		local AnimationStopped = nil
		
		
		AnimationMarkerReached2 = Track:GetMarkerReachedSignal("Jump"):Connect(function()
			AnimationMarkerReached2:Disconnect()
			
			StateLibrary.ModifyState(Player, "Charging", false)

			task.spawn(function()

				local MAX_HEIGHT = 25
				local GoalPosition = root.Position + Vector3.new(0,MAX_HEIGHT,0)

				--[[ Raycast ]]--
				local StartPosition = root.Position
				local EndPosition = root.CFrame * CFrame.new(0,MAX_HEIGHT,0)

				local RayData = RaycastParams.new()
				RayData.FilterDescendantsInstances = {Character, workspace.World.Entities, workspace.World.Visuals} or workspace.World.Visuals
				RayData.FilterType = Enum.RaycastFilterType.Exclude
				RayData.IgnoreWater = true

				local ray = workspace:Raycast(StartPosition, EndPosition.Position, RayData)
				if ray then
					local partHit, pos, normVector = ray.Instance or nil, ray.Position or nil, ray.Normal or nil
					if partHit then
						MAX_HEIGHT = - Vector3.new(0,10,0)
						partHit = nil
						pos = nil
						normVector = nil
						ray = nil
					end
				end

				local BodyPosition = Instance.new("BodyPosition")
				BodyPosition.MaxForce = Vector3.new(1e5, 1e5, 1e5)
				BodyPosition.P = 200;
				BodyPosition.D = 35;
				BodyPosition.Parent = root
				BodyPosition.Position = GoalPosition
				BodyPosition.Name = "ShurikenBodyPos"

			end)

		end)
		
		AnimationMarkerReached1 = Track:GetMarkerReachedSignal("Throw"):Connect(function()
			AnimationMarkerReached1:Disconnect()
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
				Character = Player.Character,

				Category = "Sasuke",

				Function = "Fuma Shuriken",

				Status = "Release",

				AbilityData = AbilityData,
				Mouse = MousePos,
			})
			
			local RightArmCFrame = root.CFrame
			local Victim = GetNearestFromMouse(Character,8,ExtraData.Hit)
			
			local Direction = ((Victim ~= nil and Victim:FindFirstChild("HumanoidRootPart").Position or ExtraData.Hit.Position) - Character["Right Arm"].Position).Unit
			local Points = RaycastService:GetSquarePoints(RightArmCFrame,  6,  6)
			
			RaycastService:CastProjectileHitbox({
				Points = Points,

				Direction = Direction,

				Velocity = 700, 
				Lifetime = 2, 

				Iterations = 1, 
				Visualize = false, 

				Function = function(RaycastResult) 
				
					local ValidTarget = RaycastResult.Instance
					print(ValidTarget)
					print(ValidTarget.Parent)
					if ValidTarget.Parent:FindFirstChild("Humanoid") then
						DamageAPI.InflictDamage(Character, ValidTarget.Parent, AbilityData, script.Name)
						
						local Victim = ValidTarget.Parent
						task.delay(.6,function()
							root.CFrame = Victim.HumanoidRootPart.CFrame * CFrame.new(0,0,4)
							
							NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
								Character = Player.Character,
								Hit = true,
								
								Category = "Sasuke",

								Function = "Fuma Shuriken",

								Status = "Finish",

								AbilityData = AbilityData,
								Mouse = MousePos,
							})
							

						end)
					elseif ValidTarget:IsDescendantOf(workspace.Map) then
					
						print("touched the map")
						task.delay(1,function()
							
							NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
								Character = Player.Character,
								Hit = false,

								Category = "Sasuke",

								Function = "Fuma Shuriken",

								Status = "Finish",

								AbilityData = AbilityData,
								Mouse = MousePos,
							})
							--DO HITBOX RIGHT HERE--
							
							
							local EnemyList = HitboxLibrary.GetEntitiesInRadius(RaycastResult.Position, 20, false, {[Character] = Character})
							
							for _, Enemy in ipairs(EnemyList) do 
								DamageAPI.InflictDamage(Character, Enemy, AbilityData, script.Name)
							end
						end)
					end
					
			
					
				end,
				Ignore = {Character, workspace.World.Visuals}
			})
			
			
			
			_ = root:FindFirstChild("ShurikenBodyPos") and Debris:AddItem(root:FindFirstChild("ShurikenBodyPos"),.5)

		end)
		AnimationStopped = Track.Stopped:Connect(function()
			
			AnimationStopped:Disconnect()
			AnimationMarkerReached1:Disconnect()
			AnimationMarkerReached2:Disconnect()
			DebounceAPI.ApplyCooldown(Player, script.Name, "SecondAbility")


		end)


	end,
	
	["ThirdAbility"] = function(Player, AbilityData, ExtraData)
		print("up1")
		
		local Character = Player.Character
		local Humanoid = Character.Humanoid
	
		local FireballJutsu = ReplicatedStorage.Assets.Animations.Shared.Skills.Sasuke.FireballJutsu
		
		local Track = Humanoid:LoadAnimation(FireballJutsu)
		
		Track:Play()
		StateLibrary.ModifyState(Player, "Charging", true)
		StateLibrary.ModifyState(Player, "Speed", 1, {
			Priority = 1,
			WalkSpeed = 6,
			JumpPower = 0
		})

		local AnimationMarkerReached1 = nil
		local AnimationStopped = nil
		
		Track:Play()
		
		AnimationMarkerReached1 = Track:GetMarkerReachedSignal("Fire"):Connect(function()
		
			AnimationMarkerReached1:Disconnect()
			StateLibrary.ModifyState(Player, "Charging", false)
			
			
			local Direction = (ExtraData.Hit.Position - Character.PrimaryPart.CFrame.Position).Unit
			
			NetworkStream.FireAllClients(Player.Character, "Effect", 1000, {
				Character = Player.Character,

				Category = "Sasuke",

				Function = "Fireball Jutsu",
				
				Velocity = 80,
				
				Lifetime = 5,
				
				Direction = Direction, 
				
				AbilityData = AbilityData,
				Hit = ExtraData.Hit,
			})

			--local RightArmCFrame = root.CFrame
	
			
			local Points = RaycastService:GetSquarePoints(Character.PrimaryPart.CFrame, 6, 6)
			
			RaycastService:CastProjectileHitbox({
				Points = Points,

				Direction = Direction,

				Velocity = 80, 
				Lifetime = 5, 

				Iterations = 75, 
				Visualize = false, 
				
				Function = function(RaycastResult) 					
					local ValidTarget = RaycastResult.Instance
					


				
					local EnemyList = HitboxLibrary.GetEntitiesInRadius(RaycastResult.Position, 25, false, {[Character] = Character})

					for _, Enemy in ipairs(EnemyList) do 
						DamageAPI.InflictDamage(Character, Enemy, AbilityData, script.Name)
					end
				end,
				Ignore = {Character, workspace.World.Visuals}
			})



		end)
		AnimationStopped = Track.Stopped:Connect(function()

			AnimationStopped:Disconnect()
			AnimationMarkerReached1:Disconnect()
			DebounceAPI.ApplyCooldown(Player, script.Name, "ThirdAbility")


		end)


	end,

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