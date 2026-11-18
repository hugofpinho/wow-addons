-- Buscador de equipo 1.2 (2026-11-18; 1.1: va por encima de GearQuest, fondo opaco, la lista ya no pisa el nivel;
-- 1.2: la ficha se desplaza con la rueda o su barra, con todas las fuentes, y el puesto de GearQuest se mira en el hueco del objeto)
--
-- Una ventana con dos usos:
--  1. Buscar un objeto por su nombre (en español o en inglés). Al elegirlo dice cómo se
--     consigue: botín de qué bicho y con qué porcentaje, misión, vendedor y precio,
--     fabricación, botín del mundo… y qué nivel pide. Los datos son los del buscador de
--     Polestar (Polestar.Search, Polestar.Lookup.Sources, Polestar Codex); «Ver en Polestar»
--     abre su ficha, que además te lleva hasta allí.
--  2. «Mejores»: con los filtros de clase (por defecto la tuya), especialización (por
--     defecto la que usa GearQuest, que para el brujo es «Leveo Aflicción» de
--     GearQuestLeveo), hueco y nivel enseña los mejores objetos de GearQuest para ese
--     nivel, en su orden. Para tu clase usa las listas que GearQuest ya tiene puntuadas
--     (también la especialización personalizada); para otra clase lee sus datos
--     (GearQuestForever_<CLASE>) con la especialización de GearQuest elegida.
-- Al pasar el ratón por una fila sale el tooltip del objeto; al pulsarla, cómo se consigue
-- y su puesto en GearQuest para el nivel del filtro.
--
-- Se abre con el botón «Buscador» (se puede arrastrar) o con su atajo (Opciones > Atajos >
-- AddOns). Solo lee datos de Polestar y GearQuest y crea marcos propios.

local issecret = issecretvalue or function() return false end
local function ok(v)
	if v == nil or issecret(v) then return nil end
	return v
end
local function pass(success, ...)
	if not success then return nil end
	return ...
end
local function call(fn, ...)
	if type(fn) ~= "function" then return nil end
	return pass(pcall(fn, ...))
end

local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local ROWS, ROW_H = 13, 22
local W, H = 640, 520

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local CLASS_ES = { WARRIOR = "Guerrero", PALADIN = "Paladín", HUNTER = "Cazador", ROGUE = "Pícaro", PRIEST = "Sacerdote",
	SHAMAN = "Chamán", MAGE = "Mago", WARLOCK = "Brujo", DRUID = "Druida" }
local SLOTS = { "Ranged", "MainHand", "SecondaryHand", "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands",
	"Waist", "Legs", "Feet", "Finger", "Trinket" }
local SLOT_ES = { Head = "Cabeza", Neck = "Cuello", Shoulder = "Hombros", Back = "Espalda", Chest = "Pecho",
	Wrist = "Muñecas", Hands = "Manos", Waist = "Cintura", Legs = "Piernas", Feet = "Pies", Finger = "Anillo",
	Trinket = "Abalorio", MainHand = "Arma (o bastón)", SecondaryHand = "Mano izquierda", Ranged = "A distancia (varita)" }
local SPEC_ES = {
	affliction = "Aflicción", demonology = "Demonología", destruction = "Destrucción",
	arcane = "Arcano", fire = "Fuego", frost = "Escarcha", holy = "Sagrado", discipline = "Disciplina",
	shadow = "Sombras", protection = "Protección", retribution = "Reprensión", arms = "Armas", fury = "Furia",
	assassination = "Asesinato", combat = "Combate", subtlety = "Sutileza", beast_mastery = "Bestias",
	marksmanship = "Puntería", survival = "Supervivencia", elemental = "Elemental", enhancement = "Mejora",
	restoration = "Restauración", balance = "Equilibrio", feral = "Feral",
}
local SOURCE_ES = { drop = "Botín", vendor = "Vendedor", quest = "Misión", craft = "Fabricación", world = "Botín del mundo",
	object = "Objeto", treasure = "Tesoro", container = "Contenedor", rep = "Reputación", pvp = "JcJ", gift = "Lo da un PNJ" }

local _, PLAYER_CLASS = UnitClass("player")
local state = {
	mode = "search", -- "search" | "best"
	query = "",
	list = {}, -- filas: { id, name, quality, right }
	offset = 0,
	selected = nil,
	class = PLAYER_CLASS,
	spec = nil,
	slot = "Ranged",
	level = nil,
	message = nil,
}

