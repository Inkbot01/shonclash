local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PlayerService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
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
		if v:IsA(force) and not table.find(ignoreList, v.Name) then
			v:Destroy()
		end
	end
end

function fixcamera(Character, MoveState)
	MoveState:Set("DoingAwakening", nil)
	if LocalPlayer.Character == Character then
		workspace.CurrentCamera.FieldOfView = 70
		for i, v in next, LocalPlayer.PlayerGui:GetChildren() do
			v.Enabled = true
		end
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end
end

function players(Character, Enable)
	if LocalPlayer.Character == Character then
		if Enable == true then
			for i, v in next, PlayerService:GetPlayers() do
				if v.Character == Character then
					continue
				end
				for _, v2 in next, v.Character:GetDescendants() do
					if v2:IsA("BasePart") or v2:IsA("MeshPart") or v2:IsA("Part") then
						v2.Transparency = 1
					end
				end
			end
		else
			for i, v in next, PlayerService:GetPlayers() do
				if v.Character == Character then
					continue
				end
				for _, v2 in next, v.Character:GetDescendants() do
					if v2:IsA("BasePart") or v2:IsA("MeshPart") or v2:IsA("Part") then
						if v2.Name == "HumanoidRootPart" then
							continue
						end
						v2.Transparency = 0
					end
				end
			end
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
	if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false, ModeBar = 100 }) then
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
	local MoveInfo = Modules.HellflameInfo.Awakening

	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0
	Character.Humanoid.AutoRotate = false
	task.delay(12.3, function()
		Character.Humanoid.WalkSpeed = 9
		Character.Humanoid.JumpPower = 50
		Character.Humanoid.AutoRotate = true
	end)

	MoveState:SetCooldown(MoveInfo.Cooldown)

	repeat
		task.wait()
	until (Character.Humanoid.MoveDirection).Magnitude == 0

	local CamRig = ReplicatedStorage.CamRig:Clone()
	CamRig.Parent = workspace.Ignore
	CamRig:SetPrimaryPartCFrame(Character.Torso.CFrame)
	game.Debris:AddItem(CamRig, 11.7)

	MoveState:Set("DoingAwakening", true)
	players(Character, true)

	if LocalPlayer.Character == Character then
		for i, v in next, LocalPlayer.PlayerGui:GetChildren() do
			v.Enabled = false
		end

		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		task.spawn(function()
			while MoveState:Get("DoingAwakening") == true do
				if MoveState:Get("DoingAwakening") == nil then
					break
				end
				if CamRig.Parent == nil then
					break
				end

				workspace.CurrentCamera.CFrame = CamRig.Cam.CFrame
				Timer.Wait()
			end
		end)

		task.spawn(function()
			for i = 0, 361 do
				if MoveState:Get("DoingAwakening") == nil then
					break
				end
				if CamRig.Parent == nil then
					break
				end
				print(i)
				local Tween = TweenService:Create(
					workspace.CurrentCamera,
					TweenInfo.new(0.05),
					{ FieldOfView = Models.Hellflame.FOV_Keyframes:FindFirstChild(i).Value }
				)
				Tween:Play()
				Tween:Destroy()
				Timer.Wait(0.02)
			end
			Timer.Wait(0.04)
			fixcamera(Character, MoveState)
		end)
	end

	CamRig.Humanoid:LoadAnimation(Assets.Animations.Quirks.Hellflame.AwakeningCamera):Play()
	Modules.AnimationHandler.Play(Character, "AwakeningPlayer")

	Timer.Wait(0.1)

	local Part1 = Models.Hellflame.HellflameAwakenPart_1:Clone()
	local Part2 = Models.Hellflame.HellflameAwakenPart_2:Clone()

	local Pos = Character.Torso.Position - Vector3.new(0, 2.5, 0)

	Part1.Position = Pos
	Part2.Position = Pos

	Part1.Parent = workspace.Ignore
	Part2.Parent = workspace.Ignore

	Timer.Wait(10.5)

	for i, v in next, Part1:GetDescendants() do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end
	for i, v in next, Part2:GetDescendants() do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end
	game.Debris:AddItem(Part1, 0.5)
	game.Debris:AddItem(Part2, 0.5)

	local Part3 = Models.Hellflame.HellflameAwakenPart_3:Clone()
	Part3.Position = Pos
	Part3.Parent = workspace.Ignore

	Timer.Wait(0.5)

	local FinalEffects = Models.Hellflame.HellflameAwakenFinal:Clone()
	FinalEffects.Position = Character.HumanoidRootPart.Position
	FinalEffects.Parent = workspace.Ignore
	game.Debris:AddItem(FinalEffects, 3)

	for i, v in next, FinalEffects:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

	if LocalPlayer.Character == Character then
		Modules.ImpactFrame()
	end
	Modules.Common.CameraShaker({
		Location = Character.HumanoidRootPart,
		Magnitude = 3.5,
		Damp = 0.06,
	})

	Timer.Wait(0.5)

	for i, v in next, Part3:GetDescendants() do
		if v:IsA("ParticleEmitter") or v:IsA("Beam") then
			v.Enabled = false
		end
	end
	game.Debris:AddItem(Part3, 0.5)
	players(Character, false)
end
