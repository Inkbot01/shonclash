local Visual = workspace.World.Visuals
local TweenService = game:GetService("TweenService")

local Debris = game:GetService("Debris")
return function(Data)
	
	local Amount = Data.Amount or 10
	local Offset = Data.Offset or 10
	local StartPos = Data.StartPos
	local Filter = Data.Filter or Visual
	local Size = Data.Size or Vector3.new(2,2,2)
	local Duration = Data.Duration or 2
	
	
	--[[ Terrain Rocks on Ground ]]--
	coroutine.wrap(function()
		local GroundRocks = {}
		for i = 1,Amount do

			--[[ Raycast ]]--
			local StartPosition = (Vector3.new(math.sin(360*i)*Offset, 0, math.cos(360*i)*Offset) + StartPos)
			local EndPosition = CFrame.new(StartPosition).UpVector * -10

			local RayData = RaycastParams.new()
			RayData.FilterDescendantsInstances = Filter
			RayData.FilterType = Enum.RaycastFilterType.Blacklist
			RayData.IgnoreWater = true

			local ray = game.Workspace:Raycast(StartPosition, EndPosition, RayData)
			if ray then
				local partHit, pos, normVector = ray.Instance or nil, ray.Position or nil, ray.Normal or nil
				if partHit then

					local Block = script.Block:Clone()
					Block.Size = Size

					Block.Position = pos
					Block.Anchored = true
					Block.Rotation = Vector3.new(math.random(-360,360),math.random(-360,360),math.random(-360,360))
					Block.Transparency = 0
					Block.Color = partHit.Color
					Block.Material = partHit.Material
					Block.Parent = Visual
					GroundRocks[i] = Block;
					Debris:AddItem(Block, Duration)

				end
			end
		end	
		--[[ Delete Rocks ]]--
		task.wait(Duration-0.5)
		if #GroundRocks > 0 then
			for _,v in ipairs(GroundRocks) do
				v.Anchored = false
				task.wait()
			end
		end	
	end)()
end