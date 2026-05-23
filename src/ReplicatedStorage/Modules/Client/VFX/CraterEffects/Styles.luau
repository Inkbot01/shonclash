local IgnoreList = {workspace.World.Entities, workspace.World.Visuals} -- CHANGE THIS TO IGNORE SPECIFIC INSTANCES

Params = RaycastParams.new()
Params.FilterType = Enum.RaycastFilterType.Blacklist
Params.FilterDescendantsInstances = IgnoreList
Params.IgnoreWater = true

local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')


local Rocks = script.Parent:WaitForChild('Rocks')
local Parent = workspace.World.Visuals -- SET THE PARENT USING THIS
local rayPart = function(CFrameValue, Range, Properties, ownPart)
	
	local Results = workspace:Raycast(CFrameValue.Position, -CFrameValue.UpVector * Range, Params)
	if Results then
		local Part = ownPart or Instance.new('Part')
		Part.Parent = Parent
		Part.Anchored = true
		Part.CanCollide = false
		Part.Material = Results.Material
		Part.Color = Results.Instance.Color
		Part.CFrame = CFrame.new(Results.Position)
		Part.Reflectance = Results.Instance.Reflectance
		Part.Transparency = Results.Instance.Transparency
		if Properties then
			for property, value in next, Properties do
				if Part[property] ~= nil then
					Part[property] = value
				end
			end
		end

		return Part, Results
	else
		return false
	end
end
local Wait = function(time)
	local time = time or 1/60
	local osc = os.clock()
	while os.clock() - osc < time do
		RunService.Heartbeat:Wait()
	end
end
local randInt = function(min, max)
	local random = Random.new()
	return random:NextNumber(min, max)
end
function lerp(a, b, x)
	return a + (b - a) * x
end
function getXAndZPositions(angle, radius,spi)
	local x = math.cos(angle) * radius + spi
	local z = math.sin(angle) * radius + spi
	return x, z
end


