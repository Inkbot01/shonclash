--[[

ADMIN POWERS

0		Player
1		VIP/Donor
2		Moderator
3		Administrator
4		Super Administrator
5		Owner
6		Game Creator

First table consists of the different variations of the command.

Second table consists of the description and an example of how to use it.

Third index is the ADMIN POWER required to use the command.

Fourth table consists of the arguments that will be returned in the args table.
'player'	-- returns an array of Players
'userid'	-- returns an array of userIds
'boolean'	-- returns a Boolean value
'color'		-- returns a Color3 value
'number'	-- returns a Number value
'string'	-- returns a String value
'time'		-- returns # of seconds
'banned'	-- returns a value from Bans table
'admin'		-- returns a value from Admins table
-- Adding / to any argument will make it optional; can return nil!!!

Fifth index consists of the function that will run when the command is executed properly.	]]

local ToolLibrary = require(game:GetService("ServerScriptService").Core["World"]["Tool System"])
local LootLibrary = require(game:GetService("ServerScriptService").Core["World"].LootLibrary)
local RegisteredTools = require(game:GetService("ReplicatedStorage").Modules.Shared.RegisteredItems)

return {

{{'test','othertest'},{'Test command.','Example'},6,{'number','string/'},function(pl,args)
print(pl,args[1],args[2])
	end},
	
	
	{{'df','devilfruit'},{':df me niko','Changes players fruit'},3,{'player','string/'},function(pl,args)
		for _, player in pairs(args[1]) do
			if args[1] then
				print(args[2])
				if args[2]=="" or (RegisteredTools[args[2]] and RegisteredTools[args[2]].Type == "Devil Fruit") then
					local data = player:FindFirstChild("Data")
					
					if data then
						data["Devil Fruit"].Value = args[2]
						player:LoadCharacter()
					end
					
				end
			end
		end
	end,},
	
	{{'mastery'},{':mastery plr item number','Modifys a players mastery'},3,{'player','number','string'},function(pl,args)
		for _, player in pairs(args[1]) do
			if args[1] then
				local data = player:FindFirstChild("Data").Mastery
				if data[args[3]] then
					data[args[3]].MasteryLevel.Value = tonumber(args[2])
				end
			end
		end
	end,},
	
	{{'weapon','swordstyle'},{':weapon me Yoru','Changes players weapon'},3,{'player','string/'},function(pl,args)
		for _, player in pairs(args[1]) do
			if args[1] then
				if args[2]=="" or (RegisteredTools[args[2]] and RegisteredTools[args[2]].Type == "Sword Style") then
					local data = player:FindFirstChild("Data")
					
					if data then
						data["Sword Style"].Value = args[2]
					end
					
				end
				player:LoadCharacter()
			end
		end
	end,},
	
	
};