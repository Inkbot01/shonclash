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


local function u3(MoveDirection)
	local v7 = true;
	if not (MoveDirection.magnitude < 0.05) then
		v7 = true;
		if MoveDirection == MoveDirection then
			v7 = math.abs(MoveDirection.Y) > 10;
		end;
	end;
	print(v7)
	return v7;
end;


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
		
		local HitSound = ReplicatedStorage.Assets.Sounds:WaitForChild("Swing"):Clone()

		HitSound.Parent = Character.HumanoidRootPart
		HitSound:Play()
		Debris:AddItem(HitSound, HitSound.TimeLength)
		

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
					
					AnimationService.PlayAnimation(ValidEntity, "HitReaction"..math.random(1,3), "Play")
					--	local TargetTrack = ValidEntity.Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Shared.HitReaction["HitReaction"..GlobalInformation.KeysLogged])
					--TargetTrack:Play()
				end
			end

		end
		
		GlobalInformation.LastPressed = os.clock()

		if GlobalInformation.KeysLogged == 4 then 
			StateLibrary.ModifyState(Player, "Attacking", 1)
			GlobalInformation.KeysLogged = 0
		else
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
	
	
	["FirstAbility"] = function(Player, AbilityData, ExtraData)
		
		local Character = Player.Character
		local Humanoid = Character.Humanoid
		
		
		StateLibrary.ModifyState(Player, "Charging", true)
		StateLibrary.ModifyState(Player, "Speed", 1, {
			Priority = 1,
			WalkSpeed = 1,
			JumpPower = 0
		})
		
		AnimationService.PlayAnimation(Player, "FireSpear", "Play")
		
		local Lifetime = 8
		local Velocity = 45
		


		local StartPosition = Character.HumanoidRootPart.CFrame * CFrame.new(1,.5,-2) 
		local EndPosition = Character.PrimaryPart.CFrame * CFrame.new(0,0,Lifetime * Velocity) 
		
		local Direction = (StartPosition.Position - EndPosition.Position).Unit
		local Points = RaycastService:GetSquarePoints(StartPosition, 3.5, 3.5)
		
	
		NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
			Character = Player.Character,
			Category = "Endeavor",

			Function = "Fire Spear",

			
			Lifetime = Lifetime,
			Velocity = Velocity,
			
			Direction = Direction,
			
			
			AbilityData = AbilityData,
		})
	
		
		
		task.delay(.75, function()
			

			--	local StartPosition = Character.HumanoidRootPart.CFrame * CFrame.new(1,.5,-2) 
			local StartPosition = Character.HumanoidRootPart.CFrame * CFrame.new(1,.5,-2) * CFrame.Angles(math.rad(-90),math.rad(180),0)
			local EndPosition = Character.HumanoidRootPart.CFrame * CFrame.new(0,0,Lifetime * Velocity) 

			local Direction = (StartPosition.Position - EndPosition.Position).Unit
			local Points = RaycastService:GetSquarePoints(StartPosition, 3.5, 3.5)
			
			RaycastService:CastProjectileHitbox({
				Points = Points,

				Direction = Direction,

				Velocity = Velocity, 
				Lifetime = Lifetime, 

				Iterations = 75, 
				Visualize = false, 

				Function = function(RaycastResult) 					
					local ValidTarget = RaycastResult.Instance
					
				
					
					if ValidTarget:IsA("BasePart")  then
						
						local ValidEntities = HitboxLibrary.GetEntitiesInRadius(RaycastResult.Position, 20, false, {[Character] = true})
						
						for _, ValidEntity in pairs(ValidEntities) do 
							local DistanceFromCenter = (ValidEntity.HumanoidRootPart.Position - RaycastResult.Position).magnitude
							
							local CalculatedDamage = DistanceFromCenter > 6 and AbilityData.Damage/8 or AbilityData.Damage
							
							if ValidEntity.Humanoid.Health - CalculatedDamage <= 0 then
								StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", 5)
								task.delay(1.25, function()
									DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name, AbilityData, CalculatedDamage)
								end)
								
								continue
							end
						

							StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", 1.5)

							local ForwardVelocity = Instance.new("BodyVelocity")
							ForwardVelocity.MaxForce = Vector3.new(1,1,1) * 65000
							ForwardVelocity.Parent = ValidEntity.HumanoidRootPart
							ForwardVelocity.Velocity = ((Character.HumanoidRootPart.CFrame.LookVector * 12) + (Character.HumanoidRootPart.CFrame.upVector * 5)) * 3
							Debris:AddItem(ForwardVelocity, .5)



							RagdollManager.DurationRagdoll(ValidEntity, 1.5)
							
						end
						
					end
				
				end,
				Ignore = {Character, workspace.World.Visuals}
			})
		end)
		
		
		StateLibrary.ModifyState(Player, "Charging", false)
		StateLibrary.ModifyState(Player, "Endlag", 1.5)
		
		DebounceAPI.ApplyCooldown(Player, script.Name, "FirstAbility")
	end,
		
		--[[
		["Charge"] = function(Player, AbilityData, ExtraData)
			local Character = Player.Character

		--	local anim = AnimationService.PlayAnimation(Player, "ChidoriStartUp", "Play")
			
			--> add start up
			
			local Character = Player.Character
			local Humanoid = Character.Humanoid
			
			local FireSpearAnimation = ReplicatedStorage.Assets.Animations.Shared.Skills.Endeavor.FireSpear
			
			local Track = Humanoid:LoadAnimation(FireSpearAnimation)
			
			
			StateLibrary.ModifyState(Player, "Charging", true)
			StateLibrary.ModifyState(Player, "Speed", 1, {
				Priority = 1,
				WalkSpeed = 1,
				JumpPower = 0
			})
			
			
			local AnimationMarkerReached1 = nil
			local AnimationStopped = nil
			
			Track:Play()
			
			

			AnimationMarkerReached1 = Track:GetMarkerReachedSignal("Throw"):Connect(function()
				Track:AdjustSpeed(0)
				AnimationMarkerReached1:Disconnect()
				
				
				NetworkStream.FireAllClients(Player.Character, "Effect", 100, {
					Character = Player.Character,
					Category = "Endeavor",

					Function = "Fire Spear",

					Status = "Charge",

					AbilityData = AbilityData,
				})

			end)
				
				
			
		end,
		
		["Release"] = function(Player, AbilityData, ExtraData)
			
			local Character = Player.Character
			local Humanoid = Character.Humanoid
			
			
			
			
			local Points = RaycastService:GetSquarePoints( Character["Right Arm"].CFrame * CFrame.new(-5, -1.35, 0) *  CFrame.Angles(math.rad(180), math.rad(-90), 0), 4, 4)
			
			local StartPosition = Character["Right Arm"].CFrame * CFrame.new(-5, -1.35, 0) *  CFrame.Angles(math.rad(180), math.rad(-90), 0)
			
			local EndPosition = StartPosition * CFrame.new(0, 0, -5 * 80)
			
			--local StartPosition = Character["HumanoidRootPart"].CFrame * CFrame.new(1, 1, 1)
			--local EndPosition = StartPosition * CFrame.new(0, 0, -80 * 5)
			RaycastService:CastProjectileHitbox({
				Points = Points,

				Direction = (StartPosition.Position - EndPosition.Position).Unit,

				Velocity = 80, 
				Lifetime = 5, 

				Iterations = 75, 
				Visualize = true, 

				Function = function(RaycastResult) 					
					local ValidTarget = RaycastResult.Instance
					local EnemyList = HitboxLibrary.GetEntitiesInRadius(RaycastResult.Position, 25, false, {[Character] = Character})

					for _, Enemy in ipairs(EnemyList) do 
						DamageAPI.InflictDamage(Character, Enemy, AbilityData, script.Name)
					end
				end,
				Ignore = {Character, workspace.World.Visuals}
			})
			

			NetworkStream.FireAllClients(Player.Character, "Effect", 1000, {
				Character = Player.Character,

				Category = "Endeavor",

				Function = "Fire Spear",
				
				Status = "Release",
				
				Velocity = 80,
				Lifetime = 5,

				Direction = (StartPosition.Position - EndPosition.Position).Unit, 
				EndPosition = EndPosition,
				AbilityData = AbilityData,
			})
			
			for _, Track in pairs(Humanoid:GetPlayingAnimationTracks()) do 
				if Track.Name == "FireSpear" then
					Track:AdjustSpeed(1)
				end
			end

			
			StateLibrary.ModifyState(Player, "Charging", false)
			
			DebounceAPI.ApplyCooldown(Player, script.Name, "FirstAbility")
		
		end,
	},
	--]]
	["SecondAbility"] = function(Player, AbilityData, ExtraData)
		local Character = Player.Character
		
		AnimationService.PlayAnimation(Player, "FireGrabAttempt", "Play")
		
		--[[
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.MaxForce = Vector3.new(1,1,1) * 40000
		BodyVelocity.Velocity = Character.HumanoidRootPart.CFrame.lookVector * 30
		BodyVelocity.Name = "GrabMover"
		BodyVelocity.Parent = Character.HumanoidRootPart
		
		Debris:AddItem(BodyVelocity,.5)
		--]]
		
		StateLibrary.ModifyState(Player, "Casting", .5)
		
		coroutine.wrap(function()
			local WeldHitbox = Instance.new("Part")
			WeldHitbox.CFrame = Character["Right Arm"].CFrame
			WeldHitbox.Size = Vector3.new(3, 3, 5)
			WeldHitbox.Transparency = 1
			WeldHitbox.Color = Color3.fromRGB(255, 10, 96)
			WeldHitbox.CanCollide = false
			WeldHitbox.Name = "Hitbox"
			WeldHitbox.Parent = workspace.World.Visuals

			local WeldConstraint = Instance.new("WeldConstraint")
			WeldConstraint.Part0 = Character["Left Arm"]
			WeldConstraint.Part1 = WeldHitbox
			WeldConstraint.Parent = Character["Left Arm"]

			Debris:AddItem(WeldConstraint, .5)
			Debris:AddItem(WeldHitbox, .5)
			
			local TouchedConnection 
			
			coroutine.wrap(function()
				local StartTime = os.clock()
				local OSTime_1 = tick()
				
				local LastDirection = Character.HumanoidRootPart.CFrame.lookVector
				
				local UserGrabVFX = ReplicatedStorage.Assets.Particles.Endeavor.UserGrab:Clone()
				UserGrabVFX.CFrame = Character["Left Arm"].CFrame
				UserGrabVFX.Parent = workspace.World.Visuals
				
				Debris:AddItem(UserGrabVFX, .45)
				
				local GrabStartUp = ReplicatedStorage.Assets.Sounds.Endeavor.GrabStartup:Clone()
				GrabStartUp.Parent = Character.HumanoidRootPart
				
				GrabStartUp:Play()
				
				Debris:AddItem(GrabStartUp, GrabStartUp.TimeLength)
				
				local WeldConstraint = Instance.new("WeldConstraint")
				WeldConstraint.Part0 = Character["Left Arm"]
				WeldConstraint.Part1 = UserGrabVFX
				WeldConstraint.Parent = UserGrabVFX
				
				while true do
					game:GetService("RunService").Heartbeat:Wait()

					if StateLibrary.CheckState(Player, "Stunned") or StateLibrary.CheckState(Player, "Charging")  then
						break
					end



					if workspace:FindPartOnRayWithIgnoreList(Ray.new(
						Character.HumanoidRootPart.Position, Character.HumanoidRootPart.CFrame.LookVector * 2
						), {workspace.World.Visuals, Character}) then 
						break 
					end

					if (0.25 < (tick() - OSTime_1)) then

						break
					end


					Character.HumanoidRootPart.Velocity = LastDirection * 42 * (4.25 * math.max(0.001, 1 - (tick() - OSTime_1) / .35)) 
					
					print("running")
				end

			end)()
			
			
			TouchedConnection = WeldHitbox.Touched:Connect(function(Target)

				local Humanoid = Target.Parent:FindFirstChild("Humanoid")

				if Humanoid and Target.Parent ~= Character then
					
					Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
					
					TouchedConnection:Disconnect()
					local ValidEntity = Humanoid.Parent

					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity,"Stunned",2.85)
					StateLibrary.ModifyState(Player, "Charging", true)

					Global.ClearAllBodyMovers(ValidEntity.HumanoidRootPart)
					Global.ClearConnections(Character.HumanoidRootPart)
					
					task.wait(.15)
					
					ValidEntity.HumanoidRootPart.CFrame  = Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3.05) * CFrame.Angles(0,math.rad(-180),0)
					
					ValidEntity.HumanoidRootPart.Anchored = true
					Character.HumanoidRootPart.Anchored = true
					
					--local WeldConstraint = Instance.new("WeldConstraint")
				--	WeldConstraint.Part0 = Character.PrimaryPart
					--WeldConstraint.Part1 = ValidEntity.PrimaryPart
					
					--WeldConstraint.Parent = ValidEntity.PrimaryPart

					--Debris:AddItem(WeldConstraint,1.85)

					Character.Humanoid.AutoRotate = false

					StateLibrary.ModifyState(Player, "Speed", 1.85, {
						Priority = 1,
						WalkSpeed = 0,
						JumpPower = 0
					})

					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", 2.85, {
						Priority = 1,
						WalkSpeed = 0,
						JumpPower = 0
					})
					
				
					
					AnimationService.PlayAnimation(ValidEntity, "GrabReaction", "Play")
					
					task.wait(.25)

					NetworkStream.FireAllClients(Player.Character, "Effect", 1000, {
						Character = Player.Character,

						Category = "Endeavor",
						Function = "Fire Grab",

						Target = ValidEntity,
						AbilityData = AbilityData,
					})
					
					AnimationService.PlayAnimation(Player, "FireGrabSuccess", "Play")
					

					local HitSound = ReplicatedStorage.Assets.Sounds.Endeavor.FireGrab:Clone()

					HitSound.Parent = Character.HumanoidRootPart
					HitSound:Play()
					Debris:AddItem(HitSound, HitSound.TimeLength)
					
					for i = 0, 1, .25 do 
						DamageAPI.InflictDamage(Character, Target.Parent, AbilityData, script.Name)
						task.wait(.2)
					end
					
					
				

					task.wait(1)

					Character.Humanoid.AutoRotate = true
					StateLibrary.ModifyState(Player, "Charging", false)
					
					ValidEntity.HumanoidRootPart.Anchored = false
					Character.HumanoidRootPart.Anchored = false
				end
			end)
		end)()
		
		StateLibrary.ModifyState(Player, "Charging", false)
		DebounceAPI.ApplyCooldown(Player, script.Name, "SecondAbility")
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
		
		
		AnimationService.PlayAnimation(Player, "JetBurn", "Play")
		
		Character.Humanoid.AutoRotate = false
		
		StateLibrary.ModifyState(Player, "Speed", 2.75, {
			Priority = 1,
			
			WalkSpeed = 0,
			JumpPower = 0
		})
		--StateLibrary.ModifyState(Player, "Charging", true)
		
		task.delay(.5, function()
			NetworkStream.FireAllClients(Player.Character, "Effect", 1000, {
				Character = Player.Character,

				Category = "Endeavor",
				Function = "Jet Burn",

				AbilityData = AbilityData,
			})
			
			local JetBurnSound = ReplicatedStorage.Assets.Sounds.Endeavor.JetBurn:Clone()

			JetBurnSound.Parent = Character.HumanoidRootPart
			JetBurnSound:Play()
			Debris:AddItem(JetBurnSound, JetBurnSound.TimeLength)
			
			StateLibrary.ModifyState(Player, "Casting", 2.5)
			
			for i = 0, 2.35, .25 do 
				local ValidEntities = HitboxLibrary.GetEntitiesInPart((Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -25)).Position, Vector3.new(12, 12, 25), {[Character] = true})
			
				for _, ValidEntity in pairs(ValidEntities) do 
					DamageAPI.InflictDamage(Character, ValidEntity, AbilityData, script.Name)
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", .4)
					
					StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", .4, {
						Priority = 1,
						WalkSpeed = 0,
						JumpPower = 0
					})
					
					AnimationService.PlayAnimation(ValidEntity, "HitReaction"..math.random(1,3), "Play")
					

					local JetHitSound = ReplicatedStorage.Assets.Sounds.Endeavor.JetBurnHit:Clone()

					JetHitSound.Parent = Character.HumanoidRootPart
					JetHitSound:Play()
					Debris:AddItem(JetHitSound, JetHitSound.TimeLength)

				end

				task.wait(.2)
			end
			
			
			Debris:AddItem(JetBurnSound, .1)
			
			local ValidEntities = HitboxLibrary.GetEntitiesInPart((Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -25)).Position, Vector3.new(12, 12, 25), {[Character] = true})
			for _, ValidEntity in pairs(ValidEntities) do 
				local ForwardVelocity = Instance.new("BodyVelocity")
				ForwardVelocity.MaxForce = Vector3.new(1,1,1) * 65000
				ForwardVelocity.Parent = ValidEntity.HumanoidRootPart
				ForwardVelocity.Velocity = ((Character.HumanoidRootPart.CFrame.LookVector * 12) + (Character.HumanoidRootPart.CFrame.upVector * 5)) * 3
				Debris:AddItem(ForwardVelocity, .5)
				
				RagdollManager.DurationRagdoll(ValidEntity, .5)
			end
			
			Character.Humanoid.AutoRotate = true
		end)
	
		
		
		DebounceAPI.ApplyCooldown(Player, script.Name, "FourthAbility")
	end,
	

	
	
	
}

return Superhuman