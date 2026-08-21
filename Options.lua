local addonName, ns = ...
local L = ns.L

local _G = _G
local floor = math.floor
local CreateFrame = CreateFrame

local categoryID
local widthRefresh, heightRefresh
local uiGuard = false

--------------------------------------------------------------------------------
-- Optional ElvUI skinning of the option controls
--------------------------------------------------------------------------------

local E = _G.ElvUI and _G.ElvUI[1]
local S = E and E.GetModule and E:GetModule("Skins", true)

local function SkinWidget(kind, widget)
	if not S or not widget then return end
	pcall(function()
		if kind == "button" and S.HandleButton then
			S:HandleButton(widget)
		elseif kind == "check" and S.HandleCheckBox then
			S:HandleCheckBox(widget)
		elseif kind == "slider" and S.HandleSliderFrame then
			S:HandleSliderFrame(widget)
		elseif kind == "scrollbar" and S.HandleScrollBar then
			S:HandleScrollBar(widget)
		end
	end)
end

--------------------------------------------------------------------------------
-- Canvas + widget builders
--------------------------------------------------------------------------------

local function CreateCanvas(displayName)
	local canvas = CreateFrame("Frame")
	canvas.name = displayName

	local scroll = CreateFrame("ScrollFrame", nil, canvas, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 3, -4)
	scroll:SetPoint("BOTTOMRIGHT", -27, 4)

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(560, 1)
	scroll:SetScrollChild(child)
	SkinWidget("scrollbar", scroll.ScrollBar)

	canvas.child = child
	canvas.y = -8

	local title = child:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 4, canvas.y)
	title:SetText("|cff1784d1Malkoms|r |cffffd200Current Set Equipped|r")
	canvas.y = canvas.y - 34
	return canvas
end

local function FinishCanvas(canvas)
	canvas.child:SetHeight(-canvas.y + 20)
end

local function AddHeader(canvas, text)
	canvas.y = canvas.y - 6
	local fs = canvas.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 0, canvas.y)
	fs:SetText("|cffffd200" .. text .. "|r")
	canvas.y = canvas.y - 22
end

local function AddCheckbox(canvas, label, get, set)
	local cb = CreateFrame("CheckButton", nil, canvas.child, "UICheckButtonTemplate")
	cb:SetSize(24, 24) -- match MDB Guild & Friends
	cb:SetPoint("TOPLEFT", 4, canvas.y)
	cb:SetChecked(get() and true or false)
	local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	fs:SetText(label)
	cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	SkinWidget("check", cb)
	canvas.y = canvas.y - 28
	return cb
end

local function AddDropdown(canvas, label, options, get, set)
	canvas.y = canvas.y - 8 -- breathing room above the label
	local fs = canvas.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 4, canvas.y)
	fs:SetText(label)
	canvas.y = canvas.y - 20

	local btn = CreateFrame("Button", nil, canvas.child, "UIPanelButtonTemplate")
	btn:SetSize(220, 22)
	btn:SetPoint("TOPLEFT", 4, canvas.y)

	local function currentText()
		local v = get()
		for _, o in ipairs(options) do if o.value == v then return o.text end end
		return tostring(v)
	end
	btn:SetText(currentText())

	btn:SetScript("OnClick", function()
		if not MenuUtil then return end
		MenuUtil.CreateContextMenu(btn, function(_, root)
			for _, o in ipairs(options) do
				root:CreateRadio(o.text, function() return get() == o.value end, function()
					set(o.value)
					btn:SetText(currentText())
					return MenuResponse.Close
				end)
			end
		end)
	end)
	SkinWidget("button", btn)
	canvas.y = canvas.y - 30
	return btn
end

local function AddSlider(canvas, label, minV, maxV, step, get, set)
	canvas.y = canvas.y - 8 -- breathing room above the label
	local fs = canvas.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetPoint("TOPLEFT", 4, canvas.y)
	fs:SetText(label)

	local valfs = canvas.child:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	valfs:SetPoint("LEFT", fs, "RIGHT", 6, 0)
	valfs:SetText(floor(get() + 0.5))
	canvas.y = canvas.y - 20

	local s = CreateFrame("Slider", nil, canvas.child)
	s:SetOrientation("HORIZONTAL")
	s:SetSize(220, 16)
	s:SetPoint("TOPLEFT", 6, canvas.y)
	s:SetMinMaxValues(minV, maxV)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)
	s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

	if not S then
		local track = s:CreateTexture(nil, "BACKGROUND")
		track:SetPoint("LEFT", 0, 0)
		track:SetPoint("RIGHT", 0, 0)
		track:SetHeight(5)
		track:SetColorTexture(0, 0, 0, 0.5)
	end
	SkinWidget("slider", s)

	s:SetValue(get())
	s:SetScript("OnValueChanged", function(_, v)
		v = floor(v + 0.5)
		valfs:SetText(v)
		if uiGuard then return end
		set(v)
	end)

	canvas.y = canvas.y - 28

	local function refresh(v)
		uiGuard = true
		v = floor(v + 0.5)
		s:SetValue(v)
		valfs:SetText(v)
		uiGuard = false
	end
	return s, refresh
