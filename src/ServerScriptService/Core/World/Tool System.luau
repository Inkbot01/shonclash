--|| SERVICES ||--
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TweenService = game:GetService("TweenService")

local HttpService = game:GetService("HttpService")

local AccessoryStorage = ServerStorage.Accessories
local ToolStorage = ServerStorage.Tools

--|| Imports
local RegisteredItems = require(ReplicatedStorage.Modules.Shared.RegisteredItems)

local SwordManager = require(ReplicatedStorage.Modules.Shared["Weapon Managers"]["Sword Manager"])

local Database = require(ReplicatedStorage.Modules.Shared.Database)

local ListPriority = {
	["FirstAbility"] = 1,
	["SecondAbility"] = 2,
	["ThirdAbility"] = 3,
	["FourthAbility"] = 4
}

--|| Remotes ||--
local StorageRemote = ReplicatedStorage.Remotes.Store
local NotifyRemote = ReplicatedStorage.Remotes.Notify

local ToolDirectory = ServerStorage.Tools

local ToolSystem = {}

function ToolSystem.LoadToolbar(Player)
	
	--> Attach Accessories
	
	local Data = Player:WaitForChild("Data")
	
	
	--Player:WaitForChild("Accessory")
	
	if Player.Data["Ability"].Value ~= "" then
		--[[
		local FightingTool = Instance.new("Tool")
		FightingTool.Name = Player.Data["Ability"].Value
		FightingTool.CanBeDropped = false
		FightingTool.RequiresHandle = false
		FightingTool.Parent = Player.Backpack
		--]]
		
		if Player.Data["Ability"].Value ~= "" then

			local CharacterData = Database.GetCategoryData(Player, Player.Data["Ability"].Value)
