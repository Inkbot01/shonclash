--[[		SERVICES		]]--
local InstanceHandler = require(script.Parent:WaitForChild('InstanceHandler'))
local Modes = require(script.Parent:WaitForChild('Modes'))
local TweenService = game:GetService('TweenService')
local PhysicsService = game:GetService('PhysicsService')

--[[		VARIABLES		]]--
local rayParams = RaycastParams.new()
local random = Random.new()
local fullCircle = 2 * math.pi
--
local Parts = InstanceHandler.new(Instance.new('Part'), 250, 'DebrisCache')
--
rayParams.FilterType = Enum.RaycastFilterType.Whitelist
rayParams.FilterDescendantsInstances = {workspace.World.Maps}
rayParams.IgnoreWater = true

--[[		FLOURISHES		]]--
local FlourishEntrance = 'Enlarge'
local FlourishExit = 'Shrink'
local EntranceSpeed = .3
local ExitSpeed = .3
local EntranceDivision = 3
local ExitDivision = 2
--[[		AUXILLARY		]]--
local lerp = function (a, b, x)
	return a + (b - a) * x
end
local CF = function(Position)
	if typeof(Position) == 'Vector3' then
		return CFrame.new(Position)
	end
	return Position
end
local getXAndZPositions = function (angle, radius)
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius
	return x, z
end

local Bez = function (t, p0, p1, p2)
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

local InstanceObject = function (Object, Properties)
	local ObjectInstanced = InstanceHandler.getInstance(Object or 'Part') or Instance.new(Object)
	for property, value in next, Properties do
		if property ~= 'Parent' or property ~= 'ObjectName' then
			ObjectInstanced[property] = value
		end
	end
	return ObjectInstanced
end

local FireRay = function (Origin, Offset)
	local Results = workspace:Raycast(Origin.Position, Offset, rayParams)
	if Results then
		return Results.Instance, Results.Position, Results.Material, Results.Normal
	end
	return false
end

local rayPart = function (Origin, Range, Size)
	local Ins, Pos, Mat, Norm = FireRay(Origin, -Origin.UpVector * Range)
	if Ins then
		local rayPart = InstanceObject('Part', {
			['Anchored'] = true,
			['CanCollide'] = false,
			['Material'] = Mat,
			['Size'] = Size,
			['Color'] = Ins.Color,
			['Reflectance'] = Ins.Reflectance,
			['Transparency'] = Ins.Transparency,
			['CFrame'] = CF(Pos)
		})
		for i,v in ipairs(rayPart:GetChildren()) do
			v:Destroy()
		end
		for i,v in ipairs(Ins:GetChildren()) do
			if v:IsA('Texture') then
				local Texture = v:Clone()
				Texture.Parent = rayPart
			end
		end
		return rayPart, Pos
	end
end
local randInt = function (min, max)
	return random:NextNumber(min, max)
end


local CircleMath = function (AnchorPoint, Radius, PartCount, Vertical)
	local Offsets = {}
	for i = 1, PartCount + 1 do
		local angle = i * (fullCircle / PartCount)
		local x, z = getXAndZPositions(angle, Radius)
		local Offset = (AnchorPoint) * Vector3.new(x, 0, z)
		Offsets[i] = Offset
	end
	return Offsets
end

local Styles = {}

