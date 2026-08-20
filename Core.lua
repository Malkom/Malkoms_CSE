local addonName, ns = ...

local _G = _G
local pairs, type = pairs, type

ns.addonName = addonName
ns.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
	or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "1.0.0"

--------------------------------------------------------------------------------
-- Localization (default = English key; frFR overrides)
--------------------------------------------------------------------------------

local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

if GetLocale() == "frFR" then
	L["Malkoms Current Set Equipped"] = "Malkoms - Set équipé actuel"
	L["Theme"] = "Thème"
	L["Default"] = "Défaut"
	L["Lock button (disable move/resize)"] = "Verrouiller le bouton (désactive déplacement/redimensionnement)"
	L["Keep aspect ratio"] = "Conserver le ratio"
	L["Width"] = "Largeur"
	L["Height"] = "Hauteur"
	L["Reset position"] = "Réinitialiser la position"
	L["Reset size"] = "Réinitialiser la taille"
	L["No equipment set equipped."] = "Aucun set d'équipement équipé."
	L["Drag to move, drag corner to resize."] = "Glisser pour déplacer, coin pour redimensionner."
	L["Right-click for options."] = "Clic droit pour les options."
	L["Locked"] = "Verrouillé"
	L["Equipped set"] = "Set équipé"
	L["Display"] = "Affichage"
	L["Size"] = "Taille"
	L["Opacity"] = "Opacité"
	L["Frame strata"] = "Niveau d'affichage (strata)"
	L["Show set name"] = "Afficher le nom du set"
	L["Text position"] = "Position du texte"
	L["Top (inside)"] = "Haut (intérieur)"
	L["Bottom (inside)"] = "Bas (intérieur)"
	L["Text offset X"] = "Décalage texte X"
	L["Text offset Y"] = "Décalage texte Y"
	L["Text"] = "Texte"
	L["Font"] = "Police"
	L["Font size"] = "Taille de police"
	L["Outline"] = "Contour"
	L["None"] = "Aucun"
	L["Thick outline"] = "Contour épais"
end

--------------------------------------------------------------------------------
-- SavedVariables / defaults
--------------------------------------------------------------------------------

ns.defaults = {
	point    = "CENTER",
	relPoint = "CENTER",
	x        = 0,
	y        = 0,
	width    = 40,
	height   = 40,
	aspect   = 1,       -- width / height, used when "keep ratio" is on
	locked   = false,
	keepRatio = true,
	theme    = "Default", -- Default | ElvUI | Masque
	opacity  = 1,         -- 0.1 - 1
	strata   = "MEDIUM",  -- frame strata
	showName = true,      -- show the set name on the button
	namePos  = "BOTTOM",  -- TOP | BOTTOM (inside the button)
	nameX    = 0,         -- horizontal text offset
	nameY    = 2,         -- vertical text offset
	nameFont = "Fonts\\FRIZQT__.TTF",
	nameSize = 12,
	nameOutline = "OUTLINE", -- NONE | OUTLINE | THICKOUTLINE
}

local function CopyDefaults(defaults, target)
	if type(target) ~= "table" then target = {} end
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			target[k] = CopyDefaults(v, target[k])
		elseif target[k] == nil then
			target[k] = v
		end
	end
	return target
end

ns.onReady = {}
function ns.OnReady(fn) ns.onReady[#ns.onReady + 1] = fn end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent("ADDON_LOADED")

	_G.MalkomsCSEDB = CopyDefaults(ns.defaults, _G.MalkomsCSEDB)
	ns.db = _G.MalkomsCSEDB

	for _, fn in pairs(ns.onReady) do
		local ok, err = pcall(fn)
		if not ok then
			print("|cffff2020Malkoms CSE|r init error: " .. tostring(err))
		end
	end
end)
