local addonName, ns = ...
local L = ns.L

local _G = _G
local ipairs, unpack = ipairs, unpack
local floor, max, min = math.floor, math.max, math.min
local CreateFrame = CreateFrame
local C_EquipmentSet = C_EquipmentSet

local MIN_SIZE, MAX_SIZE = 16, 256
local QUESTION_ICON = 134400 -- Interface\\Icons\\INV_Misc_QuestionMark

local DEFAULT_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Buttons\\WHITE8x8",
	edgeSize = 1,
}

local db
local f, grip
local sizingGuard = false
local masqueGroup
local E -- ElvUI engine, if present

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function clampSize(v)
	return max(MIN_SIZE, min(MAX_SIZE, v or MIN_SIZE))
end

local function GetEquippedSet()
	local ids = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs()
	if ids then
		for _, id in ipairs(ids) do
			local name, icon, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
			if isEquipped then
				return name, icon
			end
		end
	end
end

local function ApplyPosition()
	f:ClearAllPoints()
	f:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

local function SavePosition()
	local point, _, relPoint, x, y = f:GetPoint()
	db.point, db.relPoint = point, relPoint
	db.x, db.y = floor(x + 0.5), floor(y + 0.5)
end

local function ApplySizeToFrame()
	sizingGuard = true
	f:SetSize(db.width, db.height)
	sizingGuard = false
end

local function SaveSizeFromFrame()
	db.width = floor(f:GetWidth() + 0.5)
	db.height = floor(f:GetHeight() + 0.5)
	if not db.keepRatio and db.height > 0 then
		db.aspect = db.width / db.height
	end
end

--------------------------------------------------------------------------------
-- Theme
--------------------------------------------------------------------------------

-- Fully resets every skin layer so themes can be swapped live without residue.
local function ApplyTheme()
	-- 1) tear down any previous skin
	if masqueGroup then pcall(function() masqueGroup:RemoveButton(f) end) end
	if f.SetBackdrop then f:SetBackdrop(nil) end
	f.icon:SetTexCoord(0, 1, 0, 1)
	f.icon:ClearAllPoints()

	local theme = db.theme

	-- 2) Masque: let the user's skin own the button
	if theme == "Masque" and masqueGroup then
		f.icon:SetPoint("TOPLEFT", 1, -1)
		f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
		masqueGroup:AddButton(f, { Icon = f.icon }, "Legacy", true)
		return
	end

	-- 3) ElvUI look — emulated with our own backdrop using ElvUI's colors/crop,
	--    so switching away leaves nothing behind (no SetTemplate side effects).
	if theme == "ElvUI" and E then
		local bc = (E.media and E.media.bordercolor) or { 0, 0, 0 }
		local bgc = (E.media and E.media.backdropcolor) or { 0.06, 0.06, 0.06 }
		if f.SetBackdrop then
			f:SetBackdrop(DEFAULT_BACKDROP)
			f:SetBackdropColor(bgc[1], bgc[2], bgc[3], bgc[4] or 1)
			f:SetBackdropBorderColor(bc[1], bc[2], bc[3], bc[4] or 1)
		end
		f.icon:SetTexCoord(unpack(E.TexCoords or { 0.08, 0.92, 0.08, 0.92 }))
		f.icon:SetPoint("TOPLEFT", 2, -2)
		f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		return
	end

	-- 4) Default
	if f.SetBackdrop then
		f:SetBackdrop(DEFAULT_BACKDROP)
		f:SetBackdropColor(0, 0, 0, 0.6)
		f:SetBackdropBorderColor(0, 0, 0, 1)
	end
	f.icon:SetPoint("TOPLEFT", 2, -2)
	f.icon:SetPoint("BOTTOMRIGHT", -2, 2)
end
ns.CSE_ApplyTheme = ApplyTheme

function ns.CSE_ApplyOpacity()
	if f then f:SetAlpha(db.opacity or 1) end
end

