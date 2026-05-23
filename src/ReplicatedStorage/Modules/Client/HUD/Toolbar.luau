--!strict
-- Animates the 6 toolbar TextButtons (INV / STATS / TRADE / ALLY / STORE / SETTS) inside
-- Display.Buttons.Frame. Each button gets:
--   * hover → grows to 108% + tilts 12°
--   * press → shrinks to 92%
--   * release → springs back via HoverSpring
--   * click → toggles its menu panel; opening one closes any other that was open
--   * "active" state (panel currently open) → subtle 6% scale + small persistent tilt
--   * entrance → punches in from 0% scale on first reveal (covered by HUD UIScale anyway)
--
-- The TextLabel beneath each button is pulled into a rotation wrapper so tilting the
-- visual content doesn't distort the button's hit-target bounds or its UI constraints.
--
-- Reference: fruit/ReplicatedStorage/Modules/Client/HUD/Toolbar.luau + Panel.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))
local Animation = require(script.Parent:WaitForChild("Animation"))

-- TextLabel text → Menu child name. Lowercase + whitespace-stripped lookup.
local PANEL_NAMES: { [string]: string } = {
	inv       = "Inventory",
	inventory = "Inventory",
	bag       = "Inventory",
	stats     = "Stats",
	stat      = "Stats",
	trade     = "Trading",
	trading   = "Trading",
	ally      = "Ally",
	allies    = "Ally",
	store     = "Storage",
	storage   = "Storage",
	chest     = "Storage",
	setts     = "Settings",
	sett      = "Settings",
	settings  = "Settings",
	options   = "Settings",
	titles    = "Titles",
	title     = "Titles",
	artifact  = "Artifact",
	artifacts = "Artifact",
}

local function resolvePanelName(rawText: string?): string?
	if not rawText or rawText == "" then return nil end
	local key = string.lower(string.gsub(rawText, "%s+", ""))
	return PANEL_NAMES[key]
end

local function scaleUDim2(u: UDim2, factor: number): UDim2
	return UDim2.new(u.X.Scale * factor, math.round(u.X.Offset * factor),
	                 u.Y.Scale * factor, math.round(u.Y.Offset * factor))
end

-- Wire one button. `panelName` may be nil (button doesn't map to a panel — still animates,
-- just no click handler).
local function wireButton(Thread: any, button: GuiButton, activePanel: any, panelName: string?)
	-- Build rotation wrapper so the visual content tilts without distorting hit bounds.
	local wrapper = button:FindFirstChild("__HUDRotationWrapper")
	if not wrapper or not wrapper:IsA("Frame") then
		wrapper = Instance.new("Frame")
		wrapper.Name = "__HUDRotationWrapper"
		wrapper.AnchorPoint = Vector2.new(0.5, 0.5)
		wrapper.Position = UDim2.fromScale(0.5, 0.5)
		wrapper.Size = UDim2.fromScale(1, 1)
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel = 0
		wrapper.ClipsDescendants = false
		wrapper.ZIndex = button.ZIndex
		for _, child in ipairs(button:GetChildren()) do
			if child ~= wrapper and child:IsA("GuiObject") then
				child.Parent = wrapper
			end
		end
		wrapper.Parent = button
	end

	local originalSize = button.Size
	local hoverSize = scaleUDim2(originalSize, Animation.HoverScale)
	local pressSize = scaleUDim2(originalSize, Animation.PressScale)
	local activeSize = scaleUDim2(originalSize, 1.06)

	local hovering = Thread:Value(false)
	local pressing = Thread:Value(false)

	local function isActive(): boolean
		return panelName ~= nil and activePanel:Get() == panelName
	end

	local function computeSize(): UDim2
		if pressing:Get() then return pressSize end
		if hovering:Get() then return hoverSize end
		if isActive() then return activeSize end
		return originalSize
	end

	local function computeRotation(): number
		if pressing:Get() or hovering:Get() then return Animation.HoverRotation end
		if isActive() then return Animation.HoverRotation * 0.4 end  -- subtle tilt when "open"
		return 0
	end

	local sizeGoal = Thread:Value(computeSize())
	local rotGoal = Thread:Value(computeRotation())

	local function refresh()
		sizeGoal:Set(computeSize())
		rotGoal:Set(computeRotation())
	end

	Thread:Connect(hovering.Changed, refresh)
	Thread:Connect(pressing.Changed, refresh)
	Thread:Connect(activePanel.Changed, refresh)

	Thread:Configure(button)({
		AutoButtonColor = false,
		Size = Thread:Animation(sizeGoal, Animation.HoverSpring, {
			From = scaleUDim2(originalSize, 0),
			FirstInfo = Animation.PunchSpring,
		}),
		MouseEnter = function() hovering:Set(true) end,
		MouseLeave = function() hovering:Set(false); pressing:Set(false) end,
		MouseButton1Down = function() pressing:Set(true) end,
		MouseButton1Up = function() pressing:Set(false) end,
	})

	Thread:Configure(wrapper)({
		Rotation = Thread:Animation(rotGoal, Animation.HoverSpring),
	})

	if panelName then
		Thread:Connect(button.MouseButton1Click, function()
			if activePanel:Get() == panelName then
				activePanel:Set(nil)  -- toggle off
			else
				activePanel:Set(panelName)  -- toggle on (closes any other)
			end
		end)
	end
end

return function(Thread, ScreenFrame: Frame)
	local display = ScreenFrame:FindFirstChild("Display")
	local buttonsFrame = display
		and display:FindFirstChild("Buttons")
		and (display :: any).Buttons:FindFirstChild("Frame")
	if not buttonsFrame then
		warn("[HUD/Toolbar] Display.Buttons.Frame not found")
		return
	end

	-- ScreenFrame is HUD.Gui.Screen. Menu sits at HUD.Gui.Menu — one level up.
	local menuContainer = ScreenFrame.Parent and (ScreenFrame.Parent :: any):FindFirstChild("Menu")
	if menuContainer and menuContainer:IsA("GuiObject") then
		-- Make the container itself visible (transparent Frame) so panels can render.
		(menuContainer :: any).Visible = true
	end

	-- Shared state: which panel (by Menu child name) is currently open. nil = all closed.
	local activePanel = Thread:Value(nil :: string?)

	-- Reactive sync of panel Visible properties to the active state.
	Thread:Connect(activePanel.Changed, function()
		if not menuContainer then return end
		local current = activePanel:Get()
		for _, panel in ipairs(menuContainer:GetChildren()) do
			if panel:IsA("GuiObject") then
				(panel :: any).Visible = (panel.Name == current)
			end
		end
	end)

	-- Initial state: all panels closed (Menu's panels are already Visible=false by design).
	if menuContainer then
		for _, panel in ipairs(menuContainer:GetChildren()) do
			if panel:IsA("GuiObject") then
				(panel :: any).Visible = false
			end
		end
	end

	local function wirePanelClick(button: GuiButton)
		local label = button:FindFirstChildOfClass("TextLabel")
		local panelName = label and resolvePanelName(label.Text)
		if panelName and menuContainer and not menuContainer:FindFirstChild(panelName) then
			-- Don't try to map to a non-existent panel
			panelName = nil
		end
		wireButton(Thread, button :: any, activePanel, panelName)
	end

	for _, child in ipairs(buttonsFrame:GetChildren()) do
		if child:IsA("GuiButton") then
			wirePanelClick(child :: GuiButton)
		end
	end

	-- Catch any buttons added later.
	Thread:Connect(buttonsFrame.ChildAdded, function(child)
		if child:IsA("GuiButton") then
			task.defer(wirePanelClick, child :: GuiButton)
		end
	end)
end
