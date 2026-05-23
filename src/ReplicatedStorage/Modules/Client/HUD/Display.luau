--!strict
-- Wires the existing HUD.Gui.Screen.Display.Exp frame's labels + bar to PlayerData via Replica.
-- Updates Lv, EXP bar, money — re-binds when Ability changes so the level/exp track the
-- currently-equipped fighting style.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))
local PlayerDataClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("PlayerDataClient"))
local FormulaAPI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("FormulaAPI"))
local Animation = require(script.Parent:WaitForChild("Animation"))

local FillEase = Animation.ExpBarFill

local function formatMoney(amount: number): string
	local int = tostring(math.floor(amount))
	local withCommas = int:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	withCommas = (withCommas :: string):gsub("^,", "")
	return "$" .. withCommas
end

-- Pick the first TextLabel whose Text matches a predicate.
local function findLabel(parent: Instance, predicate: (TextLabel) -> boolean): TextLabel?
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("TextLabel") and predicate(child) then
			return child
		end
	end
	return nil
end

return function(Thread, ExpFrame: Frame)
	local Bar = ExpFrame:FindFirstChild("Bar")
	if not (Bar and Bar:IsA("Frame")) then
		warn("[HUD/Display] Exp frame missing 'Bar' child")
	end

	local levelLabel = findLabel(ExpFrame, function(label) return label.Text:match("^Lv%.") ~= nil end)
	local expValueLabel = findLabel(ExpFrame, function(label) return label.Text:find("/") and label.Text:match("^[%d,]+%s*/") ~= nil end)
	local moneyLabel = findLabel(ExpFrame, function(label) return label.Text:sub(1, 1) == "$" end)
	-- title label is left untouched until an EquippedTitle field exists in ProfileData

	local maxFillScale = Bar and Bar.Size.X.Scale or 0.7249

	local Level = Thread:Value(1)
	local Experience = Thread:Value(0)
	local Bounty = Thread:Value(0)

	-- Bar size driven reactively from Level + Experience
	local TargetBarSize = if Bar then Thread:Value((Bar :: Frame).Size) else nil
	if Bar and TargetBarSize then
		Thread:Reactive(function(Grab)
			local lvl = Grab(Level) :: number
			local xp = Grab(Experience) :: number
			local max = FormulaAPI.CalculateMaxMastery(lvl)
			local ratio = (max > 0) and math.clamp(xp / max, 0, 1) or 0
			TargetBarSize:Set(UDim2.new(ratio * maxFillScale, 0, 1, 0))
		end)
		Thread:Configure(Bar)({
			Size = Thread:Animation(TargetBarSize, FillEase),
		})
	end

	if levelLabel then
		Thread:Configure(levelLabel)({
			Text = Thread:Do(function(Grab)
				return "Lv. " .. tostring(Grab(Level))
			end),
		})
	end

	if expValueLabel then
		Thread:Configure(expValueLabel)({
			Text = Thread:Do(function(Grab)
				local lvl = Grab(Level) :: number
				local xp = Grab(Experience) :: number
				local max = FormulaAPI.CalculateMaxMastery(lvl)
				local function withCommas(n: number): string
					local s = tostring(math.floor(n))
					local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
					result = (result :: string):gsub("^,", "")
					return result
				end
				return string.format("%s / %s", withCommas(xp), withCommas(max))
			end),
		})
	end

	if moneyLabel then
		Thread:Configure(moneyLabel)({
			Text = Thread:Do(function(Grab)
				return formatMoney(Grab(Bounty) :: number)
			end),
		})
	end

	-- Wire to PlayerData once Replica streams in
	PlayerDataClient.OnReady(function()
		local function refresh()
			local ability = PlayerDataClient.GetData("Ability")
			if type(ability) == "string" and ability ~= "" then
				local lvl = PlayerDataClient.GetData("Mastery." .. ability .. ".MasteryLevel")
				local xp = PlayerDataClient.GetData("Mastery." .. ability .. ".MasteryExperience")
				if type(lvl) == "number" then Level:Set(lvl) end
				if type(xp) == "number" then Experience:Set(xp) end
			end
			local bounty = PlayerDataClient.GetData("Bounty")
			if type(bounty) == "number" then Bounty:Set(bounty) end
		end

		refresh()

		PlayerDataClient.OnSet("Ability", refresh)
		PlayerDataClient.OnSet("Bounty", function(new) if type(new) == "number" then Bounty:Set(new) end end)

		-- Mastery is keyed by ability — listen to all known abilities' level/exp paths.
		local masteryRoot = PlayerDataClient.GetData("Mastery")
		if type(masteryRoot) == "table" then
			for abilityName in pairs(masteryRoot) do
				PlayerDataClient.OnSet(string.format("Mastery.%s.MasteryLevel", abilityName), refresh)
				PlayerDataClient.OnSet(string.format("Mastery.%s.MasteryExperience", abilityName), refresh)
			end
		end
	end)
end
