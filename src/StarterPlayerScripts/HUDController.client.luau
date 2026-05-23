--!strict
-- HUD bootstrap.
--
-- This game has `Players.CharacterAutoLoads = false`. As a result, Roblox's StarterGui→PlayerGui
-- auto-clone may not fire until the first CharacterAdded (when the player actually spawns
-- into a match). Many legacy scripts do `PlayerGui:WaitForChild("HUD")` on player join and
-- would block until then.
--
-- Strategy: clone StarterGui.HUD into PlayerGui as "HUD" IMMEDIATELY on player join so legacy
-- scripts can proceed. Watch for StarterGui auto-clone firing later (on spawn) and remove the
-- duplicate so we have exactly one HUD in PlayerGui.
--
-- StarterGui.HUD must contain a MoveSet stub child (added via MCP) so UILibrary +
-- DebounceLibrary don't error when they read HUDGui.MoveSet.
--
-- Visibility gating: HUD.Enabled = false until the player actually spawns into a round
-- (CharacterAdded + Data.Ability set). Main.GuiController:223 also flips Enabled=true on
-- spawn — same trigger, harmless when our maybeReveal does the same.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))
local HUDModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("HUD")
local Animation = require(HUDModules:WaitForChild("Animation"))

local Thread = Faye.new()

-- Identify our NEW design by its structure (Gui.Screen.Display path).
local function isNewHud(candidate: Instance?): boolean
	if not candidate or not candidate:IsA("ScreenGui") then return false end
	local gui = candidate:FindFirstChild("Gui")
	if not gui then return false end
	local screen = gui:FindFirstChild("Screen")
	if not screen then return false end
	return screen:FindFirstChild("Display") ~= nil
end

-- Scan PlayerGui for the first NEW-design HUD, return immediately (no waiting).
local function findExistingNewHud(): ScreenGui?
	for _, candidate in ipairs(PlayerGui:GetChildren()) do
		if candidate.Name == "HUD" and isNewHud(candidate) then
			return candidate :: ScreenGui
		end
	end
	return nil
end

local HUD: ScreenGui? = findExistingNewHud()

if not HUD then
	-- Destroy any legacy "HUD" (no NEW structure) so legacy scripts find OUR HUD with the
	-- MoveSet stub instead of a wrong one.
	for _, stale in ipairs(PlayerGui:GetChildren()) do
		if stale.Name == "HUD" and stale:IsA("ScreenGui") and not isNewHud(stale) then
			stale:Destroy()
		end
	end

	local template = StarterGui:FindFirstChild("HUD")
	if template and template:IsA("ScreenGui") and isNewHud(template) then
		local clone = template:Clone()
		clone.Name = "HUD"
		clone.ResetOnSpawn = false
		clone.Enabled = false  -- maybeReveal flips this on after spawn
		clone.Parent = PlayerGui
		HUD = clone
		print(string.format("[HUDController] Cloned NEW HUD from %s as 'HUD'", template:GetFullName()))
	end
end

if not HUD then
	warn("[HUDController] Could not locate or clone the NEW HUD. Bailing.")
	return
end

-- Defensive: if the HUD template lacks the MoveSet stub (e.g. Studio was reset and MCP
-- changes weren't saved), create it programmatically. UILibrary + DebounceLibrary read
-- `HUDGui.MoveSet` directly and would error if absent.
if not HUD:FindFirstChild("MoveSet") then
	local moveset = Instance.new("Frame")
	moveset.Name = "MoveSet"
	moveset.Size = UDim2.new(0, 0, 0, 0)
	moveset.BackgroundTransparency = 1
	moveset.Visible = false
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Parent = moveset
	moveset.Parent = HUD
	print("[HUDController] Created MoveSet stub programmatically (template was missing it)")
end

-- Watch PlayerGui for additional "HUD" instances that arrive later (StarterGui auto-clone
-- can fire on CharacterAdded). Destroy them so we have exactly one HUD — ours.
local ourHud: ScreenGui = HUD
PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "HUD" and child:IsA("ScreenGui") and child ~= ourHud then
		child:Destroy()
		print("[HUDController] Removed duplicate HUD that arrived after our clone")
	end
end)

