--|| Services ||--
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)
local Global = require(ReplicatedStorage.Global)



--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")
local StateLibrary = Directory.Import("StateLibrary", "Shared")

--> Utility
local Utility = Directory.Import("Utility", "Shared")

local AnimationLibrary = Directory.Import("AnimationService", "Shared")

local FormulaAPI = Directory.Import("FormulaAPI", "Shared")

local NetworkStream = Directory.Import("NetworkStream", "Shared")

local ReigsteredItems = Directory.Import('RegisteredItems', "Shared")

--|| Networking ||--
local AbilityRequest = ReplicatedStorage.Remotes.Ability
local Effects = ReplicatedStorage.Remotes.Effect

local Notify = ReplicatedStorage.Remotes.Notify

local DamageAPI = {}

local PartyHolder = ReplicatedStorage.Parties

local function IsPlayerInParty(Player)
	for _, Party in ipairs(PartyHolder:GetChildren()) do
		if Party:FindFirstChild(Player.Name) then 
			return true, Party:FindFirstChild(Player.Name).Value, Party.Name
		end
	end
end

function DamageAPI.ApplyKnockback(Target, KnockbackData)
	if not Global.IsAlive(Target)  then return end

	local TargetPrimaryPart = Target.PrimaryPart

	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = KnockbackData.Intensity or Vector3.new(4e4, 4e4, 4e4)
	BodyVelocity.Velocity = KnockbackData.Direction
	BodyVelocity.Parent =  TargetPrimaryPart

	if TargetPrimaryPart:FindFirstChild("AerialKnockback") then
		TargetPrimaryPart.AerialKnockback:Destroy()

	end

	Debris:AddItem(BodyVelocity, KnockbackData.Duration)
end

function DamageAPI.InflictDamage(Character, Target, AbilityData, CurrentlyHeldTool, OverrideDamage)
	if not Global.IsAlive(Character) or not Global.IsAlive(Target) then return end

	local TargetHumanoid = Target:FindFirstChild("Humanoid")
	
	local TargetPlayer = Players:GetPlayerFromCharacter(Target) 
	local InflicterPlayer = Players:GetPlayerFromCharacter(Character)
	

	--local CalculatedDamage =  InflicterPlayer and FormulaAPI.CalculateDamage(InflicterPlayer, AbilityData.Damage, InflicterPlayer.Data.Mastery[CurrentlyHeldTool].MasteryLevel.Value or 1 ) or AbilityData.Damage
	local CalculatedDamage = AbilityData.Damage
	
	--> is in same party
	if InflicterPlayer and TargetPlayer then
