--|| Services ||--
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
--|| Imports ||--
local Directory = require(ReplicatedStorage.Directory)

local TableLibrary = Directory.Import("TableLibrary", "Shared")

--|| Variables ||--

local DefaultControls = {
	--> Abilities
	["One"] = "FirstAbility",
	["Two"] = "SecondAbility",
	["Three"] = "ThirdAbility",
	["Four"] = "FourthAbility",
	
	--["G"] = "Grip",
	
	--> Combat
	["MouseButton1"] = "Swing",
	
	--> Mechanics
	["Q"] = "Dash",
	["F"] = "Block",
	["LeftShift"] = "Run",
	["Space"] = "Geppo",
	
	["J"] = "Haki",
}


--|| Functions ||--
local function GetKeyFromValue(Value, Dictionary)
	for Index, _  in pairs(Dictionary) do
		if Dictionary[Index] == Value then return Index end
	end
end

local function GetPlatform()

	if (GuiService:IsTenFootInterface()) then
		return "Console"
	elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
		return "Mobile"
	else
		return "Desktop"
	end
end



--|| Module ||--

local KeybindManager = {}


function KeybindManager.MapKeybind(NewBindData, Category)

	for NewBindIndex, BindValue in pairs(NewBindData) do
		local PreviousBind = GetKeyFromValue(BindValue, DefaultControls[Category])

		if DefaultControls[NewBindIndex] == nil and PreviousBind then
			DefaultControls[PreviousBind] = BindValue
		end
	end

end

function KeybindManager:getValidKey(Key)

	local IsValidKey = DefaultControls[Key]

	if IsValidKey then
		return IsValidKey
	end

end

function KeybindManager:GetBoundKeys(Category)
	return self[Category] or DefaultControls
end

function KeybindManager:ReturnKeyIndex(Value)
	return GetKeyFromValue(Value, DefaultControls)
end


return KeybindManager
