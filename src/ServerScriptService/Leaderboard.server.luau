---|| Services ||--
local Players = game:GetService("Players")
local Replicated_Storage = game:GetService("ReplicatedStorage")

local Data_Store_Service = game:GetService("DataStoreService")

local Ordered_Data_Store = Data_Store_Service:GetOrderedDataStore("Leaderboard.v1")

local Get_Donations = Replicated_Storage.Remotes.GetDonations

local function GetRankedPlayers()
	
	local CurrentWinnerList = {}
	
	local Sucess,Erorr = pcall(function()
		local Data = Ordered_Data_Store:GetSortedAsync(false, 10)
		local Wins_Page = Data:GetCurrentPage()

		for Rank,Data in ipairs(Wins_Page) do
			local User_Name = Players:GetNameFromUserIdAsync(tonumber(Data.key))
			local User_Id = Players:GetUserIdFromNameAsync(User_Name)

			local Robux = Data.value
			
			CurrentWinnerList[Rank] = {
				User_Name = User_Name,
				User_Id = User_Id,
				Robux = Robux,
			}
		end
	end)

	if not Sucess then
		print(Erorr)
	end
	

	
	return CurrentWinnerList
end

coroutine.wrap(function()
	while true do
	
		for _,Player in pairs(Players:GetPlayers()) do
			if not Player:FindFirstChild("Data") then continue end 

			local Donated_Robux = Player.Data:FindFirstChild("DonatedRobux")
			Ordered_Data_Store:SetAsync(Player.UserId, Donated_Robux.Value)

	
		end
		task.wait(10)
	end


end)()


Get_Donations.OnServerInvoke = GetRankedPlayers
