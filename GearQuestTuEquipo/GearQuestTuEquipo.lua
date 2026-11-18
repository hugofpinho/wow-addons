-- GearQuest: con tu equipo 1.0 (2026-11-18)
--
-- Para cualquier clase. Arregla dos cosas de GearQuest Forever:
--
-- 1. Lo que llevas puesto sale «Sin puesto a tu nivel». GearQuest quita cada objeto de su
--    lista a partir de cierto nivel (cuando cree que ya lo habrás cambiado), y alguno no
--    lo pone nunca para tu facción. Si sigues con él, el tooltip no te dice en qué puesto
--    está ni qué es mejor que él.
-- 2. Con una especialización personalizada elegida, el tooltip pone «Sin puesto para c:1»
--    en vez de su nombre.
--
-- Cómo: GearQuest trae especializaciones personalizadas (GQ.Custom), que vuelven a
-- puntuar toda su lista. Este addon crea una por cada rama que uses, con los MISMOS pesos
-- de GearQuest (no cambia ninguno), llamada «<rama> +equipo» (por ejemplo «Fuego
-- +equipo»), y la elige cuando GearQuest iba a usar esa rama por tus talentos. Justo antes
-- de que GearQuest cierre la puntuación (GQ.Custom:Finish) mete cada pieza que llevas
-- puesta en todos los tramos de nivel de su hueco (desde su nivel) en los que no esté,
-- puntuada igual que el resto (GQ.Custom:Consume). Así tiene puesto, y lo que es mejor
-- que ella sale por encima. GearQuest ya esconde de las cazas lo que tienes.
-- También vale para las especializaciones personalizadas que te hagas tú en GearQuest.
--
-- Lo que GearQuest no tiene en su tabla de estadísticas (solo trae las de objetos que
-- salen en alguna lista) se lee del tooltip del objeto (en español o en inglés).
--
-- Si eliges a mano otra especialización en GearQuest, la respeta. Si cambias de equipo,
-- vuelve a puntuar sola (unos segundos, nunca en combate). No cambia nada de GearQuest:
-- usa sus funciones y engancha dos (GQ.Custom.Finish y GQ.Data.GearScoreMissText).
--
-- Si está también GearQuestLeveo (el de pesos del brujo Leveo), este no hace nada: aquel
-- ya mete el equipo puesto en su especialización.

local SUFFIX = " +equipo"
local NAME_LIMIT = 20 -- lo pide GearQuest

local GQ = _G.GearQuest
local function leveoPresent()
	if GQ and GQ.Custom and GQ.Custom._leveoHooked then return true end
	local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
	return isLoaded and isLoaded("GearQuestLeveo") and true or false
end
if not (GQ and GQ.Custom and GQ.Custom.Finish) or leveoPresent() then return end

