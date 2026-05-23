local Handler = {}
Handler.__index = Handler
local InstanceCacher = require(script:WaitForChild('InstanceCache'))

--[[		SETTINGS		]]--
local maxCache = 200

--[[		AUXILLARY FUNCTION		]]--
local createIns = function(Object, properties)
	local InstanceObject = Instance.new(Object)
	for property, value in next, properties do
		if property ~= 'Parent' and InstanceObject[property] ~= nil then
			InstanceObject[property] = value
		end
	end
	InstanceObject.Parent = properties['Parent'] or nil
	return InstanceObject
end

--[[		MAIN FUNCTION		]]--
Handler.new = function(Instance_, ...)
	local cachedInstance = InstanceCacher.new(Instance_, ...)
	Handler[Instance_.Name] = cachedInstance
end

Handler.getInstance = function(InstanceName)
	return Handler[InstanceName] and Handler[InstanceName]:GetObject()
end
Handler.returnInstance = function(InstanceName, Instance_)
	return Handler[InstanceName] and Handler[InstanceName]:ReturnObject(Instance_)
end
return Handler