local VALID_STRATA = {
	BACKGROUND = true, LOW = true, MEDIUM = true, HIGH = true,
	DIALOG = true, FULLSCREEN = true, FULLSCREEN_DIALOG = true, TOOLTIP = true,
}
function ns.CSE_ApplyStrata()
	if f and VALID_STRATA[db.strata] then f:SetFrameStrata(db.strata) end
end

--------------------------------------------------------------------------------
-- Size / lock (public, used by options)
--------------------------------------------------------------------------------

function ns.CSE_SetWidth(w)
	w = clampSize(w)
	db.width = floor(w + 0.5)
	if db.keepRatio and db.aspect and db.aspect > 0 then
		db.height = clampSize(db.width / db.aspect)
	end
	ApplySizeToFrame()
end

function ns.CSE_SetHeight(h)
	h = clampSize(h)
	db.height = floor(h + 0.5)
	if db.keepRatio and db.aspect and db.aspect > 0 then
		db.width = clampSize(db.height * db.aspect)
	end
	ApplySizeToFrame()
end

function ns.CSE_SetKeepRatio(v)
	db.keepRatio = v and true or false
	if db.keepRatio and db.height > 0 then
		db.aspect = db.width / db.height
	end
end

function ns.CSE_GetSize()
	return db.width, db.height
end

function ns.CSE_ApplyLock()
	-- Moving is gated by db.locked inside OnMouseDown; here we just show/hide the grip.
	if grip then grip:SetShown(not db.locked) end
end

function ns.CSE_ResetPosition()
	db.point, db.relPoint, db.x, db.y = "CENTER", "CENTER", 0, 0
	ApplyPosition()
end

function ns.CSE_ResetSize()
	db.width, db.height, db.aspect = 40, 40, 1
	ApplySizeToFrame()
end

--------------------------------------------------------------------------------
-- Content refresh
--------------------------------------------------------------------------------

function ns.CSE_ApplyNamePos()
	if not f or not f.label then return end
	f.label:ClearAllPoints()
	f.label:SetWidth(0)
	local x, y = db.nameX or 0, db.nameY or 0
	if db.namePos == "TOP" then
		f.label:SetPoint("TOP", f, "TOP", x, y)
	else
		f.label:SetPoint("BOTTOM", f, "BOTTOM", x, y)
	end
end

function ns.CSE_ApplyNameFont()
	if not f or not f.label then return end
	local path = db.nameFont or STANDARD_TEXT_FONT
	local size = db.nameSize or 12
	local outline = db.nameOutline
	if outline == "NONE" or not outline then outline = "" end
	local ok = f.label:SetFont(path, size, outline)
	if not ok then
		f.label:SetFont(STANDARD_TEXT_FONT, size, outline)
	end
end

function ns.CSE_ApplyName()
	if not f or not f.label then return end
	if db.showName and f.setName then
		f.label:SetText(f.setName)
		ns.CSE_ApplyNamePos()
		f.label:Show()
	else
		f.label:Hide()
	end
end

-- Map the current instance type to one of our visibility buckets.
-- Delves report as "scenario", so they fall under the Dungeons toggle (as requested).
local VIS_MAP = { none = "world", party = "dungeon", scenario = "dungeon", raid = "raid" }
local function VisibilityAllows()
	local _, instanceType = GetInstanceInfo()
	local bucket = VIS_MAP[instanceType]
	if not bucket then return true end -- pvp/arena/other: don't hide
	return db.visibility and db.visibility[bucket] ~= false
end

local function UpdateShown()
	if not f then return end
	if f.setName and VisibilityAllows() then
		f:Show()
	else
		f:Hide()
	end
end
ns.CSE_ApplyVisibility = UpdateShown

local function Refresh()
	local name, icon = GetEquippedSet()
	if name then
		f.setName = name
		f.icon:SetTexture(icon or QUESTION_ICON)
		ns.CSE_ApplyName()
	else
		f.setName = nil
		if f.label then f.label:Hide() end
	end
	UpdateShown()
end
ns.CSE_Refresh = Refresh

--------------------------------------------------------------------------------
-- Build
--------------------------------------------------------------------------------

