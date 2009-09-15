--[[
-- TODO: do code cleanup
-- TODO: save data of bags in inventory to DB
--
--
--]]

DEBUG = 0
BANKFRAMEOPEN = false

local Tablet = AceLibrary("Tablet-2.0")
local L = AceLibrary("AceLocale-2.2"):new("ContainerFu")

ContainerFu = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "AceConsole-2.0", "AceEvent-2.0", "FuBarPlugin-2.0")

ContainerFu:RegisterDB("ContainerFuDB", "ContainerFuDBPerChar")
ContainerFu:RegisterDefaults('char', {
	bank = {
		uslots = 0,
		tslots = 0,
		datasaved = false, -- bank data already saved
		display = true,    -- show bank data in tooltip
		b5 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b6 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b7 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b8 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b9 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b10 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		},
		b11 = {
			uslots = 0,
			tslots = 0,
			bagname = nil
		}
	},
	keys = {
		display = true -- show key data in tooltip
	}
})




function ContainerFu:OnInitialize()
	-- Called when the addon is loaded
end

function ContainerFu:OnEnable()
	-- Called when the addon is enabled
	self:DebugMsg("ContainerFu:OnEnable()")
	
	-- register events
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
end

function ContainerFu:OnDisable()
	-- Called when the addon is disabled
end

-- Start Fubar example

-- AceOptions data table
ContainerFu.OnMenuRequest = {
	type = 'group',
	args = {
		keys = {
			type = "toggle",
			name = L["SHOW_KEYS"], --"Show keys",
			desc = L["SHOW_KEYDATA_IN_TOOLTIP"], --"Show key data in tooltip",
			get = function() return ContainerFu.db.char.keys.display end,
			set = function()
				ContainerFu.db.char.keys.display = not ContainerFu.db.char.keys.display
				ContainerFu:Update()
			end,
		},
		bank = {
			type = "toggle",
			name = L["SHOW_BANK"], --"Show bank",
			desc = L["SHOW_BANKDATA_IN_TOOLTIP"], --"Show bank data in tooltip",
			get = function() return ContainerFu.db.char.bank.display end,
			set = function()
				ContainerFu.db.char.bank.display = not ContainerFu.db.char.bank.display
				ContainerFu:Update()
			end,

		}

	}
}

function ContainerFu:OnDataUpdate()
	local usedSlots = 0
	local bagSlots = 0

	for bagId = 0, 4 do
		bagSlots = bagSlots + GetContainerNumSlots(bagId)
		usedSlots = usedSlots + self:GetContainerUsedSlots(bagId)
	end
	
	self:SetText(string.format("CF: %d/%d", usedSlots, bagSlots))
end

function ContainerFu:OnTextUpdate()
	
	--ContainerFu:Update()

end

local tablet = AceLibrary("Tablet-2.0")


function ContainerFu:OnTooltipUpdate()

	-- inventory bags
	local cat = tablet:AddCategory(
		'text', L["BAGS"], --"Bags",
		'columns', 2,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 0,
		'child_textR2', 1,
		'child_textG2', 1,
		'child_textB2', 1
	)
	
	for bagId = 0, 4 do
		if GetContainerNumSlots(bagId) ~= 0 then
			cat:AddLine(
				'text', GetBagName(bagId),
				'text2', self:GetContainerUsedSlots(bagId) .. "/" .. GetContainerNumSlots(bagId)
			)
		end
	end

	cat:AddLine(
		'text', L["TOTAL"],
		'text2', self:CountInventoryBagsUsedSlots() .. "/" .. self:CountInventoryBagsSlots()
	)


	-- Bank content
	if self.db.char.bank.datasaved and self.db.char.bank.display then
		cat = tablet:AddCategory(
			'text', L["BANK"], --"Bank",
			'columns', 2,
			'child_textR', 1,
			'child_textG', 1,
			'child_textB', 0,
			'child_textR2', 1,
			'child_textG2', 1,
			'child_textB2', 1
		)
	
		cat:AddLine(
			'text', L["BANK_CONTENT"], --"Bank content",
			'text2', self.db.char.bank.uslots .. "/" .. GetContainerNumSlots(-1)
		)
	
		for bagId = 5, 11 do
			local bagname, uslots, tslots = self:GetBagData(bagId)
			if tslots ~= 0 then

				cat:AddLine(
					'text', bagname,
					'text2', uslots .. "/" .. tslots
				)
			end
		end

		cat:AddLine(
			'text', L["TOTAL"],
			'text2', self:CountBankUsedSlots() .. "/" .. self:CountBankSlots()
		)
	end

	-- Keyring
	if HasKey() and self.db.char.keys.display then
		cat = tablet:AddCategory(
		'text', L["KEYS"], --"Keys",
		'columns', 2,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 0,
		'child_textR2', 1,
		'child_textG2', 1,
		'child_textB2', 1
		)

		cat:AddLine(
			'text', L["KEYRING"], --"Keyring",
			'text2', self:GetContainerUsedSlots(-2) .. "/" .. GetContainerNumSlots(-2)
		)
	end

	--tablet:setHint("Click to do something")
	-- as a rule, if you have an OnClick or OnDoubleClick or OnMouseUp
end

function ContainerFu:OnClick()
	-- do something
	self:DebugMsg("OnClick()")