--[[		STYLES		]]--
Styles.Crater = function (AnchorPoint, Properties)
	--
	local BlockSize = Properties.BlockSize or {2, 3.5}
	local partCount = Properties['PartCount'] or 10
	local Radius = Properties['Radius'] or 8
	local Range = Properties['Range'] or 5
	local Angle = Properties['Angle'] or {45,65}
	local Height = Properties['Height'] or {0, 0}
	local Tilt = Properties['Tilt'] or {0,0}
	local PartOffset = Properties['PartOffset'] or {0, 0}
	local FlourishTypes = Properties['FlourishTypes'] or {}
	local IterationSpeed = Properties['IterateSpeed'] or {}
	local CurrentSplit = 1
	local Parts = {}
	local CircleFull = Properties['CircleComplete'] or 1
	--
	local Offsets = CircleMath(AnchorPoint, Radius, partCount)
	for i = 1, math.floor(#Offsets * CircleFull + .5) do
		--
		if Offsets[i + 1] ~= nil then
			local Offset = Offsets[i]
			local Offset2 = Offsets[i + 1]
			local Magnitude = (Offset - Offset2).Magnitude
			local getRandom = randInt(BlockSize[1], BlockSize[2])
			local newSize = Vector3.new(Magnitude + .5, getRandom, getRandom)
			local Part, Position = rayPart(CF(Offset), Range, newSize)
			--
			if Part then
				local CFrameTo = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.new(0, randInt(Height[1], Height[2]), randInt(PartOffset[1], PartOffset[2])) * CFrame.fromEulerAnglesXYZ(math.rad(randInt(Angle[1], Angle[2])),math.rad(randInt(Tilt[1], Tilt[2])),0)
				local PartProperties = {CFrame = CFrameTo}
				Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))
				--
				task.spawn(function()
					Parts[#Parts + 1] = Part
				end)
				Modes[FlourishTypes.Entrance or FlourishEntrance](Part, FlourishTypes.EntranceSpeed or EntranceSpeed, PartProperties)
				if IterationSpeed.Entrance then
					if IterationSpeed.EntranceDivision == 'Iterate' or EntranceDivision == 'Iterate' then
						if IterationSpeed.Entrance == 'Stepped' then
							task.wait()
						else
							task.wait(IterationSpeed.Entrance)
						end
					elseif math.floor((math.floor(#Offsets * CircleFull + .5) - 1) * (CurrentSplit / (IterationSpeed.EntranceDivision or EntranceDivision))) == i and i ~= math.floor(#Offsets * CircleFull + .5) -1 then
						if IterationSpeed.Entrance == 'Stepped' then
							task.wait()
						else
							task.wait(IterationSpeed.Entrance)
						end
						CurrentSplit += 1
					end
				end
			end
		end
		--
	end
	--
	CurrentSplit = 1
	task.wait(Properties['HoldTime'] or 5)
	for i = 1, #Parts do
		Modes[FlourishTypes.Exit or FlourishExit](Parts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		if IterationSpeed.Exit then
			if IterationSpeed.ExitDivision == 'Iterate' or ExitDivision == 'Iterate' then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
			elseif math.floor((#Parts) * (CurrentSplit / (IterationSpeed.ExitDivision or ExitDivision))) == i and i ~= #Parts then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
				CurrentSplit += 1
			end
		end
		task.spawn(function()
			task.wait((FlourishTypes.ExitSpeed or ExitSpeed) + .15)
			InstanceHandler.returnInstance('Part', Parts[i])
		end)
	end
end

Styles.ChunkCrater = function (AnchorPoint, Properties)
	--
	local BlockSize = Properties.BlockSize or {2, 3.5}
	local partCount = Properties['PartCount'] or 10
	local Radius = Properties['Radius'] or 8
	local Range = Properties['Range'] or 5
	local Angle = Properties['Angle'] or {45,65}
	local Height = Properties['Height'] or {0, 0}
	local Tilt = Properties['Tilt'] or {0,0}
	local PartOffset = Properties['PartOffset'] or {0, 0}
	local FlourishTypes = Properties['FlourishTypes'] or {}
	local IterationSpeed = Properties['IterateSpeed'] or {}
	local CurrentSplit = 1
	local Parts = {}
	local DirtParts = {}
	local CircleFull = Properties['CircleComplete'] or 1
	--
	local Offsets = CircleMath(AnchorPoint, Radius, partCount)
	for i = 1, math.floor(#Offsets * CircleFull + .5) do
		--
		if Offsets[i + 1] ~= nil then
			local Offset = Offsets[i]
			local Offset2 = Offsets[i + 1]
			local Magnitude = (Offset - Offset2).Magnitude
			local getRandom = randInt(BlockSize[1], BlockSize[2])
			local newSize = Vector3.new(Magnitude + .5, getRandom, getRandom)
			local Part, Position = rayPart(CF(Offset), Range, Vector3.new(Magnitude + .55, .5, getRandom + .05))
			
			--
			if Part then
				local DirtPart = InstanceObject('Part', {
					['Anchored'] = true,
					['CanCollide'] = false,
					['Material'] = Enum.Material.Slate,
					['Size'] = newSize,
					['Color'] = Color3.fromRGB(90, 76, 66),
					['CFrame'] = CF(Position),
				})
				
				DirtPart.CFrame = CFrame.lookAt(DirtPart.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))
				Part.CFrame = DirtPart.CFrame
				local CFrameTo = CFrame.lookAt(DirtPart.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.new(0, randInt(Height[1], Height[2]), randInt(PartOffset[1], PartOffset[2])) * CFrame.fromEulerAnglesXYZ(math.rad(randInt(Angle[1], Angle[2])), math.rad(randInt(Tilt[1], Tilt[2])),0)
				local PartProperties = {CFrame = CFrameTo}
				
				--
				task.spawn(function()
					Parts[#Parts + 1] = Part
					DirtParts[#DirtParts + 1] = DirtPart
				end)
				--
				Modes[FlourishTypes.Entrance or FlourishEntrance](DirtPart, FlourishTypes.EntranceSpeed or EntranceSpeed, PartProperties)
				Modes[FlourishTypes.Entrance or FlourishEntrance](Part, FlourishTypes.EntranceSpeed or EntranceSpeed, {CFrame = CFrameTo * CFrame.new(0, getRandom/2 + .15, 0)})
				if IterationSpeed.Entrance then
					if IterationSpeed.EntranceDivision == 'Iterate' or EntranceDivision == 'Iterate' then
						if IterationSpeed.Entrance == 'Stepped' then
							task.wait()
						else
							task.wait(IterationSpeed.Entrance)
						end
					elseif math.floor((math.floor(#Offsets * CircleFull + .5) - 1) * (CurrentSplit / (IterationSpeed.EntranceDivision or EntranceDivision))) == i and i ~= math.floor(#Offsets * CircleFull + .5) -1 then
						if IterationSpeed.Entrance == 'Stepped' then
							task.wait()
						else
							task.wait(IterationSpeed.Entrance)
						end
						CurrentSplit += 1
					end
				end
				--
			end
		end
		--
	end
	--
	CurrentSplit = 1
	task.wait(Properties['HoldTime'] or 5)
	for i = 1, #Parts do
		Modes[FlourishTypes.Exit or FlourishExit](Parts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		Modes[FlourishTypes.Exit or FlourishExit](DirtParts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		if IterationSpeed.Exit then
			if math.floor((#Parts) * (CurrentSplit / (IterationSpeed.ExitDivision or ExitDivision))) == i and i ~= #Parts then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
				CurrentSplit += 1
			end
		end
		task.spawn(function()
			task.wait((FlourishTypes.ExitSpeed or ExitSpeed) + .15)
			InstanceHandler.returnInstance('Part', Parts[i])
			InstanceHandler.returnInstance('Part', DirtParts[i])
		end)
	end
end

Styles.Orbit = function (AnchorPoint, Properties)
	--
	local BlockSize = Properties.BlockSize or {2, 3.5}
	local partCount = Properties['PartCount'] or 10
	local Radius = Properties['Radius'] or 8
	local Range = Properties['Range'] or 5
	local Angle = Properties['Angle'] or {45,65}
	local Height = Properties['Height'] or {0, 0}
	local Tilt = Properties['Tilt'] or {0,0}
	local PartOffset = Properties['PartOffset'] or {0, 0}
	local FlourishTypes = Properties['FlourishTypes'] or {}
	local IterationSpeed = Properties['IterateSpeed'] or {}
	local CurrentSplit = 1
	local Parts = {}
	local CircleFull = Properties['CircleComplete'] or 1
	--
	local Offsets = CircleMath(AnchorPoint, Radius, partCount)
	for i = 1, math.floor(#Offsets * CircleFull + .5) - 1 do
		local CurrentOffset = Offsets[i]
		local RandomBlockSize = randInt(BlockSize[1], BlockSize[2])
		local Part, Pos = rayPart(CF(CurrentOffset), Range, Vector3.new(RandomBlockSize, RandomBlockSize, RandomBlockSize))
		if Part then
			local CFrameTo = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.new(0, randInt(Height[1], Height[2]), randInt(PartOffset[1], PartOffset[2])) * CFrame.fromEulerAnglesXYZ(math.rad(randInt(Angle[1], Angle[2])),math.rad(randInt(Tilt[1], Tilt[2])),0)
			local PartProperties = {CFrame = CFrameTo}
			Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))
			--
			task.spawn(function()
				Parts[#Parts + 1] = Part
			end)
			Modes[FlourishTypes.Entrance or FlourishEntrance](Part, FlourishTypes.EntranceSpeed or EntranceSpeed, PartProperties)
			if IterationSpeed.Entrance then
				if IterationSpeed.EntranceDivision == 'Iterate' or EntranceDivision == 'Iterate' then
					if IterationSpeed.Entrance == 'Stepped' then
						task.wait()
					else
						task.wait(IterationSpeed.Entrance)
					end
				elseif math.floor((math.floor(#Offsets * CircleFull + .5) - 1) * (CurrentSplit / (IterationSpeed.EntranceDivision or EntranceDivision))) == i and i ~= math.floor(#Offsets * CircleFull + .5) -1 then
					if IterationSpeed.Entrance == 'Stepped' then
						task.wait()
					else
						task.wait(IterationSpeed.Entrance)
					end
					CurrentSplit += 1
				end
			end
			
			
		end
		
	end
	--
	CurrentSplit = 1
	task.wait(Properties['HoldTime'] or 5)
	for i = 1, #Parts do
		Modes[FlourishTypes.Exit or FlourishExit](Parts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		if IterationSpeed.Exit then
			if IterationSpeed.ExitDivision == 'Iterate' or ExitDivision == 'Iterate' then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
			elseif math.floor((#Parts) * (CurrentSplit / (IterationSpeed.ExitDivision or ExitDivision))) == i and i ~= #Parts then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
				CurrentSplit += 1
			end
		end
		task.spawn(function()
			task.wait((FlourishTypes.ExitSpeed or ExitSpeed) + .15)
			InstanceHandler.returnInstance('Part', Parts[i])
		end)
	end
end

Styles.Path = function (AnchorPoint, Properties)
	--
	local BlockSize = Properties.BlockSize or {1.5, 2}
	local Distance = Properties['Distance'] or 15
	local StepSize = Properties['StepSize'] or BlockSize[1]
	local WidthSize = Properties['Width'] or {1,3}
	local Range = Properties['Range'] or 5
	local Angle = Properties['Angle'] or {-1000,1000}
	local Height = Properties['Height'] or {0, 0}
	local Tilt = Properties['Tilt'] or  {-1000,1000}
	local RightCurve, LeftCurve = Properties['RightCurve'] and -Properties['RightCurve'] or 0, Properties['LeftCurve'] or 0
	local RightOff, LeftOff = Properties['RightOffset'] or 0, Properties['LeftOffset'] or 0
	local FlourishTypes = Properties['FlourishTypes'] or {}
	local IterationSpeed = Properties['IterateSpeed'] or {}
	local CurrentSplit = 1
	local RightParts = {}
	local LeftParts = {}
	
	local RightLaneStart, RightLaneEnd = AnchorPoint * CFrame.new(WidthSize[1], 0, 0), AnchorPoint * CFrame.new(WidthSize[2], 0, -Distance)
	local LeftLaneStart, LeftLaneEnd = AnchorPoint * CFrame.new(-WidthSize[1], 0, 0), AnchorPoint * CFrame.new(-WidthSize[2], 0, -Distance)
	local RightMidPoint = (RightLaneStart.Position + RightLaneEnd.Position) / 2
	local LeftMidPoint = (LeftLaneStart.Position + LeftLaneEnd.Position) / 2
	
	--
	for index = 0, Distance, StepSize do
		local WidthLerp = lerp(WidthSize[1], WidthSize[2], index/Distance)
		local SizeLerp = lerp(BlockSize[1], BlockSize[2], index/Distance)
		local RightPart = rayPart(CF(Bez(index/Distance, RightLaneStart.Position, (CFrame.lookAt(RightMidPoint, RightLaneStart.Position) * CFrame.new(RightCurve, 0, RightOff)).Position, RightLaneEnd.Position)), Range, Vector3.new(SizeLerp, SizeLerp, SizeLerp))
		local LeftPart = rayPart(CF(Bez(index/Distance, LeftLaneStart.Position, (CFrame.lookAt(LeftMidPoint, LeftLaneStart.Position) * CFrame.new(LeftCurve, 0, LeftOff)).Position, LeftLaneEnd.Position)), Range, Vector3.new(SizeLerp, SizeLerp, SizeLerp))
		--
		if RightPart then
			local PartAngle, PartTilt = randInt(Angle[1], Angle[2]), randInt(Tilt[1], Tilt[2])
			local CFrameTo = RightPart.CFrame * CFrame.new(0, randInt(Height[1], Height[2]), 0) * CFrame.fromEulerAnglesXYZ(math.rad(PartAngle),math.rad(PartTilt),0)
			RightPart.Orientation = Vector3.new(math.rad(PartAngle),math.rad(PartTilt),0)
			
			--
			Modes[FlourishTypes.Entrance or FlourishEntrance](RightPart, FlourishTypes.EntranceSpeed or EntranceSpeed, {CFrame = CFrameTo})
			--
		end
		--
		if LeftPart then
			--
			local PartAngle, PartTilt = randInt(Angle[1], Angle[2]), randInt(Tilt[1], Tilt[2])
			local CFrameTo = LeftPart.CFrame * CFrame.new(0, randInt(Height[1], Height[2]), 0) * CFrame.fromEulerAnglesXYZ(math.rad(PartAngle),math.rad(PartTilt),0)
			LeftPart.Orientation = Vector3.new(math.rad(PartAngle),math.rad(PartTilt),0)

			--
			Modes[FlourishTypes.Entrance or FlourishEntrance](LeftPart, FlourishTypes.EntranceSpeed or EntranceSpeed, {CFrame = CFrameTo})
			--
		end
		--
		task.spawn(function()
			RightParts[#RightParts + 1] = RightPart
			LeftParts[#LeftParts + 1] = LeftPart
		end)
		if IterationSpeed.Entrance then
			
			if IterationSpeed.EntranceDivision == 'Iterate' or EntranceDivision == 'Iterate' then
				if IterationSpeed.Entrance == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Entrance)
				end
			elseif math.floor((Distance) * (CurrentSplit / (IterationSpeed.EntranceDivision or EntranceDivision))) == index and index ~= Distance -1 then
				if IterationSpeed.Entrance == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Entrance)
				end
				CurrentSplit += 1
			end
		end
	end
	--
	CurrentSplit = 1
	task.wait(Properties['HoldTime'] or 5)
	for i = 1, #RightParts do

		Modes[FlourishTypes.Exit or FlourishExit](RightParts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		Modes[FlourishTypes.Exit or FlourishExit](LeftParts[i], FlourishTypes.ExitSpeed or ExitSpeed)

		if IterationSpeed.Exit then
			if IterationSpeed.ExitDivision == 'Iterate' or ExitDivision == 'Iterate' then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
			elseif math.floor((#RightParts) * (CurrentSplit / (IterationSpeed.ExitDivision or ExitDivision))) == i and i ~= #RightParts then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
				CurrentSplit += 1
			end
		end
		task.spawn(function()
			task.wait((FlourishTypes.ExitSpeed or ExitSpeed) + .15)
			InstanceHandler.returnInstance('Part', RightParts[i])
			InstanceHandler.returnInstance('Part', LeftParts[i])
		end)
	end
end

Styles.Break = function (AnchorPoint, Properties)
	--
	local BlockSize = Properties.BlockSize or {.25, .5}
	local partCount = Properties['PartCount'] or 10
	local Radius = Properties['Radius'] or 8
	local Width = Properties['Width'] or {-8, 8}
	local Range = Properties['Range'] or 5
	local Angle = Properties['Angle'] or {45,65}
	local Height = Properties['Height'] or {0, 0}
	local FlourishTypes = Properties['FlourishTypes'] or {}
	local IterationSpeed = Properties['IterateSpeed'] or {}
	local CurrentSplit = 1
	local Parts = {}
	--
	for i = 1, partCount do
		local newSize = Vector3.new(randInt(BlockSize[1], BlockSize[2]), randInt(BlockSize[1], BlockSize[2]), randInt(BlockSize[1], BlockSize[2]))
		local Offset = AnchorPoint * CFrame.new(randInt(-Radius, Radius), 0, randInt(-Radius, Radius))
		local Part, Pos = rayPart(Offset, Range, newSize)
		if Part then
			PhysicsService:SetPartCollisionGroup(Part, 'Blocks')
			Part.CFrame *= CFrame.new(0, Part.Size.Y/2, 0)
			Part.Anchored = false
			Part.CanCollide = true
			Parts[#Parts + 1] = Part
			Modes[FlourishTypes.Entrance or FlourishEntrance](Part, FlourishTypes.EntranceSpeed or EntranceSpeed, {CFrame = Part.CFrame})
			local BV = Instance.new('BodyVelocity', Part)
			BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
			BV.P = 100000
			BV.Velocity = Vector3.new(randInt(Width[1], Width[2]), randInt(Height[1], Height[2]), randInt(Width[1], Width[2]))


			local AV = Instance.new('BodyAngularVelocity', Part)
			AV.AngularVelocity = Vector3.new(randInt(-Angle[1],Angle[2]), randInt(-Angle[1],Angle[2]), randInt(-Angle[1],Angle[2]))
			AV.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
			AV.P = 100000
			game:GetService('Debris'):AddItem(BV, 0.25)
			game:GetService('Debris'):AddItem(AV, 0.1)
			
			
			if IterationSpeed.Entrance then
				if IterationSpeed.EntranceDivision == 'Iterate' or EntranceDivision == 'Iterate' then
					if IterationSpeed.Entrance == 'Stepped' then
						task.wait()
					else
						task.wait(IterationSpeed.Entrance)
					end
				elseif math.floor(partCount * (CurrentSplit / (IterationSpeed.EntranceDivision or EntranceDivision)) + .5) == i and i ~= partCount then
					if IterationSpeed.Entrance == 'Stepped' then
						task.wait()
					else
						task.wait(IterationSpeed.Entrance)
					end
					CurrentSplit += 1
				end
			end
		end
	end
	--
	CurrentSplit = 1
	task.wait(Properties['HoldTime'] or 5)
	for i = 1, #Parts do
		Modes[FlourishTypes.Exit or FlourishExit](Parts[i], FlourishTypes.ExitSpeed or ExitSpeed)
		if IterationSpeed.Exit then
			if IterationSpeed.ExitDivision == 'Iterate' or ExitDivision == 'Iterate' then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
			elseif math.floor((#Parts) * (CurrentSplit / (IterationSpeed.ExitDivision or ExitDivision))) == i and i ~= #Parts then
				if IterationSpeed.Exit == 'Stepped' then
					task.wait()
				else
					task.wait(IterationSpeed.Exit)
				end
				CurrentSplit += 1
			end
		end
		task.spawn(function()
			task.wait((FlourishTypes.ExitSpeed or ExitSpeed) + .15)
			InstanceHandler.returnInstance('Part', Parts[i])
		end)
	end
end
return Styles
