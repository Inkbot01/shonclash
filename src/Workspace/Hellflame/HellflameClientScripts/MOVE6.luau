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
args.FilterDescendantsInstances = {workspace.Ignore}

local connections = {}
function disconnect()
	for i,v in next, connections do
		v:Disconnect()
	end
end

function clearForces(parent, force, ignoreList)
	for i,v in next, parent:GetChildren() do
		if v:IsA(force) and not table.find(ignoreList, v.Name) then
			v:Destroy()
		end
	end
end

return function(Character, Input, MoveState, PerformMove, Timer, Modules)
	if MoveState:InCooldown() then return false end
	if not Character.Parent then return false end

	--[[ Comment this if the move is a combo extender ]] -- 
	if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]] -- 
	--if Character.States:GetAttribute("CanExtend") == true then 
	--	Character.States:SetAttribute("CanExtend",false)
	--end
	
	local Mouse = workspace.PlayerMice[Character.Name]
	local MoveInfo = Modules.HellflameInfo.HellFlight
	local Root = Character.HumanoidRootPart
	
	local function stopFlight()
		RunService:UnbindFromRenderStep(MoveState:Get("HOLD_FACE_KEY"))
		Modules.AnimationHandler.Stop(Character, "HellFlight")
		local _ = Root:FindFirstChild("HOLDINGFLIGHTBV") and Character.HumanoidRootPart:FindFirstChild("HOLDINGFLIGHTBV"):Destroy()
		local _ = Root:FindFirstChild("HOLDINGFLIGHTBG") and Character.HumanoidRootPart:FindFirstChild("HOLDINGFLIGHTBG"):Destroy()
		MoveState:SetCooldown(MoveInfo.Cooldown)
		MoveState:Set("Stopped", true)
		Character.States:SetAttribute("IsCasting",false)
		
		local RightFire = Character['Right Arm']:FindFirstChild("RIGHT_FLIGHT_FLAMES")
		local LeftFire = Character['Left Arm']:FindFirstChild("LEFT_FLIGHT_FLAMES")
		
		game.Debris:AddItem(RightFire,2)
		game.Debris:AddItem(LeftFire,2)
		
		for i,v in next, RightFire:GetChildren() do
			v.Enabled = false;
		end
		for i,v in next, LeftFire:GetChildren() do
			v.Enabled = false;
		end
	end
	
	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false}) then return end
		Character.States:SetAttribute("IsCasting",true)
		local opos = Character.HumanoidRootPart.Position
		
		MoveState:Set("Started", os.clock())
		MoveState:Set("Stopped", false)
		
		local Cleaner = PerformMove{Started = MoveState:Get("Started")}
		
		local FlightEffectLeft,FlightEffectRight = Particles.Hellflame.Flight.Flight:Clone(),Particles.Hellflame.Flight.Flight:Clone()
		FlightEffectRight.Name = "RIGHT_FLIGHT_FLAMES"
		FlightEffectLeft.Name = "LEFT_FLIGHT_FLAMES"
		FlightEffectRight.Parent = Character['Right Arm']
		FlightEffectLeft.Parent = Character['Left Arm']
		
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1,1,1)*4e4
		bv.Parent = Root
		bv.Name = "HOLDINGFLIGHTBV"

		Modules.AnimationHandler.Play(Character, "HellFlight")

		local bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1,1,1) * 4e4
		bg.CFrame = Root.CFrame
		bg.P = 3e4
		bg.Parent = Root
		bg.Name = "HOLDINGFLIGHTBG"
		MoveState:Set("HOLD_FACE_KEY", `HELLFLIGHT_{Character.Name}`)
		RunService:BindToRenderStep(MoveState:Get("HOLD_FACE_KEY"), 1, function()
			bg.CFrame = CFrame.lookAt(opos, Mouse.Position)
			bv.Velocity = Character.HumanoidRootPart.CFrame.LookVector*50
		end)
		
		Timer.Wait(4)
		if MoveState:Get("Stopped") == false then
			stopFlight()
		end
	else
		if MoveState:Get("Stopped") == false then
			stopFlight()
		end
	end
end