local module = {}
local TweenService = game:GetService('TweenService')

return function(position, offset, size, amount, timing, tweenTime)
	local startCF = CFrame.new(position) 
	local rotated = startCF 
	for i = 1, amount do
		local rock = script.Part:Clone() 
		rock.Orientation = Vector3.new()
		rock.CFrame = rotated * CFrame.Angles(0, math.rad(360 / amount * i), 0)
		rock.CFrame = rock.CFrame * CFrame.new(0, - size / 2,0) 
		local origin = rock.CFrame * CFrame.new(0, 2, -offset) * CFrame.Angles(math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360))) 
		game:GetService('Debris'):AddItem(rock, timing + 1) 
		local defaultINF = TweenInfo.new( tweenTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0 )
		local part, dpos = workspace:FindPartOnRayWithIgnoreList(Ray.new(origin.Position + Vector3.new(0, 35, 0), CFrame.new(origin .Position).UpVector * -45), {game.Players.LocalPlayer.Character, workspace.World.Visuals}) 
		local random = math.random(size*5, size*15)/10
		if part then
			rock.Orientation = Vector3.new()
			local tweenCF = nil 
			rock.Color = part.Color 
			rock.Material = part.Material 
			tweenCF = CFrame.new(dpos) * CFrame.Angles(math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360)), math.rad(math.random(-360, 360))) 
			rock.Parent = workspace.World.Visuals
			if tweenTime ~= nil then
				TweenService:Create(rock, defaultINF, {CFrame = tweenCF,Transparency = 0}):Play()
				TweenService:Create(rock.Mesh, defaultINF, {Scale = Vector3.new(random,random,random)}):Play()
			else
				rock.CFrame = tweenCF 
				rock.Mesh.Scale = Vector3.new(random, random, random) 
			end 
			local default = .25
			coroutine.wrap(function()
				if tweenTime == nil then
					wait(0.25) 
				end 

				coroutine.wrap(function()
					wait(timing) 
					if (rock and rock:findFirstChild("Mesh") == nil) or timing < .1 then
						rock:Destroy() 
						return 
					end 
					TweenService:Create(rock.Mesh, TweenInfo.new(0.5,Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {Scale = Vector3.new()}):Play() 
					TweenService:Create(rock, TweenInfo.new(0.5,Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {Orientation = Vector3.new()}):Play()
					game:GetService('Debris'):AddItem(rock, 1) 
				end) ()
			end) ()
		else
			rock:Destroy() 
		end 
	end 
end