--|| Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Global = require(ReplicatedStorage.Global)

--local DailyQuests = require(script.DailyQuests)

local TableUtility = require(ReplicatedStorage.Modules.Utility.TableLibrary)
local OutfitData = require(ReplicatedStorage.Modules.Shared.OutfitData)

--|| Remote

local InventoryRemote = ReplicatedStorage.Remotes.Inventory

local NetworkStream = require(ReplicatedStorage.Modules.Utility:WaitForChild("NetworkStream"))
local NotifyRemote = ReplicatedStorage.Remotes.Notify

local Inventory = {}


InventoryRemote.OnServerEvent:Connect(function(Player, Data)
	local PlayerData = Player:FindFirstChild("Data")
	
	local Inventory = PlayerData.Inventory
	local EquippedItems = PlayerData.EquippedItems
	
	local EquippedWeapon = PlayerData.EquippedWeapon
	
	print(Data)
	if Data.Category == "Outfits" then
		if EquippedItems[Data.Type].Value == Data.Item then
			EquippedItems[Data.Type].Value = ""
		else
			EquippedItems[Data.Type].Value = Data.Item
			
		end
	elseif Data.Category == "Weapons" then
		EquippedWeapon.Value = EquippedWeapon.Value == Data.Item and "" or Data.Item
	end
end)

return Inventory
