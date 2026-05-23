local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {workspace.Map}
raycastParams.FilterType = Enum.RaycastFilterType.Include

function clearForces(parent, force, ignoreList)
	for i,v in next, parent:GetChildren() do
		if v:IsA(force) then
			if ignoreList and not table.find(ignoreList, v.Name) then
				v:Destroy()
				return
			end
			v:Destroy()
		end 
	end
end

return function(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)
	if MoveState:InCooldown() then return false end
	if not Character.Parent then return false end
	if Input.InputState ~= Enum.UserInputState.Begin then return end
	if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false}) then return false end

	--[[ Comment this if the move is a combo extender ]] -- 
	--if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]] -- 
	if Character.States:GetAttribute("CanExtend") == true then 
		Character.States:SetAttribute("CanExtend",false)
	end
	
	local Player = PlayerService:GetPlayerFromCharacter(Character)
	local Cleaner = ReplicateMove()
	local MoveInfo = Modules.HellflameInfo.Incinerate

	local Hit = FiredData.ClientHit
	
	if not Hit then return true end
	
	Modules.StateManager.IFrame(Character,1)
	MoveState:SetCooldown(MoveInfo.Cooldown)
	
	clearForces(Character.HumanoidRootPart, "BodyVelocity")
	clearForces(Character.HumanoidRootPart, "BodyPosition")

	local Weld = Instance.new("Weld")
	Weld.C0 = CFrame.new(0,0,-2) * CFrame.Angles(0,math.rad(-180),0)
	Weld.Part0 = Character.HumanoidRootPart; Weld.Part1 = Hit.HumanoidRootPart
	Weld.Parent = Hit.HumanoidRootPart
	game.Debris:AddItem(Weld, .9)
	
	clearForces(Hit.HumanoidRootPart, "BodyVelocity")
	clearForces(Hit.HumanoidRootPart, "BodyPosition")
	
	task.delay(.3,function()
		if Hit ~= nil and Hit.Parent ~= nil then
			Modules.StateManager.IFrame(Hit,.75)
			for i=0,5 do
				Modules.StateManager.AddMode(Character, 1)
				Hit.Humanoid:TakeDamage(Modules.GetDamageFromMastery(Player, MoveInfo.BaseDamage, "Quirk"))
				Timer.Wait(.075)
			end
			
			Weld:Destroy()
			
			Modules.BurnDamage(Hit, Modules.GetDamageFromMastery(Player, 1, "Quirk"), 2, Character)
			if PlayerService:GetPlayerFromCharacter(Hit) == nil then
				local BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.MaxForce = Vector3.new(4e4,0,4e4)
				BodyVelocity.Velocity = (Hit.HumanoidRootPart.CFrame.Position - Character.HumanoidRootPart.CFrame.Position).Unit * 36
				BodyVelocity.Parent = Hit.HumanoidRootPart

				game.Debris:AddItem(BodyVelocity,.4)
			end
			
			Modules.Ragdoll:Ragdoll(Hit)
			task.delay(.7, function()
				Modules.Ragdoll:Unragdoll(Hit)
			end)
			
			Modules.StateManager.AddMode(Character, 5)
			Hit.Humanoid:TakeDamage(Modules.GetDamageFromMastery(Player, MoveInfo.BaseDamage2, "Quirk"))
		end
	end)

	return true
end