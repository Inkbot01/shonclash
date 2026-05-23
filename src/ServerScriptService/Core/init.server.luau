--|| Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

--|| Imports

--> Primary
local Global = require(ReplicatedStorage.Global)
local Directory = require(ReplicatedStorage.Directory)


--> Player
local StateLibrary = Directory.Import("StateLibrary", "Shared")
local Database = Directory.Import("Database", "Shared")

local FormulaLibrary = Directory.Import("FormulaAPI", "Shared")

local RagdollManager = Directory.Import("Ragdoll_Manager", "Shared")

local AnimationService = Directory.Import("AnimationService", "Shared")

local NetworkStream = require(ReplicatedStorage.Modules.Utility.NetworkStream)
local Utility = require(ReplicatedStorage.Modules.Utility.Utility)

local ToolSystem = require(script.World["Tool System"])
local LootLibrary = require(script.World.LootLibrary)

local RoundSystem = require(script.Mechanics["Round System"])
local OutfitData = require(ReplicatedStorage.Modules.Shared.OutfitData)
local ModuleCache = Utility:requireModules({}, script)

local SpawnEntity = ReplicatedStorage.Remotes.Spawn

local CharacterLoadTimeout = 6

--[[
local function updatePlayerHealth(Player, Regen)
	if not Player:WaitForChild("Data", 15) then return end 

	if Player.Character and Player.Character:FindFirstChild"Humanoid"  then
		
		Player.Character.Humanoid.MaxHealth = FormulaLibrary.CalculateMaxHealth(Player.Data.StatPoints.Defense.Value +  Player.AccessoryBuffs["Defense"].Value)

		if Regen then
			Player.Character.Humanoid.Health = Player.Character.Humanoid.MaxHealth
		end	
	end
end

local function updatePlayerStamina(Player, Regen)

	if not Player:WaitForChild("Data", 15) then return end 

	
	local States = Player:WaitForChild("States")
	
	if Player.Character and Player.Character:FindFirstChild"Humanoid" and States  then
		States.Stamina.MaxStamina.Value = FormulaLibrary.CalculateMaxStamina(Player.Data.StatPoints.Strength.Value + Player.AccessoryBuffs["Strength"].Value)

		if Regen then
			States.Stamina.CurrentStamina.Value = States.Stamina.MaxStamina.Value
		end	
	end
end
--]]
--[[
local function CharacterInitilization(Player, Character)
	

		local StartTime = os.clock()
	
		Character.Parent = workspace.World.Entities
	
		repeat task.wait() until Character.Parent == workspace.World.Entities or os.clock() - StartTime >= CharacterLoadTimeout

		Character.Parent = workspace.World.Entities
		
	
		
		--> create Accessory Folder
	
		--> BuildRagdoll(Humanoid)
end
--]]
local function CharacterInitilization(Character)
	


		local StartTime = os.clock()
		local CharacterLoadTime = os.clock()
		
		--repeat wait() until Global.IsAlive(Character) or os.clock() - CharacterLoadTime <= CharacterLoadTimeout
		
	
		while task.wait() do 
			if os.clock() - StartTime >= CharacterLoadTimeout then break end
			
			if Global.IsAlive(Character) and Character.Parent == workspace.World.Entities then 
				break 
				
			elseif Global.IsAlive(Character) then
				Character.Parent = workspace.World.Entities
	
			end
		end
		
	--	repeat task.wait() until (Global.IsAlive(Character) and Character.Parent == workspace.World.Entities) or os.clock() - StartTime >= CharacterLoadTimeout
		
		Character.Parent = workspace.World.Entities
		
	
		local ProxyPlayer = Players:FindFirstChild(Character.Name)
		
		local Data = ProxyPlayer:WaitForChild("Data", 10)
		
		--updatePlayerHealth(ProxyPlayer, true)
		--updatePlayerStamina(ProxyPlayer, true)

		
		--	if ProxyPlayer["Spawn Point"].Value == "Starter Island" then ProxyPlayer.States.Safezone.Base.Value = true end

		local AccessoryFolder = Instance.new("Folder")
		AccessoryFolder.Name = "Accessories"
		AccessoryFolder.Parent = Character

		local SwordFolder = Instance.new("Folder")
		SwordFolder.Name = "Swords"
		SwordFolder.Parent = Character

		ToolSystem.LoadToolbar(Players:GetPlayerFromCharacter(Character))
	
		local Humanoid = Character:WaitForChild("Humanoid")
	
	
		if Data.Ability.Value == "Endeavor" then
			NetworkStream.FireAllClients(Character, "Effect", 1000, {
				Character = Character,

				Category = "Endeavor",
				Function = "Initiate",

				AbilityData = Database.Endeavor.Swing,
			})

		end
		
		Humanoid.HealthChanged:Connect(function()
			Humanoid.Health = math.clamp(Humanoid.Health, 1, Humanoid.MaxHealth)

		
			if Humanoid.Health == 1 then
				StateLibrary.ModifyState(Players:GetPlayerFromCharacter(Character) or Character, "Knocked", Humanoid.MaxHealth/4)
			end
	
			--[[
			local Time = (1/100) / (Humanoid.MaxHealth / 4)


			if Humanoid.Health < (Humanoid.MaxHealth / 6) and not StateLibrary.CheckState(Players:GetPlayerFromCharacter(Character), "Knocked") then
			
			
				StateLibrary.ModifyState(Players:GetPlayerFromCharacter(Character), "Knocked", Humanoid.MaxHealth/6)
				
				--RagdollManager.DurationRagdoll(Character,Humanoid.MaxHealth/6, 1)

				
			end
			--]]
		
		end)

		--ProfileService:Replicate(Players:GetPlayerFromCharacter(Character))
	--ProfileService:Replicate(Players:GetPlayerFromCharacter(Character))	
