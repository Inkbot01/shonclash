local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ct = ReplicatedStorage.Utility:WaitForChild("Current Time") --make this values yourself
local Spawns = require(script:WaitForChild("Spawns"))
local apm = "AM"
local timezone = -4
local timestamp = 0
local year 
local month
local day
local hour
local mint
local sec
local wkday
local alwaysSpawn = true
RunService.Heartbeat:Connect(function()
	timestamp = os.time()+(timezone*3600)
	local t = timestamp
	
	local sec = math.floor((t%60))
	local mint = math.floor((t/60)%60)
	local hour = math.floor((t/3600)%24)
	local hour12 = hour%12
	if hour < 12 then apm = " AM"
	else apm = " PM" end
	sec = tostring((sec < 10 and "0" or "") .. sec)
	mint = tostring((mint < 10 and "0" or "") .. mint)
	hour12 = tostring((hour12 < 10 and "0" or "") .. hour12)
	--	script.Parent.Clock.Date.Text = wkday..", "..mnth .. " " .. days .. ", " .. year
	
	ct.Value = hour12 .. ":" .. mint .. ":" .. sec
	
	for name, info in pairs(Spawns) do
		if type(info) == "table" then
			--print( info.Time, ct.Value, string.find(info.Time, ct.Value))
			if string.find(info.Time, ct.Value)  then
				print(info.Time,  ct.Value, string.find(info.Time, ct.Value))
				Spawns:SpawnItem(name)
			end
		end
	end

	-- " [Saitama Has Spawned]"
	-- " [Bat Has Spawned]"
	-- " [Tatsmuki Has Spawned]"
end)