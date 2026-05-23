local LootLibrary = {}

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Debris = game:GetService("Debris")

--|| Imports
local Probability = require(script.Probability)

local ShopData = require(ReplicatedStorage.Modules.Shared.ShopData)
local RegisteredItems = require(ReplicatedStorage.Modules.Shared.RegisteredItems)

local Chances = require(script.Chances)

local CharacterRarities = require(ReplicatedStorage.Modules.Shared.CharacterRarities)
local ChestChances = require(ReplicatedStorage.Modules.Shared.ChestChances)

local SpinRemote = ReplicatedStorage.Remotes.Spin
local NotifyRemote = ReplicatedStorage.Remotes.Notify

local ShopRemote = ReplicatedStorage.Remotes.Shop
local StoreRemote = ReplicatedStorage.Remotes.Store

local CharacterPool = Probability.new(Chances)
local SpinAmount = 50

local ChestDictionary = {
	["OutfitChest"] = "Outfits",
	["EmoteChest"] = "Emotes",
	["WeaponChest"] = "Weapons",
	["ChatTitleChest"] = "ChatTitles"
}

function LootLibrary.SpinCharacter(Amount)
	local GeneratedCharacterRarity =  Amount > 1 and CharacterPool:RollPacked(Amount) or CharacterPool:Roll(1)

	
	if  type(GeneratedCharacterRarity) ~= "table" then
		if CharacterRarities[GeneratedCharacterRarity] then
			local SelectedCharacterTier = CharacterRarities[GeneratedCharacterRarity]

			
			return SelectedCharacterTier[math.random(1, #SelectedCharacterTier)]
		end
	else 
		local GeneratedCharacterList = {}
		
		for _, Item in ipairs(GeneratedCharacterRarity) do 
			if CharacterRarities[Item] then 
				local SelectedCharacter = CharacterRarities[Item]
				
				if #GeneratedCharacterList < Amount then 
					table.insert(GeneratedCharacterList, SelectedCharacter[math.random(1, #SelectedCharacter)])
				end
				
			end
		end
		
		return GeneratedCharacterList
	end
	
end

function LootLibrary.SpinRandomItem(ChestType)
	local GeneratedChestRarity = CharacterPool:Roll(1)
	
	local ChestTypeData = ChestChances[ChestType]
	
	print(ChestChances, ChestTypeData)
	if ChestTypeData then
		local SelectedChestData = ChestTypeData[GeneratedChestRarity]
		
		print(SelectedChestData)
		return SelectedChestData[math.random(1, #SelectedChestData)]
	end
	
end
local function SpinCharacter(Player)
	local Data = Player:FindFirstChild("Data")

	if not Data then return end 

	if Data.Gem.Value < SpinAmount then return end

	Data.Gem.Value = Data.Gem.Value - SpinAmount
	
	--> Add Selected Character to Unlocked Characters
	
	
	local PackedRandomizedList = LootLibrary.SpinCharacter(25)
	local Winner = PackedRandomizedList[22]
	
	Data.Ability.Value = Winner
	
	return Winner, PackedRandomizedList
end


local function GetInventoryAmount(Player, SelectedItemType)
	local ItemCounter = 0
	
	for _, Item in pairs(Player.Data.Inventory[SelectedItemType]:GetChildren()) do 
		if Item:IsA("NumberValue") then
			ItemCounter = ItemCounter + Item.Value
		end
	end
	
	return ItemCounter
end

local function SelectStoreItem(Player, ChestType)
	local Data = Player:FindFirstChild("Data")

	if not Data then return end 

	local SelectedChestData = ShopData[ChestType]
	if SelectedChestData then

		--> script for duplicates later
		if Data.Gem.Value >= SelectedChestData.Price then
			
			
			local RandomOutfit = LootLibrary.SpinRandomItem(ChestType)
			print(RandomOutfit)
			
			local SelectedItemType = ChestDictionary[ChestType]
			
			--> check if has duplicate
			if SelectedItemType == "Outfits" or SelectedItemType == "Weapons" then 
				local MaxItemTypeCap = SelectedItemType == "Weapons" and Player.Data.MaxWeaponSlot.Value or Player.Data.MaxOutfitSlot.Value
				
				if GetInventoryAmount(Player, SelectedItemType) >= MaxItemTypeCap then
					NotifyRemote:FireClient({Text = "You have reached max capactity for "..SelectedItemType})
					return
				end
			end
			
			--> subtract amount 
			Data.Gem.Value = Data.Gem.Value - SelectedChestData.Price
		
			if not Data.Inventory[SelectedItemType]:FindFirstChild(RandomOutfit) then
				
				local NewOutfit = Instance.new("NumberValue")
				NewOutfit.Name = RandomOutfit
				NewOutfit.Value = 1
				
				NewOutfit.Parent = Data.Inventory[SelectedItemType]
			else
				Data.Inventory[SelectedItemType]:FindFirstChild(RandomOutfit).Value =  Data.Inventory[SelectedItemType]:FindFirstChild(RandomOutfit).Value + 1
			end
			
			return RandomOutfit

		end
	end 
end

SpinRemote.OnServerInvoke = SpinCharacter
ShopRemote.OnServerInvoke = SelectStoreItem
	

--[[
function LootLibrary.AttemptDrop(NPC)
	local GeneratedChestTier = PoolCache:Roll(1)

	
	if Drops[NPC] then
		local IndexedNpc = Drops[NPC]
		if table.find(Drops[NPC], GeneratedChestTier) then
		
			if TierPoolCache[GeneratedChestTier] then 
				local RolledItems = TierPoolCache[GeneratedChestTier].Roller:RollPacked(math.random(1, 4))
				
				return RolledItems, GeneratedChestTier
			end
		end
	end
end
--]]



return LootLibrary