print('up')
		local _, _, InflicterPartyName =  IsPlayerInParty(InflicterPlayer)
		local _, _, TargetPartyName = IsPlayerInParty(TargetPlayer)

		if (InflicterPartyName and TargetPartyName)  and InflicterPartyName == TargetPartyName then
			return
		end
		
		
		
		--if (TargetPlayer.States.Safezone.Base.Value == true and  TargetPlayer.States.CombatLog.Base.Value ~= true) then
			
		--	Notify:FireClient(InflicterPlayer, {Text =  "<Font=GothamBold><Color=Red><AnimateStepFrequency=.3> Cannot attack players in safezone!", Duration = 1.25})
			--return
		--end
	end
	
	
	local IsBlocking = StateLibrary.CheckState(TargetPlayer or Target, "Blocking")
	
	local EntityStateData = TargetPlayer and TargetPlayer.States.Blocking or Target.States.Blocking
	
	if StateLibrary.CheckState(TargetPlayer or Target, "Knocked") then
		Target:BreakJoints()
	end
	if StateLibrary.CheckState(TargetPlayer or Target, "IFrame") and not AbilityData.BypassIFrame then return end 
	
	if IsBlocking and EntityStateData.Base.Value  then
	

		--> Parried
		if workspace:GetServerTimeNow() - EntityStateData.Begin.Value <= .2 then 

			--> update character effect for parrty
			
			StateLibrary.ModifyState(Players:GetPlayerFromCharacter(Character) or Character , "Stunned", 1.5)

			StateLibrary.ModifyState(Players:GetPlayerFromCharacter(Character) or Character, "Speed", 2, {
				JumpPower = 0,
				WalkSpeed = 8,

				Priority = .4
			})
			
			
		
			NetworkStream.FireAllClients(Character, "Effect", 200, 
				{Character = Character, 
					
					Target = Character, 
					
					Category = "Misc", 
					Function = "HitTingz", 
					
					Particle = "PerfectBlock",
					Sound = "Parry", 
					FillColor = Color3.fromRGB(170, 90, 226),
					AbilityData = AbilityData
				})
			
			--AnimationLibrary.PlayAnimation(Character, "PerfectBlock", "Play")
			
			return
		end



		--> Less than 1 Block/ Guardbreak
		if AbilityData.Guardbreak or EntityStateData.BlockAmount.Value - 1 <= 0 then
			
		
			
			EntityStateData.BlockAmount.Value = 0
			EntityStateData.Base.Value = false
			
			
			--guardbreak effect

			AnimationLibrary.PlayAnimation(Target, "NormalBlock", "Stop")
			AnimationLibrary.PlayAnimation(Target, "BlockBreak", "Play")

			StateLibrary.ModifyState(TargetPlayer, "Blocking", false)
			StateLibrary.ModifyState(TargetPlayer, "Stunned", 4)
			
			
			NetworkStream.FireAllClients(Character, "Effect", 200, {
				Character = Target, 
				
				Category = "Misc", 
				
				Function = "BlockBreak", 
			
				
				Sound = "Broken",
				
				AbilityData = AbilityData
			})
			
			NetworkStream.FireAllClients(Character, "Effect", 100, {
				Character = Target,

				Category = "Misc",
				Function = "Block",

				Status = "Release",
				AbilityData = AbilityData,
			})
			
			local BrokenBlockSound = ReplicatedStorage.Assets.Sounds.BlockBreak:Clone()

			BrokenBlockSound.Parent = Character.HumanoidRootPart
			BrokenBlockSound:Play()
			Debris:AddItem(BrokenBlockSound, BrokenBlockSound.TimeLength)
		--[[
			NetworkStream.FireAllClients(Character, "Effect", 50, {
				Character = Character,

				Target = Target,

				Category = "Misc",
				Function = "HitTingz",
				
				Particle = "BlockBreak", 
				Sound = "Broken",
				
				AbilityData = AbilityData,
			})
			--]]
		else
			--> More than 1 block


			EntityStateData.BlockAmount.Value = EntityStateData.BlockAmount.Value - 1
			
			
			
			NetworkStream.FireAllClients(Character, "Effect", 100, {
				Character = Target,

				Category = "Misc",
				Function = "Block",
				
				Status = "Update",
				
				BlockAmount = EntityStateData.BlockAmount.Value,
				MaxBlocks = EntityStateData.MaxBlocks.Value,
				
				AbilityData = AbilityData,
			})
			
			TargetHumanoid:TakeDamage(CalculatedDamage * .85)
		

			local BlockedEffectSound = ReplicatedStorage.Assets.Sounds.Blocked:Clone()

			BlockedEffectSound.Parent = Character.HumanoidRootPart
			BlockedEffectSound:Play()
			Debris:AddItem(BlockedEffectSound, BlockedEffectSound.TimeLength)
			
			
			--> Update block indicator effect

			return
		end


	end

	if TargetPlayer then
		
		if InflicterPlayer then
			StateLibrary.ModifyState(TargetPlayer, "CombatLog", 20, {LastAttackedBy = Character.Name})
		end
		

	elseif not TargetPlayer then
		local Data = Target:FindFirstChild("Data")
		if Data then 
			local DamageLog = Data:FindFirstChild("AttackLog")

			local PreviousLog = DamageLog:FindFirstChild(Character.Name)
			if PreviousLog then 
				--> add to previous log
				PreviousLog.Value = PreviousLog.Value + AbilityData.Damage
			else

				--> create new damage log
				local Attacker = Instance.new("NumberValue")
				Attacker.Name = Character.Name 
				Attacker.Value = AbilityData.Damage
				Attacker.Parent = DamageLog

			end
		end
	end
	
--[[
	NetworkStream.FireAllClients(Character, "Effect", 100, {
		Character = Character,

		Target = Target,

		Category = "Misc",
		Function = "DamageIndicator",

		AbilityData = {Damage = CalculatedDamage}
	})
--]]
	NetworkStream.FireAllClients(Character, "Effect", 100, {
		Character = Character,

		Target = Target,

		Category = "Misc",
		Function = "HitTingz",

		Particle = "HitEffect", 
		Sound = "Hit",

		AbilityData = AbilityData
	})
	
	
	
	if TargetHumanoid.Health > 0 and TargetHumanoid.Health <= (.3 * TargetHumanoid.MaxHealth) then
		NetworkStream.FireAllClients(Character, "Effect", 100, {
			Character = Character,

			Target = Target,

			Category = "Misc",
			Function = "BloodEffect",
			
			Health = TargetHumanoid.Health,
			
			AbilityData = AbilityData
		})

	end
	
	TargetHumanoid:TakeDamage(CalculatedDamage)
	
--	AnimationLibrary.PlayAnimation(Target, "Reaction"..math.random(1, 2), "Play")

	

	-->> damage indicator effect

	
	
	--> Damage Log COnnections
	
	
	
	return true
	
	--NetworkStream.FireOneClient(Players:GetPlayerFromCharacter(Character), "Notify", {Text = "<Font=SourceSansBold><Color=White><AnimateStepFrequency=1><AnimateStyle=Wiggle><AnimateStyleTime=.35>You dealt <Color=Green>100<Color=/> damage"})
	
	--StateLibrary.ModifyState(TargetPlayer, "Stunned", AbilityData.StunTime or .4)
	
end


return DamageAPI