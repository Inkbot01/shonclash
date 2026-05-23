local Module = {}
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RetryDelay = 0.1
local MaxAttempts = 5

function Retry(CallBack,FunctionName,AttemptNumber)
	local Args = {pcall(CallBack)}
	if not Args[1] then
		if AttemptNumber == MaxAttempts then
			warn("Retry failed for:",FunctionName,"Message:",Args[2])
			return false
		else
			wait(RetryDelay)
			return Retry(CallBack,FunctionName,(AttemptNumber or 1)+1)
		end
	else
		return unpack(Args)
	end
end

if not RunService:IsStudio() then
	function Module.new(Name)
		local DataStoreTable = {
			DataStore = DataStoreService:GetDataStore(Name)
		}

		function DataStoreTable:Get(Index)
			local Success,Value = Retry(function() return self.DataStore:GetAsync(Index) end,Name..":Get:"..tostring(Index))
			return Success,Value
		end

		function DataStoreTable:Set(Index,Value)
			local Success,Value = Retry(function() return self.DataStore:SetAsync(Index,Value) end,Name..":Set:"..tostring(Index))
			return Success,Value
		end

		function DataStoreTable:Update(Index,CallBack)
			local Success,Value = Retry(function() return self.DataStore:UpdateAsync(Index,CallBack) end,Name..":Update:"..tostring(Index))
			return Success,Value
		end

		return DataStoreTable
	end
else
	function Module.new(Name)
		local DataStoreTable = {}

		function DataStoreTable:Get() return true,nil; end
		function DataStoreTable:Set() return true,nil; end
		function DataStoreTable:Update() return true,nil; end

		return DataStoreTable
	end
end

return Module