print(CharacterData)
			local ToolListArray = {}

			for AbilityName, AbilityData in pairs(CharacterData) do 
				print(AbilityName, AbilityData)
				if string.find(AbilityName, "Ability") then
					ToolListArray[#ToolListArray + 1] = AbilityName

				end
			end 

			table.sort(ToolListArray, function(A, B)
				if ListPriority[A] < ListPriority[B] then
					return A < B
				end
			end)

			for _, ToolName in ipairs(ToolListArray) do 
				local FightingTool = Instance.new("Tool")
				FightingTool.CanBeDropped = false
				FightingTool.Name = CharacterData[ToolName].Name
				FightingTool.Parent = Player.Backpack
			end
			
			if Player.Data["EquippedWeapon"].Value ~= "" then
				SwordManager.EquipWeapon(Player, Player.Data["EquippedWeapon"].Value)
			end
			
			
		end
		
	end


	--[[
	for _, CurrentEquipped in ipairs(Player.EquippedAccessories:GetChildren()) do
		if CurrentEquipped.Value ~= "" then 
			local AccessoryTool = Instance.new("Tool")
			AccessoryTool.Name = CurrentEquipped.Value
			AccessoryTool.CanBeDropped = false
			AccessoryTool.RequiresHandle = false
			AccessoryTool.Parent = Player.Backpack
	
			AccessoryAPI.EquipAccessory(Player, AccessoryTool.Name)
			
			AccessoryTool.Activated:Connect(function()
			
				if Player:FindFirstChild("AccessoryCooldown") then return end 
				
				if Player.EquippedAccessories:FindFirstChild(AccessoryStorage:FindFirstChild(AccessoryTool.Name):GetAttribute("Type")).Value == AccessoryTool.Name then
					
					AccessoryAPI.UnequipAccessory(Player, AccessoryTool.Name)
				else 
				
					AccessoryAPI.EquipAccessory(Player, AccessoryTool.Name)
				end
				
			end)
		end
	end
	--]]
end

function ToolSystem.InsertItem(Player, Item)
	
	local ItemData = RegisteredItems[Item]
	

	if not ItemData then return end 

		
	if ItemData.Type == "Sword Style" then 
		local newTool = Instance.new("Tool")
		newTool.CanBeDropped = false
		newTool.RequiresHandle = false
		newTool.Name = Item
		newTool.Parent = Player.Backpack

		SwordManager[Item].LoadCase(Player.Character)
		SwordManager[Item].UnequipWeapon(Player.Character)

		newTool.Equipped:Connect(function()
			SwordManager[Item].EquipWeapon(Player.Character)
		end)

		newTool.Unequipped:Connect(function()
			SwordManager[Item].UnequipWeapon(Player.Character)
		end)
	elseif ItemData.Type == "Devil Fruit" then
		local FruitTool = Instance.new("Tool")
		FruitTool.Name = Player.Data["Devil Fruit"].Value
		FruitTool.CanBeDropped = false
		FruitTool.RequiresHandle = false
		FruitTool.Parent = Player.Backpack

		if FruitTool.Name == "Light" then
			FruitTool.Equipped:Connect(function()

				SwordManager["Light Sword"].EquipWeapon(Player.Character)
			end)

			FruitTool.Unequipped:Connect(function()

				SwordManager["Light Sword"].UnequipWeapon(Player.Character)
			end)
		end
		
	elseif ItemData.Type == "Fighting Style" then
		local FightingTool = Instance.new("Tool")
		FightingTool.Name = Player.Data["Fighting Style"].Value
		FightingTool.CanBeDropped = false
		FightingTool.RequiresHandle = false
		FightingTool.Parent = Player.Backpack
	end
	
end

function ToolSystem.RewardFruit(Player, Fruit)
	local ClonedTool = ToolStorage[Fruit]:Clone()
	ClonedTool.Parent = Player.Backpack

	local EatConnection 

	EatConnection = ClonedTool.Activated:Connect(function()
		local Player = Players:GetPlayerFromCharacter(ClonedTool.Parent)
		if Player then

			EatConnection:Disconnect()
			EatConnection = nil

			ClonedTool.CanBeDropped = false -- Prevent dropping the fruit while eatingi t

			--> add eat animationm

			Player.Data["Devil Fruit"].Value = ClonedTool.Name


			--| Visual Animation
			--animation:FireClient(Player, "Play", ReplicatedStorage.Animations.Eat)
			ClonedTool:Destroy()


			local Tool = Player.Character:FindFirstChildOfClass("Tool")
			if Tool and RegisteredItems[Tool.Name].Type == "Devil Fruit" and not Tool:FindFirstChild("Handle") then
				Tool:Deactivate()
				Tool:Destroy()
			end	

			for _, Tool in ipairs(Player.Backpack:GetChildren()) do
				if RegisteredItems[Tool.Name] then
					if  RegisteredItems[Tool.Name].Type == "Devil Fruit" and not Tool:FindFirstChild("Handle") then
						Tool:Deactivate()
						Tool:Destroy()

						break
					end
				end

			end

			ToolSystem.InsertItem(Player, Fruit)
		end
	end)

end

StorageRemote.OnServerEvent:Connect(function(Player, Item)
	
	local ToolData = RegisteredItems[Item]
	--> item does not exist
	if not ToolData or ToolData.Type == "Fighting Style" then return end
	
	--> if inside inventory
	if Player.Data.Inventory:FindFirstChild(Item) then 
	
		
		--> tool type slot is filled in player
		if Player.Data[ToolData.Type].Value ~= "" then  NotifyRemote:FireClient(Player, {Text = string.format("<Font=GothamBold><Color=Red><AnimateStyle=Rainbow><AnimateStepFrequency=.3> You cannot hold multiple %s types", ToolData.Type) , Duration = 2}) return end
		
		Player.Data.Inventory[Item]:Destroy()
		
		Player.Data[ToolData.Type].Value = Item 
		
		--> do connections for tool to equip
		
		ToolSystem.InsertItem(Player, Item)
		
	elseif Player.Data[ToolData.Type].Value == Item then 
		
		
		
		local Tool = Player.Character:FindFirstChildOfClass("Tool")
		if Tool and Tool.Name == Item and not Tool:FindFirstChild("Handle") then
			Tool:Deactivate()
			Tool:Destroy()
		end	

		for _, Tool in ipairs(Player.Backpack:GetChildren()) do
			if Tool.Name == Item  and not Tool:FindFirstChild("Handle") then
				Tool:Deactivate()
				Tool:Destroy()

				break
			end
		end

		Player.Character[ToolData.Type == "Accessory" and "Accessories" or ToolData.Type == "Sword Style" and "Swords"]:ClearAllChildren()
	
		
		Player.Data[ToolData.Type].Value = ""
		
		local NewInventoryItem = Instance.new("NumberValue")
		NewInventoryItem.Name = Item 
		NewInventoryItem.Value = 1
		NewInventoryItem.Parent = Player.Data.Inventory
		
	end
end)

return ToolSystem