--|| Services ||--
local RunService = game:GetService("RunService")

local Client = RunService:IsClient()

local VFXHandler = {}

for _, v in ipairs(script:GetChildren()) do
	if v:IsA("ModuleScript") then
		VFXHandler[v.Name] = require(v)
	end
end

return VFXHandler