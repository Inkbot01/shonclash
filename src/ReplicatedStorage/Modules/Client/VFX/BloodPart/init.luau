local DoughEndColour = Color3.fromRGB(148, 142, 123)
local TweenService = game:GetService("TweenService")

local EffectParent = workspace.World.Visuals
local Living = workspace.World.Entities

return function(Character, Amount, EndPosition, Force, Size)
	--/Puddles
	for i = 1,Amount do
		local size = Size
		local ball = script.ball:Clone()
		ball.Anchored = false
		ball.Size = Vector3.new(size,size,size)
		ball.CFrame = CFrame.new(EndPosition)*CFrame.Angles(math.rad(90),0,0)*CFrame.Angles(math.rad(math.random(-45,45)),math.rad(math.random(-45,45)),0)
		ball.Velocity = ball.CFrame.LookVector * (Force or 40)
		ball.CanTouch = true
		ball.Name = "blood"
		local conn;
		conn = ball.Touched:connect(function(hit)
			if not hit:IsDescendantOf(Living) and not hit:IsDescendantOf(EffectParent) and not hit:IsDescendantOf(Character) and hit.Name ~= "blood" then
				conn:Disconnect()
				ball.Anchored = true
				ball.CFrame = CFrame.new(ball.Position)
				size = size*2
				local tween = TweenService:Create(ball,TweenInfo.new(.5),{Size = Vector3.new(size,.25,size)})
				tween:Play()
				tween:Destroy()
				coroutine.wrap(function()
					wait(.75)
					local tween = TweenService:Create(ball,TweenInfo.new(2),{Transparency = 1, Color = DoughEndColour})
					tween:Play()
					tween:Destroy()
					game.Debris:AddItem(ball,2)
				end)()
			end
		end)
		ball.Parent = EffectParent
	end
end
