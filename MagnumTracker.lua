require "Apollo"
require "Window"

local MagnumTracker = {}

--[[
function FindMagnum()
	local ret = {}
	for i = 1,99999 do
		local spl = GameLib.GetSpell(i)
		if (spl:GetName() == "Magnum") then
			table.insert(ret, i)
		end
	end
	return ret
end

Magnum IDs: { 88040, 88041, 88151, 88152, 88153, 88154, 88155, 88156, 88157, 88158, 88307, 88308, 88309, 88310, 88311, 88312, 88313, 88314, 88315, 88316 }
]]--

function MagnumTracker:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	self.MagnumVoidName = "Hostile Invisible Unit for Fields (0 hit radius)"
	self.MagnumSpellId = 88151
	self.MagnumSpell = GameLib.GetSpell(self.MagnumSpellId)

	self.LastMagnumSpellCooldownRemaining = 0

	self.Player = nil

	self.TrackedMagnumVoidUnit = nil

	self.TrackedPixieId = nil
	self.TrackedPixieData = nil

	return o
end

function MagnumTracker:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}

	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function MagnumTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MagnumTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function MagnumTracker:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.Overlay = Apollo.LoadForm(self.xmlDoc, "Overlay", "InWorldHudStratum", self)
		if self.Overlay == nil then
			Apollo.AddAddonErrorText(self, "Could not load the overlay window for some reason.")
			return
		end

		self.Overlay:Show(true, true)

		self.xmlDoc = nil

		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
		
		Apollo.RegisterEventHandler("ChangeWorld", "OnWorldChanged", self)
		Apollo.RegisterEventHandler("ChatZoneChange", "OnChatZoneChange", self)

		Apollo.RegisterEventHandler("NextFrame", "OnNextFrame", self)
	end
end

function MagnumTracker:OnNextFrame()
	if self.TrackedMagnumVoidUnit == nil then return end
	if self.Player == nil then return end

	local unit_pos = GameLib.GetUnitScreenPosition(self.TrackedMagnumVoidUnit)
	local player_pos = GameLib.GetUnitScreenPosition(self.Player)

	if unit_pos == nil or player_pos == nil then
		self.Overlay:DestroyAllPixies()

		self.TrackedPixieId = nil
		self.TrackedPixieData = nil

		return
	end

	local offsets = { player_pos.nX, player_pos.nY, unit_pos.nX, unit_pos.nY }

	if self.TrackedPixieId == nil or self.TrackedPixieData == nil then
		self.Overlay:DestroyAllPixies()

		self.TrackedPixieData = {
			bLine = true, fWidth = 5.0, cr = { a = 1.0, r = 1.0, b = 1.0, g = 1.0 },
			loc = { fPoints = {0.0, 0.0, 0.0, 0.0}, nOffsets = offsets }	
		}

		self.TrackedPixieId = self.Overlay:AddPixie(self.TrackedPixieData)
	else
		self.TrackedPixieData.loc.nOffsets = offsets

		self.Overlay:UpdatePixie(self.TrackedPixieId, self.TrackedPixieData)
	end
end

function MagnumTracker:StartTracking(unit)
	self.TrackedMagnumVoidUnit = unit
end

function MagnumTracker:StopTracking()
	self.TrackedMagnumVoidUnit = nil

	self.Overlay:DestroyAllPixies()

	self.TrackedPixieId = nil
	self.TrackedPixieData = nil
end

function MagnumTracker:OnUnitCreated(unit)
	if self.Player == nil then
		local player = GameLib.GetPlayerUnit()
		if player ~= nil and player:IsValid() then self.Player = player end
	end

	if self.Player == nil then return end

	local unit_name = unit:GetName()
	if unit_name == self.MagnumVoidName then
		local cooldown_remaining = self.MagnumSpell:GetCooldownRemaining()
		local cooldown_time = self.MagnumSpell:GetCooldownTime()

		if cooldown_remaining > self.LastMagnumSpellCooldownRemaining and cooldown_remaining > cooldown_time - 0.1 then
			self:StartTracking(unit)
		end

		self.LastMagnumSpellCooldownRemaining = cooldown_remaining
	end
end

function MagnumTracker:OnUnitDestroyed(unit)
	if unit == self.TrackedMagnumVoidUnit then self:StopTracking() end

	self.LastMagnumSpellCooldownRemaining = self.MagnumSpell:GetCooldownRemaining()
end

function MagnumTracker:OnWorldChanged()
	self.Player = nil
end

function MagnumTracker:OnChatZoneChange()
	self:OnWorldChanged()
end


local MagnumTrackerInst = MagnumTracker:new()
MagnumTrackerInst:Init()