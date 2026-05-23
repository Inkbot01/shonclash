local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {workspace.Map}
raycastParams.FilterType = Enum.RaycastFilterType.Include

function clearForces(parent, force, ignoreList) 
	for i,v in next, parent:GetChildren() do
		if v:IsA(force) and not table.find(ignoreList, v.Name) then
			v:Destroy()
		end
	end
end 

return function(Character, Input, MoveState, ReplicateMove, Timer, Modules, ClientData, FiredData)
	if MoveState:InCooldown() then return false end
	if not Character.Parent then return false end
	if Input.InputState ~= Enum.UserInputState.Begin then return end
	if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false}) then return false end
	if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false, ModeBar = 100}) then return false end
	
	--[[ Comment this if the move is a combo extender ]] -- 
	if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]] -- 
	--if Character.States:GetAttribute("CanExtend") == true then 
	--	Character.States:SetAttribute("CanExtend",false)
	--end
	
	local Player = PlayerService:GetPlayerFromCharacter(Character)
	local Cleaner = ReplicateMove()
	local MoveInfo = Modules.HellflameInfo.Awakening
	
	MoveState:SetCooldown(MoveInfo.Cooldown)
	
	Character.States:SetAttribute("IsCasting",true)
	task.delay(12,function()
		Character.States:SetAttribute("IsCasting",false)
	end)
	Modules.StateManager.Stun(Character, 12)
	Modules.StateManager.IFrame(Character, 12)
    
	return true
end