local Safezones = {}


--/Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--/Modules
local module = {}
local Zones = require(ReplicatedStorage.Modules.Shared.Zone)

local Safezones = {}


local function InSafeZone(Character,Zone)
	local TouchingParts = Zone:GetTouchingParts()
	for i,v in pairs(TouchingParts) do
		if v.Parent == Character then 
			return true
		end
	end
end

local function LoadSafezones()
	print("loaded")
	for i,v in pairs(workspace.World.Zones.Safezones:GetChildren()) do
		Safezones[i] = Zones.new(v)


		
		local PlayerList = Safezones[i]:getPlayers()
	
		for _, Player in ipairs(PlayerList) do
			if Player:FindFirstChild("States") then
				Player.States.Safezone.Base.Value = true
			end
		end
		
		Safezones[i].playerEntered:Connect(function(Player)
			
			if Player and Player:FindFirstChild("States") then
				Player.States.Safezone.Base.Value = true
			end
	

			--Player.States.Safezone.Value = true
			--local PlayerGui = Player:WaitForChild("PlayerGui") 


			--Player.PlayerGui.HUD.AreaText.SafeZone.Visible = true
			--G.Notify(Player,"<b><font color = 'rgb(85, 255, 127)'>Entered Safezone</font></b>",2.2)
		end)

		Safezones[i].playerExited:Connect(function(Player)

			if not Player:FindFirstChild("States") then return end
		
			Player.States.Safezone.Base.Value = false
			
			--local PlayerGui = Player:WaitForChild("PlayerGui") 

			--Player.PlayerGui.HUD.AreaText.SafeZone.Visible = true
			--G.Notify(Player,"<b><font color = 'rgb(255, 46, 46)'>Left Safezone</font></b>",2.2)
		end)
	end
end

LoadSafezones()

return module
