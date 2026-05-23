--|| Services ||--
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

--|| Directories
local Remotes = ReplicatedStorage.Remotes

--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)


--> Core
local Database = Directory.Import("Database", "Shared")
local KeybindManager = Database.KeybindManager

--> Player State
local DebounceAPI = Directory.Import("DebounceLibrary", "Shared")

local StateLibrary = Directory.Import("StateLibrary", "Shared")
local RegisteredItems = Directory.Import("RegisteredItems", "Shared")

--> Utility
local Utility = Directory.Import("Utility", "Shared")


local Modules = Utility:requireModules({}, script)

--|| Networking ||--
local AbilityRequest = Remotes.Ability

AbilityRequest.OnServerEvent:Connect(function(Player, Key, Category, AdditionalData)
	local Character = Player.Character 

	local RequestedModule = Modules[Category] 
	
	local PlayerData = Database.GetCategoryData(Player, Category)
	
	local AbilityData = PlayerData[Key]
	--print(AbilityData)
	
	--> Global Information
	local GlobalInformation  = Database.GetCategoryData(Player, "GlobalInformation")
--print(GlobalInformation)

	
	
	--> Main Checks
	if not Character or not RequestedModule then return end

	--> State Checks
	
	local SelectedItem = RegisteredItems[Category]
	
	if Category ~= "Movement" and Player.Data[SelectedItem.Type].Value ~= Category then return end
	
	--if Player.States.Stamina.CurrentStamina.Value < AbilityData.Stamina then return end
	
	if not DebounceAPI.IsCooldown(Player, Category, Key) then return end
	
	--if Player.Data.Mastery:FindFirstChild(Category) and AbilityData.Mastery > Player.Data.Mastery:FindFirstChild(Category).MasteryLevel.Value then return end
	--

	
	--if not StateLibrary.IsValidAction(Character, AbilityData.ActionFlag) then return end

	--add stamina/health checks later
	
	
	if  AdditionalData.Status ~= "Release" and not StateLibrary.IsValidAction(Player, AbilityData.ActionFlag) then  return end
	
	
	

	if AbilityData.Chargeable then
		if AdditionalData.Status == "Charge" then
			Player.States.Stamina.CurrentStamina.Value  = math.clamp(Player.States.Stamina.CurrentStamina.Value - AbilityData.Stamina, 0, Player.States.Stamina.MaxStamina.Value)
		end
		
		
		
	
		
		RequestedModule[Key][AdditionalData.Status](Player, AbilityData, AdditionalData)
		
		
		--GlobalInformation.LastKey = KeybindManager:ReturnKeyIndex(Key)
		
		--local Humanoid = Character.Humanoid
		
		--Humanoid:UnequipTools()
		return
	end
	--print("above")
	
	
	RequestedModule[Key](Player, AbilityData, AdditionalData)
	Player.States.Stamina.CurrentStamina.Value  = math.clamp(Player.States.Stamina.CurrentStamina.Value - AbilityData.Stamina, 0, Player.States.Stamina.MaxStamina.Value)
	

	--> Set Values
--	GlobalInformation.LastKey = KeybindManager:ReturnKeyIndex(Key)

end)




return Modules