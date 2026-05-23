--|| Services
local MarketPlaceService = game:GetService("MarketplaceService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GiftRemote = ReplicatedStorage.Remotes.Gift
local StorageRemote = ReplicatedStorage.Remotes.Store

local GamepassIds = require(script["Gamepass Ids"])
local ToolSystem = require(script.Parent.Core.World["Tool System"])

local DeveloperProductFunctions = {}

local GiftTable = {}

Players.PlayerAdded:Connect(function(Player)
	local GamepassFolder = Instance.new("Folder")
	GamepassFolder.Name = "Gamepasses"
	GamepassFolder.Parent = Player

	for Product, Id in pairs(GamepassIds) do 
		local HasGamepass = Instance.new("BoolValue")
		HasGamepass.Name = Product

		HasGamepass.Value = false

		if MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, Id) then 
			HasGamepass.Value = true
			
			if Product == "Yoru" then
				if Player.Data["Sword Style"].Value ~= "Yoru" and Player.Data.Inventory:FindFirstChild("Yoru") == nil then
					
					if Player.Data["Sword Style"].Value == "" then
						Player.Data["Sword Style"].Value = "Yoru"
						
						ToolSystem.InsertItem(Player, "Yoru")
					else
						local NewInventoryItem = Instance.new("NumberValue")
						NewInventoryItem.Name = "Yoru" 
						NewInventoryItem.Value = 1
						NewInventoryItem.Parent = Player.Data.Inventory
					end
				end
				
			end
		end

		HasGamepass.Parent = GamepassFolder
	end

	MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(Player, Id, Bought)
		if Bought then 
			local ProductInfo = MarketPlaceService:GetProductInfo(Id, Enum.InfoType.GamePass)

			local SelectedProduct = Player.Gamepasses:FindFirstChild(ProductInfo.Name)

			
			SelectedProduct.Value = true
		end
	end)

end)

StorageRemote.OnServerEvent:Connect(function(Player, SelectedSlot)
	local Gamepasses = Player:FindFirstChild("Gamepasses")
	local Data = Player:FindFirstChild("Data")
	
	local SplitString = string.gsub(SelectedSlot, "t", "t ")
	
	if (not Gamepasses or not Data) and SelectedSlot ~= "Slot1" and not Gamepasses:FindFirstChild("Storage "..SplitString).Value  then return end 
	
	
	local DataSlot = Data[SelectedSlot]
	
	--> If slot is empty
	if DataSlot.Value == "" then
		DataSlot.Value = Data.Ability.Value
		Data.Ability.Value = ""
	else 
		Data.Ability.Value = DataSlot.Value
		DataSlot.Value = ""
	end
	
	
end)