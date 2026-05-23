--|| Services ||--
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--|| Imports ||--
local NpcDied = require(ServerStorage.Server_Modules.Npc.NpcDied)
local StatesManager = require(ReplicatedStorage.Modules.Shared.StatesManager)

local IDList_ = require(ReplicatedStorage._IDList)

--|| Variables ||--
local NpcsFolder = ReplicatedStorage:WaitForChild("Npcs")

ReplicatedStorage:WaitForChild("Modules")

local Cancel_Values = {"Stunned","ragdoll","Ragdoll"}

local NpcsTable = {}
local Run_Anim = {}

local function Search_Enemy(Enemy_Name)
	for _,Player in ipairs(workspace.World.Live:GetDescendants()) do
		if Player.Name == Enemy_Name then
			return Player
		end
	end
end

local function Weld(Part1,Part0,CFrame0,CFrame1)
	Part1.Position = Part0.Position

	local Weld = Instance.new("Weld",Part0)
	Weld.Part1 = Part1
	Weld.Part0 = Part0
	Weld.C0 = CFrame0 or CFrame.new()
	Weld.C1 = CFrame1 or CFrame.new()
	return Weld
end

local function Property(Object)
	Object.Anchored = false
	Object.CanCollide = false
	Object.CastShadow = false
	Object.CanTouch = false
	Object.Massless = true
end

local module = {
	Npc = nil,
	Name = "Hollow",
	Code = "Hollow",
	Quest_Return = {"hollows_behind_schoo"},

	Heal = {
		Heal_Every = 1,
		CoolDown_From_Stun = 30,
		Last_Healed = 0,
		Add_Amount = 1/100,
	},

	Npc_Spawning = {
		Can_Spawn = true,
		Spawn_Time = 2;
		Last_Spawned = 0;
		Despawn_Time = 5;
		Spawned_At = Vector3.new(),
		Already_Firstly_Detected_Someone = false,
		Max_Distance = 200,
		Spawn_Locations = {
			Vector3.new(-1186.73, 1.468, 202.75)
		},
	},

	Following = {
		Following_Id = "",
		Player = nil,
		Let_Go_Distance = 150,
		Capture_Distance = 15,
		Max_Npc_Per_Player = 1,
		Follow_Type = 0,
		Lost_Goal = nil,
		Run_Away = {
			Run_HP = 0,
			Ranges = {Max_Range = 37,Min_Range = 19,Safe_Range = 24},
			Start_Running_Range = 0,
			Look_At_Player_When_No_Walk = false,
			Look_At_When_walking_away = false,
		}
	},

	On_Idle = {
		Move_Places = true,
		Goal_Point = nil,
		Last_Arrived = 0,
		delay_before_next_departure = {2,6},
		Move_To_Locations = {},
	},

	Defaults = {
		WalkSpeed = 14,
		JumpPower = 50,
	},

	Run = {
		Run_Speed = 20,
		Is_Running = false,
		Run_On_Idle = {Distance = 20,Away_Or_Near = "Away",Enabled = false},
		Run_On_Lost = {Distance = 30,Away_Or_Near = "Away",Enabled = false},
		Run_On_Following = {Distance = 5,Away_Or_Near = "Away",Enabled = true},
	},

	Attacks = {
		Last_Performed = 0,
		Perform_CoolDown = .5,
		Holding = nil,
		Settings = {
			Last_Stunned = 0,
			Hold_Moves_Disabled = false,
			None_Hold_Moves_Disabled = false,
			Last_Punched = 0,
			id = ""
		},
		Skills = {
			["Combat"] = {
				Module = require(ServerStorage.Server_Modules.Npc.Npc_Attacks.Hollow_Combat),
				Is_Hold = false,
			},

			["Block"] = {
				Module = require(ServerStorage.Server_Modules.Npc.Npc_Attacks.Normal_Block),
				Last_Checked_Hold = 0,
				CoolDown = 2,
				Last_Performed = 0,
				Check_Every = {Min = 1,Max = 3,Divide = 2},
				Max_Hold = {2,4},
				Is_Hold = true,
			},

			["Roar"] = {
				Module = require(ServerStorage.Server_Modules.Npc.Npc_Attacks.Hollow["RoarNPC"]),
				Last_Checked_Hold = 0,
				CoolDown = 25,
				Last_Performed = 0,
				Check_Every = {Min = 0,Max = .3,Divide = 1},
				Max_Hold = {0,0},
				Is_Hold = true,
			},

			["Stomp"] = {
				Module = require(ServerStorage.Server_Modules.Npc.Npc_Attacks.Hollow["StompNPC"]),
				Last_Checked_Hold = 0,
				CoolDown = 25,
				Last_Performed = 0,
				Check_Every = {Min = 0,Max = .3,Divide = 1},
				Max_Hold = {0,0},
				Is_Hold = true,
			},
		},
	},
	Debris = {},
	Functions_Debree = {},
}