end



local function Weld(Part1,Part0,CFrame0,CFrame1)
	Part1.Position = Part0.Position

	local we = Instance.new("Weld",Part0)
	we.Part1 = Part1
	we.Part0 = Part0
	we.C0 = CFrame0 or CFrame.new()
	we.C1 = CFrame1 or CFrame.new()
	return we
end


local function getZone(Character)

	local HumanoidRootPart = Character:FindFirstChild"HumanoidRootPart"
	
	--local SelectedIsland = ""
	if HumanoidRootPart then

	--	local Result = workspace:Raycast(Character.HumanoidRootPart.Position, Character.HumanoidRootPart.Position - Vector3.new(0,200,0), ZoneParams)
		
		for _, Island in ipairs(workspace.World.Maps:GetChildren()) do
			if Island:FindFirstChild("Spawns") then
				for _, SpawnPoint in ipairs(Island.Spawns:GetChildren()) do 
					if (SpawnPoint.Position - HumanoidRootPart.Position).Magnitude <= 200 then
						return Island.Name
					end
				end
			end
		
			
		end
		
		
		
	end
end


Players.PlayerAdded:Connect(function(Player)
	
	StateLibrary.CreateStates(Player)
	
	local States = Player:WaitForChild"States"	
	local Data = Player:WaitForChild("Data")
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Humanoid = Character:WaitForChild"Humanoid"
	
	
	CharacterInitilization(Player.Character or Player.CharacterAdded:Wait())
	
	Player.CharacterAdded:Connect(function(NewCharacter)
		
		
			--ModuleCache["Inventory System"].RegisterItem(Player, "Apple", 10
		StateLibrary.RefreshStates(Player)


		CharacterInitilization(NewCharacter)

	end)

	Player.CharacterRemoving:Connect(function(Character)
		local States = Player:FindFirstChild("States")

		
		RoundSystem.IncrementData(Player, "Deaths", 1)
		
		if Player:FindFirstChild("Data") then
			Player.Data.Deaths.Value = Player.Data.Deaths.Value + 1
		end
		
		
		if States and StateLibrary.CheckState(Player, "CombatLog") then
			local IsPlayerThatKilled = Player.States.CombatLog.LastAttackedBy.Value

			if Players:FindFirstChild(IsPlayerThatKilled) then
				
				RoundSystem.IncrementData(Players:FindFirstChild(IsPlayerThatKilled), "Points", 100)
				RoundSystem.IncrementData(Players:FindFirstChild(IsPlayerThatKilled), "Kills", 1)
				
				if Players:FindFirstChild(IsPlayerThatKilled):FindFirstChild("Data") then
					Player:FindFirstChild(IsPlayerThatKilled).Data.Kills.Value = Player:FindFirstChild(IsPlayerThatKilled).Data.Kills.Value + 1
					
				end
			--	local BountyDifference = math.floor((Player.Data.Bounty.Value - (Player.Data.Bounty.Value * .80)))

				--Player.Data.Bounty.Value = Player.Data.Bounty.Value - BountyDifference
				--Players:FindFirstChild(IsPlayerThatKilled).Data.Bounty.Value = Players:FindFirstChild(IsPlayerThatKilled).Data.Bounty.Value + BountyDifference

				StateLibrary.ModifyState(Players:FindFirstChild(IsPlayerThatKilled), "CombatLog", false)
			end
		end
	end)
	
	
	ModuleCache["QuestAPI"].GiveDailyQuests(Player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = Player

	local Points = Instance.new("NumberValue")
	Points.Value = 0
	Points.Name = "Points"
	Points.Parent = leaderstats
	
	local ModePoints = Instance.new("NumberValue")
	ModePoints.Value = 0
	ModePoints.Name = "ModePoints"
	ModePoints.Parent = Player
	
	local MaxModePoints = Instance.new("NumberValue")
	MaxModePoints.Value = 100
	MaxModePoints.Name = "MaxModePoints"
	MaxModePoints.Parent = Player
	
	--[[
		Data.Bounty.Changed:Connect(function()
			Player.leaderstats.Bounty.Value = Player.Data.Bounty.Value
		end)
	
	
		Data.StatPoints.Defense.Changed:Connect(function()
			updatePlayerHealth(Player, false)
		end)

		Data.StatPoints.Strength.Changed:Connect(function()
			updatePlayerStamina(Player, false)
		end)

		Data.Level.Changed:Connect(function()
			ModuleCache["QuestAPI"].NotifyForNextIsland(Player)
		end)
	==]]

	--> Database Initlization
	
	--> State Initilization

	--> Parent Character
	--CharacterInitilization(Player.Character)
	
	
	--> character 
	
end)


Players.PlayerRemoving:Connect(function(Player)
	--> remove databsae profile
	
end)




SpawnEntity.OnServerEvent:Connect(function(Player)
	
	if ReplicatedStorage.GlobalData:FindFirstChild("VotingTimer").Value > 0 then
		
		--> notify client that they cant spawn
		print("cannot spawn during voting period")
		return
	elseif Player.Data.Ability.Value == "" then
		print("needs ability")
		return
	end
	Player:LoadCharacter()
	
	local Data = Player:WaitForChild("Data")
	
	for _, Item in ipairs(Data.EquippedItems:GetChildren()) do 
		if OutfitData[Item.Value] then

			if table.find(OutfitData[Item.Value], Item.Name) then
				local NewFolder = Instance.new("Folder")
				NewFolder.Name = Item.Name
				NewFolder.Parent = Player.Character

				--local Shirt = workspace.Morphs.Sasuke.Shirt:Clone()

				for _, Child in ipairs(ReplicatedStorage.Morphs[Item.Value][Item.Name]:GetDescendants()) do 
					if Child:IsA("BasePart") then
						Child.CanCollide = false
						Child.Massless = true
						Child.Anchored = false					

						local WeldPart = Player.Character:WaitForChild(Child.Parent.Name)
						local ReferencePart = ReplicatedStorage.Morphs.Sasuke.Dummy:WaitForChild(Child.Parent.Name)

						local rel= ReplicatedStorage.Morphs[Item.Value].Dummy:WaitForChild(Child.Parent.Name).CFrame:ToObjectSpace(Child.CFrame)

						local NewItem = Child:Clone()
						Weld(NewItem, Player.Character:FindFirstChild(Child.Parent.Name), rel)

						NewItem.Parent = NewFolder
					end
				end

				NewFolder.Parent = Player.Character
			end
		end
	end
	
		
end)
