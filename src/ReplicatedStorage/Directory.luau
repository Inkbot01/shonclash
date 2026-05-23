
--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local ServerScriptService 

if RunService:IsServer() then
	ServerScriptService = game:GetService("ServerScriptService")
end

--|| Module ||--
local Directory = {
	Shared = {},
	Server = {},
}

local ScriptEnvironments = {
	["Shared"] = ReplicatedStorage,
	["Server"] = ServerScriptService,
}

--|| Functions ||--

local function GetEnvironment()
	return RunService:IsClient() and Directory.Shared or Directory.Server
end


local function AppendFolder(Folder, SelectedEnvironment)
	SelectedEnvironment = typeof(SelectedEnvironment) == "string" and Directory[SelectedEnvironment] or GetEnvironment()

	local SelectedFolder = SelectedEnvironment[Folder]

	if SelectedFolder then return end

	table.insert(SelectedEnvironment, Folder)
end

local function MassAppend(ScriptEnvironment)
	--SelectedEnvironment = typeof(SelectedEnvironment) == "string" and Directory[SelectedEnvironment] or GetEnvironment()

	for _, Folder in pairs(ScriptEnvironments[ScriptEnvironment]:GetDescendants()) do

		if Folder:IsA("Folder") then AppendFolder(Folder, ScriptEnvironment) continue end
	end

end

local function GetModuleFromEnvironment(Module, SelectedEnvironment)

	for _, Folder in pairs(SelectedEnvironment) do
		local SelectedModule = Folder:FindFirstChild(Module)

		if SelectedModule and SelectedModule:IsA("ModuleScript") then  return SelectedModule end
	end

	return nil
end

local function FetchModule(Modules, SelectedEnvironment, FolderName)


	if typeof(Modules) == "table" then

		local PackedModules = {}

		for _, Module in ipairs(Modules) do
			local SelectedModule = GetModuleFromEnvironment(Module, SelectedEnvironment)

			if SelectedModule then PackedModules[#PackedModules + 1] = require(SelectedModule) end
		end
		
		return unpack(PackedModules)
	end

	local SelectedModule = GetModuleFromEnvironment(Modules, SelectedEnvironment)


	if SelectedModule then return require(SelectedModule) end
end


local function Init()
	if (Directory.Shared[1] == nil) then

		MassAppend("Shared")

		if ServerScriptService then 
			MassAppend("Server")
		end

	end
end

Init()


function Directory.Import(Module, SelectedEnvironment, FolderName)
	SelectedEnvironment = typeof(SelectedEnvironment) == "string" and Directory[SelectedEnvironment] or GetEnvironment()

	return FetchModule(Module, SelectedEnvironment)
end




return Directory