--||Services||--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local InsertService = game:GetService("InsertService")

--||Directories
local Gui = ReplicatedStorage.Assets.Gui
local Entities = workspace.World.Entities

--|| Assets
local OverheadAttachment = Gui.Overhead.OverheadAttachment
local CrewOverheadAttachment = Gui.Overhead.CrewOverheadAttachment

local GetData = ReplicatedStorage.Remotes.GetData

--||Variables
local Player = Players.LocalPlayer

local Overheads = {}



function Overheads.AttachConnection(Entity)
	print('attached')
	if Overheads[Entity] then return end
	
	Overheads[Entity] = true
	print("top")
	local AncesterChanged
	AncesterChanged = Entity.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			AncesterChanged:Disconnect()
			AncesterChanged = nil
			
			Overheads[Entity] = nil
		end
	end)
	
	local Humanoid = Entity:WaitForChild("Humanoid", 6)
	local Head = Entity:WaitForChild("Head", 6)
	
	if Humanoid and Head then
		--> Turn off default
		Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		Humanoid.HealthDisplayDistance = 0
		Humanoid.NameDisplayDistance = 0
		Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		
		local OverheadAttachmentClone = OverheadAttachment:Clone()
		OverheadAttachmentClone.Parent = Head 
		
		OverheadAttachmentClone.BillboardGui.Frame.PlayerName.Text = Entity.Name
		
		local HealthBar = OverheadAttachmentClone.BillboardGui.Frame.Health
		
		if Entity.Name == Player.Name then 
			HealthBar.Visible = false  
			
		else
			HealthBar.Fill.Size = UDim2.new(1, 0, 1, 0)
			HealthBar.Ghost.Size = UDim2.new(1, 0, 1, 0) --ADJUST THIS LATER TO ADD GHOST EFFECT

			Humanoid.HealthChanged:Connect(function()
				if OverheadAttachmentClone:IsDescendantOf(workspace) then
					local NewX = Humanoid.Health/Humanoid.MaxHealth


					HealthBar.Ghost:TweenSize(UDim2.new(NewX, 0, 1, 0), "Out", "Quart", .8, true)
					HealthBar.Fill:TweenSize(UDim2.new(NewX, 0, 1, 0), "Out", "Quart", .2, true)
				end
			end)
		end
		
		
		
	end
end



Entities.ChildAdded:Connect(Overheads.AttachConnection)

coroutine.resume(coroutine.create(function()
	for _, Entity in ipairs(Entities:GetChildren()) do
		print('connected')
		Overheads.AttachConnection(Entity)
	end
end))

return Overheads