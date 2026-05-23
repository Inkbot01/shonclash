--|| Services
local MarketPlaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")

local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GiftRemote = ReplicatedStorage.Remotes.Gift
local Code = ReplicatedStorage.Remotes.Code

local Notify = ReplicatedStorage.Remotes.Notify

local CodeDatabase = require(script.CodeDatabase)

local ToolStorage = ServerStorage.Tools

local ToolSystem = require(ServerScriptService.Core.World["Tool System"])
local LootLibrary = require(ServerScriptService.Core.World.LootLibrary)

local QuestAPI = require(ServerScriptService.Core.World.QuestAPI)

local RegisteredItems = require(ReplicatedStorage.Modules.Shared.RegisteredItems)

local DeveloperProductFunctions = {}

local GiftTable = {}


local StatList = {"Strength", "Defense", "Gun", "Fruit", "Sword"}

DeveloperProductFunctions["15 Min Exp Boost"] = function(Info, Player)
	if Player:FindFirstChild("Boosts") then
		Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value + 900
	end
end 
DeveloperProductFunctions["1 Hour Exp Boost"] = function(Info, Player)
	if Player:FindFirstChild("Boosts") then
		Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value + 3600
	end
end 

DeveloperProductFunctions["3 Hour Exp Boost"] = function(Info, Player)
	if Player:FindFirstChild("Boosts") then
		Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value + 10800
	end
end 
DeveloperProductFunctions["6 Hour Exp Boost"] = function(Info, Player)
	if Player:FindFirstChild("Boosts") then
		Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value + 21600
	end
end 
DeveloperProductFunctions["12 Hour Exp Boost"] = function(Info, Player)
	if Player:FindFirstChild("Boosts") then
		Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value + 43000
	end
end 

--> Gems
DeveloperProductFunctions["100 Gems"] = function(Info, Player)
	print("1")
	Player.Data.Gem.Value = Player.Data.Gem.Value + 100
	
	Notify:FireClient(Player, {Text = "<Font=GothamSemibold><AnimationStyle=Wiggle><Color=LightBlue><AnimateStepFrequency=.3> You have purchased 100 gems!", Duration = 1.5})
end

DeveloperProductFunctions["1000 Gems"] = function(Info, Player)
	Player.Data.Gem.Value = Player.Data.Gem.Value + 1000
end

DeveloperProductFunctions["2200 Gems"] = function(Info, Player)
	Player.Data.Gem.Value = Player.Data.Gem.Value + 2200
end

DeveloperProductFunctions["4400 Gems"] = function(Info, Player)
	Player.Data.Gem.Value = Player.Data.Gem.Value + 4400
end

DeveloperProductFunctions["5500 Gems"] = function(Info, Player)
	Player.Data.Gem.Value = Player.Data.Gem.Value + 5500
end


--> 

DeveloperProductFunctions["10 Robux"] = function(Info, Player)
	Player.Data.DonatedRobux.Value = Player.Data.DonatedRobux.Value + 10
end

DeveloperProductFunctions["100 Robux"] = function(Info, Player)
	Player.Data.DonatedRobux.Value = Player.Data.DonatedRobux.Value + 100
end

DeveloperProductFunctions["1,000 Robux"] = function(Info, Player)
	Player.Data.DonatedRobux.Value = Player.Data.DonatedRobux.Value + 1000
end

DeveloperProductFunctions["10,000 Robux"] = function(Info, Player)
	Player.Data.DonatedRobux.Value = Player.Data.DonatedRobux.Value + 10000
end

DeveloperProductFunctions["100,000 Robux"] = function(Info, Player)
	Player.Data.DonatedRobux.Value = Player.Data.DonatedRobux.Value + 100000
end




local function processReceipt(Info)
	local player = Players:GetPlayerByUserId(Info.PlayerId)

	-- Determine if the product was already granted by checking the data store

	if not player:FindFirstChild("PurchaseCooldown") then
		local PurchaseCooldown = Instance.new("IntValue")
		PurchaseCooldown.Name = "PurchaseCooldown"
		PurchaseCooldown.Parent =  player

		Debris:AddItem(PurchaseCooldown, 1)
		
		local playerProductKey = Info.PlayerId .. "_" .. Info.PurchaseId
		local productData = MarketPlaceService:GetProductInfo(Info.ProductId, Enum.InfoType.Product)
		local productName = ""
		productName = productData.Name

		-- Find the player who made the purchase in the server

		if not player then
			-- The player probably left the game
			-- If they come back, the callback will be called again
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Look up handler function from 'productFunctions' table above

		local handler = DeveloperProductFunctions[productName]
