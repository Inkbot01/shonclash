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

local params = RaycastParams.new()
params.FilterDescendantsInstances = { workspace.Map }
params.FilterType = Enum.RaycastFilterType.Include

local tween1 = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)

local connections = {}
function disconnect()
	for i, v in next, connections do
		v:Disconnect()
	end
end

function clearForces(parent, force, ignoreList)
	for i, v in next, parent:GetChildren() do
		if v:IsA(force) and not table.find(ignoreList, v.Name) then
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
	if Character.States:GetAttribute("CanExtend") == true then
		return false
	end
	--[[ Uncomment this if the move is a combo extender ]]
	--
	--if Character.States:GetAttribute("CanExtend") == true then
	--	Character.States:SetAttribute("CanExtend",false)
	--end

	local Cleaner = PerformMove()
	local MoveInfo = Modules.HellflameInfo.HellEruption

	MoveState:SetCooldown(MoveInfo.Cooldown)

	Modules.AnimationHandler.Play(Character, "HellEruption")

	local ArmFire = Models.Hellflame.ArmFire_Eruption.Attachment:Clone()
	ArmFire.Name = "BURNARMERUPT"
	ArmFire.Parent = Character["Right Arm"]

	Timer.Wait(0.6)

	for i, v in next, ArmFire:GetChildren() do
		v.Enabled = false
	end
	game.Debris:AddItem(ArmFire, 4)

	local Eruption = Particles.Hellflame.Eruption:Clone()
	local Pos = Character["Right Arm"].Position - Vector3.new(0, 0.75, 0)
	Eruption.Position = Pos
	Eruption.Parent = workspace.Ignore
	game.Debris:AddItem(Eruption, 4)

	for i, v in next, Eruption:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			if v:GetAttribute("EmitDelay") ~= 0 then
				task.delay(v:GetAttribute("EmitDelay"), function()
					v:Emit(v:GetAttribute("EmitCount"))
				end)
				continue
			end
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

	Modules.Common.CameraShaker({
		Location = Character.HumanoidRootPart,
		Magnitude = 1.5,
		Damp = 0.03,
	})
	local Raycast = workspace:Raycast(Character.HumanoidRootPart.Position, Vector3.new(0, -6, 0), params)

	if Raycast then
		local burnt_decal = Models.burnmark:Clone()
		burnt_decal.Parent = workspace.Ignore
		burnt_decal.Position = Raycast.Position
		game.Debris:AddItem(burnt_decal, 4)

		TweenService:Create(burnt_decal, tween1, { Size = Vector3.new(30, 0.001, 30) }):Play()

		task.delay(1.5, function()
			for i, Decal in burnt_decal:GetChildren() do
				TweenService:Create(Decal, tween1, { Transparency = 1 }):Play()
			end
		end)
	end
	task.delay(0.2, function()
		Modules.Common.CameraShaker({
			Location = Character.HumanoidRootPart,
			Magnitude = 3.5,
			Damp = 0.06,
		})
		local Raycast2 = workspace:Raycast(Character.HumanoidRootPart.Position, Vector3.new(0, -6, 0), params)

		if Raycast2 then
			local burnt_decal = Models.burnmark:Clone()
			burnt_decal.Parent = workspace.Ignore
			burnt_decal.Position = Raycast.Position
			game.Debris:AddItem(burnt_decal, 4)

			TweenService:Create(burnt_decal, tween1, { Size = Vector3.new(50, 0.001, 50) }):Play()

			task.delay(1.5, function()
				for i, Decal in burnt_decal:GetChildren() do
					TweenService:Create(Decal, tween1, { Transparency = 1 }):Play()
				end
			end)
		end
	end)
end
