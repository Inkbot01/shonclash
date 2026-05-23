local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Visual = workspace.World.Visuals

return function(Data)
	
	local StartPos = Data.StartPos
	local Offset = Data.Offset
	local Amount = Data.Amount
	local Size = Data.Size
	
	local Filter = Data.Filter
	
	local IterationDelay = Data.IterationDelay
	local Duration = Data.Duration or 2
	
	--[[ Rocks Following Trail ]]--
	for loops = 1,2 do
		coroutine.wrap(function()
			local GroundRocks = {}
			for i = 1,Amount do
				
				--[[ Change Offset. Two Rocks on Both Sides. ]]--
				if loops == 2 then Offset *= -1 end
				
				--[[ Raycast ]]--
				local StartPosition = (StartPos * CFrame.new(Offset,0,-i*5)).Position
				local EndPosition = CFrame.new(StartPosition).UpVector * -10

				local RayData = RaycastParams.new()
				RayData.FilterDescendantsInstances = Filter or Visual
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
						Debris:AddItem(Block, Duration+0.25)
					end
				end		
				if IterationDelay then
					task.wait(IterationDelay)
				end
			end	
			--[[ Delete Rocks ]]--
			task.wait(Duration)
			if #GroundRocks > 0 then
				for _,v in ipairs(GroundRocks) do
					local Tween = TweenService:Create(v,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{["Size"] = Vector3.new(0,0,0)})
					Tween:Play()
					Tween:Destroy()
					--wait()
				end
			end
		end)()
	end

end
