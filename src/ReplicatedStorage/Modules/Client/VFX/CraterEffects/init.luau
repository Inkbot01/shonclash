--[[
	TYPES:
	Crater
	Orbit
	Path
	Rounded Path
	Closed Path
	Wall Break
	Expanding Crater
	Expanding Orbit
	
	------------------------------
	PROPERTIES:
	
	PartCount -- INTEGER NUMBER TO DICTATE THE AMOUNT OF PARTS IN AN ORBIT/CRATER ATTACK 
	Radius -- SIZE OF A CRATER/ORBIT // For expanding you must put it in list like so: {3,10}. The first value is the staring radius, and the second being the ending radius.
	Range -- RAYCAST MAX DISTANCE DOWNWARDS
	Size -- VECTOR3 VALUE DICTATING PART SIZE
	AnimationSpeed -- HOW FAST THE PARTS SPAWN UPWARDS
	BlockSize -- THE SIZE OF A BLOCK IN A PATH (NOTE: RUN THIS VIA A LIST VALUE: {3,4} THE FIRST BEING THE INITIAL SIZE AND THE SECOND BEING THE FINAL SIZE)
	Width -- THE WIDTH OF A PATH (NOTE: RUN THIS VIA A LIST VALUE: {3,4} THE FIRST BEING THE INITIAL WIDTH AND THE SECOND BEING THE FINAL WIDTH)
	Distance -- THIS IS A PATH TRAVELS
	stepSize -- DISTANCE BETWEEN THE PATH PARTS
	HoldTime -- TIME IN SECONDS BEFORE AN EFFECT DISAPPEARS
	delayTime -- TIME BETWEEN NEXT PART IN PATH (NOTE: PUTTING THIS TO "Stepped" MAKES THE DELAY TIME RUN IN A RUNSERVICE HEARTBEAT)
	Angle -- CRATER ANGLE
	Height -- HEIGHT OF AN EXPLOSION
	Collidable -- PART COLLIDABLILITY FOR WALLBREAK AND FOR EXPLOSION
	IncreaseSpeed -- THIS IS TO CHANGE THE ANIMATION SPEED FOR EXPANDING ORBITS OR EXPANDING CRATERS
	
	
	SET UP:
	[[		NEW		]]
--[[
	local craterEffects = require(craterModule)

	craterEffects.new(Type, AnchorPoint, Properties)

	-- Lets try using orbit with a 5 radius and 8 part count at a tween speed of 0.2
	
	
	craterEffects.new(
	'Orbit', -- This is the type of effect you want
	Character.HumanoidRootPart.CFrame, -- This is the start/center point (depending on the effect)
	{
	['AnimationSpeed'] = 0.2;
	['PartCount'] = 8;
	['Radius'] = 5
	}
	)
]]
--[[		PRESETS		]]
--[[
	local craterEffects = require(craterModule)

	craterEffects.presets(Presets, AnchorPoint, Extras)

	-- This allows you to save presets using the instructions within the 'Presets' script.
	
	
	craterEffects.presets(
	'OFA', -- This is the type of effect you want
	Character.HumanoidRootPart.CFrame, -- This is the start/center point (depending on the effect)
	{
	['AnimationSpeed'] = 0.2;
	['PartCount'] = 8;
	['Radius'] = 5
	}
	)
]]


local Presets = require(script:WaitForChild('Presets'))
local Functions = require(script:WaitForChild('Styles'))

callback = function(called, ErrorType)
	return warn('CRATER MODULE ERROR:\n					'..called..' does not exist as a '..ErrorType)
end
return {
	['new'] = function(Type : string, AnchorPoint : CFrame, ... : dict)
		if Functions[Type] then
			Functions[Type](AnchorPoint, ...)
		else callback(Type, 'type')
		end
		
	end,
	['presets'] = function(Preset : string, AnchorPoint : CFrame, ... : dict)
		if Presets[Presets] then
			local Type, Settings = Presets[Preset](...)
			Functions[Type](AnchorPoint, Settings)
		else callback(Preset, 'preset')
		end
	end,
	
}