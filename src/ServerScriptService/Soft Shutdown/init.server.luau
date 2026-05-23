--[[

Credits To Merely

]]

--|| Services ||--
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--|| Variables ||--
local ReserveServerMessage = "This is a reserve server, you'll be teleported back in a moment..."
local TeleportingMessage = "This server is currently being shutdown for an update; you will be moved to a reserve server."

local WaitTime = 5

local function LoadTableFromInstanceValues(Folder, Table)
	for _,Instances in ipairs(Folder:GetChildren()) do
		if Instances:IsA("Folder") then
			Table[Instances.Name] = {}

			LoadTableFromInstanceValues(Instances, Table[Instances.Name])

			--module:To_Table(Instances,Add_In_Table[Instances.Name])
		else

			Table[Instances.Name] = Instances.Value
		end
	end
end



if (game.VIPServerId ~= "" and game.VIPServerOwnerId == 0) then
	-- this is a reserved server without a VIP server owner
	Players.PlayerAdded:Connect(function(Player)
		local PlayerGui = Player:WaitForChild"PlayerGui"
		local ShutdownUI = script.ShutdownUI:Clone()
		ShutdownUI.TextLabel.Text = ReserveServerMessage
		ShutdownUI.Parent = PlayerGui
		
		wait(WaitTime)
		TeleportService:Teleport(game.PlaceId, Player)
	end)
	
	for _, Player in ipairs(Players:GetPlayers()) do
		local PlayerGui = Player:WaitForChild"PlayerGui"
		local ShutdownUI = script.ShutdownUI:Clone()
		ShutdownUI.TextLabel.Text = ReserveServerMessage
		ShutdownUI.Parent = PlayerGui
		
		wait(WaitTime)
		TeleportService:Teleport(game.PlaceId, Player)
	end
else
	game:BindToClose(function()
		if (#Players:GetPlayers() == 0) then
			return
		end
		
		if (RunService:IsStudio()) then
			return
		end
		
		for _, Player in ipairs(Players:GetPlayers()) do
			local PlayerGui = Player:WaitForChild"PlayerGui"
			local ShutdownUI = script.ShutdownUI:Clone()
			ShutdownUI.TextLabel.Text = TeleportingMessage
			ShutdownUI.Parent = PlayerGui
			
			LoadTableFromInstanceValues(Player.Data, _G.GetData(Player))
		end
		
		wait(WaitTime*2)
		local ServerCode = TeleportService:ReserveServer(game.PlaceId)
		
		for _, Player in ipairs(Players:GetPlayers()) do
			TeleportService:TeleportToPrivateServer(game.PlaceId, ServerCode, {Player})
		end
		
		Players.PlayerAdded:Connect(function(Player)
			TeleportService:TeleportToPrivateServer(game.PlaceId, ServerCode, {Player})
		end)

		while (#Players:GetPlayers() > 0) do
			RunService.Stepped:Wait()
		end	
	end)
end