--|| services ||--
local players = game:GetService("Players")

local server_storage = game:GetService("ServerStorage")
local replicated_storage = game:GetService("ReplicatedStorage")
local server_script_service = game:GetService("ServerScriptService")

local debris = game:GetService("Debris")
local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")

local Global = require(replicated_storage.Global)
--|| modules ||--
local Ragdoll = {}

function Ragdoll.StartRagdoll(Character,Duration, Priority)
	
	if Character and Character:FindFirstChild("Humanoid") ~= nil then
		
		print("found ragdoll", Priority)
		local RagdollInstance = Character:FindFirstChild("ragdoll")

		if RagdollInstance then
			local RagdollPriority = RagdollInstance:FindFirstChild("ragdollpriority")

			if RagdollPriority.Value <= (Priority or 0) then return end
		end	
		
		if Character:FindFirstChild("HumanoidRootPart") ~= nil then
		
			local ragdoll_value = Instance.new("NumberValue")
			ragdoll_value.Name = "ragdoll"
			ragdoll_value.Value = Duration ~= nil and Duration or 0
			ragdoll_value.Parent = Character
			
			local RagdollPriority = Instance.new("NumberValue")
			RagdollPriority.Name = "ragdollpriority"
			RagdollPriority.Value = Priority or 0 
			RagdollPriority.Parent = ragdoll_value
			
			Character.Humanoid.Sit = true
			Character.Humanoid.AutoRotate = false
			Character.Humanoid.PlatformStand = true

			--Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			--Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			--Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
			--Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			--Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)

			if players:FindFirstChild(Character.Name) == nil then
				
				local states_false = {
					Enum.HumanoidStateType.Jumping,
					Enum.HumanoidStateType.GettingUp
				}

				local states_true = {
					Enum.HumanoidStateType.Physics,
					Enum.HumanoidStateType.Ragdoll,
					Enum.HumanoidStateType.FallingDown,
				}


				replicated_storage.Remotes.EnableState:FireAllClients( Character.Humanoid,states_false, false)
				replicated_storage.Remotes.EnableState:FireAllClients(Character.Humanoid,states_true, true)
			end

			--replicated_storage.Remotes.Client.Initiate_Client:FireAllClients("ChangeState",Character.Humanoid,Enum.HumanoidStateType.Ragdoll)
			--replicated_storage.Remotes.Client.Initiate_Client:FireAllClients("ChangeState",Character.Humanoid,Enum.HumanoidStateType.FallingDown)

			if Character ~= nil and Character.Parent ~= nil and Character:FindFirstChild("Humanoid") and Global.IsAlive(Character) then
				local leftarm = Character:WaitForChild("Left Arm")
				local rightrm = Character:WaitForChild("Right Arm")
				local leftleg = Character:WaitForChild("Left Leg")
				local rightleg = Character:WaitForChild("Right Leg")

				if Character.Torso:FindFirstChild("Left Hip") then
					Character.Torso:FindFirstChild("Left Hip").Enabled = false
					if Character.Torso:FindFirstChild("Left Hip2") then
						Character.Torso:FindFirstChild("Left Hip2").Enabled = false
					end

					Character.Torso.CanCollide = true

					local attach0 = Instance.new("Attachment",Character.Torso)
					local attach1 = Instance.new("Attachment",Character["Left Leg"])
					attach0.CFrame = CFrame.new(-0.5, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
					attach1.CFrame = CFrame.new(-0, 1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
					attach0.Name = "BallAttachment"
					attach1.Name = "BallAttachment"

					local glue = Instance.new("BallSocketConstraint")
					glue.Attachment0 = attach0
					glue.Attachment1 = attach1
					glue.Name = "Left leg"	
					glue.Parent = Character.Torso

					local collider = Instance.new("Part")
					collider.Name = "Collider"
					collider.Position = Vector3.new(0,999,0)
					collider.Size = Vector3.new(1.5, 1, 1)
					collider.Shape = "Block"
					collider.Massless = true
					collider.TopSurface = "Smooth"
					collider.BottomSurface = "Smooth"
					collider.formFactor = "Symmetric"
					collider.Transparency = 1
					collider.Parent = leftleg

					local weld = Instance.new("Weld")
					weld.Part0 = leftleg
					weld.Part1 = collider
					weld.C0 = CFrame.new(0,-0.2,0) * CFrame.fromEulerAnglesXYZ(0, 0, math.pi/2)
					weld.Parent = collider

					if Character.Torso:FindFirstChild("Right Hip") and Character.Torso:FindFirstChild("Right Shoulder") and Character.Torso:FindFirstChild("Left Hip") and Character.Torso:FindFirstChild("Left Shoulder") then
						Character.Torso:FindFirstChild("Right Hip").Enabled = false
						if Character.Torso:FindFirstChild("Right Hip2") then
							Character.Torso:FindFirstChild("Right Hip2").Enabled = false
						end

						local attach0 = Instance.new("Attachment",Character.Torso)
						local attach1 = Instance.new("Attachment",Character["Right Leg"])
						attach0.Name = "BallAttachment"
						attach1.Name = "BallAttachment"
						attach0.CFrame = CFrame.new(0.5, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)
						attach1.CFrame = CFrame.new(0, 1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)

						local glue1 = Instance.new("BallSocketConstraint")
						glue1.Attachment0 = attach0
						glue1.Attachment1 = attach1
						glue1.Name = "Right leg"
						glue1.Parent = Character.Torso

						local collider1 = Instance.new("Part")
						collider1.Name = "Collider"
						collider1.Position = Vector3.new(0,9999,0)
						collider1.Size = Vector3.new(1.5, 1, 1)
						collider1.Massless = true
						collider1.Shape = "Block"
						collider1.Parent = rightleg

						local weld1 = Instance.new("Weld")
						weld1.Part0 = rightleg
						weld1.Part1 = collider1
						weld1.C0 = CFrame.new(0,-0.2,0) * CFrame.fromEulerAnglesXYZ(0, 0, math.pi/2)
						weld1.Parent = collider1

						collider1.TopSurface = "Smooth"
						collider1.BottomSurface = "Smooth"
						collider1.formFactor = "Symmetric"
						collider1.Transparency = 1

						Character.Torso:FindFirstChild("Right Shoulder").Enabled = false
						if Character.Torso:FindFirstChild("Right Shoulder2") then
							Character.Torso:FindFirstChild("Right Shoulder2").Enabled = false
						end

						local attach0 = Instance.new("Attachment",Character.Torso)
						local attach1 = Instance.new("Attachment",Character["Right Arm"])
						attach0.Name = "BallAttachment"
						attach1.Name = "BallAttachment"
						attach0.CFrame =	CFrame.new(1.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
						attach1.CFrame = CFrame.new(0, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)

						local glue11 = Instance.new("BallSocketConstraint")
						glue11.Attachment0 = attach0
						glue11.Attachment1 = attach1
						glue11.Name = "Right shoulder"
						glue11.Parent = Character.Torso

						local collider11 = Instance.new("Part")
						collider11.Name = "Collider"
						collider11.Position = Vector3.new(0,9999,0)
						collider11.Size = Vector3.new(1.8,1,1)
						collider11.Massless = true
						collider11.Shape = "Block"
						collider.Parent = rightrm

						local weld11 = Instance.new("Weld")
						weld11.Part0 = rightrm
						weld11.Part1 = collider11
						weld11.C0 = CFrame.new(0,-0.2,0) * CFrame.fromEulerAnglesXYZ(0, 0, math.pi / 2)
						weld11.Parent = collider11

						collider11.TopSurface = "Smooth"
						collider11.BottomSurface = "Smooth"
						collider11.formFactor = "Symmetric"
						collider11.Transparency = 1

						Character.Torso:FindFirstChild("Left Shoulder").Enabled = false
						if Character.Torso:FindFirstChild("Left Shoulder2") then
							Character.Torso:FindFirstChild("Left Shoulder2").Enabled = false
						end

						local attach0 = Instance.new("Attachment",Character.Torso)
						local attach1 = Instance.new("Attachment",Character["Left Arm"])
						attach0.Name = "BallAttachment"
						attach1.Name = "BallAttachment"
						attach0.CFrame =	CFrame.new(-1.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
						attach1.CFrame = CFrame.new(0, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)

						local glue111 = Instance.new("BallSocketConstraint")
						glue111.Attachment0 = attach0
						glue111.Attachment1 = attach1
						glue111.Name = "Left shoulder"
						glue111.Parent = Character.Torso

						local collider111 = Instance.new("Part")
						collider111.Name = "Collider"
						collider111.Position = Vector3.new(0,9999,0)
						collider111.Size = Vector3.new(1.5, 1, 1)
						collider111.Massless = true	
						collider111.Shape = "Block"
						collider111.Parent = leftarm

						local weld111 = Instance.new("Weld")
						weld111.Part0 = leftarm
						weld111.Part1 = collider111
						weld111.C0 = CFrame.new(0,-0.2,0) * CFrame.fromEulerAnglesXYZ(0, 0, math.pi / 2)
						weld111.Parent = collider111

						collider111.TopSurface = "Smooth"
						collider111.BottomSurface = "Smooth"
						collider111.formFactor = "Symmetric"
						collider111.Transparency = 1
					end	
				end
			end

			task.spawn(function()
				if ragdoll_value.Value > 0 then
					while ragdoll_value.Parent ~= nil do				
						ragdoll_value.Value -= .1
						if ragdoll_value.Value < 0.1 or Character == nil then
							ragdoll_value:Destroy()
						end
						task.wait(.1)
					end
					Ragdoll.EndRagdoll(Character, Priority)
				end
			end)
		end
	end
end

function Ragdoll.EndRagdoll(Character, Priority)
	
	local RagdollInstance = Character:FindFirstChild("ragdoll")
	
	if RagdollInstance then
		print("found ragdoll", Priority)
		local RagdollPriority = RagdollInstance:FindFirstChild("ragdollpriority")
		
		if RagdollPriority.Value <= (Priority or 0) then return end
	end	
	
	if Character ~= nil and Character:FindFirstChild("Humanoid") ~= nil and Character:FindFirstChild("Torso") ~= nil and Character.Torso:FindFirstChild("Right Hip2") ~= nil or Character:FindFirstChild("Torso") and Character.Torso:FindFirstChild("Right Shoulder") ~= nil or Character:FindFirstChild("Torso") ~= nil and Character.Torso:FindFirstChild("Left Hip") ~= nil or Character:FindFirstChild("Torso") ~= nil and Character.Torso:FindFirstChild("Left Shoulder") ~= nil then
		Character.Torso["Left Hip"].Enabled = true
		Character.Torso["Right Hip"].Enabled = true
		Character.Torso["Left Shoulder"].Enabled = true
		Character.Torso["Right Shoulder"].Enabled = true

		if Character.Torso:FindFirstChild("Left Hip2") then
			Character.Torso["Left Hip2"].Enabled = true
			Character.Torso["Right Hip2"].Enabled = true
			Character.Torso["Left Shoulder2"].Enabled = true
			Character.Torso["Right Shoulder2"].Enabled = true
		end

		for _,instance in ipairs(Character.Torso:GetChildren()) do 
			if instance:IsA("Glue") or instance.Name == "BallAttachment" or instance:IsA("BallSocketConstraint") then
				instance:Destroy()
			end
		end

		for _,instance in ipairs(Character:GetDescendants()) do 
			if instance.Name == "Collider" or instance.Name == "BallAttachment" or instance.Name == "ragdoll" then
				instance:Destroy()
			end
		end

		local old_rotation = Character.HumanoidRootPart.Orientation

		Character.Humanoid.Sit = false
		Character.Torso.CanCollide = false
		Character.Humanoid.AutoRotate = true
		Character.Humanoid.PlatformStand = false

		Character.HumanoidRootPart.CFrame = CFrame.new(Character.HumanoidRootPart.Position + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, math.rad(old_rotation.Y), 0)

		if players:FindFirstChild(Character.Name) == nil then
			local states_true = {
				Enum.HumanoidStateType.Jumping,
				Enum.HumanoidStateType.GettingUp
			}

			local states_false = {
				Enum.HumanoidStateType.Physics,
				Enum.HumanoidStateType.Ragdoll,
				Enum.HumanoidStateType.FallingDown,
			}
			
			
			replicated_storage.Remotes.EnableState:FireAllClients(Character.Humanoid,states_false, false)
			replicated_storage.Remotes.EnableState:FireAllClients( Character.Humanoid,states_true, true)
			
			
			
		end
	end
end

function Ragdoll.DurationRagdoll(Character,Duration)
	
	
	Ragdoll.StartRagdoll(Character,Duration)
end

return Ragdoll