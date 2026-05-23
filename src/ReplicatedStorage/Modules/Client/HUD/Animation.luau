--!strict
-- HUD animation constants. Adapted from fruit's Modules/Client/HUD/Animation.luau —
-- same spring tunings so the feel matches the reference. Faye comes from Wally Packages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Faye = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Faye"))

local Animation = {}

-- Hover / press springs. Quick, slightly bouncy. Used by Toolbar buttons + Panel close buttons.
Animation.HoverSpring   = Faye.SpringInfo(0.22, 1.6, 0.5)
Animation.UnhoverSpring = Faye.SpringInfo(0.30, 1.3, 0.7)
Animation.PressSpring   = Faye.SpringInfo(0.08, 3.0, 0.6)
Animation.ReleaseSpring = Faye.SpringInfo(0.28, 2.0, 0.5)

-- Bar fill animations.
Animation.BarFill         = Faye.Info(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
Animation.HealthBarFill   = Faye.SpringInfo(0.22, 1.6, 0.7)
Animation.HealthDamageBar = Faye.SpringInfo(0.85, 1.0, 0.6)
Animation.ExpBarFill      = Faye.SpringInfo(0.85, 1.3, 0.55)

Animation.HealthFlash    = Faye.Info(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Animation.HealthSettle   = Faye.Info(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
Animation.HealthLowColor   = Color3.fromRGB(255, 70, 70)
Animation.HealthHighColor  = Color3.fromRGB(197, 255, 110)
Animation.HealthFlashColor = Color3.fromRGB(255, 50, 50)

-- Button feel.
Animation.HoverScale    = 1.08
Animation.PressScale    = 0.92
Animation.HoverRotation = 12   -- degrees of tilt on hover

-- Entrance animations.
Animation.ItemEnterSpring = Faye.SpringInfo(0.45, 1.5, 0.55)
Animation.ItemEnterScale  = 0.7
Animation.ItemEnterTilt   = 10

-- Punch (toolbar buttons can use this on first reveal).
Animation.PunchSpring = Faye.SpringInfo(0.35, 1.8, 0.45)
Animation.PunchScale  = 1.18

return Animation
