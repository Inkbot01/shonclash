local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ti = TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0)
local ti2 = TweenInfo.new(2,Enum.EasingStyle.Circular,Enum.EasingDirection.Out,0,false,0)

function module.ClickEffect(Mouse,Frame,Color,growsize)
	if Frame then
		local x,y = Mouse.X - Frame.AbsolutePosition.X,Mouse.Y - Frame.AbsolutePosition.Y
		local Circle = ReplicatedStorage.Assets.Gui.Circle:Clone()
		if Color then
			Circle.ImageColor3 = Color
		end
		Circle.Position = UDim2.new(0,x,0,y,0)
		Circle.Parent = Frame

		local Tween = TweenService:Create(Circle,ti,{Size = UDim2.new(growsize or 6,0,growsize or 6,0),ImageTransparency = 1})
		Tween:Play()
		Tween:Destroy()

		game.Debris:AddItem(Circle,.25)
	end
end

return module