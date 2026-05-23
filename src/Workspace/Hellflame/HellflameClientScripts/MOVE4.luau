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

local params = RaycastParams.new()
params.FilterDescendantsInstances = { workspace.Map }
params.FilterType = Enum.RaycastFilterType.Include

local ti4 = TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)

local t = tick
local function beamProjectile(g, v0, x0, t1)
	-- calculate the bezier points
	local c = 0.5 * 0.5 * 0.5
	local p3 = 0.5 * g * t1 * t1 + v0 * t1 + x0
	local p2 = p3 - (g * t1 * t1 + v0 * t1) / 3
	local p1 = (c * g * t1 * t1 + 0.5 * v0 * t1 + x0 - c * (x0 + p3)) / (3 * c) - p2

	-- the curve sizes
	local curve0 = (p1 - x0).magnitude
	local curve1 = (p2 - p3).magnitude

	-- build the world CFrames for the attachments
	local b = (x0 - p3).unit
	local r1 = (p1 - x0).unit
	local u1 = r1:Cross(b).unit
	local r2 = (p2 - p3).unit
	local u2 = r2:Cross(b).unit
	b = u1:Cross(r1).unit

	local cf1 = CFrame.new(x0.x, x0.y, x0.z, r1.x, u1.x, b.x, r1.y, u1.y, b.y, r1.z, u1.z, b.z)

	local cf2 = CFrame.new(p3.x, p3.y, p3.z, r2.x, u2.x, b.x, r2.y, u2.y, b.y, r2.z, u2.z, b.z)

	return curve0, -curve1, cf1, cf2, p1, p2, p3
end
function Lerp(a, b, c)
	return a + (b - a) * c
end

