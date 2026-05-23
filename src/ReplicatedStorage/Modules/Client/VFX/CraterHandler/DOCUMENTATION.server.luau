--[[		DOCUMENTATION		]]--


--[[
THIS MODULE IS FOR CLIENT-SIDED EFFECTS ONLY
THIS MODULE IS NOT BACKWARDS COMPATIBLE WITH THE OLD CRATERHANDLER MODULE
SPELLING MATTERS, PLEASE SPELL THINGS THE WAY THEY ARE TYPED OUT IN THIS MODULE FOR THE DIFFERENT STYLES, MODES AND PROPERTIES


--		SET-UP		--
Place the "SERVERSCRIPTSERVICE" folder into ServerScriptService to allow for some effects to be used.

Require the module into the script you want it to use. 
Set up the module by calling it:

CraterHandler.new() or CraterHandler.preset()

The first param is the effect or preset you want to use // View the STYLE section to see list
The second param is the 'AnchorPoint' which is the CFrame where the effect will start
The third param are for the properties related to the effect // View the PROPERTIES section to see list

--------
CraterHandler.preset()

The preset section allows you to save specific types of craters you may want and still be able to change how the preset behaves.
It's basically where you can create your own module, have it save how it does whatever's in the module and reuse through multiple scripts.
A test preset has been made to show you a quick and easy set-up
--------
CraterHandler.new()

this is where you can create a new type of effect from the pre-made effects and edit them with easy.
--------

Set the properties up via a table inside the function.

CraterHandle.preset('OFA', Root.CFrame {
	Range = 30,
	Height = {.25, .7}
})

or 

CraterHandle.new('Crater', Root.CFrame {
	Range = 30,
	Height = {.25, .7},
	BlockSize = {1, 1.5}
})
--



--		STYLES		--
Properties for all styles: BlockSize, Height, Angle, Tilt, Range, HoldTime, FlourishType, IterateSpeed

--
Crater : A circlular crater where the parts are all connected rather than all be a cubic shape
Properties for this specific style: Radius, PartCount, PartOffset, CircleComplete

--
ChunkCrater : Similar to the Chunk style except it features a more realistic look with having a dirt-colored block pop underneath the main block.
Properties for this specific style: Radius, PartCount, PartOffset, CircleComplete

--
Path : Dual lanes where blocks go for a certain distance in a straight or curved path depending on the properties.
Properties for this specific style: Height, RightCurve, LeftCurve, RightOffset, LeftOffset, Distance, Width, StepSize

--
Orbit : A circlular crater where the parts are all connected rather than all be a cubic shape
Properties for this specific style: Radius, PartCount, PartOffset, CircleComplete

--
Break : An explosion of parts appear
Properties for this specific style: Radius, PartCount, Width

--



--		MODES		--

Appear Modes -- Modes that are best used for Entrance Flourish

FadeIn : Parts transparency fades it in

Grow : Part comes out from the ground

Enlarge : Parts size increases from 0 to the regular size

----------------------------------------------------------------

Disappear Modes -- Modes that are best used for Exit Flourish

FadeOut : Parts transparency fades it out

Melt : Part melts back into the ground

Shrink : Parts size goes from regular size to 0



--		PROPERTIES		--
These all must be within the 

--
Radius : [INTEGER] The distance from the centre of the AnchorPoint to the edge of the specified distance

Ex: Radius = 15 -- Radius will be 15
Used In Styles: Break, Crater, Orbit, ChunkCrater

--

PartCount : [INTEGER] The number of parts instanced

Ex: PartCount = 30 -- This will instance 30 parts
Used In Styles: Break, Crater, Orbit, ChunkCrater

--

BlockSize : [TABLE] The size of the parts instanced. The first value of the array is the smallest size the part can be, the second value is the largest size.

Ex: BlockSize = {1.5, 6} -- Parts minimum size will be 1.5 and max will be 6
Used In ALL STYLES

--

Range : [INTEGER] The range of detection for the raycast.

Ex: Range = 40 -- The raycast will detect up til 40 studs
Used in ALL STYLES

--

FlourishTypes : [TABLE] Specifies the two types of flourishes of how the part tweens in and out. As well as their speeds.

Ex: FlourishTypes = {
	Entrance = "Grow", -- The entrance flourish
	EntranceSpeed = .5, -- The entrance tween speed
	ExitSpeed = .25, -- The exist tween speed
	Exit = "Shrink" -- The exit flourish
}
Used in ALL STYLES

--

IterateSpeed : [TABLE] Specifies four settings in which you can set the tempo of how the parts come out and divide them into sections.

Ex: IterateSpeed = {
	Entrance = .25, -- This will dictate the speed
	EntranceDivision = 2, -- This is how many sections you want it to split into
	Exit = 'Stepped', -- Same as 'Entrance' but for exiting. You can use 'Stepped' for both Entrance and Exit to make it do it at a speed of 1/60th of a second
	ExitDivision = 'Iterate', -- Same as 'EntranceDivision' but for exiting. You can use 'Iterate' for both 'EntranceDivision' and 'ExitDivision' to allow each part to come out individually
}
Used in ALL STYLES

--

Width : [TABLE] Describes the Width between the parts in the Path setting to and uses two values to dictate it. For the 'Break' effect it dictates the max amount of distance parts will travel.

Ex: Width = {3, 5} -- Starts at a spacing of 3, ends at a spacing of 5 in a Path
or Width = {-8, 8} -- Covers front and back distance of 8 in a Break effect.
Used in Path, Break

--

Height : [TABLE] Describes the minimum and maximum height of parts, for a bigger explosion in Break, set this value much higher

Ex: Height = {-.8, .75} -- This will cause a little irregularity in Craters and Orbits making them look more realistic with a little offsetting
or Height = {15, 35} -- This is a much better setting for Break effects as it makes the parts shoot up higher
Used in ALL STYLES

--

Angle : [TABLE] Describes the minimum and maximum angle for parts

Ex: Angle = {-65, 65} will turn the part 65 front or back
Used in ALL STYLES

--

Tilt : [TABLE] Describes the minimum and maximum tilt for parts

Ex: Tilt = {-15, 15} -- Similar to Angle best to keep this number not too high
Used in ALL STYLES

--

HoldTime : [INTEGER] The amount of time the effect lasts

Ex: HoldTime = 10 -- The effect will last a time of 10 seconds before it'll be removing itself
Used in ALL STYLES

--

PartOffset : [INTEGER] The minimum or maximum a part offsets front or back

Ex: PartOffset = {-.85, .99} -- I'tll move the part in a range of either .85 back or a maximum or .99 forward
Used in Crater, ChunkCrater, Orbit

--

RightOffset / LeftOffset : [INTEGER] Having the Curvature of a path be affected either closer to the front or closer to the beginning, two different settings for the Left or Right path.

Ex: RightOffset = 4 -- Moves the curve 4 studs forward
or LeftOff = 3.5 -- Can also be a float
Used in Path

--

RightCurve / LeftCurve : [Integer] Intensity of curvature for either the right or left path in a Path effect

Ex: RightCurve = 8 -- Depending on the distance, this number may not make the curve as intense as you want it, try to base it off distance
or LeftCurve = 12.5 -- Can also be a float
Used in Path

--

CircleComplete : [Integer] This is the percentage a Crater, ChunkCrater or Orbit circle will be completed.

Ex: CircleComplete = .5 -- Half the circle will be done, the default is 1 meaning the full circle will be finished
Used in Crater, ChunkCrater, Orbit
--

StepSize : [Integer] The for loop step size in a Path

Ex: StepSize = 2 -- This will theoretically halve your partcount for a Path, if you're aiming to add more parts, make the number a decimal
Used in Path

--

PauseThread : [BOOLEAN] If true, it'll pause your current threat to execute the effects

--
]]