end
-- End FuBar example


function ContainerFu:BAG_UPDATE()
	local slots = GetContainerNumSlots(arg1)
	self:DebugMsg("Inventory changed, bagId: " .. arg1 .. "BagSlots: " .. slots)
	--self.Update()
	if arg1 == 0 or arg1 == 1 or arg1 == 2 or arg1 == 3 or arg1 ==4 then
		self:SetText(string.format("CF: %d/%d", self:CountInventoryBagsUsedSlots(), self:CountInventoryBagsSlots()))
	end
	
	if BANKFRAMEOPEN then
		self.db.char.bank.uslots = self:GetContainerUsedSlots(-1)
		self.db.char.bank.tslots = GetContainerNumSlots(-1)

		if arg1 >= 5 and arg1 <= 11 then self:ToDbSaveBag(arg1) end
	end
	
end

function ContainerFu:BANKFRAME_OPENED()
	BANKFRAMEOPEN = true

	self:ToDbSaveBag(-1)

	for bagId = 5, 11 do
		if GetContainerNumSlots(bagId) ~= 0 then
			self:ToDbSaveBag(bagId)
		end
	end

	self.db.char.bank.datasaved = true
end

function ContainerFu:BANKFRAME_CLOSED()
	BANKFRAMEOPEN = false
end

function ContainerFu:PLAYERBANKBAGSLOTS_CHANGED()
	self:DebugMsg("PLAYERBAGSLOTS_CHANDED()" .. arg1)
	self:ToDbSaveBag(arg1)
end

function ContainerFu:PLAYERBANKSLOTS_CHANGED()
	--[[
	self:DebugMsg("PLAYERBANKSLOTS_CHANGED() arg1=" .. arg1)
	if BANKFRAMEOPEN then self:ToDbSaveBag(arg1) end
	--]]
end

-- save bank bag data to DB
function ContainerFu:ToDbSaveBag(bagId)

	self:DebugMsg("ToDbSaveBag(" .. bagId .. ")")
	if bagId == -1 then
		self.db.char.bank.uslots = self:GetContainerUsedSlots(bagId)
		self.db.char.bank.tslots = GetContainerNumSlots(bagId)

	elseif 5 <= bagId and bagId <= 11 then --bank bags

		assert(loadstring(
			"ContainerFu.db.char.bank.b" .. bagId .. ".uslots = ContainerFu:GetContainerUsedSlots(" .. bagId .. ")"))()
		assert(loadstring(
			"ContainerFu.db.char.bank.b" .. bagId .. ".tslots = GetContainerNumSlots(" .. bagId .. ")"))()
		assert(loadstring(
			"ContainerFu.db.char.bank.b" .. bagId .. ".bagname = GetBagName(" .. bagId .. ")"))()
	
	end

	ContainerFu:Update()
end

function ContainerFu:GetBagData(bagId)
	local bagname = "" 
	local uslots = 0
	local tslots = 0

	if bagId == -1 then
		bagname = "Bank content"
		uslots = self.db.char.bank.uslots
		tslots = self.db.char.bank.tslots

	elseif 5 <= bagId and bagId <= 11 then
		bagname = assert(loadstring("return ContainerFu.db.char.bank.b" .. bagId .. ".bagname"))()
		uslots = assert(loadstring("return ContainerFu.db.char.bank.b" .. bagId .. ".uslots"))()
		tslots = assert(loadstring("return ContainerFu.db.char.bank.b" .. bagId .. ".tslots"))()
	end

	return bagname, uslots, tslots
end

function ContainerFu:GetContainerUsedSlots(bagId)
	local usedSlots = 0
	local totalSlots = GetContainerNumSlots(bagId)

	if totalSlots ~= 0 then
		for slot = 1, totalSlots do
			if GetContainerItemInfo(bagId, slot) then usedSlots = usedSlots + 1 end
		end

		return usedSlots
	else
		return 0 --nil
	end
end

-- returns total number of bag slots in inventory
function ContainerFu:CountInventoryBagsSlots()
	local slots = 0

	for bagId = 0, 4 do
		slots = slots + GetContainerNumSlots(bagId)
	end

	return slots
end

-- returns number of used slots in inventory bags
function ContainerFu:CountInventoryBagsUsedSlots()
	local uslots = 0

	for bagId = 0, 4 do
		uslots = uslots + self:GetContainerUsedSlots(bagId)
	end

	return uslots
end


function ContainerFu:CountBankSlots()
	local slots = 0
	local bankslots = {5, 6, 7, 8, 9, 10, 11}

	for i, v in ipairs(bankslots) do
		slots = slots + assert(loadstring("return ContainerFu.db.char.bank.b" .. v .. ".tslots"))()
	end

	slots = slots + ContainerFu.db.char.bank.tslots

	return slots
end

function ContainerFu:CountBankUsedSlots()
	local uslots = 0;
	local bankslots = {5, 6, 7, 8, 9, 10, 11}

	for i,v in ipairs(bankslots) do
		uslots = uslots + assert(loadstring("return ContainerFu.db.char.bank.b" .. v .. ".uslots"))()
	end

	uslots = uslots + ContainerFu.db.char.bank.uslots

	return uslots
end

function ContainerFu:DebugMsg(msg)
	if DEBUG == 1 then self:Print("DEBUG: " .. msg) end
end