print(handler)

		local GiftPlayer 


		if GiftTable[player.Name] then
			GiftPlayer = GiftTable[player.Name].GiftPerson
			print("found gift person")
		end
		-- Call the handler function and catch any errors

		local success, result = pcall(handler, Info, GiftPlayer or player)

		if not success  then -- check out for errors
			print(success, result)
			print(productName)
			warn("Error occurred while processing a product purchase; "..result)
			print("ProductId:", Info.ProductId)
			print("Player:", player)

			if GiftTable[player.Name] then GiftTable[player.Name] = nil end

			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if GiftTable[player.Name] then 

			print(player.Name, GiftPlayer)

		--	module:successNotify(GiftPlayer, string.format("<AnimateStyle=Rainbow><AnimateStepFrequency=1><Color=Purple>You have been GIFTED %s by %s", productName, player.Name))
			--module:successNotify(player, string.format("<AnimateStyle=Rainbow><AnimateStepFrequency=1><Color=Yellow>You have GIFTED %s to %s", productName, GiftTable[player.Name].GiftPerson.Name))

			GiftTable[player.Name] = nil 

		end
		-- IMPORTANT: Tell Roblox that the game successfully handled the purchase

		print("processed")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

end

MarketPlaceService.ProcessReceipt = processReceipt


GiftRemote.OnServerEvent:Connect(function(Player, GiftPlayer, Id, Data)
	if Players[GiftPlayer.Name] and Player and not Player:FindFirstChild("GiftCooldown") then

		local GiftCooldown = Instance.new("BoolValue")
		GiftCooldown.Name = "GiftCooldown"
		GiftCooldown.Parent = Player
		game.Debris:AddItem(GiftCooldown, 4)


		if GiftTable[Player.Name] then 
			warn("Gift Table exists for player, table was OVERRIDED")

			GiftTable[Player.Name] = nil
		end

		GiftTable[Player.Name] = {
			GiftPerson = GiftPlayer,
			GiftInitiated = os.clock()
		}

		MarketPlaceService:PromptProductPurchase(Player, Id)


	end
end)


Code.OnServerEvent:Connect(function(Player, CodeUsed)

	local Codes = CodeDatabase.GetCodesInRotation()
	if Player.Data.Codes:FindFirstChild(CodeUsed) == nil and Codes[CodeUsed] then

		local CodeInstance = Instance.new("StringValue")
		CodeInstance.Name = CodeUsed
		CodeInstance.Value = CodeUsed
		CodeInstance.Parent = Player.Data.Codes
	
		for Index, RewardAmount in pairs(Codes[CodeUsed]) do
			
			if Player.Data:FindFirstChild(Index) then
				Player.Data[Index].Value = Player.Data[Index].Value + RewardAmount
				
			elseif Player.Data.Boosts:FindFirstChild(Index) then
				
				Player.Data.Boosts:FindFirstChild(Index).Value = Player.Data.Boosts:FindFirstChild(Index).Value + RewardAmount
			end
		end
		
		Notify:FireClient(Player, {Text = "<Color=Green><AnimateStyle=Rainbow><AnimateStepFrequency=1><AnimateStyle=Rainbow>Code was redeemed."})
	else
		Notify:FireClient(Player, {Text = "<Color=Red><AnimateStepFrequency=1><AnimateStyle=Rainbow>Code was unable to be redeemed."})
	end
end)

coroutine.wrap(function()
	while task.wait(1) do 
		for _, Player in ipairs(Players:GetPlayers()) do 
			
			
			if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Boosts")  then 
				if Player.Data.Boosts["x2Exp"].Value > 0 then Player.Data.Boosts["x2Exp"].Value = Player.Data.Boosts["x2Exp"].Value - 1 end
				--if Player.Data.Boosts["x2Yen"].Value > 0 then Player.Data.Boosts["x2Yen"].Value = Player.Data.Boosts["x2Yen"].Value - 1 end
				
				
				
			end
		end
	end
	
end)()
