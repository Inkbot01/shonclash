--|| Services ||--
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--||Imports||--
local Global = require(ReplicatedStorage.Global)

--||Remotes||--
local Remotes = ReplicatedStorage.Remotes

local CachedRemotes = {}

local Children = Remotes:GetDescendants()

for _,Remote in ipairs(Children) do
	if Remote:IsA("RemoteEvent") or Remote:IsA("RemoteFunction") then
		CachedRemotes[Remote.Name] = Remote
	end
end

local NetworkStream = {}

function NetworkStream.FireAllClients(Entity, RemoteName, RenderDistance, ...)
	RenderDistance = RenderDistance or 20
	--Entity = Entity.Character or Entity
	
	if not Global.IsAlive(Entity) then return end
	
	local RenderPlayers = Global.GetNearPlayers(Entity.PrimaryPart.Position,RenderDistance)

	for _,Player in ipairs(RenderPlayers) do
		CachedRemotes[RemoteName]:FireClient(Player, ...)
	end
end

function NetworkStream.FireOneClient(Player, RemoteName, ...)
	
	if not Player:IsA("Player") and not Players:GetPlayerFromCharacter(Player) then return end 
	
	
	local ValidPlayer = Players:IsA(Player) and Player or Players:GetPlayerFromCharacter(Player)
	
	CachedRemotes[RemoteName]:FireClient(Player, ...)
end


function NetworkStream.FireServer(Player, RemoteName, ...)
	local SelectedRemote = CachedRemotes[RemoteName]

	if SelectedRemote then
		SelectedRemote:FireServer(...)
	end

end

function NetworkStream.GetRemote(RemoteName)
	return CachedRemotes[RemoteName] or warn("could not find remote")
end

return NetworkStream