-- Hueco del personaje → hueco de GearQuest. Sin camisa ni tabardo.
local SLOT_OF = {
	[1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest", [6] = "Waist", [7] = "Legs",
	[8] = "Feet", [9] = "Wrist", [10] = "Hands", [11] = "Finger", [12] = "Finger",
	[13] = "Trinket", [14] = "Trinket", [15] = "Back", [16] = "MainHand",
	[17] = "SecondaryHand", [18] = "Ranged",
}
local FACT_FIELDS = {
	"sourceType", "instructions", "setPiece", "lore", "zone", "npc",
	"questName", "profession", "reqRep", "reqSkills", "proc",
}
local HAND_OF = {
	INVTYPE_2HWEAPON = "two", INVTYPE_WEAPONMAINHAND = "main", INVTYPE_WEAPON = "one",
}

local issecret = issecretvalue or function() return false end

local function playerClass()
	local _, classFile = UnitClass("player")
	return classFile
end

-- Corta un texto a n bytes sin partir una letra.
local function cut(text, n)
	if #text <= n then return text end
	local s = text:sub(1, n)
	while #s > 0 and s:byte(#s) >= 0x80 and s:byte(#s) < 0xC0 do s = s:sub(1, -2) end
	if #s > 0 and s:byte(#s) >= 0xC0 then s = s:sub(1, -2) end
	return s
end

local function nextId(list)
	local highest = 0
	for i = 1, #list do
		local n = tonumber(tostring(list[i].id or ""):match("^c:(%d+)$"))
		if n and n > highest then highest = n end
	end
	return "c:" .. (highest + 1)
end

local function classList(classFile)
	local store = GQ.Custom.Store and GQ.Custom:Store()
	if not store then return nil end
	store[classFile] = store[classFile] or {}
	return store[classFile]
end

local function isOurs(classFile, specId)
	local record = specId and GQ.Custom.Get and GQ.Custom:Get(classFile, specId)
	return record and record.tuEquipo and true or false
end

-- La especialización «<rama> +equipo» de esa rama: la crea si no está.
local function ensureRecord(classFile, base)
	local list = classList(classFile)
	if not list then return nil end
	for i = 1, #list do
		if list[i].tuEquipo and list[i].base == base then return list[i].id end
	end
	local label = (GQ.Spec.GetSpecLabel and GQ.Spec:GetSpecLabel(base, classFile)) or base
	local name = cut(tostring(label), NAME_LIMIT - #SUFFIX) .. SUFFIX
	if GQ.Custom.FindByName and GQ.Custom:FindByName(classFile, name) then
		name = cut(tostring(base), NAME_LIMIT - #SUFFIX - 1) .. "*" .. SUFFIX
	end
	local record = { id = nextId(list), name = name, base = base, overrides = {}, tuEquipo = true }
	list[#list + 1] = record
	return record.id
end

local function apply()
	if not (GQ.Custom.Store and GQ.Spec and GQ.Spec.SetSelectedSpec and GQ.Spec.GetDisplaySpec
		and GQ.Spec.DetectSpecFromTalents) then
		return false
	end
	local classFile = playerClass()
	if not classFile then return false end
	if not GQ.Custom:Store() then return false end
	local ok, base = pcall(GQ.Spec.DetectSpecFromTalents, GQ.Spec, classFile)
	if not ok or not base then return true end -- sin talentos todavía: lo de GearQuest
	if GQ.Custom.Shipped and not GQ.Custom:Shipped(classFile, base) then return true end
	local id = ensureRecord(classFile, base)
	if not id then return false end
	local current = GQ.Spec:GetDisplaySpec(classFile)
	if current == id then return true end
	-- Solo si GearQuest iba a usar esa rama, o una de las nuestras (cambio de talentos).
	-- Si elegiste otra a mano, se queda.
	if current == nil or current == base or isOurs(classFile, current) then
		pcall(GQ.Spec.SetSelectedSpec, GQ.Spec, id, classFile)
	end
	return true
end

-- Lo que llevas puesto -----------------------------------------------------------------

local function equipped()
	local items, parts = {}, {}
	if not GetInventoryItemID then return items, "" end
	for inv = 1, 18 do
		local slot = SLOT_OF[inv]
		if slot then
			local id = GetInventoryItemID("player", inv)
			if type(id) == "number" and not issecret(id) then
				items[#items + 1] = { id = id, slot = slot, inv = inv }
				parts[#parts + 1] = inv .. ":" .. id
			end
		end
	end
	return items, table.concat(parts, ",")
end

local function handOf(itemId)
	local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not getInstant then return nil end
	local ok, _, _, _, equipLoc = pcall(getInstant, itemId)
	return ok and HAND_OF[equipLoc] or nil
end

-- Estadísticas sacadas del tooltip (mismo formato que la tabla de GearQuest).
local STAT_WORD = {
	aguante = "sta", intelecto = "int", ["espíritu"] = "spi", fuerza = "str", agilidad = "agi",
	stamina = "sta", intellect = "int", spirit = "spi", strength = "str", agility = "agi",
}
local SCHOOL = {
	{ "de las sombras", "spShadow" }, { "de fuego", "spFire" }, { "de escarcha", "spFrost" },
	{ "de naturaleza", "spNature" }, { "arcanos", "spArcane" }, { "sagrados", "spHoly" },
	{ "shadow", "spShadow" }, { "fire", "spFire" }, { "frost", "spFrost" },
	{ "nature", "spNature" }, { "arcane", "spArcane" }, { "holy", "spHoly" },
}
local KIND = {
	tela = "Cloth", cuero = "Leather", malla = "Mail", placas = "Plate",
	cloth = "Cloth", leather = "Leather", mail = "Mail", plate = "Plate",
}

local function decimal(text)
	return tonumber((tostring(text):gsub(",", ".")))
end

local function parseEffect(effect, add)
	-- Lo que solo vale contra un tipo de enemigo o en una forma no cuenta.
	if effect:find("enfrentarte", 1, true) or effect:find("contra ", 1, true)
		or effect:find("dragonantes", 1, true) or effect:find(" against ", 1, true)
		or effect:find("versus", 1, true) then
		return
	end
	local n
	-- Poder de ataque
	if effect:find("poder de ataque", 1, true) or effect:find("attack power", 1, true) then
		n = tonumber(effect:match("(%d+)"))
		if not n then return end
		if effect:find("forma", 1, true) or effect:find(" form", 1, true) then return add("feralAp", n) end
		if effect:find("distancia", 1, true) or effect:find("ranged", 1, true) then return add("rap", n) end
		return add("ap", n)
	end
	-- Crítico y golpe (con hechizos o con armas)
	n = effect:match("(%d+[,%.]?%d*)%s*%%")
	local pct = n and decimal(n)
	if pct and (effect:find("cr%S*tico") or effect:find("critical", 1, true)) then
		if effect:find("hechizo", 1, true) or effect:find("spell", 1, true) then return add("spellCrit", pct) end
		return add("crit", pct)
	end
	if pct and (effect:find("golpear", 1, true) or effect:find("acertar", 1, true) or effect:find("to hit", 1, true) or effect:find("chance to hit", 1, true)) then
		if effect:find("hechizo", 1, true) or effect:find("spell", 1, true) then return add("spellHit", pct) end
		return add("hit", pct)
	end
	if pct and (effect:find("esquivar", 1, true) or effect:find("dodge", 1, true)) then return add("dodge", pct) end
	if pct and (effect:find("parar", 1, true) or effect:find("parry", 1, true)) then return add("parry", pct) end
	if effect:find("valor de bloqueo", 1, true) or effect:find("block value", 1, true) then
		return add("blockValue", tonumber(effect:match("(%d+)")))
	end
	if effect:find("defensa", 1, true) or effect:find("defense", 1, true) then
		return add("defense", tonumber(effect:match("(%d+)")))
	end
	local mp5 = effect:match("restaura (%d+) p%. de man%S* cada 5 s") or effect:match("restores (%d+) mana per 5 sec")
	if mp5 then return add("mp5", tonumber(mp5)) end
	local hp5 = effect:match("restaura (%d+) p%. de salud cada 5 s") or effect:match("restores (%d+) health per 5 sec")
	if hp5 then return add("hp5", tonumber(hp5)) end
	if not (effect:find("^aumenta hasta") or effect:find("^increases")) then return end
	local first = tonumber(effect:match("(%d+)"))
	if not first then return end
	local healAt = effect:find("sanaci", 1, true) or effect:find("curaci", 1, true) or effect:find("healing", 1, true)
	local damageAt = effect:find("daño", 1, true) or effect:find("damage", 1, true)
	local spells = effect:find("hechizo", 1, true) or effect:find("spell", 1, true) or effect:find("magical", 1, true)
	if healAt and damageAt then
		local a, b = effect:match("(%d+)%D+(%d+)")
		if a and b then
			if healAt < damageAt then a, b = b, a end
			add("damageDone", tonumber(a))
			add("heal", tonumber(b))
		else
			add("damageDone", first)
			add("heal", first)
		end
	elseif healAt then
		add("heal", first)
	elseif damageAt and spells then
		for _, school in ipairs(SCHOOL) do
			if effect:find(school[1], 1, true) then return add(school[2], first) end
		end
		add("sp", first)
	end
end

local function statsFromTooltip(inv)
	if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return nil end
	local okData, data = pcall(C_TooltipInfo.GetInventoryItem, "player", inv)
	if not (okData and type(data) == "table" and type(data.lines) == "table") then return nil end
	local row, req, found = {}, nil, false
	local function add(key, value)
		if value and value > 0 then
			row[key] = (row[key] or 0) + value
			found = true
		end
	end
	for i, line in ipairs(data.lines) do
		local left, right = line.leftText, line.rightText
		if issecret(left) then left = nil end
		if issecret(right) then right = nil end
		if type(left) == "string" then
			local low = left:lower()
			local n, word = low:match("^%+(%d+) (.+)$")
			if n then
				if STAT_WORD[word] then
					add(STAT_WORD[word], tonumber(n))
				elseif word:find("resistencia", 1, true) or word:find("resistance", 1, true) then
					add("resist", tonumber(n))
				elseif word:find("poder de ataque", 1, true) or word:find("attack power", 1, true) then
					parseEffect(low, add)
				end
			end
			local armor = low:match("^(%d+) armadura$") or low:match("^(%d+) armor$")
			if armor then add("armor", tonumber(armor)) end
			local dps = low:match("%(([%d,%.]+) daño por segundo%)") or low:match("%(([%d,%.]+) damage per second%)")
			if dps then add("dps", decimal(dps)) end
			local level = low:match("necesitas ser de nivel (%d+)") or low:match("requires level (%d+)")
			if level then req = tonumber(level) end
			local effect = low:match("^equipar: (.+)$") or low:match("^equip: (.+)$")
			if effect then parseEffect(effect, add) end
		end
		if type(right) == "string" then
			local low = right:lower()
			local speed = low:match("velocidad ([%d,%.]+)") or low:match("speed ([%d,%.]+)")
			if speed then row.spd = decimal(speed) end
			if i <= 8 and KIND[low] then row.kind = KIND[low] end
		end
	end
	if not found then return nil end
	return row, req
end

local builtSig = {}   -- por especialización: firma del equipo con el que se puntuó
local tooltipReq = {} -- nivel requerido leído del tooltip, por objeto

local function newEntry(classFile, base, template, fact, item, lo, hi, factions)
	local e
	if template then
		e = GQ.Data:CopyEntry(template)
	else
		e = { itemId = item.id, classes = { [classFile] = true }, generated = true }
		if fact then
			for _, key in ipairs(FACT_FIELDS) do
				if fact[key] ~= nil then e[key] = fact[key] end
			end
		end
		e.hand = handOf(item.id)
	end
	e.id = "tuequipo:" .. item.id .. ":" .. item.slot .. ":" .. lo
	e.slot = item.slot
	e.minLevel, e.maxLevel = lo, hi
	e.curatedRank, e.pipelineScore = 99, 0
	e.specs = { [base] = true }
	e.factions = factions
	e.reserve, e.origin, e.customSpec = nil, nil, nil
	e.tuEquipo = true
	return e
end

local function listHas(list, itemId)
	for i = 1, #list do
		if list[i].itemId == itemId then return true end
	end
	return false
end

-- Antes de GQ.Custom:Finish, con las filas de la especialización ya puntuadas y
-- repartidas por tramos (job.bands), sin ordenar todavía.
local function addEquipped(custom, job)
	local classFile = playerClass()
	if not (job and job.record and job.classFile == classFile and job.specId) then return end
	if not (GQ.Data and GQ.Data.CopyEntry and custom.Consume) then return end
	local base = job.record.base
	local items, sig = equipped()
	builtSig[job.specId] = sig
	if #items == 0 or not base then return end
	local stats = job.stats or GQ.Data.itemStats or {}

	local wanted = {}
	for _, item in ipairs(items) do wanted[item.id .. "|" .. item.slot] = true end
	local templates = {}
	for _, e in ipairs(job.entries or {}) do
		local id = e and e.itemId
		if id and not e.customSpec then
			local key = id .. "|" .. tostring(e.slot)
			if wanted[key] and e.classes and e.classes[classFile] then
				local ofBase = e.specs and e.specs[base] and true or false
				local have = templates[key]
				if not have or (ofBase and not have.ofBase) then
					templates[key] = { entry = e, ofBase = ofBase }
				end
			end
		end
	end

	local done = {}
	for _, item in ipairs(items) do
		local key = item.id .. "|" .. item.slot
		if not stats[item.id] then
			local row, req = statsFromTooltip(item.inv)
			if row then
				stats[item.id] = row
				tooltipReq[item.id] = req
			end
		end
		if stats[item.id] and not done[key] then
			done[key] = true
			local template = templates[key] and templates[key].entry
			local fact = GQ.Data.GetItemFact and GQ.Data:GetItemFact(item.id)
			local req = tonumber(fact and fact.reqLevel) or tooltipReq[item.id] or (template and template.minLevel) or 1
			local target, present, top = {}, {}, {}
			for _, band in pairs(job.bands) do
				local list = band.slots[item.slot]
				if list and list[1] then
					local hi = band.level
					for i = 1, #list do
						local m = list[i].maxLevel
						if type(m) == "number" and m > hi then hi = m end
					end
					if hi >= req then
						if listHas(list, item.id) then present[band.level] = true end
						local cur = target[band.level]
						if not cur or #list > #cur then
							target[band.level] = list
							top[band.level] = hi
						end
					end
				end
			end
			for level, list in pairs(target) do
				if not present[level] then
					custom:Consume(job, newEntry(classFile, base, template, fact, item, level, top[level], list[1].factions))
				end
			end
		end
	end
end

local function hookGearQuest()
	if GQ.Custom._tuEquipoHooked or leveoPresent() then return end
	GQ.Custom._tuEquipoHooked = true
	local finish = GQ.Custom.Finish
	GQ.Custom.Finish = function(self, job, ...)
		local ok, err = pcall(addEquipped, self, job)
		if not ok and not self._tuEquipoWarned then
			self._tuEquipoWarned = true
			print("|cffff8800GearQuest: con tu equipo|r: no he podido añadir tu equipo (" .. tostring(err) .. ").")
		end
		return finish(self, job, ...)
	end
	-- «Sin puesto para c:1» → «Sin puesto para Fuego +equipo».
	if GQ.Data and GQ.Data.GearScoreMissText then
		local miss = GQ.Data.GearScoreMissText
		GQ.Data.GearScoreMissText = function(self, ...)
			local text = miss(self, ...)
			if type(text) == "string" and text:find("c:%d") and GQ.Custom.Get then
				local classFile = (GQ.GetEffectiveClass and GQ:GetEffectiveClass()) or playerClass()
				text = text:gsub("c:%d+", function(id)
					local ok, record = pcall(GQ.Custom.Get, GQ.Custom, classFile, id)
					return ok and record and record.name or nil
				end)
			end
			return text
		end
	end
end
hookGearQuest()

-- Si cambias de equipo, vuelve a puntuar la especialización personalizada elegida.
local waitingCombat = false
local function rescoreIfGearChanged()
	if not (GQ.Custom.EnsureBuilt and GQ.Spec and GQ.Spec.GetDisplaySpec and GQ.Custom.Get) then return end
	local classFile = playerClass()
	local current = classFile and GQ.Spec:GetDisplaySpec(classFile)
	if not (current and GQ.Custom:Get(classFile, current)) then return end
	if not (GQ.Custom._built and GQ.Custom._built[current]) then return end -- aún no puntuada
	local _, sig = equipped()
	if sig == "" or sig == builtSig[current] then return end
	if InCombatLockdown and InCombatLockdown() then
		waitingCombat = true
		return
	end
	if GQ.Custom._job then return "busy" end
	GQ.Custom._built[current] = nil
	if GQ.Custom._rebuilt then GQ.Custom._rebuilt[current] = nil end
	pcall(GQ.Custom.EnsureBuilt, GQ.Custom, classFile, current)
end

local gearPending = false
local function gearLater(seconds)
	if gearPending then return end
	gearPending = true
	C_Timer.After(seconds, function()
		gearPending = false
		if rescoreIfGearChanged() == "busy" then gearLater(3) end
	end)
end

local pending = false
local function later(seconds, tries)
	if pending then return end
	pending = true
	C_Timer.After(seconds, function()
		pending = false
		if not apply() and (tries or 0) < 10 then later(3, (tries or 0) + 1) end
	end)
end

local f = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED",
	"ACTIVE_TALENT_GROUP_CHANGED", "CHARACTER_POINTS_CHANGED",
	"PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED" }) do
	pcall(f.RegisterEvent, f, event)
end
f:SetScript("OnEvent", function(_, event)
	if leveoPresent() and not GQ.Custom._tuEquipoHooked then return end
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		gearLater(2)
	elseif event == "PLAYER_REGEN_ENABLED" then
		if waitingCombat then
			waitingCombat = false
			gearLater(1)
		end
	else
		later(event == "PLAYER_LOGIN" and 3 or 1)
		if event == "PLAYER_LOGIN" then
			hookGearQuest()
			gearLater(20) -- por si GearQuest puntuó antes de que el juego diera el equipo
		end
	end
end)
