local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VillianExam = ReplicatedStorage.Utility:FindFirstChild("Villian Exam")
local HeroExam = ReplicatedStorage.Utility:FindFirstChild("Hero Exam")
 --make this value yourself
local Spawns = {
	["Villian Exam"] = {
		Rarity = 1/1;
		Despawn = 600;
		Time = "8:00:00 - 12:00:00 - 4:00:00"; -- All times are in EST
		Miniboss = false;
	};
	
	["Hero Exam"] = {
		Rarity = 1/1;
		Despawn = 600;
		Time = "07:55:00"; -- All times are in EST
	};
}

function getRace(thing)
	local x = Random.new():NextNumber(0,1);
	local y = 0;
	for _,v in pairs(Spawns) do
		local percentage = v.Rarity
		if (x < percentage + y) then
			return true;
		end;
		y += percentage;
	end;
end;

function Spawns:SpawnItem(ItemName)
	if Spawns[ItemName] then
		--print("here1")
		--if getRace(ItemName) then
			if ReplicatedStorage.Utility:FindFirstChild(ItemName).Value == false then
				
				coroutine.wrap(function()
					ReplicatedStorage.Utility:FindFirstChild(ItemName).Value = true 
					task.wait(10)
					ReplicatedStorage.Utility:FindFirstChild(ItemName).Value = false
				end)()
				
			end
		--else
		--	warn("Failed to spawn",ItemName)
		--end
	else
		warn(ItemName,"is not valid")
	end
end

return Spawns