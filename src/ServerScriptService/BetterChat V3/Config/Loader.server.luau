-- Author: @Jumpathy
-- Name: loader.lua
-- Description: Better chat loader

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local inDevelopment = false
local configuration = require(script.Parent)
local toRequire = inDevelopment and  game:GetService("ServerScriptService"):WaitForChild("MainModule") or 9375790695
local addons = script.Parent.Parent:WaitForChild("Addons")

local TitleRemote = ReplicatedStorage.Remotes.Title

require(toRequire)(configuration,addons)

TitleRemote.OnServerEvent:Connect(function(Player, TitleName)
	
	local PlayerData = Player:FindFirstChild("Data")
	if not PlayerData then return end 
	
	local ChatTitleData = PlayerData.Inventory:FindFirstChild("ChatTitles")
	
	if not ChatTitleData:FindFirstChild(TitleName) then return end 
	

	if not configuration.ChatTags.Users[Player.UserId] then
		configuration.ChatTags.Users[Player.UserId] = {
			{
				Text = TitleName,
				Color = Color3.fromRGB(0, 81, 255)
			}
		}
		
	else
		
		if configuration.ChatTags.Users[Player.UserId][1].Text == TitleName then return end 
		
		configuration.ChatTags.Users[Player.UserId][#configuration.ChatTags.Users[Player.UserId] + 1] = {
			Text = TitleName,
			Color = Color3.fromRGB(0, 81, 255)
		}
		
	end
	
end)