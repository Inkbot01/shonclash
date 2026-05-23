--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))
local Data = require(script.Parent:WaitForChild("Data"))
local Animation = require(script.Parent:WaitForChild("Animation"))

return function(Thread, HealthFrame: Frame)
	local Bar = HealthFrame:FindFirstChild("Bar")
	if not Bar or not Bar:IsA("Frame") then
		warn("[HUD/HealthBar] Health frame is missing a 'Bar' child")
		return
	end

	local maxFillScale = Bar.Size.X.Scale

	local Health = Data.HumanoidValue(Thread, "Health", 100)
	local MaxHealth = Data.HumanoidValue(Thread, "MaxHealth", 100)

	local TargetSize = Thread:Value(Bar.Size)
	Thread:Reactive(function(Grab)
		local h = Grab(Health) :: number
		local m = Grab(MaxHealth) :: number
		local ratio = (m > 0) and math.clamp(h / m, 0, 1) or 0
		TargetSize:Set(UDim2.new(ratio * maxFillScale, 0, 1, 0))
	end)

	Thread:Configure(Bar)({
		Size = Thread:Animation(TargetSize, Animation.HealthBarFill),
	})

	for _, child in ipairs(HealthFrame:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text, "/") then
			Thread:Configure(child)({
				Text = Thread:Do(function(Grab)
					local h = Grab(Health) :: number
					local m = Grab(MaxHealth) :: number
					return string.format("%d / %d", math.floor(h), math.floor(m))
				end),
			})
			break
		end
	end
end