function module:Initiate_Spawn_Npc()
	if module.Npc == nil and self.Npc_Spawning.Can_Spawn == true then

		for _,Object in ipairs(script.Parent:GetChildren()) do
			if Object:IsA("Model") then 
				Object:Destroy()
			end
		end

		for Index,Array in pairs(NpcsTable) do
			NpcsTable[Index] = nil
			Array:Destroy()
		end

		local Get = NpcsFolder:WaitForChild(self.Code)
		if Get then
			if Get:IsA("Folder") then
				Get = Get:GetChildren()[math.random(1,#Get:GetChildren())]
			end
			local Code = Instance.new("StringValue")
			Code.Name = "Code"
			Code.Value = self.Code
			Code.Parent = Get

			Get = Get:Clone()

			CollectionService:AddTag(Get,"Humanoids")
			StatesManager:Initilize("Npc",Get)

			local Color_Variation = BrickColor.random()			
			for _,Object in ipairs(Get:GetDescendants()) do
				if Object:IsA("BasePart") and Object.Name ~= "Mask" then
					Object.BrickColor = Color_Variation
					Object.Material = Enum.Material.Concrete
					if Object.Name == "Head" then
						Object.Transparency = 1
					end
				end
			end

			local Mask = ReplicatedStorage.Assets.Models.Hollows.Masks:FindFirstChild("Mask"..math.random(1,9))
			if Mask then
				local Mask = Mask:Clone()
				Mask.Parent = Get

				local MotorWeld = Instance.new("Motor6D")
				MotorWeld.Name = "Handle"
				MotorWeld.Part0 = Get.Head.FakeHead
				MotorWeld.Part1 = Mask.Handle
				MotorWeld.C0 = CFrame.new(0,0,0)
				MotorWeld.Parent = Get.Head.FakeHead	
			end

			local Spawn_ = self.Npc_Spawning.Spawn_Locations[math.random(1,#self.Npc_Spawning.Spawn_Locations)]

			Get.Humanoid.MaxHealth = math.random(60,85)
			Get.Humanoid.Health = Get.Humanoid.MaxHealth

			Get.DamageBoost.Value = math.random(0,2)
			Get.Parent = script.Parent
			Get.Name = self.Name

			Get:SetPrimaryPartCFrame(CFrame.new(Spawn_))
			Get:MoveTo(Spawn_)
			Get:SetPrimaryPartCFrame(Get.PrimaryPart.CFrame * CFrame.new(0,Get.Humanoid.HipHeight,0))

			self.Npc_Spawning.Spawned_At = Spawn_
			self.Npc = Get
			
			if #self.On_Idle.Move_To_Locations < 1 then
				for Index = 1,3 do
					local Goal = Get.PrimaryPart.Position + Vector3.new(math.random(-10,10),0,math.random(-10,10))
					table.insert(self.On_Idle.Move_To_Locations,Goal)
				end
			end
			
			module.Attacks.Holding = nil
			module.Run.Is_Running = false
			module.Following.Lost_Goal = nil

			table.insert(NpcsTable,Get)

			local Damage_Log = Instance.new("Folder")
			Damage_Log.Name = "Damage_Log"
			Damage_Log.Parent = Get

			module.Defaults.WalkSpeed = Get.Humanoid.WalkSpeed
			module.Npc_Spawning.Already_Firstly_Detected_Someone = false
			module.Defaults.JumpPower = Get.Humanoid.JumpPower

			local States_To_Change = {
				Enum.HumanoidStateType.GettingUp,
				Enum.HumanoidStateType.Ragdoll,
			}

			Get.ChildRemoved:Connect(function(Child)
				if Child.Name == "ragdoll" then
					for _,Array in ipairs(States_To_Change) do
						if Get ~= nil and Get.Parent ~= nil then
							if Get:FindFirstChild("Humanoid") then
								Get.Humanoid:SetStateEnabled(Array,true)
							end
						end
					end
					ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("Set_State_Enabled",Get.Humanoid,States_To_Change,true)
					ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("ChangeState",Get.Humanoid,Enum.HumanoidStateType.GettingUp)

					Get.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)

			Get.ChildAdded:Connect(function(Child)
				if table.find(Cancel_Values,Child.Name) then
					module:Cancel_All_Skills()

					for _,Animation in ipairs(Get.Humanoid:GetPlayingAnimationTracks()) do
						if string.find(Animation.Name,"Hollow") and not string.find(Animation.Name,"Reaction") then
							Animation:Stop()
						end
					end
				end

				if Child.Name == "Stunned" then
					if Child:IsA("StringValue") then
						if Get and Get:FindFirstChild("Grip_Ting") then
							Get.Grip_Ting:Destroy()
						end

						module.Attacks.Settings.Last_Stunned = os.clock()

						local Fount_Player = Search_Enemy(Child.Value)
						if Fount_Player  then
							if self.Following.Player ~= Fount_Player and Fount_Player:FindFirstChild("HumanoidRootPart") and Get:FindFirstChild("HumanoidRootPart") then
								if Fount_Player:FindFirstChild("Max_Npc_Values") == nil then
									module.FollowingMax_Npc_Values = Instance.new("Folder")
									module.FollowingMax_Npc_Values.Name = "Max_Npc_Values"
									module.FollowingMax_Npc_Values.Parent = Fount_Player
								end

								module:Clear_Debris()
								module:Clear_Functions_Debree()

								local Victim_Values = ReplicatedStorage.Player_Instances:FindFirstChild(Fount_Player.Name) or Fount_Player

								local Current = Instance.new("ObjectValue")
								Current.Name = Get.Name
								Current.Value = Get
								Current.Parent = Fount_Player.Max_Npc_Values

								table.insert(module.Debris,Current)

								if self.Following.Player == nil then
									module:Npc_Detect_Player(Get.HumanoidRootPart.Position,Fount_Player.HumanoidRootPart.Position)
								end
								self.Following.Player = Fount_Player
							end
						end
					end
				elseif Child.Name == "ragdoll" then					
					Get.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					for _,Array in ipairs(States_To_Change) do
						Get.Humanoid:SetStateEnabled(Array,false)
					end
					ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("Set_State_Enabled",Get.Humanoid,States_To_Change,false)
					ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("ChangeState",Get.Humanoid,Enum.HumanoidStateType.Physics)

					ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("Set_State_Enabled",Get.Humanoid,Enum.HumanoidStateType.Seated,false)
					Get.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)					
				end
			end)

			local Humanoid,HumanoidRootPart = Get:FindFirstChild("Humanoid"),Get:FindFirstChild("HumanoidRootPart")
			if Humanoid and HumanoidRootPart then
				local HealthChanged = nil
				local StateChanged = nil

				local Dead = false

				local function Die()
					if not Dead then
						Dead = true
						if HealthChanged then
							HealthChanged:Disconnect()
						end

						if StateChanged then
							StateChanged:Disconnect()
						end

						local success,erro = pcall(function()
							local Attackers = Get:FindFirstChild("Damage_Log")
							if Attackers then
								local List = {}
								for _,Object in ipairs(Attackers:GetChildren()) do
									List[Object.Name] = Object.Value
								end
								NpcDied(module.Quest_Return,Get,List)
							end
						end)
						if erro then
							warn(erro)
						end

						module:Cancel_All_Skills()

						task.wait(self.Npc_Spawning.Despawn_Time)

						for Index,Array in pairs(NpcsTable) do
							NpcsTable[Index] = nil
							Array:Destroy()
						end

						if Get then
							if Get then
								Get:Destroy()
								Get = nil
							end
							if module.Npc then
								module.Npc:Destroy()
								module.Npc = nil
							end
						end

						for _,Object in ipairs(script.Parent:GetChildren()) do
							if Object:IsA("Model") then
								Object:Destroy()
							end
						end

						module.Run.Is_Running = false
						module.Following.Lost_Goal = nil

						self.Following.Player = nil
						self.Following.Follow_Type = 0;

						module.Attacks.Holding = nil
						--self.Npc_Spawning.Last_Spawned = os.clock()
						self.Npc_Spawning.Can_Spawn = false
						task.delay(self.Npc_Spawning.Spawn_Time,function()
							self.Npc_Spawning.Can_Spawn = true
						end)
						self.Following.Following_Id = "";

						if self.Npc then
							self.Npc:Destroy()
							self.Npc = nil
						end
					end
				end

				StateChanged = Humanoid.StateChanged:Connect(function()
					if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Dead and not Dead then
						Die()
					end
				end)

				HealthChanged = Humanoid.HealthChanged:Connect(function()
					if Humanoid.Health <= 0 and not Dead then
						Die()
					end
				end)
			else
				if Get then
					Get:Destroy()
					Get = nil
				end

				if module.Npc then
					module.Npc:Destroy()
					module.Npc = nil
				end
			end
		end
	end
end

function module:Clear_Debris(Type)
	if #module.Debris > 0 and module.Npc == nil or (#module.Debris > 0 and module.Npc) then
		for i,v in pairs(module.Debris) do
			v:Destroy()
		end
	end
end

function module:Cancel_All_Skills()
	if module.Attacks.Holding then
		local Attack_Module = module.Attacks.Holding.Module
		Attack_Module.Last_Performed = os.clock()
		if Attack_Module["Cancel"] then
			task.spawn(function()
				Attack_Module:Cancel(module.Npc,module.Attacks.Settings,module.Following.Player)
			end)
		end
		module.Attacks.Holding = nil
	end
end

function module:Clear_Functions_Debree()
	for _,Connection in pairs(module.Functions_Debree) do
		Connection:Disconnect()
	end
end

function module:Npc_Reached_Max_Distance(Position)
	ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("Npc_Teleport_Back",Position)
end

function module:Npc_Detect_Player(NpcPosition,PlayerPosition)
	if module.Npc and module.Npc:FindFirstChild("Head") then
		ReplicatedStorage.Remotes.Client.Initiate_Client:FireAllClients("Notice_Effect",module.Npc.Head)
	end
end

function module:Initiate_Run(Toggle)
	module.Run.Is_Running = Toggle
	if module.Npc then
		local Humanoid = module.Npc:FindFirstChild("Humanoid")
		if Humanoid then
			if Humanoid then
				if Run_Anim[Humanoid] == nil then
					Run_Anim[Humanoid] = Humanoid:LoadAnimation(ReplicatedStorage.Assets.Animations.Movement.HollowRun)
				end
				if Toggle then
					Run_Anim[Humanoid]:Play()
					Run_Anim[Humanoid]:AdjustSpeed(1)
				else
					Run_Anim[Humanoid]:Stop()
				end
			end
		end
	end
end

return module