return {
	['Crater'] = function(AnchorPoint, settings)
		local fullCircle = 2 * math.pi
		local partCount = settings['PartCount'] or 5
		local radius = settings['Radius'] or 5
		local range = settings['Range'] or 5
		local Angle = settings['Angle'] or 45
		local BlockSize = settings['BlockSize'] or {3, 5}
		for i = 1, partCount do
			local angle = i * (fullCircle / partCount)
			local x, z = getXAndZPositions(angle, radius,0)
			local Offset = (AnchorPoint) * Vector3.new(x,0,z)

			local angle2 = (i + 1) * (fullCircle / partCount)
			local x2, z2 = getXAndZPositions(angle2, radius,0)
			local Offset2 = (AnchorPoint) * Vector3.new(x2,0,z2)
			local Magnitude = (Offset - Offset2).Magnitude
			local getRandom = randInt(BlockSize[1], BlockSize[2])
			local newSize = Vector3.new(Magnitude + .5, getRandom, getRandom)
			local Part = rayPart(CFrame.new(Offset),  range, {Size = newSize})
			if Part then
				Part.Name = 'CraterPart-'..i
				local cframeTo = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.fromEulerAnglesXYZ(math.rad(settings['Angle']),0,0)
				local Properties = {CFrame = cframeTo}
				Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))

				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)

				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
		end
	end,

	['Orbit'] = function(AnchorPoint, settings)
		local fullCircle = 2 * math.pi
		local partCount = settings['PartCount'] or 5
		local radius = settings['Radius'] or 5
		local range = settings['Range'] or 5

		for i = 1, partCount do
			local angle = i * (fullCircle / partCount)
			local x, z = getXAndZPositions(angle, radius,0)
			local Offset = (AnchorPoint) * Vector3.new(x,0,z)

			local Part = rayPart(CFrame.new(Offset),  range, {Size = settings['Size']})
			if Part then
				Part.Name = 'OrbitPart-'..i
				local cframeTo = Part.CFrame * CFrame.fromEulerAnglesXYZ(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000))
				local Properties = {CFrame = cframeTo}
				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)
				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
		end
	end,

	['Path'] = function(AnchorPoint, settings)
		local Width = settings['Width'] or {4,4}
		local blockSize = settings['BlockSize'] or {2,2}
		local count = settings['Distance'] or 15
		local range = settings['Range'] or 5
		local finalCFrame
		local finalSize
		for index = 1, count, settings['stepSize'] or 1 do
			local reachSize = lerp(Width[1], Width[2], index/count)
			finalSize = reachSize
			local reachBlockSize = lerp(blockSize[1], blockSize[2], index/count)
			finalCFrame = AnchorPoint * CFrame.new(0, 0, -index)
			local rightPart = rayPart(AnchorPoint * CFrame.new(reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			local leftPart = rayPart(AnchorPoint * CFrame.new(-reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			local Properties = {Size = Vector3.new(reachBlockSize, reachBlockSize, reachBlockSize)}
			if leftPart then
				leftPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				leftPart.Name = 'leftPartPath-'..index
				TweenService:Create(leftPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()

				coroutine.wrap(function()
					wait(settings['HoldTime'])
					local Tween2 = TweenService:Create(leftPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween2:Play()
					Tween2.Completed:Wait()
					leftPart:Destroy()
				end)()
			end
			if rightPart then
				rightPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				rightPart.Name = 'rightPartPath-'..index
				TweenService:Create(rightPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					wait(settings['HoldTime'])
					local Tween1 = TweenService:Create(rightPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween1:Play()
					Tween1.Completed:Wait()
					rightPart:Destroy()
				end)()
			end

			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
	end,

	['RoundedPath'] = function(AnchorPoint, settings)
		local Width = settings['Width'] or {4,4}
		local blockSize = settings['BlockSize'] or {2,2}
		local count = settings['Distance'] or 15
		local range = settings['Range'] or 5
		local finalCFrame
		local finalSize
		local finalBlockSize
		
		for index = 1, count, settings['stepSize'] or 1 do
			local reachSize = lerp(Width[1], Width[2], index/count)
			finalSize = reachSize
			local reachBlockSize = lerp(blockSize[1], blockSize[2], index/count)
			finalBlockSize = reachBlockSize
			finalCFrame = AnchorPoint * CFrame.new(0, 0, -index)

			local Properties = {Size = Vector3.new(reachBlockSize, reachBlockSize, reachBlockSize)}

			local leftPart = rayPart(AnchorPoint * CFrame.new(-reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			if leftPart then
				leftPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				leftPart.Name = 'leftPartPath-'..index
				TweenService:Create(leftPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()

				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween2 = TweenService:Create(leftPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween2:Play()
					Tween2.Completed:Wait()
					leftPart:Destroy()
				end)()
			end

			local rightPart = rayPart(AnchorPoint * CFrame.new(reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			if rightPart then
				rightPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				rightPart.Name = 'rightPartPath-'..index
				TweenService:Create(rightPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween1 = TweenService:Create(rightPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween1:Play()
					Tween1.Completed:Wait()
					rightPart:Destroy()
				end)()
			end
			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
		--

		local halfCircle = -math.pi
		local partCount = settings['PartCount'] or finalSize/2
		local radius = finalSize
		local range = settings['Range'] or 5

		for i = 1, partCount do
			local angle = i * (halfCircle / partCount)
			local x, z = getXAndZPositions(angle, radius, 0)
			local Offset = (finalCFrame) * Vector3.new(x,0,z)

			local Part = rayPart(CFrame.new(Offset),  range, {Size = Vector3.new(finalBlockSize, finalBlockSize, finalBlockSize)})
			if Part then
				Part.Name = 'OrbitPart-'..i
				local cframeTo = Part.CFrame * CFrame.fromEulerAnglesXYZ(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000))
				local Properties = {CFrame = cframeTo}
				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)
				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
	end,

	['ClosedPath'] = function(AnchorPoint, settings)
		local Width = settings['Width'] or {4,4}
		local blockSize = settings['BlockSize'] or {2,2}
		local count = settings['Distance'] or 15
		local range = settings['Range'] or 5

		local halfCircle = math.pi
		local partCount = settings['PartCount'] or Width[1]/2
		local radius = Width[1]
		local range = settings['Range'] or 5

		for i = 1, partCount do
			local angle = i * (halfCircle / partCount)
			local x, z = getXAndZPositions(angle, radius,0)
			local Offset = (AnchorPoint) * Vector3.new(x,0,z)

			local Part = rayPart(CFrame.new(Offset),  range, {Size = Vector3.new(blockSize[1], blockSize[1], blockSize[1])})
			if Part then
				Part.Name = 'OrbitPart-'..i
				local cframeTo = Part.CFrame * CFrame.fromEulerAnglesXYZ(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000))
				local Properties = {CFrame = cframeTo}
				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)
				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
		end

		for index = 1, count, settings['stepSize'] or 1 do
			local reachSize = lerp(Width[1], Width[2], index/count)
			local reachBlockSize = lerp(blockSize[1], blockSize[2], index/count)


			local Properties = {Size = Vector3.new(reachBlockSize, reachBlockSize, reachBlockSize)}

			local leftPart = rayPart(AnchorPoint * CFrame.new(-reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			if leftPart then
				leftPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				leftPart.Name = 'leftPartPath-'..index
				TweenService:Create(leftPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()

				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween2 = TweenService:Create(leftPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween2:Play()
					Tween2.Completed:Wait()
					leftPart:Destroy()
				end)()
			end

			local rightPart = rayPart(AnchorPoint * CFrame.new(reachSize, 0, -index), range, {Size = Vector3.new(0,0,0)})
			if rightPart then
				rightPart.Orientation = Vector3.new(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000));
				rightPart.Name = 'rightPartPath-'..index
				TweenService:Create(rightPart, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
				coroutine.wrap(function()
					Wait(settings['HoldTime'])
					local Tween1 = TweenService:Create(rightPart, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween1:Play()
					Tween1.Completed:Wait()
					rightPart:Destroy()
				end)()
			end
			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
	end,
	['WallBreak'] = function(AnchorPoint, settings)
		local PartCount = settings['PartCount'] or 5
		local Height = settings['Height'] or {3,4}
		local Width = settings['Width'] or {-2,2}
		local Range = settings['Range'] or 10
		local BlockSize = settings['BlockSize'] or {3,6}
		for _ = 1, PartCount do
			local Part = rayPart(AnchorPoint, Range, {Size = Vector3.new(0,0,0)})
			if Part then
				Part.Anchored = false
				Part.CanCollide = settings['Collidable'] or true
				Part.CFrame = AnchorPoint
				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(randInt(BlockSize[1], BlockSize[2]), randInt(BlockSize[1], BlockSize[2]), randInt(BlockSize[1], BlockSize[2]))}):Play()

				local BV = Instance.new('BodyVelocity', Part)
				BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
				BV.P = 100000
				BV.Velocity = Vector3.new(randInt(Width[1], Width[2]), randInt(Height[1], Height[2]), randInt(Width[1], Width[2]))


				local AV = Instance.new('BodyAngularVelocity', Part)
				AV.AngularVelocity = Vector3.new(randInt(-40,40), randInt(-40,40), randInt(-40,40))
				AV.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
				AV.P = 100000
				game:GetService('Debris'):AddItem(BV, 0.25)
				game:GetService('Debris'):AddItem(AV, 0.1)
				coroutine.wrap(function()
					Wait(settings['HoldTime'] or 2)
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end

			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
	end,

	['Spikes'] = function(AnchorPoint, settings)
		local Distance = settings['Distance'] or 50
		local step = settings['stepSize'] or 1
		local Width = settings['Width'] or {3,3}
		local blockSize = settings['BlockSize'] or {2,5}
		local Angle = settings['Angle'] or {-1000,1000}
		local Range = settings['Range'] or 10
		for index = 1, Distance, step do
			local lerpedWidth = lerp(Width[1], Width[2], index/Distance)
			local lerpedSize = lerp(blockSize[1], blockSize[2], index/Distance)
			for _ = 1, math.floor(lerpedWidth) do
				local Part = rayPart(AnchorPoint * CFrame.new(randInt(-lerpedWidth, lerpedWidth), 0, -index), Range, {Size = Vector3.new(1.453, lerpedSize, 1.242)}, Rocks.Spike:Clone())
				if Part then
					Part.Orientation = Vector3.new(math.rad(randInt(Angle[1], Angle[2])),math.rad(randInt(Angle[1], Angle[2])),math.rad(randInt(Angle[1], Angle[2])))
					local Properties = {
						CFrame = Part.CFrame * CFrame.new(0,lerpedSize/2.2,0); 
					}
					Part.CFrame = Part.CFrame * CFrame.new(0,-15,0)

					TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
					coroutine.wrap(function()
						Wait(settings['HoldTime'] or 2)
						local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
						Tween:Play()
						Tween.Completed:Wait()
						Part:Destroy()
					end)()
				end
			end
			if settings['delayTime'] then
				if settings['delayTime'] == 'Stepped' then
					RunService.Heartbeat:Wait()
				else
					Wait(settings['delayTime'])
				end
			end
		end
	end,
	['RadialSpikes'] = function(AnchorPoint, settings)
		local fullCircle = 2 * math.pi
		local partCount = settings['PartCount'] or 5
		local radius = settings['Radius'] or {2,5}
		local range = settings['Range'] or 5
		local blockSize = settings['BlockSize'] or {2,5}
		local Angle = settings['Angle'] or 45
		local step = settings['stepSize'] or 1

		for index = 1, radius[2],step do
			local newradius = lerp(radius[1], radius[2], index/radius[2])
			local lerpedSize = lerp(blockSize[1], blockSize[2], index/radius[2])
			for i = 1, partCount do
				local angle = i * (fullCircle / partCount)
				local x, z = getXAndZPositions(angle, newradius,0)
				local Offset = (AnchorPoint) * Vector3.new(x,0,z)
				local Part = rayPart(CFrame.new(Offset),  range, {Size = Vector3.new(1.453, lerpedSize, 1.242)}, Rocks.Spike:Clone())
				if Part then
					local cframeTo = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.fromEulerAnglesXYZ(math.rad(Angle),0,0) * CFrame.new(0,lerpedSize/2.5,0)
					local Properties = {CFrame = cframeTo}
					Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))

					Part.CFrame = Part.CFrame * CFrame.new(0,-15,0)

					TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()
					coroutine.wrap(function()
						wait(settings['HoldTime'])
						local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
						Tween:Play()
						Tween.Completed:Wait()
						Part:Destroy()
					end)()
				end
			end
		end


	end,
	['ExpandingCrater'] = function(AnchorPoint, settings)
		local fullCircle = 2 * math.pi
		local partCount = settings['PartCount'] or 5
		local radius = settings['Radius'] or {5,25}
		local BlockSize  = settings['BlockSize'] or {2,10}
		local range = settings['Range'] or 5
		local incSpeed = settings['IncreaseSpeed'] or 1
		local Angle = settings['Angle'] or 45

		for i = 1, partCount do
			local angle = i * (fullCircle / partCount)
			local x, z = getXAndZPositions(angle, radius[1],0)
			local Offset = (AnchorPoint) * Vector3.new(x,0,z)

			local angle2 = (i + 1) * (fullCircle / partCount)
			local x2, z2 = getXAndZPositions(angle2, radius[1],0)
			local Offset2 = (AnchorPoint) * Vector3.new(x2,0,z2)
			local Magnitude = (Offset - Offset2).Magnitude
			local newSize = Vector3.new(Magnitude + .5, BlockSize[1], BlockSize[1])
			local Part = rayPart(CFrame.new(Offset),  range, {Size = newSize})
			if Part then
				Part.Name = 'CraterPart-'..i

				local cframeTo = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.fromEulerAnglesXYZ(math.rad(Angle),0,0)
				local Properties = {CFrame = cframeTo}
				Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z))

				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)

				TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties):Play()

				coroutine.wrap(function()
					Wait(settings['AnimationSpeed'] or 0.25)
					for index = radius[1],radius[2], incSpeed do
						local lerpedRadius = lerp(radius[1], radius[2], index/radius[2])
						local lerpedSize = lerp(BlockSize[1],BlockSize[2],index/radius[2])
						local angle = i * (fullCircle / partCount)
						local x, z = getXAndZPositions(angle, lerpedRadius, 0)
						local Offset = (AnchorPoint) * Vector3.new(x,0,z)
						local Results = workspace:Raycast(CFrame.new(Offset).Position, -CFrame.new(Offset).UpVector * range, Params)
						if Results then
							local angle = i * (fullCircle / partCount)
							local x, z = getXAndZPositions(angle, lerpedRadius,0)
							local Offset = (AnchorPoint) * Vector3.new(x,0,z)

							local angle2 = (i + 1) * (fullCircle / partCount)
							local x2, z2 = getXAndZPositions(angle2, lerpedRadius,0)
							local Offset2 = (AnchorPoint) * Vector3.new(x2,0,z2)
							local Magnitude = (Offset - Offset2).Magnitude
							local newSize = Vector3.new(Magnitude + .5, lerpedSize, lerpedSize)

							Part.Position = Results.Position
							Part.Material = Results.Material
							Part.Color = Results.Instance.Color
							Part.CFrame = CFrame.new(Results.Position)
							Part.Reflectance = Results.Instance.Reflectance
							Part.Transparency = Results.Instance.Transparency
							Part.Size = newSize
							Part.CFrame = CFrame.lookAt(Part.Position, Vector3.new(AnchorPoint.X, 0, AnchorPoint.Z)) * CFrame.fromEulerAnglesXYZ(math.rad(Angle),0,0)


						end
						RunService.Heartbeat:Wait()
					end
					Wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
		end
	end,
	['ExpandingOrbit'] = function(AnchorPoint, settings)
		local fullCircle = 2 * math.pi
		local partCount = settings['PartCount'] or 5
		local radius = settings['Radius'] or {5,25}
		local BlockSize  = settings['BlockSize'] or {2,10}
		local range = settings['Range'] or 5
		local incSpeed = settings['IncreaseSpeed'] or .8


		for i = 1, partCount do
			local angle = i * (fullCircle / partCount)
			local x, z = getXAndZPositions(angle, radius[1],0)
			local Offset = (AnchorPoint) * Vector3.new(x,0,z)

			local Part = rayPart(CFrame.new(Offset),  range, {Size = Vector3.new(BlockSize[1],BlockSize[1],BlockSize[1])})
			if Part then
				Part.Name = 'OrbitPart-'..i
				local Rotation =  CFrame.fromEulerAnglesXYZ(randInt(-1000,1000), randInt(-1000,1000), randInt(-1000,1000))
				local cframeTo = Part.CFrame * Rotation
				local Properties = {CFrame = cframeTo}
				Part.CFrame = Part.CFrame * CFrame.new(0,-2.5,0)
				local AnimTween = TweenService:Create(Part, TweenInfo.new(settings['AnimationSpeed'] or 0.25, Enum.EasingStyle.Sine), Properties)
				AnimTween:Play()

				coroutine.wrap(function()
					AnimTween.Completed:Wait()
					for index = radius[1],radius[2], incSpeed do
						local lerpedRadius = lerp(radius[1], radius[2], index/radius[2])
						local lerpedSize = lerp(BlockSize[1],BlockSize[2],index/radius[2])
						local angle = i * (fullCircle / partCount)
						local x, z = getXAndZPositions(angle, lerpedRadius, 0)
						local Offset = (AnchorPoint) * Vector3.new(x,0,z)
						local Results = workspace:Raycast(CFrame.new(Offset).Position, -CFrame.new(Offset).UpVector * range, Params)
						if Results then
							Part.Position = Results.Position
							Part.Material = Results.Material
							Part.Color = Results.Instance.Color
							Part.CFrame = CFrame.new(Results.Position)
							Part.Reflectance = Results.Instance.Reflectance
							Part.Transparency = Results.Instance.Transparency
							Part.Size = Vector3.new(lerpedSize,lerpedSize,lerpedSize)
							Part.CFrame = Part.CFrame * Rotation
						end
						RunService.Heartbeat:Wait()
					end
					wait(settings['HoldTime'])
					local Tween = TweenService:Create(Part, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = Vector3.new(0,0,0)})
					Tween:Play()
					Tween.Completed:Wait()
					Part:Destroy()
				end)()
			end
		end
	end,
}