local tween1 = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)

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

	local Cleaner = PerformMove()
	local Mouse = workspace.PlayerMice[Character.Name]
	local Root = Character.HumanoidRootPart
	local MoveInfo = Modules.HellflameInfo.HellSlam
	local Humanoid = Character.Humanoid

	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false }) then
			return
		end
		Character.States:SetAttribute("IsCasting", true)
		local opos = Character.HumanoidRootPart.Position
		--game.Debris:AddItem(a1,6);game.Debris:AddItem(a2,6);game.Debris:AddItem(b,6);game.Debris:AddItem(w123,6)

		if LocalPlayer.Character == Character then
			local a1 = Assets.AimStuff.Part.at1:Clone()
			a1.Parent = Root
			local a2 = Assets.AimStuff.Part.at2:Clone()
			a2.Parent = Root
			local b = Assets.AimStuff.Part.Beam:Clone()
			b.Parent = Root
			b.Attachment0 = a1
			b.Attachment1 = a2
			local w123 = Assets.AimStuff.Circle:Clone()
			w123.Parent = Root

			w123.BillboardGui.Enabled = true
			task.spawn(function()
				while
					a1 ~= nil
					and a2 ~= nil
					and a1.Parent ~= nil
					and a2.Parent ~= nil
					and w123 ~= nil
					and w123.Parent ~= nil
					and Root ~= nil
					and Root.Parent ~= nil
					and b ~= nil
					and b.Parent ~= nil
				do
					local t = 0.95
					local g = Vector3.new(0, -game.Workspace.Gravity, 0)
					local x0 = Root.CFrame * Vector3.new(0, 2, -2)
					local v0 = (
						(
							((Root.Position - Mouse.Position).Magnitude > 75)
								and (Root.Position + (CFrame.new(Root.Position, Mouse.Position).LookVector * 75))
							or Mouse.Position
						)
						- x0
						- 0.5 * g * t * t
					) / t

					local curve0, curve1, cf1, cf2 = beamProjectile(g, v0, x0, t)
					b.CurveSize0 = curve0
					b.CurveSize1 = curve1
					w123.CFrame = cf2
					-- convert world space CFrames to be relative to the attachment parent
					a1.CFrame = a1.Parent.CFrame:inverse() * cf1
					a2.CFrame = a2.Parent.CFrame:inverse() * cf2
					game["Run Service"].RenderStepped:Wait()
				end
			end)
		end

		for i, v in next, Particles.Hellflame["Hell Slam"].ArmFire:GetChildren() do
			local clone = v:Clone()
			clone.LockedToPart = true
			clone.Name = "XzCXASDASDASDSABurn"
			clone.Parent = Character["Right Arm"]
		end
		for i, v in next, Particles.Hellflame["Hell Slam"].ArmFire:GetChildren() do
			local clone = v:Clone()
			clone.LockedToPart = true
			clone.Name = "XzCXASDASDASDSABurn"
			clone.Parent = Character["Left Arm"]
		end

		local BurnSfx = SFX.Quirks.Hellflame.IgnitedArrow.BurningSFX:Clone()
		BurnSfx.Parent = Character.HumanoidRootPart
		BurnSfx:Play()

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 1, 1) * 4e5
		bv.Velocity = Vector3.new(0, 0.001, 0)
		bv.Parent = Root
		bv.Name = "movebvthingasd"

		Modules.AnimationHandler.Play(Character, "HellSlam")
		MoveState:Set("Min", os.clock() + 0.2)

		local bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1, 1, 1) * 4e4
		bg.CFrame = Root.CFrame
		bg.P = 3e4
		bg.Parent = Root
		bg.Name = "movebgthingasd"
		MoveState:Set("HOLD_FACE_KEY", `HELLSLAMHOLD_{Character.Name}`)
		RunService:BindToRenderStep(MoveState:Get("HOLD_FACE_KEY"), 1, function()
			bg.CFrame = CFrame.lookAt(opos, Mouse.Position)
		end)

		Timer.Wait(0.2)
		Modules.AnimationHandler.AdjustSpeed(Character, "HellSlam", 0)
	elseif Input.InputState == Enum.UserInputState.End then
		if Character.HumanoidRootPart:FindFirstChildOfClass("BodyPosition") then
			Character.HumanoidRootPart:FindFirstChildOfClass("BodyPosition"):Destroy()
		end
		if not Modules.SanityCheck(Character, { Stuns = 0, IsBlocking = false }) then
			return false
		end
		task.delay(1.5, function()
			Character.States:SetAttribute("IsCasting", false)
		end)
		MoveState:SetCooldown(MoveInfo.Cooldown)
		RunService:UnbindFromRenderStep(MoveState:Get("HOLD_FACE_KEY"))
		if Root:FindFirstChild("movebgthingasd") == nil then
			return
		end

		if LocalPlayer.Character == Character then
			Root:FindFirstChild("Circle"):Destroy()
			Root:FindFirstChild("Beam"):Destroy()
			Root:FindFirstChild("at1"):Destroy()
			Root:FindFirstChild("at2"):Destroy()
		end

		Character.HumanoidRootPart.BurningSFX:Destroy()

		local Duration = MoveState:Get("Min") - os.clock()
		print(Duration)
		if Duration > 0.01 then
			Timer.Wait(Duration)
		end

		Modules.AnimationHandler.AdjustSpeed(Character, "HellSlam", 1)
		MoveState:Set("Released", true)

		local bv = Root:FindFirstChild("movebvthingasd")
		local bg = Root:FindFirstChild("movebgthingasd")

		local t = 1.25
		local g = Vector3.new(0, -game.Workspace.Gravity, 0)
		local x0 = Root.CFrame * Vector3.new(0, 2, -2)
		local v0 = (
			(
				((Root.Position - Mouse.Position).Magnitude > 75)
					and (Root.Position + (CFrame.new(Root.Position, Mouse.Position).LookVector * 75))
				or Mouse.Position
			)
			- x0
			- 0.5 * g * t * t
		) / t

		local _, _, _, _, p3, p2, p1 = beamProjectile(g, v0, x0, t)
		--<
		p1 = Root.Position
		p3 = (
			((Root.Position - Mouse.Position).Magnitude > 75)
				and (Root.Position + (CFrame.new(Root.Position, Mouse.Position).LookVector * 75))
			or Mouse.Position
		)
		local pp, pp2 = p3, Vector3.new(0, -40, 0)
		local results = workspace:Raycast(pp, pp2, params)
		if results ~= nil and results.Instance ~= nil then
			p3 = results.Position
		end
		-->
		local bp = Instance.new("BodyPosition")
		if bv ~= nil then
			bv:Destroy()
		end
		bp.MaxForce = Vector3.new(4e4, 4e4, 4e4)
		bp.P = 9e4
		bp.Position = Root.Position
		bp.Parent = Root
		local Cancel = Instance.new("BoolValue")
		Cancel.Name = "Cancel"
		Cancel.Parent = bg

		local Propel = Particles.Hellflame["Hell Slam"].PROPEL:Clone()
		Propel.CFrame = Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(-30), 0, 0)
		Propel.Parent = workspace.Ignore
		game.Debris:AddItem(Propel, 1)
		for i, v in next, Propel:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end

		for i, v in next, Character:GetChildren() do
			if v.Name == "Left Arm" or v.Name == "Right Arm" or v.Name == "Left Leg" or v.Name == "Right Leg" then
				local trail = Particles.Hellflame["Hell Slam"].trailthingy:Clone()
				trail.Parent = Character
				local weld = Instance.new("Weld")
				weld.Part0 = v
				weld.Part1 = trail
				weld.Parent = trail
			end
		end

		--leave
		for i = 1, 25 do
			local complete = i / 25
			local l_1 = Lerp(p1, p2, complete)
			local l_2 = Lerp(p2, p3, complete)
			local l_3 = Lerp(l_1, l_2, complete)
			bp.Position = l_3 + Vector3.new(0, 3, 0)
			wait()
		end

		Timer.Wait(0.1)

		local curve0, curve1, cf1, cf2 = beamProjectile(g, v0, x0, t)

		task.delay(0.15, function()
			if bp ~= nil then
				bp:Destroy()
			end
			if bg ~= nil then
				bg:Destroy()
			end
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)

		Modules.Common.CameraShaker({
			Location = cf2.Position,
			Magnitude = 3.5,
			Damp = 0.06,
		})
		if LocalPlayer.Character == Character then
			Modules.ImpactFrame()
		end

		local HELLSLAMEXPLOSION = Particles.Hellflame["Hell Slam"].HELL_SLAM:Clone()
		HELLSLAMEXPLOSION.Position = cf2.Position
		HELLSLAMEXPLOSION.Parent = workspace.Ignore
		game.Debris:AddItem(HELLSLAMEXPLOSION, 4)
		for i, v in next, HELLSLAMEXPLOSION.Attachment:GetChildren() do
			v:Emit(v:GetAttribute("EmitCount"))
		end

		local Hitbox = Modules.Hitbox.Radius({
			Radius = 30,
			Position = cf2.Position,
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
				).Unit * math.random(-30, 30) + Hit.HumanoidRootPart.CFrame.UpVector * 35
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

		Modules.WUNBO_ROCKS({
			Pos = cf2.Position,
			Size = Vector3.new(3, 3, 3),
			Distance = 30,
			filter = params,
			MaxRocks = 10,
			despawnTime = 2,
		})

		local Raycast = workspace:Raycast(cf2.Position, Vector3.new(0, -6, 0), params)

		if Raycast then
			local burnt_decal = Models.burnmark:Clone()
			burnt_decal.Parent = workspace.Ignore
			burnt_decal.Position = Raycast.Position
			game.Debris:AddItem(burnt_decal, 4)

			TweenService:Create(burnt_decal, tween1, { Size = Vector3.new(60, 0.001, 60) }):Play()

			task.delay(1.5, function()
				for i, Decal in burnt_decal:GetChildren() do
					TweenService:Create(Decal, tween1, { Transparency = 1 }):Play()
				end
			end)
		end

		Modules.FlyingRocks({
			i = 2,
			j = 4,
			Offset = 3,
			Origin = v0,
			Size = Vector2.new(3, 4),
			AxisRange = 30,
			Height = Vector2.new(15, 30),
			Percent = 1,
			Duration = 2,
		})

		Timer.Wait(0.3)

		for i, v in next, Character:GetChildren() do
			if v.Name == "trailthingy" then
				v:Destroy()
			end
		end

		for i, v in next, Character["Right Arm"]:GetChildren() do
			if v.Name == "XzCXASDASDASDSABurn" then
				v.Enabled = false
			end
		end
		for i, v in next, Character["Left Arm"]:GetChildren() do
			if v.Name == "XzCXASDASDASDSABurn" then
				v.Enabled = false
			end
		end

		task.delay(0.75, function()
			for i, v in next, Character["Right Arm"]:GetChildren() do
				if v.Name == "XzCXASDASDASDSABurn" then
					v:Destroy()
				end
			end
			for i, v in next, Character["Left Arm"]:GetChildren() do
				if v.Name == "XzCXASDASDASDSABurn" then
					v:Destroy()
				end
			end
		end)
	end
end
