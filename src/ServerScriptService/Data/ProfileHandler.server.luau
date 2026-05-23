--!strict
-- Bridges the existing ProfileService + Player.Data instance mirror (legacy)
-- into a modern Replica that the new HUD reads through PlayerDataClient.
--
-- For each player, this:
--   1. Waits for the legacy `Player.Data` Folder to be populated (post ProfileService load).
--   2. Snapshots it into a Lua table.
--   3. Creates a Replica with Token "PlayerData" and Tags { UserId = userId }.
--   4. Subscribes the owning player to their own Replica.
--   5. Wires every leaf *Value.Changed → replica:Set(path, value) so client receives live updates.
--
-- This is intentionally read-side only: server systems still write into Player.Data via the
-- legacy path; the Replica is a read view for the client. Wave 2 proper will migrate writes too.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replica = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replica"))

local PlayerDataToken = Replica.Token("PlayerData")

local DATA_FOLDER_WAIT_TIMEOUT = 30
local INITIAL_SETTLE_DELAY = 1.0  -- give ProfileService a moment to populate Player.Data after the folder appears

local function readLeafValue(child: Instance): any
	if child:IsA("ValueBase") then
		return (child :: any).Value
	end
	return nil
end

local function folderToTable(folder: Instance): { [string]: any }
	local result: { [string]: any } = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Folder") then
			result[child.Name] = folderToTable(child)
		elseif child:IsA("ValueBase") then
			result[child.Name] = readLeafValue(child)
		end
	end
	return result
end

-- Calling any method on a destroyed Replica throws. We track destruction via a local
-- flag so post-destroy signal callbacks can no-op cleanly.
local function wireLeafMirror(folder: Instance, replica: any, basePath: { string }, alive: { value: boolean })
	for _, child in ipairs(folder:GetChildren()) do
		local path = table.clone(basePath)
		table.insert(path, child.Name)

		if child:IsA("Folder") then
			wireLeafMirror(child, replica, path, alive)
		elseif child:IsA("ValueBase") then
			child:GetPropertyChangedSignal("Value"):Connect(function()
				if alive.value then
					replica:Set(path, readLeafValue(child))
				end
			end)
		end
	end

	folder.ChildAdded:Connect(function(newChild)
		if not alive.value then return end

		local path = table.clone(basePath)
		table.insert(path, newChild.Name)

		if newChild:IsA("Folder") then
			task.defer(function()
				if alive.value then
					replica:Set(path, folderToTable(newChild))
					wireLeafMirror(newChild, replica, path, alive)
				end
			end)
		elseif newChild:IsA("ValueBase") then
			replica:Set(path, readLeafValue(newChild))
			newChild:GetPropertyChangedSignal("Value"):Connect(function()
				if alive.value then
					replica:Set(path, readLeafValue(newChild))
				end
			end)
		end
	end)
end

local function subscribeWhenReady(replica: any, player: Player)
	if Replica.ReadyPlayers[player] then
		replica:Subscribe(player)
		return
	end
	local connection
	connection = Replica.NewReadyPlayer:Connect(function(readyPlayer: Player)
		if readyPlayer ~= player then
			return
		end
		connection:Disconnect()
		if replica:IsActive() and player.Parent == Players then
			replica:Subscribe(player)
		end
	end)
end

local function setupPlayer(player: Player)
	local dataFolder = player:WaitForChild("Data", DATA_FOLDER_WAIT_TIMEOUT)
	if not dataFolder then
		warn(string.format("[ProfileHandler] Player.Data missing for %s after %ds", player.Name, DATA_FOLDER_WAIT_TIMEOUT))
		return
	end

	task.wait(INITIAL_SETTLE_DELAY)

	if player.Parent ~= Players then
		return  -- player left during settle
	end

	local initialData = folderToTable(dataFolder)

	local ok, replicaOrErr = pcall(function()
		return Replica.New({
			Token = PlayerDataToken,
			Tags = { UserId = player.UserId },
			Data = initialData,
		})
	end)
	if not ok then
		warn(string.format("[ProfileHandler] Replica.New failed for %s: %s", player.Name, tostring(replicaOrErr)))
		return
	end
	local replica = replicaOrErr

	subscribeWhenReady(replica, player)

	local alive = { value = true }
	wireLeafMirror(dataFolder, replica, {}, alive)

	local removingConnection
	removingConnection = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer ~= player then
			return
		end
		removingConnection:Disconnect()
		alive.value = false
		pcall(function()
			replica:Destroy()
		end)
	end)
end

for _, existingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, existingPlayer)
end
Players.PlayerAdded:Connect(setupPlayer)
