local TweenService = game:GetService('TweenService')

local RayCastParams = RaycastParams.new()
RayCastParams.FilterType = Enum.RaycastFilterType.Whitelist
RayCastParams.FilterDescendantsInstances = {workspace.World.Maps}

return function(Root, b)
	local X, Z
	for i = 1, 360, 46 do
		X = 4 * math.cos(math.rad(i))
		Z = 4 * math.sin(math.rad(i))

		local RayCastResult = workspace:Raycast(
			(CFrame.new(Root.Position) * CFrame.new(X, 0, Z)).Position + Vector3.new(0, 5, 0), 
			Vector3.new(0, -20, 0),	
			RayCastParams
		)

		if RayCastResult then
			local Part = Instance.new("Part", workspace.World.Visuals)
			local particle1 = script.FallingDust:Clone()
			particle1.Parent = Part 
			Part.CFrame = CFrame.new(RayCastResult.Position, Vector3.new(Root.Position.X, RayCastResult.Position.Y, Root.Position.Z))
			Part.TopSurface = Enum.SurfaceType.Smooth
			Part.BottomSurface = Enum.SurfaceType.Smooth
			Part.Material = RayCastResult.Material
			Part.Size = Vector3.new(5.25 * 0.7, 0, 0)
			Part.Color = RayCastResult.Instance.Color
			Part.Anchored = true
			Part.CanCollide = false
			
			particle1:Emit(15)

			local PartTween = TweenService:Create(Part, TweenInfo.new(0.25), {CFrame = Part.CFrame * CFrame.Angles(math.rad(math.random(-40,40)), 0, 0), Size = Part.Size + (Vector3.new(0, Random.new():NextNumber(.3,1), .75) * 1.5)})
			PartTween:Play()
			spawn(function()
				task.wait(6)
				local PTween = TweenService:Create(Part, TweenInfo.new(0.5), {Size = Vector3.new(Part.Size.X, 0, 0)})
				PTween:Play()
				wait(0.5)
				Part:Destroy()
			end)
		end
	end
end
