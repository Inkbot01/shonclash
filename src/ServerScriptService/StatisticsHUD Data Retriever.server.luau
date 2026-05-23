local HttpService = game:GetService("HttpService");
local ReplicatedStorage = game.ReplicatedStorage;

local StatisticsHUDRemotes = ReplicatedStorage["StatisticsHUD Remotes"];
local Data = HttpService:JSONDecode(HttpService:GetAsync('http://ip-api.com/json/'))


local getDistributedGameTime = StatisticsHUDRemotes.getDistributedGameTime;
getDistributedGameTime.OnServerInvoke = function()
	return game.Workspace.DistributedGameTime;
end

