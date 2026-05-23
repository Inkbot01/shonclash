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

local args = RaycastParams.new()
args.FilterType = Enum.RaycastFilterType.Exclude
args.FilterDescendantsInstances = { workspace.Ignore }

local ti4 = TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)

local connections = {}
function disconnect()
	for i, v in next, connections do
		v:Disconnect()
	end
end

return function(Character, Input, MoveState, PerformMove, Timer, Modules)
	if MoveState:InCooldown() then
		return false
	end
	if not Character.Parent then
		return false
	end

	--[[ Remove this if the move is a combo extender ]]
	--
	if Character.States:GetAttribute("CanExtend") == true then
		return false
	end
	--[[ Remove this if the move is a combo extender ]]
	--

	local Mouse = workspace.PlayerMice[Character.Name]
	local Root = Character.HumanoidRootPart
	local MoveInfo = Modules.HellflameInfo.IgnitedArrow

	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false }) then
			return
		end
		Character.States:SetAttribute("IsCasting", true)
		local Cleaner = PerformMove()
		local opos = Character.HumanoidRootPart.Position

		local Arrow_Weld = Models.Hellflame.IgnitedArrow.Arrow_Weld:Clone()
		Arrow_Weld.attach.Part0 = Character["Right Arm"]
		Arrow_Weld.Parent = Character

		local BurnSfx = SFX.Quirks.Hellflame.IgnitedArrow.BurningSFX:Clone()
		BurnSfx.Parent = Arrow_Weld.Anchor
		BurnSfx:Play()

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 1, 1) * 4e5
		bv.Velocity = Vector3.new(0, 0.001, 0)
		bv.Parent = Root
		bv.Name = "Holding_Move_BV"

		Modules.AnimationHandler.Play(Character, "IgnitedArrow")
		MoveState:Set("Min", os.clock() + 0.7)

		local bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1, 1, 1) * 4e4
		bg.CFrame = Root.CFrame
		bg.P = 3e4
		bg.Parent = Root
		bg.Name = "Holding_Move_BG"
		MoveState:Set("HOLD_FACE_KEY", `IGNITE_ARROW_HOLD_{Character.Name}`)
		RunService:BindToRenderStep(MoveState:Get("HOLD_FACE_KEY"), 1, function()
			bg.CFrame = CFrame.lookAt(opos, Mouse.Position)
		end)

		Timer.Wait(0.7)
		Modules.AnimationHandler.AdjustSpeed(Character, "IgnitedArrow", 0)
	elseif Input.InputState == Enum.UserInputState.End then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsBlocking = false }) then
			return false
		end
		MoveState:SetCooldown(MoveInfo.Cooldown)
		if Root:FindFirstChild("Holding_Move_BG") == nil then
			return
		end
		Character.States:SetAttribute("IsCasting", false)

		local Duration = MoveState:Get("Min") - os.clock()
		print(Duration)
		if Duration > 0.01 then
			Timer.Wait(Duration)
		end

		local Arrow = Character:FindFirstChild("Arrow_Weld")
		Arrow.Parent = workspace.Ignore

		task.delay(3, function()
			if MoveState:Get("Done") == true then
				return
			end
			Arrow:Destroy()
		end)

		Modules.AnimationHandler.AdjustSpeed(Character, "IgnitedArrow", 1)
		MoveState:Set("Released", true)

		Timer.Wait(0.2)

		local ThrowSfx = SFX.Quirks.Hellflame.IgnitedArrow.ThrowSFX:Clone()
		ThrowSfx.PlayOnRemove = true
		ThrowSfx.Parent = Character["Right Arm"]
		ThrowSfx:Destroy()

		local ThrowVfx = Particles.Hellflame.IgnitedArrow.Release:Clone()
		ThrowVfx.CFrame = Character.HumanoidRootPart.CFrame
		ThrowVfx.Parent = workspace.Ignore
		game.Debris:AddItem(ThrowVfx, 1)

		for i, v in next, ThrowVfx.Attachment:GetChildren() do
			v:Emit(v:GetAttribute("EmitCount"))
		end

		if LocalPlayer.Character == Character then
			Modules.Common.CameraShaker({
				Location = Character.HumanoidRootPart,
				Magnitude = 1,
				Damp = 0.01,
			})
		end

		RunService:UnbindFromRenderStep(MoveState:Get("HOLD_FACE_KEY"))

		local Cleaner = PerformMove({ MousePosition = Mouse.Position })

		local Holding_Move_BV, Holding_Move_BG =
			Root:FindFirstChild("Holding_Move_BV"), Root:FindFirstChild("Holding_Move_BG")
		if Holding_Move_BG ~= nil then
			game.Debris:AddItem(Holding_Move_BG, 0.5)
		end

		if Arrow:FindFirstChild("attach") ~= nil then
			Arrow.attach:Destroy()
		end

		Holding_Move_BV:Destroy()

		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 4e4
		BodyVelocity.Velocity = Character.HumanoidRootPart.CFrame.LookVector * -34
		BodyVelocity.Parent = Character.HumanoidRootPart
		BodyVelocity.Name = "Knockback"
		game.Debris:AddItem(BodyVelocity, 0.3)

		local CFrameValue = Instance.new("CFrameValue")
		CFrameValue.Value = Arrow:GetPrimaryPartCFrame()

		CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
			if Arrow.Parent == nil then
				CFrameValue:Destroy()
				return
			end
			Arrow:SetPrimaryPartCFrame(CFrameValue.Value)
		end)

		local tween = TweenService:Create(
			CFrameValue,
			TweenInfo.new(
				(CFrame.new(Root.Position, Mouse.Position) * CFrame.new(0, 0, -3).Position - Mouse.Position).Magnitude
					/ 110
			),
			{
				Value = CFrame.lookAt(Mouse.Position, Vector3.new(Root.Position.X, Root.Position.Y, Root.Position.Z))
					* CFrame.Angles(math.rad(90), 0, 0),
			}
		)
		tween:Play()
		tween:Destroy()

		tween.Completed:Connect(function()
			MoveState:Set("Done", true)
			if Arrow.Parent == nil then
				return
			end
			task.delay(0.1, function()
				for i, v in next, Arrow:GetChildren() do
					tween = TweenService:Create(v, TweenInfo.new(0.25), { Transparency = 1 })
					tween:Play()
					tween:Destroy()
					for i, v2 in next, v:GetChildren() do
						if v2:IsA("ParticleEmitter") then
							v2.Enabled = false
						end
					end
				end
			end)

			for i, v in next, Arrow:GetChildren() do
				v.Anchored = true
			end
			CFrameValue:Destroy()
			local Explosion = Particles.Hellflame.IgnitedArrow.Arrow_Explosion.Attachment:Clone()
			Explosion.Parent = Arrow.Anchor
			for i, v in next, Explosion:GetChildren() do
				v:Emit(v:GetAttribute("EmitCount"))
			end
			local ExplodeSfx = SFX.Quirks.Hellflame.IgnitedArrow.Explode:Clone()
			ExplodeSfx.PlayOnRemove = true
			ExplodeSfx.Parent = Arrow.Anchor
			ExplodeSfx:Destroy()
			game.Debris:AddItem(Arrow, 3.85)

			Modules.Common.CameraShaker({
				Location = Explosion.WorldPosition,
				Magnitude = 3,
				Damp = 0.04,
			})

			local Hitbox = Modules.Hitbox.Radius({
				Radius = 6,
				Position = Mouse.Position,
			})
			Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
			Hitbox.Params.FilterDescendantsInstances = { workspace.Interactable, workspace.PlayerMice, Character }
			Hitbox.OnHit:Connect(function(Hit)
				if Hit.States:GetAttribute("IFRAMES") ~= 0 then
					return
				end
				if PlayerService:GetPlayerFromCharacter(Hit) ~= nil then
					clearForces(Hit.HumanoidRootPart, "BodyVelocity")
					clearForces(Hit.HumanoidRootPart, "BodyPosition")
					local BodyVelocity = Instance.new("BodyVelocity")
					BodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
					BodyVelocity.Name = "Knockback"
					BodyVelocity.Velocity = (
						Hit.HumanoidRootPart.CFrame.Position - Character.HumanoidRootPart.CFrame.Position
					).Unit * math.random(-25, 25) + Hit.HumanoidRootPart.CFrame.UpVector * 25
					BodyVelocity.Parent = Hit.HumanoidRootPart

					game.Debris:AddItem(BodyVelocity, 0.2)
				end
				Modules.StateManager.IncreaseHitCounter(Character)
				Modules.DamageIndicator({
					Character = Hit,
					Text = Modules.GetDamageFromMastery(
						PlayerService:GetPlayerFromCharacter(Character),
						MoveInfo.BaseDamage,
						"Quirk"
					),
				})
			end)
			Hitbox:Calculate(1, 1)
		end)
	end
end