-- Also catch a race: if a duplicate landed BETWEEN our scan and our clone, sweep now.
for _, candidate in ipairs(PlayerGui:GetChildren()) do
	if candidate.Name == "HUD" and candidate:IsA("ScreenGui") and candidate ~= ourHud then
		candidate:Destroy()
		print("[HUDController] Swept residual HUD duplicate after clone")
	end
end

local Gui = HUD:WaitForChild("Gui", 5)
local Screen = Gui and Gui:WaitForChild("Screen", 5)
local Display = Screen and Screen:WaitForChild("Display", 5)

if not Display then
	warn("[HUDController] HUD is missing Gui.Screen.Display. Bailing.")
	return
end

print(string.format("[HUDController] Using HUD: %s", HUD:GetFullName()))

local function mount(name: string, target: Instance?)
	local moduleScript = HUDModules:FindFirstChild(name)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		warn(string.format("[HUDController] %s module missing", name))
		return
	end
	if not target then
		warn(string.format("[HUDController] %s target instance missing — skipping", name))
		return
	end
	local ok, err = pcall(function()
		require(moduleScript)(Thread, target)
	end)
	if not ok then
		warn(string.format("[HUDController] %s failed: %s", name, tostring(err)))
	end
end

mount("HealthBar", Display:FindFirstChild("Health"))
mount("StaminaBar", Display:FindFirstChild("Stamina"))
mount("Display", Display:FindFirstChild("Exp"))
mount("Toolbar", Screen)  -- hover/press animations for the 6 nav buttons + menu panel toggle

-- ─── Visibility gating: HUD hidden until spawn ───────────────────────
HUD.Enabled = false

-- UIScale on Gui frame so we can animate a "pop-in" entrance on reveal.
-- Starts at 0.7 (matches Animation.ItemEnterScale); springs to 1.0 on reveal.
local guiScale = Gui:FindFirstChildOfClass("UIScale")
if not guiScale then
	guiScale = Instance.new("UIScale")
	guiScale.Scale = Animation.ItemEnterScale
	guiScale.Parent = Gui
else
	guiScale.Scale = Animation.ItemEnterScale
end

local ScaleGoal = Thread:Value(Animation.ItemEnterScale)
Thread:Configure(guiScale)({
	Scale = Thread:Animation(ScaleGoal, Animation.ItemEnterSpring),
})

local revealed = false
local function maybeReveal()
	if revealed then return end
	local character = LocalPlayer.Character
	if not character then return end
	if not character:FindFirstChildOfClass("Humanoid") then return end
	local dataFolder = LocalPlayer:FindFirstChild("Data")
	if not dataFolder then return end
	local abilityValue = dataFolder:FindFirstChild("Ability")
	if not (abilityValue and abilityValue:IsA("ValueBase")) then return end
	if (abilityValue :: any).Value == "" then return end
	revealed = true
	if HUD then
		HUD.Enabled = true
	end
	ScaleGoal:Set(1)  -- spring HUD from 0.7 → 1.0 (Faye picks it up via the bound Animation)
	print("[HUDController] HUD revealed (character + Ability set)")
end

-- Re-enable HUD on every respawn (Main.GuiController:369 disables it on Humanoid.Died).
-- We want our HUD to stay visible across deaths once we've revealed it at least once.
LocalPlayer.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid", 10)
	if revealed and HUD then
		HUD.Enabled = true
	end
	maybeReveal()
end)

task.spawn(function()
	local dataFolder = LocalPlayer:WaitForChild("Data", 30)
	if not dataFolder then return end
	local abilityValue = dataFolder:WaitForChild("Ability", 30)
	if not abilityValue then return end
	abilityValue:GetPropertyChangedSignal("Value"):Connect(maybeReveal)
	maybeReveal()
end)

maybeReveal()
