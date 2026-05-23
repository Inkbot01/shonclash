--|| Services ||--
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")


--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)

local Utility = Directory.Import("Utility", "Shared")
local TableUtility = Directory.Import("TableLibrary", "Shared")

--|| Variables ||--

local Database = Utility:requireModules({}, script)


local GlobalInformation = {
	LastKey = "",

	LastPressed = os.clock(),

	KeysLogged = 0,
}

--|| Functions |--




--|| Module|| --

function Database.CreateProfile(Player)
	if Database.GetProfile(Player) then return end

	Database[Player] = {
		InitTimeStamp = os.clock(),

		Database = TableUtility.GetDeepCopy(Database),

		GlobalInformation = TableUtility.GetDeepCopy(GlobalInformation),
	}

end

function Database.GetProfile(Player)
	return Database[Player] or warn("no profile for player")
end

function Database.GetCategoryData(Player, Category, Key)

	local PlayerDatabase = Database.GetProfile(Player)

	if PlayerDatabase == nil then return end

	local IndexedCategory = PlayerDatabase.Database[Category] or PlayerDatabase[Category]

	return IndexedCategory[Key] or IndexedCategory
end

function Database.RemoveProfile(Player)
	if Database.GetProfile(Player) then
		Database[Player] = nil
	end
end

for _, Player in pairs(Players:GetPlayers()) do
	Database.CreateProfile(Player)
end

--> Create Profile on Player Join
Players.PlayerAdded:Connect(Database.CreateProfile)

--> Destroy Profile on Player Leave
Players.PlayerRemoving:Connect(Database.RemoveProfile)
return Database 