--|| Services 
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--|| Directories 
local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes

local Shared = Modules.Shared
local Utility = Modules.Utility

--|| Shared 
local Directory = require(ReplicatedStorage.Directory)

local Database = require(Modules.Shared.Database)

-- || Remotes
local UpdateCooldown = Remotes.UpdateCooldown

--|| Module 

local DebounceAPI = {}


function DebounceAPI.ApplyCooldown(Player, Category, Key, OptionalTime)
	local CooldownProfile = Database.GetCategoryData(Player, Category)
	
	
	if not CooldownProfile then return nil end


	CooldownProfile[Key].InitTimeStamp = OptionalTime or os.clock()
	
	if Player:IsA("Player") and RunService:IsServer()  then
		UpdateCooldown:FireClient(Player, Category, Key)
	end
	
end

function DebounceAPI.IsCooldown(Player, Category, Key)
	local CooldownProfile = Database.GetCategoryData(Player, Category)

	if not CooldownProfile then return nil end

	if os.clock() - CooldownProfile[Key].InitTimeStamp < CooldownProfile[Key].Cooldown then
		return false
	end

	return true
end

function DebounceAPI.GetCooldownData(Player, Category, Key)
	local CooldownProfile = Database.GetCategoryData(Player, Category)

	if not CooldownProfile then return nil end

	return CooldownProfile[Key].InitTimeStamp, CooldownProfile[Key].Cooldown
end

--> Apply to Prexisting
if RunService:IsClient() then
	local Player = Players.LocalPlayer
	
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local HUD = PlayerGui:WaitForChild("HUD")
	if not PlayerGui.HUD:FindFirstChild("MoveSet") then return DebounceAPI end
	
	local SkillHolder = PlayerGui.HUD.MoveSet
	
	local function TerminateCharge(ToolName, ProcessedKey)
		local CategoryData = Database[ToolName]

		if not ProcessedKey or not CategoryData then return end

		local AbilityData = Database[ToolName][ProcessedKey]


		local IndexedAbilityFrame = SkillHolder:FindFirstChild(AbilityData.Name)
		
		if not IndexedAbilityFrame then return end

		local InitTimeStamp, Cooldown = DebounceAPI.GetCooldownData(Player, ToolName, ProcessedKey)
		
		IndexedAbilityFrame.Button.Img.ImageColor3 = Color3.fromRGB(52, 52, 52)
		
		IndexedAbilityFrame.Button.Right.Visible = true
		IndexedAbilityFrame.Button.Left.Visible = true

		while os.clock() - InitTimeStamp <= Cooldown do
			
			local max_hold = os.clock() - InitTimeStamp

			local newv = math.clamp(max_hold,0,Cooldown)
			newv = 1-(newv/Cooldown)

			local rot = newv * 360
			IndexedAbilityFrame.Button.Right.Img.UIGradient.Rotation = math.clamp(360-rot,0,180)
			IndexedAbilityFrame.Button.Left.Img.UIGradient.Rotation = -math.clamp(rot,0,180)

			RunService.Heartbeat:Wait()
		end
		
		IndexedAbilityFrame.Button.Right.Visible = false
		IndexedAbilityFrame.Button.Left.Visible = false
		--]]
	end
	
	UpdateCooldown.OnClientEvent:Connect(function(Category, Key)
		
		DebounceAPI.ApplyCooldown(Player, Category, Key)
		TerminateCharge(Category, Key)
	
		
	end)
end


--]]

return DebounceAPI