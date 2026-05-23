-- Russel Costales and Kyrushui cause remodel
-- October 10, 2021
-- Instance Cacher

local CacheMethods = {}
CacheMethods.__index = CacheMethods

local cacheLocation = Vector3.new(0, 10e8, 0)

local cacheFolder do
	if not workspace:FindFirstChild("Cache") then
		cacheFolder = Instance.new("Folder")
		cacheFolder.Name = "Cache"
		cacheFolder.Parent = workspace
	end
end
--[[		AUXILLARY FUNCTION		]]--
local createIns = function(Object, properties)
	local InstanceObject = Instance.new(Object)
	for property, value in next, properties do
		if property ~= 'Parent' and InstanceObject[property] ~= nil then
			InstanceObject[property] = value
		end
	end
	InstanceObject.Parent = properties['Parent']
	return InstanceObject
end

clearTables = function(Table)
	for index = 1, #Table do
		if type(Table[index]) == 'table' then
			clearTables(Table)
		end
		Table[index] = nil
	end
	Table = nil
end
--[[		MAIN FUNCTIONS		]]--

CacheMethods.new = function(Template, CacheAmount, FolderName)
	local self = setmetatable({}, CacheMethods)
	local cachedArea = createIns('Folder', {['Parent'] = cacheFolder, ['Name'] = FolderName or 'CachedFolder'})
	
	if Template:IsA('BasePart') or Template:IsA('MeshPart') then
		if not Template.Anchored then Template.Anchored = true end
	elseif Template:IsA('Model') then
		for _, ins in Template:GetChildren() do
			if Template:IsA('BasePart') or Template:IsA('MeshPart') then
				if not Template.Anchored then Template.Anchored = true end
			end
		end
	end
	self.Active = {}
	self.Inactive = {}
	self.Cached = {}
	self.ExtraObjects = {}
	self.Template = Template
	self.CacheArea = cachedArea
	
	function self:AddCache(Amount, isExtra)
		for _ = 1, Amount do
			local clonedTemplate = self.Template:Clone()
			clonedTemplate.Position = cacheLocation
			clonedTemplate.Parent = self.CacheArea
			table.insert(self.Cached, clonedTemplate)
			table.insert(self.Inactive, clonedTemplate)
			if isExtra then
				table.insert(self.ExtraObjects, clonedTemplate)
			end
		end
	end
	
	function self:GetObject()
		if self.Inactive[1] then
			local Object = self.Inactive[1]
			table.remove(self.Inactive, table.find(self.Inactive, Object))
			table.insert(self.Active, Object)
			return Object
		else
		--	warn('Out of: '..self.Template.Name..' in Cache for usage! Creating new object...')
			self:AddCache(1, true)
			local Object = self.Inactive[1]
			table.remove(self.Inactive, table.find(self.Inactive, Object))
			table.insert(self.Active, Object)
			return Object
		end
		
		
	end
	function self:ReturnObject(Object)
		if table.find(self.Cached, Object) then
			table.remove(self.Active, table.find(self.Inactive, Object))
			if table.find(self.ExtraObjects, Object) then
				Object:Destroy()
				Object = nil
			else
				table.insert(self.Inactive, Object)
				Object.Position = cacheLocation
			end
			
		end
	end
	function self:Delete()
		self.CacheArea:Destroy()
		clearTables(self)
		--if #self ~= 0 then
		--	for index = 1, #self do
		--		if type(self[index]) == table then
		--			for i,v in ipairs(self[index]) do
		--				if type(v) == Instance then
		--					v:Destroy()
		--					self[index][v] = nil
		--				else
		--					self[index][v] = nil
		--				end
		--			end
		--		end
		--		self[index] = nil
		--	end
		--end
		--self = nil
		warn('CACHED DESTROYED')
	end
	function self:DeleteExtra()
		for i, v in ipairs(self.ExtraCache) do
			if os.clock() - v[2] >= 60 and not table.find(self.Active, v) then
				
			end
		end
	end
	
	self:AddCache(CacheAmount or 20)
	warn('CACHED CREATED')
	return self
end

return CacheMethods