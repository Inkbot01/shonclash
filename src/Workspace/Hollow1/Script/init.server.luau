--|| Services ||--
local Players = game:GetService("Players")

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--|| Imports ||--
local NpcConfiguration = require(script.Parent.Npc_Configuration)

--|| Variables ||--
local NoStunWhitelist = {""}
local Stop_Blocking_Victim_Values = {"Stunned"}

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {workspace.World.Live.Mobs}
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

ReplicatedStorage:WaitForChild("Modules")

function ClearDebree()
	for Index,Array in pairs(NpcConfiguration.Debris) do
		NpcConfiguration.Debris[Index]:Destroy()
		NpcConfiguration.Debris[Index] = nil
	end
end

function ClearFunctionDebree()
	for Index,Array in pairs(NpcConfiguration.Functions_Debree) do
		NpcConfiguration.Functions_Debree[Index]:Disconnect()
		NpcConfiguration.Functions_Debree[Index] = nil
	end
end

while true do
	local Npc = NpcConfiguration.Npc
	if Npc == nil and #NpcConfiguration.Debris > 0 then
		ClearDebree()
	end

	if Npc then
		local Root,Hum = Npc:FindFirstChild("HumanoidRootPart"),Npc:FindFirstChild("Humanoid")

		if Root and Hum and Hum.Health > 0 then
			local Player = NpcConfiguration.Following.Player

			local Is_Stunned = false
			if Npc:FindFirstChild("Stunned") or Npc:FindFirstChild("Cant_Move") or Npc:FindFirstChild("ragdoll") then
				Is_Stunned = true
			end
			local Running = NpcConfiguration.Run.Is_Running

			if Is_Stunned then
				Hum.WalkSpeed = 0
				Hum.JumpPower = 0
			elseif Npc:FindFirstChild("ToSpeed") then
				Hum.WalkSpeed = Npc.ToSpeed.Value
			else
				if Npc:findFirstChild("BlockHits") or os.clock() - NpcConfiguration.Attacks.Settings.Last_Punched <= 1 then
					Hum.WalkSpeed = os.clock() - NpcConfiguration.Attacks.Settings.Last_Punched <= 1 and 7 or 7
				else
					Hum.WalkSpeed = Running and NpcConfiguration.Run.Run_Speed or NpcConfiguration.Defaults.WalkSpeed
				end
			end

			if Npc:FindFirstChild("Rotate") then
				Hum.AutoRotate = false
			else
				Hum.AutoRotate = true
			end

			if not Is_Stunned and Root:CanSetNetworkOwnership() then
				Root:SetNetworkOwner(nil)
			end

			if (not Is_Stunned or table.find(NoStunWhitelist,Npc.Name)) then
				local Run = NpcConfiguration.Run
				local New_Run_V = false
				if Root and Root.Velocity.Magnitude > 5 and Npc:FindFirstChild("BlockHits") == nil and Npc:FindFirstChild("Cant_Move") == nil and not (os.clock() - NpcConfiguration.Attacks.Settings.Last_Punched <= .6) then
					if not New_Run_V and Run.Run_On_Following.Enabled then
						if NpcConfiguration.Following.Player  and NpcConfiguration.Following.Player:FindFirstChild("HumanoidRootPart") then
							local Mag = (Root.Position-NpcConfiguration.Following.Player.HumanoidRootPart.Position).Magnitude
							if Run.Run_On_Following.Away_Or_Near == "Near" then
								if Mag <= Run.Run_On_Following.Distance then
									New_Run_V = true
								end
							else
								if Mag >= Run.Run_On_Following.Distance then
									New_Run_V = true
								end
							end
						end
					end
				end

				if Npc:FindFirstChild("ToSpeed") then
					New_Run_V = false
				end

				if Run.Is_Running ~= New_Run_V then
					NpcConfiguration:Initiate_Run(New_Run_V)
				end

				if NpcConfiguration.Following.Player and NpcConfiguration.Following.Player.Parent == nil then
					NpcConfiguration.Following.Player = nil
				end

				local Following = NpcConfiguration.Following
				if Following.Player then
					local Victim_Values = Following.Player
					local FRoot,FHum = Following.Player:FindFirstChild("HumanoidRootPart"),Following.Player:FindFirstChild("Humanoid")
					if FRoot and FHum then
						if FHum.Health > 0 and Victim_Values:FindFirstChild("carry") == nil and Victim_Values:FindFirstChild("being_carried") == nil and Victim_Values:FindFirstChild("gettin_gripped") == nil and (FRoot.Position - Root.Position).Magnitude <= Following.Let_Go_Distance then

						else
							Following.Player = nil
						end
					else
						Following.Player = nil
					end
				end

				if Following.Player == nil then
					for i,v in pairs(CollectionService:GetTagged("Players")) do
						local Victim_Values = v
						if v ~= Npc and v:IsDescendantOf(workspace) and Victim_Values:FindFirstChild("carry") == nil and Victim_Values:FindFirstChild("being_carried") == nil and Victim_Values:FindFirstChild("gettin_gripped") == nil and v:FindFirstChildOfClass("ForceField") == nil and v:FindFirstChild("Grande_RightLeg") == nil and v:FindFirstChild("In_Human_State") == nil then
							local FRoot,FHum = v:FindFirstChild("HumanoidRootPart"),v:FindFirstChild("Humanoid")
							if FRoot and FHum then
								if FHum.Health > 0 and (FRoot.Position - Root.Position).Magnitude <= Following.Capture_Distance then
									ClearDebree(1)
									if v:FindFirstChild("Max_Npc_Values") == nil then
										Max_Npc_Values = Instance.new("Folder")
										Max_Npc_Values.Name = "Max_Npc_Values"
										Max_Npc_Values.Parent = v
									end

									if #v.Max_Npc_Values:GetChildren() < Following.Max_Npc_Per_Player then
										ClearFunctionDebree()

										local victimvalues = v

										local Child_Connection = victimvalues.ChildAdded:Connect(function(C)
											if table.find(Stop_Blocking_Victim_Values,C.Name) then
												if NpcConfiguration.Attacks.Holding then
													ClearFunctionDebree()
													NpcConfiguration:Cancel_All_Skills(true)
												end
											end
										end)

										table.insert(NpcConfiguration.Functions_Debree,Child_Connection)

										local Current = Instance.new("ObjectValue")
										Current.Name = Npc.Name
										Current.Value = Npc
										Current.Parent = v.Max_Npc_Values

										table.insert(NpcConfiguration.Debris,Current)

										local Player_Position = FRoot.Position
										local Npc_Position = Root.Position

										NpcConfiguration:Npc_Detect_Player(Npc_Position,Player_Position)
										Following.Player = v
									end

								end
							end
						end
					end
				end

				if Following.Player == nil then
					ClearDebree(2)
				end

				if Player == nil then
					local reset_on_idle = true
					local on_idle = NpcConfiguration.On_Idle
					if on_idle.reached_goal == nil then
						on_idle.reached_goal = false
					end
					if on_idle and on_idle.Move_Places then
						local get = math.random(on_idle.delay_before_next_departure[1],on_idle.delay_before_next_departure[2])
						if os.clock() - on_idle.Last_Arrived > get then
							if on_idle.Goal_Point == nil then
								local goal = on_idle.Move_To_Locations[math.random(1,#on_idle.Move_To_Locations)]
								on_idle.Goal_Point = goal
								on_idle.reached_goal = false
								Hum:MoveTo(goal)
								reset_on_idle = false
							else
								if (Root.Position - on_idle.Goal_Point).Magnitude <= 3 then
									on_idle.Last_Arrived = os.clock()
									on_idle.Goal_Point = nil
									on_idle.reached_goal = true
									Hum:MoveTo(Root.Position)
								else
									Hum:MoveTo(on_idle.Goal_Point)
									if Root.Velocity.Magnitude < (Hum.WalkSpeed * .75) then
										Hum.Jump = true
									end
								end
								reset_on_idle = false
							end
						else
							reset_on_idle = false
						end
					end
					if reset_on_idle then
						on_idle.Last_Arrived = 0
						on_idle.reached_goal = 0
						on_idle.Goal_Point = nil
					end
				elseif Player then					
					local player_root,player_hum = Player:FindFirstChild("HumanoidRootPart"),Player:FindFirstChild("Humanoid")
					if player_root and player_hum then
						local RunAway = NpcConfiguration.Following.Run_Away
						if Hum.Health <= RunAway.Run_HP then
							if (Root.Position - player_root.Position).Magnitude <= RunAway.Ranges.Max_Range then
								Hum:MoveTo(Root.Position + ((Root.Position - player_root.Position).Unit * 10))
								if Root.Velocity.Magnitude  <(Hum.WalkSpeed * .75) then
									Hum.Jump = true
								end
							else
								NpcConfiguration.Following.Player = nil
								ClearDebree()
								ClearFunctionDebree()
								NpcConfiguration.On_Idle.Last_Moved = 0
							end
						else
							Hum:MoveTo(player_root.Position)

							local Position1,Position2 = Root.Position,(player_root.Position-Root.Position).Unit * 100000
							local RaycastResult = workspace:Raycast(Position1,Position2,raycastParams)
							if Root.Velocity.Magnitude < (Hum.WalkSpeed * .75) and (RaycastResult == nil or (RaycastResult and RaycastResult.Instance == nil or (RaycastResult.Instance and RaycastResult.Instance:IsDescendantOf(Player) == false))) and (Root.Position - player_root.Position).Magnitude >= 5 then
								Hum.Jump = true
							end

							local Attacking = NpcConfiguration.Attacks
							if Attacking.Holding == nil and Npc:FindFirstChild("Disabled") == nil and not Attacking.Settings.None_Hold_Moves_Disabled and ((Npc:FindFirstChild("Stunned") == nil and Npc:FindFirstChild("Cant_Move") == nil and Npc:FindFirstChild("No_Moves") == nil) or table.find(NoStunWhitelist,Npc.Name)) then
								local Picked = false
								for i,v in pairs(Attacking.Skills) do
									if Picked == false then
										if not v.Is_Hold and v.Module then
											local Return = v.Module(NpcConfiguration.Npc,NpcConfiguration.Attacks.Settings,NpcConfiguration.Following.Player)
											if Return then
												Picked = true
												break
											end
										end
									else
										break
									end
								end
							end
							if Attacking.Holding == nil and Npc:FindFirstChild("Disabled") == nil and ((Npc:FindFirstChild("ragdoll") == nil and Npc:FindFirstChild("Cant_Move") == nil and Npc:FindFirstChild("No_Moves") == nil and Npc:FindFirstChild("Stunned") == nil) or table.find(NoStunWhitelist,Npc.Name)) and not Attacking.Settings.Hold_Moves_Disabled then
								if os.clock() - Attacking.Last_Performed >= Attacking.Perform_CoolDown then
									Attacking.Last_Performed = os.clock()
									local Picked = false
									for i,v in pairs(Attacking.Skills) do
										if not Picked then
											if v.Is_Hold and os.clock() - v.Last_Performed >= v.CoolDown then
												if v.Module then
													if v.Module["Hold"] then
														Attacking.Settings.id = _G.Generate_ID()
														Attacking.Holding = v
														local Return = v.Module:Hold(NpcConfiguration.Npc,NpcConfiguration.Attacks.Settings,NpcConfiguration.Following.Player)
														if Return then
															Picked = true
															v.Last_Checked_Hold = os.clock()
															v.Last_Performed = os.clock()
														else
															Attacking.Holding = nil
														end
													end
												end
											end
										else
											break
										end
									end
								end
							elseif Attacking.Holding then
								local Holding = Attacking.Holding
								if Holding then
									local Check = math.random(Holding.Check_Every.Min,Holding.Check_Every.Max) / Holding.Check_Every.Divide
									if os.clock() - Holding.Last_Checked_Hold >= Check then
										local Max_Hold = math.random(Holding.Max_Hold[1],Holding.Max_Hold[2])
										if Holding.Max_Hold[3] then
											Max_Hold /= Holding.Max_Hold[3]
										end
										if os.clock() - Attacking.Last_Performed >= Max_Hold then
											if Holding.Module then
												if Holding.Module["UnHold"] then
													Holding.Module:UnHold(NpcConfiguration.Npc,NpcConfiguration.Attacks.Settings,NpcConfiguration.Following.Player)
												end
											end
											Holding.Last_Performed = os.clock()
											Attacking.Holding = nil
											Attacking.Last_Performed = os.clock()
										end
									end
								end
							end
						end
					end
				end
			end
		end
	else
		if Npc and Npc:IsDescendantOf(workspace) == false then
			Npc = nil
		end
		NpcConfiguration:Initiate_Spawn_Npc()
	end
	task.wait(.02)
end