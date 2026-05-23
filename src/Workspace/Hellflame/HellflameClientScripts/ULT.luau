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
	if Input.InputState ~= Enum.UserInputState.Begin then return end
	if not Modules.SanityCheck(Character, {Stuns = 0, IsCasting = false, IsBlocking = false}) then return false end

	--[[ Comment this if the move is a combo extender ]] -- 
	if Character.States:GetAttribute("CanExtend") == true then return false end
	--[[ Uncomment this if the move is a combo extender ]] -- 
	--if Character.States:GetAttribute("CanExtend") == true then 
	--	Character.States:SetAttribute("CanExtend",false)
	--end
	
	local Cleaner = PerformMove()
	--local MoveInfo = Modules.QuirkInfo.QuirkMove
	
	--MoveState:SetCooldown(MoveInfo.Cooldown)
end