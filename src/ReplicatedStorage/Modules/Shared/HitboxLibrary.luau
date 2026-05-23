--|| Services ||--
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)
local Global = require(ReplicatedStorage.Global)


--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")
local StateLibrary = Directory.Import("StateLibrary", "Shared")

--> Utility
local Utility = Directory.Import("Utility", "Shared")
local NetworkStream = Directory.Import("NetworkStream", "Shared")


--|| Networking ||--
local AbilityRequest = ReplicatedStorage.Remotes.Ability
local Effects = ReplicatedStorage.Remotes.Effect

--|| Variables ||--
local World = workspace.World

-- || Functions ||--


local HitboxLibrary = {}

function HitboxLibrary.GetEntitiesInRadius(StartPosition, Radius, InSight, Blacklist)
	Radius = Radius or 40
	Blacklist = Blacklist or {}


	local EntityTable = {}

	for _, Entity in ipairs(World.Entities:GetChildren()) do
		if Global.IsAlive(Entity) and (Blacklist[Entity] == nil) then
			local EntityRootPart = Entity.HumanoidRootPart

			if (StartPosition - EntityRootPart.Position).Magnitude <= Radius then 
				if InSight then


					local UnitVector = (StartPosition - EntityRootPart.Position).Unit

					local VictimLook = EntityRootPart.CFrame.lookVector
					local DotVector = UnitVector:Dot(VictimLook)



					if DotVector <=  0 then EntityTable[#EntityTable + 1] = Entity end

					continue
				end

				EntityTable[#EntityTable + 1] = Entity


			end


		end
	end

	return EntityTable, #EntityTable > 0 and true or false
end

function HitboxLibrary.GetEntitiesInPart(StartPosition, Size, Blacklist, Visualize)
	StartPosition = typeof(StartPosition) == "CFrame" and StartPosition or CFrame.new(StartPosition)
	

	local params = OverlapParams.new()
	params.CollisionGroup = "Default"
	params.FilterDescendantsInstances = {workspace.World.Visuals, Blacklist}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.MaxParts = 400
	
	if Visualize then
		local Part = Instance.new("Part")
		Part.CFrame = StartPosition
		Part.Size = Size
		Part.Transparency = .6
		Part.Color = Color3.fromRGB(255, 10, 96)
		Part.CanCollide = false
		Part.CanQuery = false
		Part.Anchored = true
		Part.Parent = workspace.World.Visuals
		Part.Name = "VisualHitbox"
		
		game.Debris:AddItem(Part, .25)
--		print(Part.CFrame)
	end
	
	local PartsInBox = workspace:GetPartBoundsInBox(StartPosition, Size, params)
	local EncompassingEntities = {}
	
	for _, EncompassingPart in ipairs(PartsInBox) do 
		local Humanoid = EncompassingPart.Parent:FindFirstChild("Humanoid")
		
		if Humanoid then
			if not EncompassingEntities[Humanoid.Parent] then
				EncompassingEntities[Humanoid.Parent] = Humanoid.Parent
			end
		end
	end
	
	return EncompassingEntities
	
end

return HitboxLibrary