end

local function AddButton(canvas, label, onClick)
	local btn = CreateFrame("Button", nil, canvas.child, "UIPanelButtonTemplate")
	btn:SetSize(180, 22)
	btn:SetPoint("TOPLEFT", 4, canvas.y)
	btn:SetText(label)
	btn:SetScript("OnClick", onClick)
	SkinWidget("button", btn)
	canvas.y = canvas.y - 30
	return btn
end

--------------------------------------------------------------------------------
-- Font list (built-in fonts + LibSharedMedia if available)
--------------------------------------------------------------------------------

local function GetFontList()
	local list = {
		{ text = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
		{ text = "Arial Narrow", value = "Fonts\\ARIALN.TTF" },
		{ text = "Skurri", value = "Fonts\\SKURRI.TTF" },
		{ text = "Morpheus", value = "Fonts\\MORPHEUS.TTF" },
		{ text = "2002", value = "Fonts\\2002.TTF" },
	}
	local LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
	if LSM then
		local seen = {}
		for _, e in ipairs(list) do seen[e.value] = true end
		for _, name in ipairs(LSM:List("font")) do
			local path = LSM:Fetch("font", name, true)
			if path and not seen[path] then
				seen[path] = true
				list[#list + 1] = { text = name, value = path }
			end
		end
	end
	return list
end

--------------------------------------------------------------------------------
-- Build panel
--------------------------------------------------------------------------------

ns.OnReady(function()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end

	local canvas = CreateCanvas(L["Malkoms Current Set Equipped"])

	AddHeader(canvas, L["Display"])
	AddDropdown(canvas, L["Theme"], {
		{ text = L["Default"], value = "Default" },
		{ text = "ElvUI", value = "ElvUI" },
		{ text = "Masque", value = "Masque" },
	}, function() return ns.db.theme end, function(v)
		ns.db.theme = v
		if ns.CSE_ApplyTheme then ns.CSE_ApplyTheme() end
	end)

	AddCheckbox(canvas, L["Lock button (disable move/resize)"],
		function() return ns.db.locked end,
		function(v) ns.db.locked = v; if ns.CSE_ApplyLock then ns.CSE_ApplyLock() end end)

	AddDropdown(canvas, L["Frame strata"], {
		{ text = "BACKGROUND", value = "BACKGROUND" },
		{ text = "LOW", value = "LOW" },
		{ text = "MEDIUM", value = "MEDIUM" },
		{ text = "HIGH", value = "HIGH" },
		{ text = "DIALOG", value = "DIALOG" },
		{ text = "TOOLTIP", value = "TOOLTIP" },
	}, function() return ns.db.strata end, function(v)
		ns.db.strata = v
		if ns.CSE_ApplyStrata then ns.CSE_ApplyStrata() end
	end)

	AddSlider(canvas, L["Opacity"], 10, 100, 5,
		function() return (ns.db.opacity or 1) * 100 end,
		function(v)
			ns.db.opacity = v / 100
			if ns.CSE_ApplyOpacity then ns.CSE_ApplyOpacity() end
		end)

	-- Visibility section
	AddHeader(canvas, L["Visibility"])
	AddCheckbox(canvas, L["Open World"],
		function() return ns.db.visibility.world end,
		function(v) ns.db.visibility.world = v; if ns.CSE_ApplyVisibility then ns.CSE_ApplyVisibility() end end)
	AddCheckbox(canvas, L["Dungeons (incl. Delves)"],
		function() return ns.db.visibility.dungeon end,
		function(v) ns.db.visibility.dungeon = v; if ns.CSE_ApplyVisibility then ns.CSE_ApplyVisibility() end end)
	AddCheckbox(canvas, L["Raids"],
		function() return ns.db.visibility.raid end,
		function(v) ns.db.visibility.raid = v; if ns.CSE_ApplyVisibility then ns.CSE_ApplyVisibility() end end)

	-- Text section
	AddHeader(canvas, L["Text"])
	AddCheckbox(canvas, L["Show set name"],
		function() return ns.db.showName end,
		function(v) ns.db.showName = v; if ns.CSE_ApplyName then ns.CSE_ApplyName() end end)

	AddDropdown(canvas, L["Text position"], {
		{ text = L["Bottom (inside)"], value = "BOTTOM" },
		{ text = L["Top (inside)"], value = "TOP" },
	}, function() return ns.db.namePos end, function(v)
		ns.db.namePos = v
		if ns.CSE_ApplyNamePos then ns.CSE_ApplyNamePos() end
	end)

	AddSlider(canvas, L["Text offset X"], -60, 60, 1,
		function() return ns.db.nameX end,
		function(v) ns.db.nameX = v; if ns.CSE_ApplyNamePos then ns.CSE_ApplyNamePos() end end)

	AddSlider(canvas, L["Text offset Y"], -60, 60, 1,
		function() return ns.db.nameY end,
		function(v) ns.db.nameY = v; if ns.CSE_ApplyNamePos then ns.CSE_ApplyNamePos() end end)

	AddDropdown(canvas, L["Font"], GetFontList(),
		function() return ns.db.nameFont end, function(v)
			ns.db.nameFont = v
			if ns.CSE_ApplyNameFont then ns.CSE_ApplyNameFont() end
		end)

	AddSlider(canvas, L["Font size"], 6, 24, 1,
		function() return ns.db.nameSize end,
		function(v) ns.db.nameSize = v; if ns.CSE_ApplyNameFont then ns.CSE_ApplyNameFont() end end)

	AddDropdown(canvas, L["Outline"], {
		{ text = L["None"], value = "NONE" },
		{ text = L["Outline"], value = "OUTLINE" },
		{ text = L["Thick outline"], value = "THICKOUTLINE" },
	}, function() return ns.db.nameOutline end, function(v)
		ns.db.nameOutline = v
		if ns.CSE_ApplyNameFont then ns.CSE_ApplyNameFont() end
	end)

	AddHeader(canvas, L["Size"])
	AddCheckbox(canvas, L["Keep aspect ratio"],
		function() return ns.db.keepRatio end,
		function(v)
			if ns.CSE_SetKeepRatio then ns.CSE_SetKeepRatio(v) end
			if ns.CSE_RefreshSizeControls then ns.CSE_RefreshSizeControls() end
		end)

	local _, wRefresh = AddSlider(canvas, L["Width"], 16, 128, 1,
		function() return ns.db.width end,
		function(v)
			if ns.CSE_SetWidth then ns.CSE_SetWidth(v) end
			if ns.CSE_RefreshSizeControls then ns.CSE_RefreshSizeControls() end
		end)

	local _, hRefresh = AddSlider(canvas, L["Height"], 16, 128, 1,
		function() return ns.db.height end,
		function(v)
			if ns.CSE_SetHeight then ns.CSE_SetHeight(v) end
			if ns.CSE_RefreshSizeControls then ns.CSE_RefreshSizeControls() end
		end)

	widthRefresh, heightRefresh = wRefresh, hRefresh

	AddButton(canvas, L["Reset size"], function()
		if ns.CSE_ResetSize then ns.CSE_ResetSize() end
		if ns.CSE_RefreshSizeControls then ns.CSE_RefreshSizeControls() end
	end)
	AddButton(canvas, L["Reset position"], function()
		if ns.CSE_ResetPosition then ns.CSE_ResetPosition() end
	end)

	FinishCanvas(canvas)

	local category = Settings.RegisterCanvasLayoutCategory(canvas, "Malkoms CSE")
	Settings.RegisterAddOnCategory(category)
	categoryID = category:GetID()
end)

function ns.CSE_RefreshSizeControls()
	if widthRefresh and heightRefresh and ns.CSE_GetSize then
		local w, h = ns.CSE_GetSize()
		widthRefresh(w)
		heightRefresh(h)
	end
end

function ns.OpenOptions()
	if Settings and Settings.OpenToCategory and categoryID then
		Settings.OpenToCategory(categoryID)
	end
end

--------------------------------------------------------------------------------
-- Slash
--------------------------------------------------------------------------------

_G.SLASH_MALKOMSCSE1 = "/mcse"
_G.SLASH_MALKOMSCSE2 = "/malkomscse"
SlashCmdList["MALKOMSCSE"] = function() ns.OpenOptions() end
