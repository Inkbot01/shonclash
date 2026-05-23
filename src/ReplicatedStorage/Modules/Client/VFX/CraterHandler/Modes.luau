--[[		SERVICES		]]--
local TweenService = game:GetService('TweenService')

--[[		VARIABLES		]]--
local TweenPresets = {
	['SineMode'] = function (Time)
		return TweenInfo.new(Time, Enum.EasingStyle.Sine)
	end,
}

--[[		AUXILLARY		]]--
local createTween = function(...)
	return TweenService:Create(...)
end

--[[		MODULE		]]--
local Modes = {}

-- Disappear
Modes.Shrink = function (Part, Time)
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), {
		Size = Vector3.new(0,0,0)
	})
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end
--
Modes.Melt = function (Part, Time)
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), {
		Position = Part.Position + Vector3.new(0, -Part.Size.X * 1.5, 0)
	})
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end
--
Modes.FadeOut = function (Part, Time)
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), {
		Transparency = 1
	})
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end

-- Appear
Modes.Enlarge = function (Part, Time, Properties)
	local PartSize = Part.Size
	Part.CFrame = Properties['CFrame']
	Part.Size = Vector3.new(0,0,0)
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), {Size = PartSize})
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end
--
Modes.Grow = function (Part, Time, Properties)
	Part.CFrame = Part.CFrame * CFrame.new(0,-Part.Size.X/1.5, 0)
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), Properties)
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end
--
Modes.FadeIn = function (Part, Time, Properties)
	Part.CFrame = Properties['CFrame']
	local PartTransparency = Part.Transparency
	Part.Transparency = 1
	local Tween = createTween(Part, TweenPresets['SineMode'](Time), {
		Transparency = PartTransparency
	})
	Tween:Play()
	task.spawn(function()
		Tween.Completed:Wait()
		Tween:Destroy()
	end)
end
--

return Modes

