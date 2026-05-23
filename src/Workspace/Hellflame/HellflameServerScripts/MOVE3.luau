local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")

local SFX = ReplicatedStorage:WaitForChild("SFX")

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

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {workspace.Map}
raycastParams.FilterType = Enum.RaycastFilterType.Include

return function(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)	
	if MoveState:InCooldown() then return false end
	if not Character.Parent then return false end
	
	--[[ Comment this if the move is a combo extender ]] -- 
	--if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]] -- 
	if Character.States:GetAttribute("CanExtend") == true then 
		Character.States:SetAttribute("CanExtend",false)
	end
	
	local Cleaner = ReplicateMove()
	local Player = PlayerService:GetPlayerFromCharacter(Character)
	local MoveInfo = Modules.HellflameInfo.JetBurn
	
	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false}) then return false end
		Character.States:SetAttribute("IsCasting",true)
		
		MoveState:Set("Pressed",true)
		MoveState:Set("Min", os.clock() + .8) 
		
	elseif Input.InputState == Enum.UserInputState.End then
		Timer.Wait(.15)
		if not Modules.SanityCheck(Character, {Stuns = 0, IsBlocking = false}) then return false end
		MoveState:SetCooldown(MoveInfo.Cooldown)
		task.delay(.9,function()
			Character.States:SetAttribute("IsCasting",false)
		end)
		
		local Duration = MoveState:Get("Min") - os.clock()
		print(Duration)
		if Duration > 0.01 then
			Timer.Wait(Duration)
		end
		
		Timer.Wait(.15)
		if MoveState:Get("Pressed") == nil then return false end
		
		Timer.Wait(.15)
		
		local Hitbox = Modules.Hitbox.Box{
			Size = Vector3.new(20.1, 19.3, 28),
			CFrame = CFrame.new(Character.HumanoidRootPart.Position + Character.HumanoidRootPart.CFrame.LookVector*17, workspace.PlayerMice[Character.Name].Position),
		}
		Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
		Hitbox.Params.FilterDescendantsInstances = {workspace.Interactable, workspace.Map, workspace.PlayerMice, Character}
		Hitbox.OnHit:Connect(function(Hit)
			if Hit.States:GetAttribute("IFRAMES") ~= 0 then return end
			
			Modules.StateManager.AddMode(Character, 10)
			task.spawn(function()
				Modules.DoBlockDamage(Hit, 7)
				Modules.StateManager.Stun(Hit, .5)
				Hit.Humanoid:TakeDamage(Modules.GetDamageFromMastery(Player, Modules.HellflameInfo.JetBurn.BaseDamage, "Quirk"))
				Modules.BurnDamage(Hit, Modules.GetDamageFromMastery(Player, 1, "Quirk"), 1.5, Character)

				if PlayerService:GetPlayerFromCharacter(Hit) == nil then
					clearForces(Hit.HumanoidRootPart, "BodyVelocity");clearForces(Hit.HumanoidRootPart, "BodyPosition");
					
					local BodyVelocity = Instance.new("BodyVelocity")
					BodyVelocity.MaxForce = Vector3.new(4e4,4e4,4e4)
					BodyVelocity.Name = "Knockback"
					BodyVelocity.Velocity = (Hit.HumanoidRootPart.CFrame.Position - Character.HumanoidRootPart.CFrame.Position).Unit * 35
					BodyVelocity.Parent = Hit.HumanoidRootPart
					
					game.Debris:AddItem(BodyVelocity,.2)
				end
				
				Modules.Ragdoll:Ragdoll(Hit)
				task.delay(1.5, function()
					Modules.Ragdoll:Unragdoll(Hit)
				end)
			end)
		end)
		Hitbox:Calculate(1,1)
	end
	
	return true 
end