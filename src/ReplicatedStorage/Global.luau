--|| Services ||--
local Players = game:GetService("Players");

local Debris = game:GetService("Debris");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local ServerScriptService = game:GetService("ServerScriptService");


local GlobalFunctions = {}


local DataTypeConversion = {
	["string"] = "StringValue",
	["number"] = "NumberValue",
	["boolean"] = "BoolValue",
	["DateTime"] = "NumberValue"
}


function GlobalFunctions.ClearConnections(Connections)
	if typeof(Connections) ~= "table" then warn("Invalid type provided to clear connections") return end
	
	for _, Connection in ipairs(Connections) do
		Connection:Disconnect()
		Connection = nil
	end
end

function GlobalFunctions.LoadInstancesFromTable(Parent, Table, Player)
	for Index, Value in next, Table do
		if typeof(Value) == "table" then
			local Folder = Instance.new("Folder")
			Folder.Name = Index
			Folder.Parent = Parent
			GlobalFunctions.LoadInstancesFromTable(Folder, Value)
		else
			local NewValue = Instance.new(DataTypeConversion[typeof(Value)])
			NewValue.Value = Value
			NewValue.Name = Index
			NewValue.Parent = Parent
		end
	end
end

function GlobalFunctions.GetNearPlayers(StartingPosition, Radius)
	local Table = {}
	local PlayerList = Players:GetPlayers()


	for _,Player in ipairs(PlayerList) do
		local EnemyCharacter = Player.Character or Player.CharacterAdded:Wait();
		local EnemyRootPart = EnemyCharacter:FindFirstChild("HumanoidRootPart")

		if  EnemyCharacter  and EnemyRootPart then
			if (EnemyRootPart.Position - StartingPosition).Magnitude <= Radius and EnemyCharacter then
				Table[#Table + 1] = Player
			end
		end

	end

	return Table
end

function GlobalFunctions.IsAlive(Model)
	if Model and Model.PrimaryPart
		and Model:FindFirstChild("Humanoid")
		and Model.Humanoid:IsDescendantOf(workspace)
		and Model.Humanoid.Health > 0 then
		return true
	end
	return false
end

function GlobalFunctions.SecondsToHMS(Seconds)
	return string.format("%02i:%02i:%02i", Seconds/60^2, Seconds/60%60, Seconds%60)
end

function GlobalFunctions.EmitAll(Particle)
	for _, ins in pairs(Particle:GetDescendants()) do
		if ins:IsA("ParticleEmitter") then	
			if ins:GetAttribute("EmitDelay") then
				task.delay(ins:GetAttribute("EmitDelay"), function()
					ins:Emit(ins:GetAttribute("EmitCount"))
				end)
			else
				ins:Emit(ins:GetAttribute("EmitCount"))
			end
		end
	end
end

function GlobalFunctions.ClearAllBodyMovers(Part)
	for _, Child in ipairs(Part:GetChildren()) do 
		if Child:IsA("BodyForce") then
			Child:Destroy()
		end
	end
end

if RunService:IsClient() then
	local UserInputService = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")
	
	function GlobalFunctions.GetPlatform()

		if (GuiService:IsTenFootInterface() or UserInputService.GamepadEnabled) then
			return "Console"
		elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
			return "Mobile"
		else
			return "Desktop"
		end
	end
end




return GlobalFunctions