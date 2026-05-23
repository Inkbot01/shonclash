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

	--[[ Comment this if the move is a combo extender ]]
	--
	--if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]]
	--
	if Character.States:GetAttribute("CanExtend") == true then
		Character.States:SetAttribute("CanExtend", false)
	end

	local Cleaner = PerformMove()
	local Mouse = workspace.PlayerMice[Character.Name]
	local Root = Character.HumanoidRootPart
	local MoveInfo = Modules.HellflameInfo.JetBurn

	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false }) then
			return
		end
		Character.States:SetAttribute("IsCasting", true)
		local Cleaner = PerformMove()
		local opos = Character.HumanoidRootPart.Position

		Modules.AnimationHandler.Play(Character, "JetBurn")
		MoveState:Set("Min", os.clock() + 0.75)
		task.delay(0.35, function()
			for i, v in next, Particles.Hellflame.ArmFire:GetChildren() do
				v:Clone().Parent = Character["Right Arm"]
			end
		end)

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1, 1, 1) * 4e5
		bv.Velocity = Vector3.new(0, 0.001, 0)
		bv.Parent = Root
		bv.Name = "Holding_Move_BV"

		local bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1, 1, 1) * 4e4
		bg.CFrame = Root.CFrame
		bg.P = 3e4
		bg.Parent = Root
		bg.Name = "Holding_Move_BG"
		MoveState:Set("HOLD_FACE_KEY", `JETBURNHOLD_{Character.Name}`)
		RunService:BindToRenderStep(MoveState:Get("HOLD_FACE_KEY"), 1, function()
			bg.CFrame = CFrame.lookAt(opos, Mouse.Position)
		end)

		Timer.Wait(0.7)
		Modules.AnimationHandler.AdjustSpeed(Character, "JetBurn", 0)
	elseif Input.InputState == Enum.UserInputState.End then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsBlocking = false }) then
			return
		end
		Character.States:SetAttribute("IsCasting", false)
		MoveState:SetCooldown(MoveInfo.Cooldown)
		RunService:UnbindFromRenderStep(MoveState:Get("HOLD_FACE_KEY"))
		if Root:FindFirstChild("Holding_Move_BG") == nil then
			return
		end

		local Holding_Move_BV = Root:FindFirstChild("Holding_Move_BV")
		local Holding_Move_BG = Root:FindFirstChild("Holding_Move_BG")
		if Holding_Move_BG ~= nil then
			game.Debris:AddItem(Holding_Move_BG, 0.5)
		end

		local Duration = MoveState:Get("Min") - os.clock()
		print(Duration)
		if Duration > 0.01 then
			Timer.Wait(Duration)
		end

		Modules.AnimationHandler.AdjustSpeed(Character, "JetBurn", 1)
		MoveState:Set("Released", true)

		Timer.Wait(0.3)

		task.delay(0.75, function()
			for i, v in next, Character["Right Arm"]:GetChildren() do
				if v.Name == "Burn" then
					v.Enabled = false
				end
			end
			task.wait(0.5)
			for i, v in next, Character["Right Arm"]:GetChildren() do
				if v.Name == "Burn" then
					v:Destroy()
				end
			end
		end)

		local JetBurnVFX = Particles.Hellflame.Jet_Burn:Clone()
		game.Debris:AddItem(JetBurnVFX, 3)
		JetBurnVFX.Parent = workspace.Ignore
		JetBurnVFX.CFrame = Character.HumanoidRootPart.CFrame

		for i, v in next, JetBurnVFX:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end

		Modules.Common.CameraShaker({
			Location = Character.HumanoidRootPart,
			Magnitude = 4,
			Damp = 0.01,
		})

		local Hitbox = Modules.Hitbox.Box({
			Size = Vector3.new(20.1, 19.3, 28),
			CFrame = CFrame.new(
				Character.HumanoidRootPart.Position + Character.HumanoidRootPart.CFrame.LookVector * 17,
				workspace.PlayerMice[Character.Name].Position
			),
		})
		Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
		Hitbox.Params.FilterDescendantsInstances =
			{ workspace.Interactable, workspace.Map, workspace.PlayerMice, Character }
		Hitbox.OnHit:Connect(function(Hit)
			if Hit.States:GetAttribute("IFRAMES") ~= 0 then
				return
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
			if PlayerService:GetPlayerFromCharacter(Hit) ~= nil then
				clearForces(Hit.HumanoidRootPart, "BodyVelocity")
				clearForces(Hit.HumanoidRootPart, "BodyPosition")
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
				BodyVelocity.Name = "Knockback"
				BodyVelocity.Velocity = (
					Hit.HumanoidRootPart.CFrame.Position - Character.HumanoidRootPart.CFrame.Position
				).Unit * 50
				BodyVelocity.Parent = Hit.HumanoidRootPart

				game.Debris:AddItem(BodyVelocity, 1.5)
			end
		end)
		Hitbox:Calculate(1, 1)

		Timer.Wait(0.7)
		Holding_Move_BV:Destroy()
	end
end
