--|| Services 
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--|| Directories 
local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local Shared = Modules.Shared
local Utility = Modules.Utility

local StateLibrary = require(Modules.Shared.StateLibrary)

local NetworkStream = require(Modules.Utility.NetworkStream)

--- -0.0566549301, -0.254163653, 0.037109375, 0, 0, 1, -0.999995351, 0, 0, 0, -0.999995351, 0
--- -0.0535964966, -1.75727093, 0.684082031, 0.999996066, 0, 0, 0, 0.999996066, 0, 0, 0, 1

local function Weld(Part1,Part0,CFrame0,CFrame1)
	Part1.Position = Part0.Position

	local we = Instance.new("Motor6D",Part0)
	we.Part1 = Part1
	we.Part0 = Part0
	we.C0 = CFrame0 or CFrame.new()
	we.C1 = CFrame1 or CFrame.new()
end

local SwordManager = {
	EquipWeapon = function(Player, WeaponName)
		local Character = Player.Character
		
		
		for _, Child in ipairs(ReplicatedStorage.Assets.Models.Weapons[WeaponName]:GetChildren()) do 

			for _, SubChild in ipairs(Child:GetChildren()) do 
				if SubChild:IsA("BasePart") then
					SubChild.CanCollide = false
					SubChild.Massless = true
					SubChild.Anchored = false					

					local WeldPart = Character:WaitForChild(SubChild.Parent.Name)
					local ReferencePart = SubChild.Parent

					local rel= ReferencePart.CFrame:ToObjectSpace(SubChild.CFrame)

					local NewItem = SubChild:Clone()
					Weld(NewItem, WeldPart, rel)

					NewItem.Parent = Character.Swords
				end
			end

		end

	end,
	
	UnequipWeapon = function(Player, WeaponName)
		local Character = Player.Character
		
		if Character:FindFirstChild("Swords") then
			Character.Swords:ClearAllChildren()
		end
	end,
}

return SwordManager