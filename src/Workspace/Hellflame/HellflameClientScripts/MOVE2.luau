local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PlayerService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Particles = Assets:WaitForChild("Particles")
local Models = Assets:WaitForChild("Models")
local SFX = ReplicatedStorage:WaitForChild("SFX")

local LocalPlayer = game.Players.LocalPlayer
local DebreeThings = ReplicatedStorage:WaitForChild("Debree")

local args = RaycastParams.new()
args.FilterType = Enum.RaycastFilterType.Exclude
args.FilterDescendantsInstances = { workspace.Ignore }

local connections = {}
function disconnect()
	for i, v in next, connections do
		v:Disconnect()
	end
end

function clearForces(parent, force, ignoreList)
	for i, v in next, parent:GetChildren() do
		if v:IsA(force) then
			if ignoreList and not table.find(ignoreList, v.Name) then
				v:Destroy()
				return
			end
			v:Destroy()
		end
	end
end

return function(Character, Input, MoveState, PerformMove, Timer, Modules)
	if MoveState:InCooldown() then
		return false
	end
	if not Character.Parent then
		return false
	end
	if Input.InputState ~= Enum.UserInputState.Begin then
		return
	end
	if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false }) then
		return false
	end

	--[[ Comment this if the move is a combo extender ]]
	--
	--if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]]
	--
	if Character.States:GetAttribute("CanExtend") == true then
		Character.States:SetAttribute("CanExtend", false)
	end

	local AlreadyHit = nil
	local MoveInfo = Modules.HellflameInfo.Incinerate

	MoveState:SetCooldown(MoveInfo.Cooldown)
	Modules.StateManager.Cast(Character, 2.5)
	Modules.AnimationHandler.Play(Character, "IncinerateStart")

	for i, v in next, Particles.Hellflame.Incinerate.ArmFire:GetChildren() do
		local clone = v:Clone()
		clone.Name = "FSDKOLFNSIODFJASDIOPFJASDIOPFJKASDOPFJSABURN"
		clone.Parent = Character["Left Arm"]
	end

	local DashTrail = Particles.Hellflame.Incinerate.DashTrail:Clone()
	local Weld = Instance.new("Weld")
	Weld.Part0 = DashTrail
	Weld.Part1 = Character.HumanoidRootPart
	Weld.Parent = DashTrail
	DashTrail.Parent = workspace.Ignore
	task.delay(0.35, function()
		for i, v in next, DashTrail:GetChildren() do
			v.Enabled = false
		end
		Timer.Wait(0.75)
		DashTrail:Destroy()
	end)

	Character.Humanoid.AutoRotate = false
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0

	clearForces(Character.HumanoidRootPart, "BodyVelocity")
	clearForces(Character.HumanoidRootPart, "BodyPosition")

	local function HitFX(Hit)
		if Hit.States:GetAttribute("IFRAMES") ~= 0 then
			return
		end
		if AlreadyHit ~= nil then
			return
		end
		AlreadyHit = Hit
		print(AlreadyHit)

		clearForces(Hit.HumanoidRootPart, "BodyVelocity")
		clearForces(Hit.HumanoidRootPart, "BodyPosition")

		local Cleaner = PerformMove({ ClientHit = Hit })

		Character.HumanoidRootPart.Anchored = true

		Modules.AnimationHandler.Play(Character, "IncinerateLanded")
		local VictimAnim = Hit.Humanoid:LoadAnimation(Assets.Animations.Quirks.Hellflame.IncinerateVictim)
		VictimAnim:AdjustSpeed(0.9)
		VictimAnim:Play()

		Timer.Wait(0.1)

		local GrabEffect = Particles.Hellflame.Incinerate.Grab:Clone()
		GrabEffect.Position = Hit.HumanoidRootPart.Position
		GrabEffect.Parent = workspace.Ignore
		game.Debris:AddItem(GrabEffect, 0.75)

		for i, v in next, GrabEffect:GetDescendants() do
			if v:IsA("ParticleEmitter") and v.Enabled == false then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end

		task.delay(0.2, function()
			if Hit ~= nil and Hit.Parent ~= nil then
				local BurnEffect = Particles.Hellflame.Incinerate.IncinerateBurn:Clone()
				BurnEffect.CFrame = Character["Left Arm"].CFrame
					* CFrame.new(0, Character["Left Arm"].Size.Y / -1.5, 0)
					* CFrame.Angles(0, math.rad(-90), 0)
				BurnEffect.Parent = workspace.Ignore
				task.delay(0.3, function()
					for i, v in next, BurnEffect:GetDescendants() do
						if v.Name == "red" then
							local Tween = Modules.BoatTween:Create(v, {
								Time = 0.1,
								EasingStyle = "EntranceExpressive",
								EasingDirection = "In",

								StepType = "Heartbeat",

								Goal = {
									Color = ColorSequence.new(Color3.fromRGB(5, 55, 255)),
								},
							})
							Tween:Play()
						end
					end
				end)
				for i = 0, 5 do
					Modules.DamageIndicator({
						Character = Hit,
						Text = Modules.GetDamageFromMastery(LocalPlayer, MoveInfo.BaseDamage, "Quirk"),
					})
					Modules.StateManager.IncreaseHitCounter(Character)
					Timer.Wait(0.075)
				end

				for i, v in next, BurnEffect:GetDescendants() do
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
					end
				end
				game.Debris:AddItem(BurnEffect, 0.5)

				local Explode = Particles.Hellflame.Incinerate.Explosion:Clone()
				Explode.CFrame = CFrame.lookAt(
					(Character["Left Arm"].CFrame * CFrame.new(0, Character["Left Arm"].Size.Y / -2, 0)).Position,
					(Character["Left Arm"].CFrame * CFrame.new(0, Character["Left Arm"].Size.Y / -2, 0)).Position
						+ Hit.Head.CFrame.LookVector
				) * CFrame.Angles(math.rad(45), 0, 0)
				Explode.Parent = workspace.Ignore
				game.Debris:AddItem(Explode, 3)
				for i, v in next, Explode:GetDescendants() do
					if v:IsA("ParticleEmitter") then
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end

				Modules.Common.CameraShaker({
					Location = Explode.Position,
					Magnitude = 2,
					Damp = 0.07,
				})
				--Modules.ImpactFrame()

				if PlayerService:GetPlayerFromCharacter(Hit) ~= nil then
					local BodyVelocity = Instance.new("BodyVelocity")
					BodyVelocity.MaxForce = Vector3.new(4e4, 0, 4e4)
					BodyVelocity.Velocity = (
						Hit.HumanoidRootPart.CFrame.Position - Character.HumanoidRootPart.CFrame.Position
					).Unit * 36
					BodyVelocity.Parent = Hit.HumanoidRootPart

					game.Debris:AddItem(BodyVelocity, 0.4)
				end

				Modules.DamageIndicator({
					Character = Hit,
					Text = Modules.GetDamageFromMastery(LocalPlayer, MoveInfo.BaseDamage2, "Quirk"),
				})
				Modules.StateManager.IncreaseHitCounter(Character)
			end
		end)
	end

	local Hitbox = Modules.Hitbox.Radius({
		Radius = 4,
		Position = Character.HumanoidRootPart.Position,
	})
	Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
	Hitbox.Params.FilterDescendantsInstances = { workspace.Interactable, workspace.PlayerMice, Character }
	Hitbox.OnHit:Connect(HitFX)
	Hitbox:Calculate()

	if AlreadyHit then
		Timer.Wait(1.5)
		Character.HumanoidRootPart.Anchored = false
		Character.Humanoid.AutoRotate = true
		Character.Humanoid.WalkSpeed = 9
		Character.Humanoid.JumpPower = 50

		for i, v in next, Character["Left Arm"]:GetChildren() do
			if v.Name == "FSDKOLFNSIODFJASDIOPFJASDIOPFJKASDOPFJSABURN" then
				for i, v2 in next, v:GetChildren() do
					v2.Enabled = false
				end
			end
		end
		Timer.Wait(0.75)
		for i, v in next, Character["Left Arm"]:GetChildren() do
			if v.Name == "FSDKOLFNSIODFJASDIOPFJASDIOPFJKASDOPFJSABURN" then
				v:Destroy()
			end
		end
		return
	end

	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.new(4e4, 0, 4e4)
	BodyVelocity.Velocity = Character.HumanoidRootPart.CFrame.LookVector * 50
	BodyVelocity.Parent = Character.HumanoidRootPart
	game.Debris:AddItem(BodyVelocity, 0.2)

	Timer.Wait(0.3)

	local Hitbox = Modules.Hitbox.Radius({
		Radius = 6,
		Position = Character.HumanoidRootPart.Position,
	})
	Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
	Hitbox.Params.FilterDescendantsInstances = { workspace.Interactable, workspace.PlayerMice, Character }
	Hitbox.OnHit:Connect(HitFX)
	Hitbox:Calculate()

	Timer.Wait(0.2)
	Character.HumanoidRootPart.Anchored = false
	Character.Humanoid.AutoRotate = true
	Character.Humanoid.WalkSpeed = 9
	Character.Humanoid.JumpPower = 50

	for i, v in next, Character["Left Arm"]:GetChildren() do
		if v.Name == "FSDKOLFNSIODFJASDIOPFJASDIOPFJKASDOPFJSABURN" then
			for i, v2 in next, v:GetChildren() do
				v2.Enabled = false
			end
		end
	end
	Timer.Wait(0.75)
	Character.Humanoid.AutoRotate = true
	Timer.Wait(0.25)
	for i, v in next, Character["Left Arm"]:GetChildren() do
		if v.Name == "FSDKOLFNSIODFJASDIOPFJASDIOPFJKASDOPFJSABURN" then
			v:Destroy()
		end
	end
end
