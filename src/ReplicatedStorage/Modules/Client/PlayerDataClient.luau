--!strict
-- Adapted from fruit/ReplicatedStorage/Modules/Client/PlayerDataClient.luau
-- Wraps the Wally `Replica` (thehoosky/replica@1.0.2) so HUD widgets read player data
-- through one stable API. Uses the "PlayerData" replica token created by ProfileHandler.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replica = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replica"))

local LocalPlayer = Players.LocalPlayer

local PlayerDataClient = {}

local DataReplica: any = nil
local ReadyCallbacks: { (any) -> () } = {}

Replica.RequestData()

Replica.OnNew("PlayerData", function(replica)
	if replica.Tags.UserId == LocalPlayer.UserId then
		DataReplica = replica
		local pending = ReadyCallbacks
		ReadyCallbacks = {}
		for _, cb in ipairs(pending) do
			task.spawn(cb, replica)
		end
	end
end)

function PlayerDataClient.Get(): any
	return DataReplica
end

function PlayerDataClient.WaitForData(): any
	if DataReplica then
		return DataReplica
	end
	repeat
		task.wait()
	until DataReplica
	return DataReplica
end

function PlayerDataClient.OnReady(callback: (any) -> ())
	if DataReplica then
		task.spawn(callback, DataReplica)
		return
	end
	table.insert(ReadyCallbacks, callback)
end

function PlayerDataClient.GetData(path: string?): any
	if not DataReplica then
		return nil
	end
	if not path or path == "" then
		return DataReplica.Data
	end

	local current: any = DataReplica.Data
	for key in string.gmatch(path, "[^%.]+") do
		if type(current) ~= "table" then
			return nil
		end
		current = current[key]
		if current == nil then
			return nil
		end
	end
	return current
end

function PlayerDataClient.OnSet(path: string, callback: (newValue: any, oldValue: any) -> ()): any
	local replica = DataReplica or PlayerDataClient.WaitForData()
	local keys = {}
	for key in string.gmatch(path, "[^%.]+") do
		table.insert(keys, key)
	end
	return replica:OnSet(keys, callback)
end

return PlayerDataClient
