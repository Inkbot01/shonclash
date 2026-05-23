--|| Services ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Visual = workspace.World.Visuals

--|| Variables ||--
local RNG = Random.new()
local TI2 = TweenInfo.new(.3,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,false,0)

return function(Data)
	local Character = Data.Character
	
	local Humanoid,Root = Character:FindFirstChild("Humanoid"), Character:FindFirstChild("HumanoidRootPart")

	Character.Archivable = true
	local Clone = Character:Clone()
	for _,v in ipairs(Clone:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored = true
			v.Color = Data.Color or Color3.fromRGB(255,255,255)
			v.Material = Enum.Material.Neon		
			v.Transparency = Data.StartTransparency
			
			if v:FindFirstChild("Hat") then
				v.Hat:Destroy()
			end
			
			local Tween = TweenService:Create(v,TweenInfo.new(Data.Duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{["Transparency"] = 1})
			Tween:Play()
			Tween:Destroy()
						
			Debris:AddItem(v, Data.Duration)
		else
			v:Destroy()
		end
	end
	Clone.Parent = Visual
	Debris:AddItem(Clone, Data.Duration)
end
