--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))
local Data = require(script.Parent:WaitForChild("Data"))
local Animation = require(script.Parent:WaitForChild("Animation"))

return function(Thread, StaminaFrame: Frame)
	local Bar = StaminaFrame:FindFirstChild("Bar")
	if not Bar or not Bar:IsA("Frame") then
		warn("[HUD/StaminaBar] Stamina frame is missing a 'Bar' child")
		return
	end

	local maxFillScale = Bar.Size.X.Scale

	local Current = Data.PlayerValue(Thread, "States.Stamina.CurrentStamina", 100)
	local Max = Data.PlayerValue(Thread, "States.Stamina.MaxStamina", 100)

	local TargetSize = Thread:Value(Bar.Size)
	Thread:Reactive(function(Grab)
		local c = Grab(Current) :: number
		local m = Grab(Max) :: number
		local ratio = (m > 0) and math.clamp(c / m, 0, 1) or 0
		TargetSize:Set(UDim2.new(ratio * maxFillScale, 0, 1, 0))
	end)

	Thread:Configure(Bar)({
		Size = Thread:Animation(TargetSize, Animation.HealthBarFill),
	})

	for _, child in ipairs(StaminaFrame:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text, "/") then
			Thread:Configure(child)({
				Text = Thread:Do(function(Grab)
					local c = Grab(Current) :: number
					local m = Grab(Max) :: number
					return string.format("%d / %d", math.floor(c), math.floor(m))
				end),
			})
			break
		end
	end
end
