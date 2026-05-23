local Styles = require(script.Parent.Parent:WaitForChild('Styles'))


OFA = function(AnchorPoint)
	task.spawn(function()
		Styles.ChunkCrater(AnchorPoint, {
			Angle = {45, 65},
			Tilt = {-15, 15},
			Height = {-.5, .8},
			BlockSize = {1.25, 2},
			PartCount = 20,
			Radius = 10,
			IterateSpeed = {
				Entrance = .1,
				EntranceDivision = 2,
				Exit = .25,
				ExitDivision = 2
			}
		})
	end)
	
	task.spawn(function()
		Styles.Break(AnchorPoint, {
			Radius = 15,
			PartCount = 15,
			BlockSize = {.25, 3},
			Height = {15, 25},
			Angle = {-5, 5},
			Tilt = {-5, 5},
			Width = {-35, 35},
			IterateSpeed = {
				Entrance = .1,
				EntranceDivision = 2,
				Exit = .25,
				ExitDivision = 2
			}
		})
	end)
	Styles.ChunkCrater(AnchorPoint, {
		Angle = {45, 65},
		Tilt = {-15, 15},
		Height = {-.5, .8},
		BlockSize = {2, 3},
		PartCount = 20,
		Radius = 15,
		IterateSpeed = {
			Entrance = .1,
			EntranceDivision = 2,
			Exit = .25,
			ExitDivision = 2
		}
	})
end
return OFA