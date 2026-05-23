--!strict
-- HUD Data adapter — single read API for every HUD widget.
-- Goal: when Wave 2 swaps Player.Data/States instances for ProfileStore+Replica,
-- only this module changes. Widgets remain identical.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))

local LocalPlayer = Players.LocalPlayer

type Thread = any
type Value = any

local Data = {}

function Data.HumanoidValue(Thread: Thread, property: string, default: any): Value
	local value = Thread:Value(default)

	local function attach(character: Model)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			humanoid = character:WaitForChild("Humanoid", 5)
		end
		if not humanoid then return end
		value:Set((humanoid :: any)[property])
		Thread:Connect(humanoid:GetPropertyChangedSignal(property), function()
			value:Set((humanoid :: any)[property])
		end)
	end

	if LocalPlayer.Character then
		attach(LocalPlayer.Character)
	end
	Thread:Connect(LocalPlayer.CharacterAdded, attach)

	return value
end

function Data.PlayerValue(Thread: Thread, path: string, default: any): Value
	local value = Thread:Value(default)

	local function resolve(): Instance?
		local node: any = LocalPlayer
		for segment in string.gmatch(path, "[^%.]+") do
			node = node:FindFirstChild(segment)
			if not node then return nil end
		end
		return node
	end

	local function attach()
		local inst = resolve()
		if not inst then return end
		if inst:IsA("ValueBase") then
			value:Set((inst :: any).Value)
			Thread:Connect(inst:GetPropertyChangedSignal("Value"), function()
				value:Set((inst :: any).Value)
			end)
		end
	end

	attach()
	Thread:Connect(LocalPlayer.CharacterAdded, function()
		task.defer(attach)
	end)

	return value
end

function Data.GlobalValue(Thread: Thread, valueName: string, default: any): Value
	local globalData = ReplicatedStorage:FindFirstChild("GlobalData")
	if not globalData then
		warn("[HUD/Data] ReplicatedStorage.GlobalData missing; returning default for " .. valueName)
		return Thread:Value(default)
	end

	local inst = globalData:WaitForChild(valueName, 5)
	if not inst or not inst:IsA("ValueBase") then
		return Thread:Value(default)
	end

	local value = Thread:Value((inst :: any).Value)
	Thread:Connect(inst:GetPropertyChangedSignal("Value"), function()
		value:Set((inst :: any).Value)
	end)
	return value
end

function Data.LeaderstatValue(Thread: Thread, statName: string, default: any): Value
	local leaderstats = LocalPlayer:WaitForChild("leaderstats", 5)
	if not leaderstats then
		return Thread:Value(default)
	end

	local inst = leaderstats:WaitForChild(statName, 5)
	if not inst or not inst:IsA("ValueBase") then
		return Thread:Value(default)
	end

	local value = Thread:Value((inst :: any).Value)
	Thread:Connect(inst:GetPropertyChangedSignal("Value"), function()
		value:Set((inst :: any).Value)
	end)
	return value
end

return Data
