--|| Services ||--
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Debris = game:GetService("Debris")

local RunService = game:GetService("RunService")

--|| Directories
local Remotes = ReplicatedStorage.Remotes

--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)
local DamageAPI = require(ServerScriptService.Core.Mechanics["Damage API"])

local Global = require(ReplicatedStorage.Global)

--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> Player State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")

local StateLibrary = Directory.Import("StateLibrary", "Shared")

local AnimationService = Directory.Import("AnimationService", "Shared")

--> Utility
local Utility = Directory.Import("Utility", "Shared")

local NetworkStream = Directory.Import("NetworkStream", "Shared")
local HitboxLibrary = Directory.Import("HitboxLibrary", "Shared")

local RaycastService = Directory.Import("RaycastService", "Shared")
--|| Networking ||--
local AbilityRequest = Remotes.Ability
local Effect = Remotes.Effect



local Superhuman = {
	["Dash"] = function(Player, AbilityData, ExtraData)

		local Character = Player.Character
		if ExtraData.Direction == "Forward" then
			local WeldHitbox = Instance.new("Part")
			WeldHitbox.CFrame = Character["Right Arm"].CFrame
			WeldHitbox.Size = Vector3.new(1.5, 1.5, 3)
			WeldHitbox.Transparency = 1
			WeldHitbox.Color = Color3.fromRGB(255, 10, 96)
			WeldHitbox.CanCollide = false
			WeldHitbox.Name = "Hitbox"
			WeldHitbox.Parent = workspace.World.Visuals

			local WeldConstraint = Instance.new("WeldConstraint")
			WeldConstraint.Part0 = Character["Right Arm"]
			WeldConstraint.Part1 = WeldHitbox
			WeldConstraint.Parent = Character["Right Arm"]

			Debris:AddItem(WeldConstraint, 1)
			Debris:AddItem(WeldHitbox, 1)

			local EncompassingEntities = {}
			
			local InitiatedCombo = false
			
			WeldHitbox.Touched:Connect(function(Target)

				local Humanoid = Target.Parent:FindFirstChild("Humanoid")


				if Humanoid then
					local ValidEntity = Humanoid.Parent
					if not EncompassingEntities[Humanoid.Parent] then
						EncompassingEntities[Humanoid.Parent] = Humanoid.Parent

						if Global.IsAlive(Humanoid.Parent) then
							local Harmed =	DamageAPI.InflictDamage(Character, Humanoid.Parent, AbilityData, script.Name)


							StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Stunned", .75)
							StateLibrary.ModifyState(Players:GetPlayerFromCharacter(ValidEntity) or ValidEntity, "Speed", .75, {
								Priority = 1,

								WalkSpeed = 0,
								JumpPower = 0
							})
							
							InitiatedCombo = true
						end
					end
				end

			end)
			
			task.wait(.65)
			if not InitiatedCombo then
				

				StateLibrary.ModifyState(Player, "Speed", .15, {
					Priority = 1,

					WalkSpeed = 0,
					JumpPower = 0
				})
				StateLibrary.ModifyState(Player, "Stunned", .15)
			end
		
		end
	end,

}

return Superhuman