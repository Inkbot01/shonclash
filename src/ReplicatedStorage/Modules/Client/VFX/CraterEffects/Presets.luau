--[[
	DEVELOPED BY: KYRUSHUI // 2021

	-------------------
	WHEN RETURNING, RETURN THE TYPE OF FUNCTION YOU WANT IT TO FIRE AND RETURN THE SETTINGS YOU CREATED
	
	ex:

		['OFA'] = function(customization)
		local customization = customization or {}
		local settingsPatch = {
			['AnimationSpeed'] = .2;
			['Width'] = {3.5,.8};
			['stepSize'] = 1;
			['Distance'] = customization['Distance'] or 25;
			['BlockSize'] = customization['BlockSize'] or {1,2};
			['HoldTime'] = customization['HoldTime'] or 3;
			['Range'] = customization['Range'] or 5
		}

		return 'Path', settingsPatch
	end,
	
	
	(NOTE: YOU DO NOT NEED TO DEFINE ANY PARAMETERS IF YOU DO NOT WISH FOR IT.)
	----------------------
	
]]

return {
	['OFA'] = function(customization) -- ADD YOUR OWN PRESETS
		local customization = customization or {}
		local settingsPatch = {
			['AnimationSpeed'] = .2;
			['Width'] = {5.5,.8};
			['stepSize'] = 1;
			['Distance'] = customization['Distance'] or 50;
			['BlockSize'] = customization['BlockSize'] or {2,.5};
			['HoldTime'] = customization['HoldTime'] or 3;
			['Range'] = customization['Range'] or 5
		}

		return 'Path', settingsPatch
	end,
}
