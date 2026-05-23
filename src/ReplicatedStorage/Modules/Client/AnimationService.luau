--||Services||--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

--||Modules||--
local Modules = ReplicatedStorage.Modules

--local AnimationSettings = require(script:WaitForChild("AnimationSettings"))
local Utility = require(Modules.Utility.Utility)

--||Directories||--
local Library = ReplicatedStorage.Assets

local AnimationFolder = Library.Animations

local SharedFolder = AnimationFolder.Shared


--||Remotes||--
local Remotes = ReplicatedStorage.Remotes

local AnimationRemote = Remotes.Animation

--||Variables||--



--||Main||--
local AnimationService = {}

local function GetCharacterFromEntity(Entity)
	return Entity:IsA("Player") and Entity.Character or Entity
end

local function PreloadAnimations(Character, Animations)
	local LoadedAnimations = AnimationService.GetCharacterAnimations(Character)

	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:WaitForChild("Animator") 


	for _, AnimationObject in ipairs(Animations) do
		if LoadedAnimations[AnimationObject.Name] then continue end

		LoadedAnimations[AnimationObject.Name] = Animator:LoadAnimation(AnimationObject)
	end


end

local function FreezeAnimationAtPosition(Track, percentagePosition)
	-- Set the speed to 0 to freeze the animation
	Track:AdjustSpeed(0)
	if not Track.IsPlaying then
		-- Play the animation if it is not playing
		Track:Play() 
	end
	-- Jump to the desired TimePosition
	Track.TimePosition = (percentagePosition / 100) * Track.Length
end

if RunService:IsClient() then
	local Player = Players.LocalPlayer
	local Character = Player.Character or Player.CharacterAdded:Wait()

	function AnimationService.Initialize(Character)
		local Humanoid = Character:WaitForChild("Humanoid")
		local SharedChildren = Utility:deepSearchFolder(SharedFolder, "Animation")

		AnimationService[Character] = {
			LoadedAnimations = {},
		}

		PreloadAnimations(Character, SharedChildren)
		warn('preloaded animations')
		
		--for _, FruitAnimations in ipairs(AnimationService[Character].QueuedFruits) do
		--	PreloadAnimations(Character, Utility:deepSearchFolder(DevilFruit[FruitAnimations]))
		--end


	end

	function AnimationService.GetCharacterAnimations(Character)

		return AnimationService[Character].LoadedAnimations or warn"Character does not have a profile"
	end

	function AnimationService.PlayAnimation(Character, AnimationName, AnimationData, Override)

		local Track = AnimationService.GetCharacterAnimations(Character)[AnimationName]

		if Track == nil then return end

		local FadeTime = AnimationData and AnimationData.FadeTime or .1
		local Weight =  AnimationData and AnimationData.Weight or 1

		local CallBack = AnimationData and AnimationData.CallBack 
		
		local LoopStatus = AnimationData and AnimationData.Loop or false
		local PlayOver = AnimationData and AnimationData.PlayOver or false
		
		local Priority = AnimationData and AnimationData.Priority
		local Freeze = AnimationData and AnimationData.Freeze or false
		
		if PlayOver and AnimationService.IsPlaying(Character, AnimationName) then return end 

		
		if Priority then
			Track.Priority = Enum.AnimationPriority[Priority]
		end
		
		Track:Play(FadeTime,Weight)


		if AnimationData and AnimationData.TimePosition then
			
			
			Track:AdjustSpeed(0)
			Track.TimePosition = (AnimationData.TimePosition / 100) * Track.Length

			
		end
		
		if AnimationData and AnimationData.Speed then 
			Track:AdjustSpeed(AnimationData.Speed)
		
		end
		
		Track.Looped = LoopStatus
		
		
		if CallBack then
			local TrackConnection = nil

			TrackConnection = Track.Stopped:Connect(function()
				CallBack()

				TrackConnection:Disconnect()
				TrackConnection = nil
			end)

		end

	end

	function AnimationService.StopAnimation(Character, AnimationName, AnimationData)
		local Track = AnimationService.GetCharacterAnimations(Character)[AnimationName]

		if Track == nil then return end
		--if Track.IsPlaying == false then return end

		local FadeTime = AnimationData and AnimationData.FadeTime or .1
		local Weight = AnimationData and  AnimationData.Weight or 1

		Track:Stop(FadeTime,Weight)
		
	end

	function AnimationService.RemoveCharacterAnimations(Character)
		if AnimationService.GetCharacterAnimations(Character) then
			AnimationService[Character] = nil
		end
	end
	
	function AnimationService.IsPlaying(Character, AnimationName)
		local Track = AnimationService.GetCharacterAnimations(Character)[AnimationName]
		
		if Track == nil then return end 
	
		return Track.IsPlaying
	end
	
	AnimationRemote.OnClientEvent:Connect(function(AnimationName, ExecutionStatus, AnimationData, OptionalEntity)

		if OptionalEntity and AnimationService[OptionalEntity] == nil then
			AnimationService.Initialize(OptionalEntity)
		end

		AnimationService[ExecutionStatus.."Animation"]((OptionalEntity or Player.Character), AnimationName, AnimationData)

	end)

	AnimationService.Initialize(Player.Character)

	--> Add Anims on Spawn
	Player.CharacterAdded:Connect(AnimationService.Initialize)

	--> Reset Anims on Death
	Player.CharacterRemoving:Connect(AnimationService.RemoveCharacterAnimations)

else

	function AnimationService.PlayAnimation(Player, AnimationName, ExeuctionStatus, AnimationData)
		if not Player:IsA("Player") then Player = Players:GetPlayerFromCharacter(Player) or Player end

		if Player:IsA("Player") then
			AnimationRemote:FireClient(Player, AnimationName, ExeuctionStatus, AnimationData)
		else
			AnimationRemote:FireAllClients(AnimationName, ExeuctionStatus, AnimationData, Player)
		end

	end

end


return AnimationService