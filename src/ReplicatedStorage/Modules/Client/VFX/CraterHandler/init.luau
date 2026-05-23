--[[		VARIABLES		]]--
local Presets = {}
local Modes = require(script:WaitForChild('Modes'))
local Styles = require(script:WaitForChild('Styles'))

local PauseThread = false
--[[		AUXILLARY		]]--
local TableSort = function(MainTable, Table)
	for i,v in ipairs(Table) do
		if not v:IsA('ModuleScript') and v == type('Instance') then
			MainTable[v.Name] = v
		else
			MainTable[v.Name] = require(v)
		end
	end
end

--[[		SETUP		]]--
TableSort(Presets, script:WaitForChild('Presets'):GetChildren())

--[[		MODULE		]]--
local Handler = {}

Handler.new = function(Style, AnchorPoint, Properties)
	if not Properties.PauseThread then
		if not PauseThread then
			task.spawn(function()
				return Styles[Style] and Styles[Style](AnchorPoint, Properties or {})
			end)
		else
			return Styles[Style] and Styles[Style](AnchorPoint, Properties or {})
		end
		
	elseif Properties.PauseThread == false then
		task.spawn(function()
			return Styles[Style] and Styles[Style](AnchorPoint, Properties or {})
		end)
	else
		return Styles[Style] and Styles[Style](AnchorPoint, Properties or {})
	end
	
end

Handler.preset = function(Preset, AnchorPoint, Properties)
	return Presets[Preset] and Presets[Preset](AnchorPoint, Properties or {})
end


return Handler