local UPDATE_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"EQUIPMENT_SETS_CHANGED",
	"EQUIPMENT_SWAP_FINISHED",
	"PLAYER_EQUIPMENT_CHANGED",
	"ACTIVE_TALENT_GROUP_CHANGED",
	"WEAR_EQUIPMENT_SET",
	"ZONE_CHANGED_NEW_AREA",
}

ns.OnReady(function()
	db = ns.db

	if _G.ElvUI then E = _G.ElvUI[1] end
	if _G.LibStub then masqueGroup = _G.LibStub("Masque", true) and _G.LibStub("Masque"):Group("Malkoms CSE", "Set Icon") end

	f = CreateFrame("Button", "MalkomsCSEButton", UIParent, "BackdropTemplate")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:SetResizable(true)
	if f.SetResizeBounds then f:SetResizeBounds(MIN_SIZE, MIN_SIZE, MAX_SIZE, MAX_SIZE) end
	f:EnableMouse(true)

	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetPoint("TOPLEFT", 2, -2)
	f.icon:SetPoint("BOTTOMRIGHT", -2, 2)

	-- Set name label (on the button)
	f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.label:SetJustifyH("CENTER")
	f.label:Hide()

	-- Resize grip (bottom-right)
	grip = CreateFrame("Button", nil, f)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", 0, 0)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetFrameLevel(f:GetFrameLevel() + 5)
	grip:SetScript("OnMouseDown", function()
		if not db.locked then f:StartSizing("BOTTOMRIGHT") end
	end)
	grip:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		SaveSizeFromFrame()
		if ns.CSE_RefreshSizeControls then ns.CSE_RefreshSizeControls() end
	end)

	local function stopMoving(self)
		if self.isMoving then
			self:StopMovingOrSizing()
			self.isMoving = false
			SavePosition()
		end
	end

	-- Dedicated watcher frame: its OnUpdate can't be clobbered by the theme
	-- skinning the button (e.g. Masque). It guarantees the move stops as soon as
	-- the left mouse button is released, even if the cursor outran the frame and
	-- the mouse-up landed somewhere else.
	local mover = CreateFrame("Frame")
	mover:Hide()
	mover:SetScript("OnUpdate", function(self)
		if not f.isMoving or not IsMouseButtonDown("LeftButton") then
			stopMoving(f)
			self:Hide()
		end
	end)

	f:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not db.locked then
			self:StartMoving()
			self.isMoving = true
			mover:Show()
		end
	end)
	f:SetScript("OnMouseUp", function(self, button)
		stopMoving(self)
		mover:Hide()
		if button == "RightButton" then
			ns.OpenOptions()
		end
	end)
	f:SetScript("OnHide", function(self) stopMoving(self); mover:Hide() end)

	f:SetScript("OnSizeChanged", function(self, w)
		if sizingGuard then return end
		if db.keepRatio and db.aspect and db.aspect > 0 then
			sizingGuard = true
			self:SetHeight(w / db.aspect)
			sizingGuard = false
		end
	end)

	f:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.setName then
			GameTooltip:SetText("|cff1784d1Malkoms|r  " .. L["Equipped set"] .. ": |cffffffff" .. self.setName .. "|r")
		else
			GameTooltip:SetText(L["No equipment set equipped."])
		end
		if not db.locked then
			GameTooltip:AddLine(L["Drag to move, drag corner to resize."], 0.8, 0.8, 0.8)
		end
		GameTooltip:AddLine(L["Right-click for options."], 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)

	ns.CSE_button = f

	-- Apply saved state
	ApplyPosition()
	ApplySizeToFrame()
	ns.CSE_ApplyStrata()
	ns.CSE_ApplyOpacity()
	ns.CSE_ApplyNameFont()
	ApplyTheme()
	ns.CSE_ApplyLock()

	-- Events
	local ev = CreateFrame("Frame")
	for _, e in ipairs(UPDATE_EVENTS) do
		pcall(function() ev:RegisterEvent(e) end)
	end
	ev:SetScript("OnEvent", function() Refresh() end)

	Refresh()
end)