---------------------------------------------------------------------------
-- Datos: nombres, Polestar, GearQuest
---------------------------------------------------------------------------

local function P() return _G.Polestar end
local function GQ() return _G.GearQuest end

local function itemName(id, fallback)
	local n = C_Item and ok(call(C_Item.GetItemNameByID, id))
	if n then return n end
	local p = P()
	n = p and p.Search and ok(call(p.Search.LocalName, "item", id))
	if n then return n end
	n = p and p.Codex and ok(call(p.Codex.Name, "item", id))
	return n or fallback or ("Objeto " .. id)
end

local function itemQuality(id, fallback)
	return (C_Item and ok(call(C_Item.GetItemQualityByID, id))) or fallback
end

local function qualityHex(q)
	local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if c and c.hex then return c.hex end
	if c and c.r then return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255) end
	return "|cffffffff"
end

local function num(v, decimals)
	local s = string.format("%." .. (decimals or 1) .. "f", v)
	s = s:gsub("%.?0+$", "")
	return (s:gsub("%.", ","))
end

local function money(c)
	c = tonumber(c)
	if not c or c <= 0 then return nil end
	local g, s, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
	local out = {}
	if g > 0 then out[#out + 1] = g .. " o" end
	if s > 0 then out[#out + 1] = s .. " p" end
	if k > 0 and g == 0 then out[#out + 1] = k .. " c" end
	return table.concat(out, " ")
end

local function faction()
	return ok((UnitFactionGroup("player"))) or "Alliance"
end

-- Especializaciones de GearQuest para una clase: las suyas y las personalizadas.
local function specOptions(class)
	local gq, out = GQ(), {}
	if not (gq and gq.Spec and gq.Spec.GetOptions) then return out end
	for _, opt in ipairs(call(gq.Spec.GetOptions, gq.Spec, class) or {}) do
		local selectable = not gq.Spec.IsSpecSelectable or call(gq.Spec.IsSpecSelectable, gq.Spec, opt.id, class)
		if selectable then out[#out + 1] = { id = opt.id, label = SPEC_ES[opt.id] or opt.label or opt.id } end
	end
	if gq.Custom and gq.Custom.List then
		for _, rec in ipairs(call(gq.Custom.List, gq.Custom, class) or {}) do
			out[#out + 1] = { id = rec.id, label = rec.name or rec.id, base = rec.base, custom = true }
		end
	end
	return out
end

local function defaultSpec(class)
	local gq = GQ()
	if not (gq and gq.Spec) then return nil end
	if class == PLAYER_CLASS and gq.Spec.GetDisplaySpec then
		local s = call(gq.Spec.GetDisplaySpec, gq.Spec, class)
		if s then return s end
	end
	return gq.Spec.GetDefaultSpec and call(gq.Spec.GetDefaultSpec, gq.Spec, class)
end

local function specLabel(class, id)
	for _, o in ipairs(specOptions(class)) do
		if o.id == id then return o.label end
	end
	return id and (SPEC_ES[id] or id) or "—"
end

-- Filas «itemId hueco nivelMin nivelMax puesto spec nota extra» de los datos de una clase.
local packedCache = {}
local function packedRows(class, fac)
	local key = class .. "|" .. fac
	if packedCache[key] then return packedCache[key] end
	local gq = GQ()
	local data = gq and gq.Data
	local name = string.lower(class) .. "PicksPacked"
	if data and not data[name] and not InCombatLockdown() then
		local addon = "GearQuestForever_" .. class
		if C_AddOns and C_AddOns.LoadAddOn then call(C_AddOns.LoadAddOn, addon) elseif LoadAddOn then call(LoadAddOn, addon) end
	end
	local packed = data and data[name]
	if type(packed) ~= "table" then return nil end
	local blob = packed.rows and packed.rows[fac]
	if type(blob) ~= "string" then return nil end
	local rows = {}
	for line in blob:gmatch("[^\n]+") do
		local id, si, lo, hi, rank, spi, score = line:match("^(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) ([%d%.%-]+)")
		if id then
			rows[#rows + 1] = { id = tonumber(id), slot = packed.slots[tonumber(si)], minLevel = tonumber(lo),
				maxLevel = tonumber(hi), rank = tonumber(rank), spec = packed.specs[tonumber(spi)], score = tonumber(score) }
		end
	end
	local facts = data[string.lower(class) .. "ItemFacts"]
	packedCache[key] = { rows = rows, facts = type(facts) == "table" and facts or {} }
	return packedCache[key]
end

local function inBand(e, level)
	return (e.minLevel or 1) <= level and level <= (e.maxLevel or e.minLevel or 60)
end

-- Los mejores de GearQuest. Devuelve la lista ordenada y, si hay que esperar, un texto.
local function bestFor(class, spec, slot, level)
	local gq = GQ()
	if not (gq and gq.Data) then return {}, "GearQuest no está cargado." end
	local fac = faction()
	local out, seen = {}, {}
	local function add(id, rank, score, name, quality)
		if not id or seen[id] then return end
		seen[id] = true
		out[#out + 1] = { id = id, rank = rank, score = score, name = name, quality = quality }
	end
	-- Tu clase: las listas que GearQuest tiene puntuadas (también la personalizada).
	if class == PLAYER_CLASS and gq.Data.byClassSlotSpec then
		local custom = type(spec) == "string" and spec:match("^c:")
		if custom and gq.Custom and gq.Custom.EnsureBuilt then
			local built = call(gq.Custom.EnsureBuilt, gq.Custom, class, spec)
			if not built and gq.Custom.SpecIsIndexed and not call(gq.Custom.SpecIsIndexed, gq.Custom, class, spec) then
				return {}, "GearQuest está puntuando esta especialización; espera unos segundos."
			end
		end
		local map = gq.Data.byClassSlotSpec[class] and gq.Data.byClassSlotSpec[class][slot]
		if map then
			local cands = {}
			for _, list in ipairs({ map[spec] or {}, map._any or {} }) do
				for _, e in ipairs(list) do
					local facOk = not e.factions or e.factions[fac]
					if inBand(e, level) and facOk then cands[#cands + 1] = e end
				end
			end
			table.sort(cands, function(a, b)
				local ra, rb = a.rank or 999, b.rank or 999
				if ra ~= rb then return ra < rb end
				return (a.pipelineScore or 0) > (b.pipelineScore or 0)
			end)
			for _, e in ipairs(cands) do add(e.itemId, e.rank, e.pipelineScore, e.name, e.quality) end
			if #out > 0 then return out end
		end
	end
	-- Otra clase (o no hay lista hecha): los datos de la clase, con la especialización
	-- de GearQuest (una personalizada se lee con su base).
	local base = spec
	if type(spec) == "string" and spec:match("^c:") and gq.Custom and gq.Custom.Get then
		local rec = call(gq.Custom.Get, gq.Custom, class, spec)
		base = rec and rec.base or base
	end
	local data = packedRows(class, fac)
	if not data then return {}, "No hay datos de GearQuest para esta clase." end
	local cands = {}
	for _, r in ipairs(data.rows) do
		if r.slot == slot and r.spec == base and inBand(r, level) then cands[#cands + 1] = r end
	end
	table.sort(cands, function(a, b)
		if a.rank ~= b.rank then return a.rank < b.rank end
		return (a.score or 0) > (b.score or 0)
	end)
	for _, r in ipairs(cands) do
		local f = data.facts[r.id] or {}
		add(r.id, r.rank, r.score, f.name, f.quality)
	end
	if base ~= spec then
		return out, "Para otra clase se usan los pesos de GearQuest de «" .. (SPEC_ES[base] or base) .. "»."
	end
	return out
end

-- Puesto del objeto en la lista del filtro, y si no está a ese nivel, en qué niveles sí.
-- Hueco de GearQuest de un objeto, por dónde se equipa.
local EQUIP_TO_SLOT = {
	INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder", INVTYPE_CLOAK = "Back",
	INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest", INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands",
	INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet", INVTYPE_FINGER = "Finger",
	INVTYPE_TRINKET = "Trinket", INVTYPE_2HWEAPON = "MainHand", INVTYPE_WEAPON = "MainHand",
	INVTYPE_WEAPONMAINHAND = "MainHand", INVTYPE_HOLDABLE = "SecondaryHand", INVTYPE_WEAPONOFFHAND = "SecondaryHand",
	INVTYPE_SHIELD = "SecondaryHand", INVTYPE_RANGED = "Ranged", INVTYPE_RANGEDRIGHT = "Ranged",
	INVTYPE_THROWN = "Ranged", INVTYPE_RELIC = "Ranged",
}
local function slotOfItem(id)
	local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	local equipLoc = getInstant and ok(select(4, call(getInstant, id)))
	return equipLoc and EQUIP_TO_SLOT[equipLoc]
end

-- Puesto en GearQuest en el hueco del propio objeto (un bastón se mira entre las armas
-- aunque el filtro diga «A distancia»). Devuelve puesto, nota y hueco mirado.
local function gqPlace(id)
	local slot = slotOfItem(id) or state.slot
	local list = bestFor(state.class, state.spec, slot, state.level)
	for i, e in ipairs(list) do
		if e.id == id then return i, e.score, slot end
	end
	return nil, nil, slot
end

-- Cómo se consigue, con los datos de Polestar.
local function sourcesOf(id)
	local p = P()
	if not (p and p.Lookup and p.Lookup.Sources) then return nil, "Polestar no está cargado." end
	local list = call(p.Lookup.Sources, "item", id, true)
	if type(list) ~= "table" then return nil, "Polestar no ha podido leer sus datos (¿en combate?)." end
	return list
end

local function requiredLevel(id)
	local info = C_Item and { call(C_Item.GetItemInfo, id) }
	local lvl = info and ok(info[5])
	if lvl then return lvl, ok(info[4]), ok(info[9]) end
	local p = P()
	local rec = p and p.Codex and p.Codex.Item and call(p.Codex.Item, id)
	return rec and rec.reqLevel, nil, nil
end

---------------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------------

local frame = CreateFrame("Frame", "BuscadorEquipoFrame", UIParent)
frame:SetSize(W, H)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
-- Por encima de la ventana de GearQuest (DIALOG, nivel 100), que si no se veía a través.
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local function box(parent, r, g, b, a, layer)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	t:SetColorTexture(r, g, b, a)
	return t
end
local function border(parent, r, g, b, a)
	for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", "H" }, { "BOTTOMLEFT", "BOTTOMRIGHT", "H" }, { "TOPLEFT", "BOTTOMLEFT", "V" }, { "TOPRIGHT", "BOTTOMRIGHT", "V" } }) do
		local t = box(parent, r, g, b, a, "BORDER")
		t:SetPoint(side[1]); t:SetPoint(side[2])
		if side[3] == "H" then t:SetHeight(1) else t:SetWidth(1) end
	end
end
local function text(parent, size, r, g, b)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(FONT, size, "")
	fs:SetTextColor(r or 1, g or 1, b or 1)
	fs:SetJustifyH("LEFT")
	return fs
end
local function button(parent, label, w, h)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, h or 22)
	b:SetText(label)
	return b
end

box(frame, 0.04, 0.04, 0.06, 1):SetAllPoints()
border(frame, 0.75, 0.6, 0.2, 1)

local title = text(frame, 15, 1, 0.82, 0)
title:SetPoint("TOPLEFT", 12, -10)
title:SetText("Buscador de equipo")
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)
close:SetScript("OnClick", function() frame:Hide() end)

-- Caja de búsqueda
local search = CreateFrame("EditBox", nil, frame)
search:SetSize(270, 22)
search:SetPoint("TOPLEFT", 12, -34)
search:SetFont(FONT, 13, "")
search:SetTextColor(1, 1, 1)
search:SetAutoFocus(false)
search:SetTextInsets(6, 6, 0, 0)
box(search, 0, 0, 0, 0.7):SetAllPoints()
border(search, 0.5, 0.5, 0.5, 1)
local hint = text(search, 12, 0.5, 0.5, 0.5)
hint:SetPoint("LEFT", 7, 0)
hint:SetText("Escribe el nombre de un objeto…")

-- Filtros
local function cycler(labelText, x, y, width)
	local lab = text(frame, 12, 0.85, 0.85, 0.85)
	lab:SetPoint("TOPLEFT", x, y)
	lab:SetText(labelText)
	local prev = button(frame, "<", 22)
	prev:SetPoint("TOPLEFT", x + 74, y + 4)
	local val = text(frame, 12)
	val:SetPoint("LEFT", prev, "RIGHT", 4, 0)
	val:SetWidth(width)
	val:SetJustifyH("CENTER")
	val:SetWordWrap(false)
	local nxt = button(frame, ">", 22)
	nxt:SetPoint("LEFT", val, "RIGHT", 4, 0)
	return prev, val, nxt
end
local classPrev, classVal, classNext = cycler("Clase:", 300, -38, 96)
local specPrev, specVal, specNext = cycler("Especializ.:", 300, -64, 150)
local slotPrev, slotVal, slotNext = cycler("Hueco:", 12, -64, 128)

local lvlLab = text(frame, 12, 0.85, 0.85, 0.85)
lvlLab:SetPoint("TOPLEFT", 12, -90)
lvlLab:SetText("Nivel máx.:")
local lvlMinus = button(frame, "-", 22)
lvlMinus:SetPoint("TOPLEFT", 86, -86)
local lvlVal = text(frame, 13)
lvlVal:SetPoint("LEFT", lvlMinus, "RIGHT", 4, 0)
lvlVal:SetWidth(30)
lvlVal:SetJustifyH("CENTER")
local lvlPlus = button(frame, "+", 22)
lvlPlus:SetPoint("LEFT", lvlVal, "RIGHT", 4, 0)
local bestBtn = button(frame, "Mejores de GearQuest", 170, 22)
bestBtn:SetPoint("LEFT", lvlPlus, "RIGHT", 12, 0)

-- Lista
local listArea = CreateFrame("Frame", nil, frame)
listArea:SetPoint("TOPLEFT", 8, -136)
listArea:SetSize(300, ROWS * ROW_H + 4)
box(listArea, 0, 0, 0, 0.45):SetAllPoints()
border(listArea, 0.35, 0.35, 0.35, 1)
listArea:EnableMouseWheel(true)
local listTitle = text(frame, 11, 0.7, 0.7, 0.7)
listTitle:SetPoint("BOTTOMLEFT", listArea, "TOPLEFT", 2, 3)
local more = text(frame, 11, 0.6, 0.6, 0.6)
more:SetPoint("TOPLEFT", listArea, "BOTTOMLEFT", 2, -3)

-- Ficha
local detail = CreateFrame("Frame", nil, frame)
detail:SetPoint("TOPLEFT", listArea, "TOPRIGHT", 8, 0)
detail:SetPoint("BOTTOMRIGHT", -8, 40)
box(detail, 0, 0, 0, 0.3):SetAllPoints()
border(detail, 0.35, 0.35, 0.35, 1)
-- La ficha se desplaza (rueda del ratón o la barra de la derecha) si no cabe.
local DETAIL_W = W - 8 - 300 - 8 - 8 -- ancho del recuadro
local TEXT_W = DETAIL_W - 8 - 20  -- menos margen y barra
local scroll = CreateFrame("ScrollFrame", nil, detail)
scroll:SetPoint("TOPLEFT", 1, -1)
scroll:SetPoint("BOTTOMRIGHT", -16, 1)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(TEXT_W + 8, 10)
scroll:SetScrollChild(content)
local dTitle = text(content, 14)
dTitle:SetPoint("TOPLEFT", 7, -7)
dTitle:SetWidth(TEXT_W)
dTitle:SetWordWrap(true)
local dBody = text(content, 12, 0.92, 0.92, 0.92)
dBody:SetPoint("TOPLEFT", dTitle, "BOTTOMLEFT", 0, -6)
dBody:SetWidth(TEXT_W)
dBody:SetJustifyV("TOP")
dBody:SetSpacing(2)
local bar = CreateFrame("Slider", nil, detail)
bar:SetPoint("TOPRIGHT", -3, -4)
bar:SetPoint("BOTTOMRIGHT", -3, 4)
bar:SetWidth(10)
bar:SetOrientation("VERTICAL")
bar:SetMinMaxValues(0, 0)
bar:SetValueStep(1)
if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(false) end
box(bar, 1, 1, 1, 0.08):SetAllPoints()
local thumb = bar:CreateTexture(nil, "OVERLAY")
thumb:SetColorTexture(0.75, 0.6, 0.2, 0.9)
thumb:SetSize(10, 40)
bar:SetThumbTexture(thumb)
bar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
local function scrollBy(delta)
	local _, max = bar:GetMinMaxValues()
	local v = math.max(0, math.min(max, bar:GetValue() - delta * 36))
	bar:SetValue(v)
end
detail:EnableMouseWheel(true)
detail:SetScript("OnMouseWheel", function(_, delta) scrollBy(delta) end)
-- Tras cambiar el texto: alto del contenido, tamaño de la barra y vuelta arriba.
local layoutRetry = false
local function layoutDetail()
	if (scroll:GetHeight() or 0) <= 0 and not layoutRetry then
		-- La ventana aún no tiene tamaño (se acaba de abrir): se mira en el fotograma siguiente.
		layoutRetry = true
		C_Timer.After(0, function() layoutRetry = false; layoutDetail() end)
	end
	local h = 7 + (dTitle:GetStringHeight() or 0) + 6 + (dBody:GetStringHeight() or 0) + 10
	content:SetHeight(h)
	local view = scroll:GetHeight() or 0
	local max = math.max(0, h - view)
	bar:SetMinMaxValues(0, max)
	bar:SetValue(0)
	scroll:SetVerticalScroll(0)
	bar:SetShown(max > 0)
	if max > 0 and view > 0 then thumb:SetHeight(math.max(24, (bar:GetHeight() or view) * view / h)) end
end
local polestarBtn = button(frame, "Ver en Polestar", 150, 24)
polestarBtn:SetPoint("BOTTOMRIGHT", -10, 10)
local status = text(frame, 11, 0.75, 0.75, 0.75)
status:SetPoint("BOTTOMLEFT", 12, 16)
status:SetPoint("RIGHT", polestarBtn, "LEFT", -8, 0)
status:SetWordWrap(true)

local rows = {}
local refresh, showDetail

for i = 1, ROWS do
	local row = CreateFrame("Button", nil, listArea)
	row:SetSize(296, ROW_H)
	row:SetPoint("TOPLEFT", 2, -2 - (i - 1) * ROW_H)
	row.sel = box(row, 1, 0.82, 0, 0.22)
	row.sel:SetAllPoints()
	row.sel:Hide()
	box(row, 1, 1, 1, 0.10, "HIGHLIGHT"):SetAllPoints()
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_H - 4, ROW_H - 4)
	row.icon:SetPoint("LEFT", 2, 0)
	row.right = text(row, 11, 0.75, 0.75, 0.75)
	row.right:SetPoint("RIGHT", -4, 0)
	row.right:SetJustifyH("RIGHT")
	row.name = text(row, 12)
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
	row.name:SetPoint("RIGHT", row.right, "LEFT", -4, 0)
	row.name:SetWordWrap(false)
	row:SetScript("OnClick", function(self)
		if not self.entry then return end
		state.selected = self.entry.id
		refresh()
	end)
	row:SetScript("OnEnter", function(self)
		if not self.entry then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		call(GameTooltip.SetItemByID, GameTooltip, self.entry.id)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	rows[i] = row
end
listArea:SetScript("OnMouseWheel", function(_, delta)
	state.offset = state.offset - delta * 3
	refresh()
end)

---------------------------------------------------------------------------
-- Lógica
---------------------------------------------------------------------------

local function doSearch()
	local p = P()
	state.mode = "search"
	state.offset = 0
	state.list = {}
	state.message = nil
	local q = state.query
	if q == "" then refresh() return end
	if not (p and p.Search and p.Search.Query) then
		state.message = "Hace falta Polestar (su buscador) para buscar por nombre."
		refresh() return
	end
	local results = call(p.Search.Query, q, { kinds = { item = true }, limit = 60, subtitles = true })
	if type(results) ~= "table" then
		state.message = "Polestar no ha podido buscar ahora (¿en combate?)."
		refresh() return
	end
	for _, r in ipairs(results) do
		if r.kind == "item" and r.id then
			state.list[#state.list + 1] = { id = tonumber(r.id), name = r.title, quality = r.quality,
				right = r.status == "retired" and "ya no sale" or nil, sub = r.subtitle }
		end
	end
	if #state.list == 0 then
		local codexOk, reason = true, nil
		if p.Search.Status then codexOk, reason = call(p.Search.Status) end
		state.message = codexOk == false and ("Los datos de Polestar no están cargados (" .. tostring(reason) .. ").") or "No hay objetos con ese nombre."
	end
	refresh()
end

local function doBest()
	state.mode = "best"
	state.offset = 0
	state.message = nil
	local list, note = bestFor(state.class, state.spec, state.slot, state.level)
	state.list = {}
	for i, e in ipairs(list) do
		state.list[#state.list + 1] = { id = e.id, name = itemName(e.id, e.name), quality = itemQuality(e.id, e.quality),
			right = "n.º " .. i .. (e.score and (" · " .. num(e.score)) or "") }
	end
	state.message = note or (#list == 0 and "GearQuest no tiene nada para ese hueco y nivel." or nil)
	if note and note:find("puntuando") then
		C_Timer.After(3, function() if frame:IsShown() and state.mode == "best" then doBest() end end)
	end
	refresh()
end

local function sourceLines(id)
	local list, err = sourcesOf(id)
	if not list then return { "|cffff6060" .. err .. "|r" } end
	if #list == 0 then return { "|cff999999Polestar no sabe de dónde sale.|r" } end
	local out = {}
	for i, r in ipairs(list) do
		if i > 40 then out[#out + 1] = "|cff999999… y " .. (#list - 40) .. " más (en Polestar).|r" break end
		local kind = SOURCE_ES[r.type] or r.type or "?"
		local parts = { "|cffffd100" .. kind .. ":|r " .. tostring(r.label or "") }
		local chance = tonumber(r.chance)
		if chance and chance > 0 then parts[#parts + 1] = num(chance, chance < 1 and 2 or 1) .. " %" end
		if r.zone and r.zone ~= "" then parts[#parts + 1] = r.zone end
		local price = r.type == "vendor" and money(r.price)
		if price then parts[#parts + 1] = price end
		local line = table.concat(parts, " — ")
		if r.available == false and r.whyText then line = line .. " |cffff8080(" .. r.whyText .. ")|r" end
		out[#out + 1] = line
	end
	return out
end

showDetail = function()
	local id = state.selected
	if not id then
		dTitle:SetText("")
		dBody:SetText("|cff999999Busca un objeto o pulsa «Mejores de GearQuest», y elige una fila.|r")
		layoutDetail()
		polestarBtn:Disable()
		return
	end
	local q = itemQuality(id)
	dTitle:SetText(qualityHex(q) .. itemName(id) .. "|r")
	local lines = {}
	local req, ilvl, equipLoc = requiredLevel(id)
	local info = {}
	info[#info + 1] = "Nivel requerido: " .. (req and req > 0 and tostring(req) or "ninguno")
	if ilvl then info[#info + 1] = "nivel de objeto " .. ilvl end
	lines[#lines + 1] = table.concat(info, " · ")
	lines[#lines + 1] = " "
	lines[#lines + 1] = "|cff80c0ffCómo se consigue|r"
	for _, l in ipairs(sourceLines(id)) do lines[#lines + 1] = l end
	lines[#lines + 1] = " "
	local place, score, gqSlot = gqPlace(id)
	local where = (CLASS_ES[state.class] or state.class) .. ", " .. specLabel(state.class, state.spec) .. ", " .. (SLOT_ES[gqSlot] or gqSlot) .. ", nivel " .. state.level
	if place then
		lines[#lines + 1] = "|cff80c0ffGearQuest|r (" .. where .. "): puesto n.º " .. place .. (score and (" · nota " .. num(score)) or "")
	else
		lines[#lines + 1] = "|cff80c0ffGearQuest|r (" .. where .. "): no está en su lista."
	end
	dBody:SetText(table.concat(lines, "\n"))
	layoutDetail()
	polestarBtn:SetEnabled(P() ~= nil and P().Lookup ~= nil)
end

refresh = function()
	if not frame:IsShown() then return end
	classVal:SetText(CLASS_ES[state.class] or state.class)
	specVal:SetText(specLabel(state.class, state.spec))
	slotVal:SetText(SLOT_ES[state.slot] or state.slot)
	lvlVal:SetText(tostring(state.level))
	hint:SetShown(search:GetText() == "" and not search:HasFocus())
	listTitle:SetText(state.mode == "best" and ("Mejores para nivel " .. state.level .. " según GearQuest") or "Resultados de la búsqueda")
	local maxOffset = math.max(0, #state.list - ROWS)
	if state.offset > maxOffset then state.offset = maxOffset end
	if state.offset < 0 then state.offset = 0 end
	for i, row in ipairs(rows) do
		local e = state.list[state.offset + i]
		row.entry = e
		if e then
			row.icon:SetTexture((C_Item and ok(call(C_Item.GetItemIconByID, e.id))) or 134400)
			row.name:SetText(qualityHex(e.quality) .. (e.name or itemName(e.id)) .. "|r")
			row.right:SetText(e.right or "")
			row.sel:SetShown(e.id == state.selected)
			row:Show()
		else
			row:Hide()
		end
	end
	more:SetText(#state.list > ROWS and string.format("%d-%d de %d · rueda del ratón", state.offset + 1, math.min(state.offset + ROWS, #state.list), #state.list) or "")
	status:SetText(state.message or "")
	showDetail()
end

local function cycle(list, current, delta)
	local idx = 1
	for i, v in ipairs(list) do if v == current then idx = i end end
	idx = ((idx - 1 + delta) % #list) + 1
	return list[idx]
end

local function setClass(class)
	state.class = class
	state.spec = defaultSpec(class)
	if state.mode == "best" then doBest() else refresh() end
end
classPrev:SetScript("OnClick", function() setClass(cycle(CLASSES, state.class, -1)) end)
classNext:SetScript("OnClick", function() setClass(cycle(CLASSES, state.class, 1)) end)
local function stepSpec(delta)
	local ids = {}
	for _, o in ipairs(specOptions(state.class)) do ids[#ids + 1] = o.id end
	if #ids == 0 then return end
	state.spec = cycle(ids, state.spec, delta)
	if state.mode == "best" then doBest() else refresh() end
end
specPrev:SetScript("OnClick", function() stepSpec(-1) end)
specNext:SetScript("OnClick", function() stepSpec(1) end)
local function stepSlot(delta)
	state.slot = cycle(SLOTS, state.slot, delta)
	if state.mode == "best" then doBest() else refresh() end
end
slotPrev:SetScript("OnClick", function() stepSlot(-1) end)
slotNext:SetScript("OnClick", function() stepSlot(1) end)
local function stepLevel(delta)
	state.level = math.max(10, math.min(60, state.level + delta))
	if state.mode == "best" then doBest() else refresh() end
end
lvlMinus:SetScript("OnClick", function() stepLevel(-1) end)
lvlPlus:SetScript("OnClick", function() stepLevel(1) end)
bestBtn:SetScript("OnClick", function() search:ClearFocus(); doBest() end)
polestarBtn:SetScript("OnClick", function()
	local p = P()
	if state.selected and p and p.Lookup and p.Lookup.Show then
		-- Este buscador va por encima de casi todo: se cierra para que la ficha de Polestar
		-- no quede debajo. Al volver a abrirlo sigue con la misma búsqueda.
		frame:Hide()
		call(p.Lookup.Show, nil, "item", state.selected)
	end
end)

local pendingSearch
search:SetScript("OnTextChanged", function(self, userInput)
	if not userInput then return end
	state.query = self:GetText() or ""
	hint:SetShown(state.query == "" and not self:HasFocus())
	if pendingSearch then pendingSearch.cancelled = true end
	local token = {}
	pendingSearch = token
	C_Timer.After(0.3, function()
		if not token.cancelled then doSearch() end
	end)
end)
search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
search:SetScript("OnEditFocusGained", function() hint:Hide() end)
search:SetScript("OnEditFocusLost", function(self) hint:SetShown((self:GetText() or "") == "") end)

frame:SetScript("OnShow", function()
	if not state.level then state.level = ok(UnitLevel("player")) or 1 end
	if not state.spec then state.spec = defaultSpec(state.class) end
	refresh()
end)

local events = CreateFrame("Frame")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function()
	if frame:IsShown() then
		if events.pending then return end
		events.pending = true
		C_Timer.After(0.5, function() events.pending = false; refresh() end)
	end
end)

function BuscadorEquipo_Abrir()
	if frame:IsShown() then frame:Hide() else frame:Show() end
end
BINDING_HEADER_BUSCADOREQUIPO = "Buscador de equipo"
BINDING_NAME_BUSCADOREQUIPO_ABRIR = "Abrir o cerrar el buscador"
SLASH_BUSCADOREQUIPO1 = "/buscador"
SlashCmdList.BUSCADOREQUIPO = BuscadorEquipo_Abrir

local opener = CreateFrame("Button", "BuscadorEquipoBoton", UIParent, "UIPanelButtonTemplate")
opener:SetSize(112, 22)
opener:SetText("Buscador")
opener:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -258)
opener:SetMovable(true)
opener:SetClampedToScreen(true)
opener:RegisterForDrag("LeftButton")
opener:SetScript("OnDragStart", opener.StartMoving)
opener:SetScript("OnDragStop", opener.StopMovingOrSizing)
opener:SetScript("OnClick", BuscadorEquipo_Abrir)
opener:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Buscador de equipo")
	GameTooltip:AddLine("Busca un objeto y dice cómo se consigue, o enseña los mejores de GearQuest por hueco y nivel.", 1, 1, 1, true)
	GameTooltip:AddLine("Arrástralo para moverlo.", 0.7, 0.7, 0.7, true)
	GameTooltip:Show()
end)
opener:SetScript("OnLeave", function() GameTooltip:Hide() end)
