local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")

local SFX = ReplicatedStorage:WaitForChild("SFX")

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

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = { workspace.Map }
raycastParams.FilterType = Enum.RaycastFilterType.Include

return function(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)
	if MoveState:InCooldown() then
		return false
	end
	if not Character.Parent then
		return false
	end
	if not Modules.IsMasteryEnough() then
		return false
	end

	--[[ Remove this if the move is a combo extender ]]
	--
	if Character.States:GetAttribute("CanExtend") == true then
		return false
	end
	--[[ Remove this if the move is a combo extender ]]
	--

	local Cleaner = ReplicateMove()
	local Player = PlayerService:GetPlayerFromCharacter(Character)
	local MoveInfo = Modules.HellflameInfo.IgnitedArrow

	if Input.InputState == Enum.UserInputState.Begin then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsCasting = false, IsBlocking = false }) then
			return false
		end
		Character.States:SetAttribute("IsCasting", true)

		MoveState:Set("Pressed", true)
		MoveState:Set("Min", os.clock() + 0.7)
	elseif Input.InputState == Enum.UserInputState.End then
		if not Modules.SanityCheck(Character, { Stuns = 0, IsBlocking = false }) then
			return false
		end
		MoveState:SetCooldown(MoveInfo.Cooldown)
		if MoveState:Get("Pressed") == nil then
			return false
		end
		MoveState:Set("Released", os.clock())
		Character.States:SetAttribute("IsCasting", false)

		local Duration = MoveState:Get("Min") - os.clock()
		print(Duration)
		if Duration > 0.01 then
			Timer.Wait(Duration)
		end

		task.delay(
			(
				CFrame.new(Character.HumanoidRootPart.Position, FiredData.MousePosition)
					* CFrame.new(0, 0, -3).Position
				- workspace.PlayerMice[Character.Name].Position
			).Magnitude / 110,
			function()
				--Timer.Wait(.2)
				if os.clock() - MoveState:Get("Released") > 2.5 then
					return false
				end
				local Hitbox = Modules.Hitbox.Radius({
					Radius = 6,
					Position = FiredData.MousePosition,
				})
				Hitbox.Params.FilterType = Enum.RaycastFilterType.Exclude
				Hitbox.Params.FilterDescendantsInstances = { workspace.Interactable, workspace.PlayerMice, Character }
				Hitbox.OnHit:Connect(function(Hit)
					if Hit.States:GetAttribute("IFRAMES") ~= 0 then
						return
					end
					if os.clock() - MoveState:Get("Released") > 2.5 then
						return false
					end

					Modules.StateManager.AddMode(Character, 10)
					Modules.DoBlockDamage(Hit, 60)
					if PlayerService:GetPlayerFromCharacter(Hit) == nil then
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
					Modules.StateManager.Stun(Hit, 1.25)
					Modules.BurnDamage(Hit, Modules.GetDamageFromMastery(Player, 1, "Quirk"), 2.5, Character)
					Hit.Humanoid:TakeDamage(Modules.GetDamageFromMastery(Player, MoveInfo.BaseDamage, "Quirk"))

					Modules.Ragdoll:Ragdoll(Hit)
					task.delay(1.5, function()
						Modules.Ragdoll:Unragdoll(Hit)
					end)
				end)
				Hitbox:Calculate(1, 1)
			end
		)
	end

	return true
end
