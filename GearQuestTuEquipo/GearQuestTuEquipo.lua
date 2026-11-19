-- GearQuest: con tu equipo 1.1 (2026-11-19)
--
-- Para cualquier clase. Sobre GearQuest Forever:
--
-- 1. Pesos de subida de nivel de tu rama. GearQuest trae especializaciones personalizadas
--    (GQ.Custom), que vuelven a puntuar toda su lista con otros pesos. Este addon crea una por
--    rama, «<rama> leveo» (por ejemplo «Fuego leveo»), con los pesos de GearQuest de esa rama y
--    unos ajustes para subir de nivel (tabla LEVELING: crítico y golpe de los lanzadores,
--    varitas, intelecto del brujo). La primera vez que entras te pregunta la rama; se cambia
--    cuando quieras en GearQuest → Ajustes → «Pesos y especialización». «Según mis talentos»
--    elige sola la rama con más puntos y respeta otra que elijas a mano en GearQuest.
-- 2. Doble especialización: eliges también la rama de la segunda. Al cambiar de
--    especialización en el juego (ACTIVE_TALENT_GROUP_CHANGED), GearQuest pasa a los puestos de
--    la otra al momento.
-- 3. Lo que llevas puesto tiene puesto. GearQuest quita cada objeto de su lista a partir de
--    cierto nivel, y alguno no lo pone nunca para tu facción: salía «Sin puesto a tu nivel».
--    Justo antes de que GearQuest cierre la puntuación (GQ.Custom:Finish) se mete cada pieza
--    puesta en los tramos de su hueco desde su nivel, puntuada igual (GQ.Custom:Consume). Las
--    piezas con sufijo aleatorio entran con su sufijo de verdad («del hechicero»): GearQuest
--    solo guarda una versión de cada objeto y no conoce los sufijos nuevos de Forever.
-- 4. Lo que no esté en la lista (otro sufijo, algo que GearQuest ya quitó a tu nivel) tiene en
--    el tooltip el puesto que tendría, calculado con su tooltip y la misma puntuación.
-- 5. «Sin puesto para c:1» pasa a decir el nombre de la especialización.
--
-- Lo que GearQuest no tiene en su tabla de estadísticas se lee del tooltip (en español o en
-- inglés), con el crítico y el golpe en sus unidades. Si cambias de equipo o de nivel, vuelve a
-- puntuar sola (unos segundos, nunca en combate). No cambia nada de GearQuest: usa sus
-- funciones y engancha GQ.Custom.Finish, GQ.Data.GearScoreMissText y su página de ajustes.
--
-- Si está también GearQuestLeveo (el del brujo Leveo), este no hace nada.

local SUFFIX = " leveo"
local NAME_LIMIT = 20 -- lo pide GearQuest
-- Unidades de GearQuest para crítico y golpe (en sus datos, «+1,0 % de crítico» = crit 14 y
-- «+0,7 % de golpe» = hit 7): 14 por cada 1 % de crítico y 10 por cada 1 % de golpe.
local CRIT_UNIT, HIT_UNIT = 14, 10

-- Pesos de subida de nivel: lo que se cambia de los de GearQuest en cada rama. Lo que no está
-- aquí se queda como lo trae GearQuest (con su multiplicador de subida de nivel: aguante ×3,
-- intelecto, espíritu y maná ×2…). En sus unidades: crit 0,2 = 2,8 puntos por 1 % de crítico.
--   Lanzadores: GearQuest valora el crítico y el golpe como en banda al 60 (1 % de golpe = 12,5
--   de poder con hechizos). Subiendo de nivel, con poco poder con hechizos y enemigos de tu
--   nivel, 1 % de golpe ≈ 4 y 1 % de crítico ≈ 3 (más con Fuego por Ignite).
--   Varitas: GearQuest cuenta cada punto de daño por segundo de la varita ×7, como si te pasaras
--   el combate disparando. Sacerdote: se sube mucho con varita (2–2,5); mago: para rematar (1);
--   brujo: según la rama (Aflicción drena y remata, 0,5).
--   Brujo: el intelecto llena la reserva de maná igual que el aguante la de vida, que Life Tap
--   convierte 1 a 1 (0,5).
--   Aflicción lleva Suppression, que quita los fallos contra tu nivel: golpe 0,2 (2 por 1 %).
--   Cuerpo a cuerpo, cazadores, tanques y sanadores: los de GearQuest.
local LEVELING = {
	MAGE = {
		arcane = { crit = 0.2, hit = 0.4, dpsWeightRanged = 1 },
		fire = { crit = 0.3, hit = 0.4, dpsWeightRanged = 1 },
		frost = { crit = 0.2, hit = 0.4, dpsWeightRanged = 1 },
		battlemage_arcane = { crit = 0.2, hit = 0.4, dpsWeightRanged = 1 },
		battlemage_fire = { crit = 0.3, hit = 0.4, dpsWeightRanged = 1 },
		battlemage_frost = { crit = 0.2, hit = 0.4, dpsWeightRanged = 1 },
	},
	PRIEST = {
		shadow = { crit = 0.2, hit = 0.4, dpsWeightRanged = 2 },
		holy = { dpsWeightRanged = 2.5 },
		discipline = { dpsWeightRanged = 2.5 },
	},
	WARLOCK = {
		affliction = { crit = 0.25, hit = 0.2, int = 0.5, dpsWeightRanged = 0.5 },
		demonology = { crit = 0.2, hit = 0.4, int = 0.5, dpsWeightRanged = 1 },
		destruction = { crit = 0.3, hit = 0.4, int = 0.5, dpsWeightRanged = 0.7 },
	},
	DRUID = { balance = { crit = 0.2, hit = 0.4 } },
	SHAMAN = { elemental = { crit = 0.25, hit = 0.4 } },
}
local function levelingFor(classFile, base)
	local byClass = LEVELING[classFile]
	return byClass and byClass[base] or {}
end

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

local function copy(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

local function sameTable(a, b)
	if type(a) ~= "table" then return false end
	for k, v in pairs(b) do if a[k] ~= v then return false end end
	for k in pairs(a) do if b[k] == nil then return false end end
	return true
end

-- La especialización «<rama> leveo» de esa rama, con sus pesos de subida de nivel: la crea si
-- no está y la pone al día (también las «<rama> +equipo» de la versión 1.0).
local function ensureRecord(classFile, base)
	local list = classList(classFile)
	if not list then return nil end
	local want = levelingFor(classFile, base)
	local label = (GQ.Spec.GetSpecLabel and GQ.Spec:GetSpecLabel(base, classFile)) or base
	local name = cut(tostring(label), NAME_LIMIT - #SUFFIX) .. SUFFIX
	for i = 1, #list do
		local record = list[i]
		if record.tuEquipo and record.base == base then
			if not sameTable(record.overrides, want) or record.name:sub(-#SUFFIX) ~= SUFFIX then
				record.overrides = copy(want)
				if record.name:sub(-#SUFFIX) ~= SUFFIX and not (GQ.Custom.FindByName and GQ.Custom:FindByName(classFile, name)) then
					record.name = name
				end
				if GQ.Custom._built then GQ.Custom._built[record.id] = nil end
				if GQ.Custom._failed then GQ.Custom._failed[record.id] = nil end
				return record.id, true
			end
			return record.id
		end
	end
	if GQ.Custom.FindByName and GQ.Custom:FindByName(classFile, name) then
		name = cut(tostring(base), NAME_LIMIT - #SUFFIX - 1) .. "*" .. SUFFIX
	end
	local record = { id = nextId(list), name = name, base = base, overrides = copy(want), tuEquipo = true }
	list[#list + 1] = record
	return record.id
end

-- Qué rama usa cada especialización del juego: «auto» (la de tus talentos), o una fija; la
-- segunda (doble especialización) puede ser «same» (la misma que la principal).
local function settings()
	if type(GearQuestTuEquipoDB) ~= "table" then GearQuestTuEquipoDB = {} end
	local d = GearQuestTuEquipoDB
	if d.main == nil then d.main = "auto" end
	if d.second == nil then d.second = "same" end
	return d
end

local function activeGroup()
	local get = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup
	local ok, group = false, nil
	if get then ok, group = pcall(get) end
	if not (ok and type(group) == "number") and GetActiveTalentGroup then
		ok, group = pcall(GetActiveTalentGroup)
	end
	return (ok and group == 2) and 2 or 1
end

local function wantedChoice()
	local d = settings()
	if activeGroup() == 2 and d.second and d.second ~= "same" then return d.second end
	return d.main
end

-- Las ramas de tu clase que trae GearQuest (sin la de los niveles 1-9).
local function specOptions(classFile)
	local out = {}
	for _, opt in ipairs((GQ.Spec.GetOptions and GQ.Spec:GetOptions(classFile)) or {}) do
		if opt.id and not tostring(opt.id):find("^levelling") and not (GQ.Custom.Shipped and not GQ.Custom:Shipped(classFile, opt.id)) then
			local label = (GQ.Spec.GetSpecLabel and GQ.Spec:GetSpecLabel(opt.id, classFile)) or opt.label or opt.id
			out[#out + 1] = { id = opt.id, label = tostring(label) }
		end
	end
	return out
end

local function apply()
	if not (GQ.Custom.Store and GQ.Spec and GQ.Spec.SetSelectedSpec and GQ.Spec.GetDisplaySpec
		and GQ.Spec.DetectSpecFromTalents) then
		return false
	end
	local classFile = playerClass()
	if not classFile then return false end
	if not GQ.Custom:Store() then return false end
	local choice = wantedChoice()
	local current = GQ.Spec:GetDisplaySpec(classFile)
	if choice and choice ~= "auto" and not (GQ.Custom.Shipped and not GQ.Custom:Shipped(classFile, choice)) then
		-- Elegida en los ajustes: esa, siempre.
		local id, changed = ensureRecord(classFile, choice)
		if not id then return false end
		if current ~= id then
			pcall(GQ.Spec.SetSelectedSpec, GQ.Spec, id, classFile)
		elseif changed and GQ.Custom.EnsureBuilt then
			pcall(GQ.Custom.EnsureBuilt, GQ.Custom, classFile, id)
		end
		return true
	end
	-- «Según mis talentos».
	local ok, base = pcall(GQ.Spec.DetectSpecFromTalents, GQ.Spec, classFile)
	if not ok or not base then return true end -- sin talentos todavía: lo de GearQuest
	if GQ.Custom.Shipped and not GQ.Custom:Shipped(classFile, base) then return true end
	local id, changed = ensureRecord(classFile, base)
	if not id then return false end
	if current == id then
		if changed and GQ.Custom.EnsureBuilt then pcall(GQ.Custom.EnsureBuilt, GQ.Custom, classFile, id) end
		return true
	end
	-- Solo si GearQuest iba a usar esa rama, o una de las nuestras (cambio de talentos o de
	-- especialización). Si elegiste otra a mano en GearQuest, se queda.
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
		if effect:find("hechizo", 1, true) or effect:find("spell", 1, true) then return add("spellCrit", pct * CRIT_UNIT) end
		return add("crit", pct * CRIT_UNIT)
	end
	if pct and (effect:find("golpear", 1, true) or effect:find("acertar", 1, true) or effect:find("to hit", 1, true) or effect:find("chance to hit", 1, true)) then
		if effect:find("hechizo", 1, true) or effect:find("spell", 1, true) then return add("spellHit", pct * HIT_UNIT) end
		return add("hit", pct * HIT_UNIT)
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

local function statsFromLines(lines)
	if type(lines) ~= "table" then return nil end
	local data = { lines = lines }
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

-- Del hueco del personaje (con su sufijo, si lo tiene).
local function statsFromTooltip(inv)
	if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return nil end
	local okData, data = pcall(C_TooltipInfo.GetInventoryItem, "player", inv)
	if not (okData and type(data) == "table") then return nil end
	return statsFromLines(data.lines)
end

-- De un enlace cualquiera (lo que miras en la subasta, en la bolsa…).
local function statsFromLink(link)
	if not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
	local okData, data = pcall(C_TooltipInfo.GetHyperlink, link)
	if not (okData and type(data) == "table") then return nil end
	return statsFromLines(data.lines)
end

local builtSig = {}   -- por especialización: firma del equipo con el que se puntuó
local tooltipReq = {} -- nivel requerido leído del tooltip, por objeto

local function newEntry(classFile, base, template, fact, item, lo, hi, factions, suffix)
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
		e.hand = item.hand or handOf(item.id)
	end
	e.id = "tuequipo:" .. item.id .. ":" .. item.slot .. ":" .. lo .. (suffix and suffix ~= "" and (":" .. suffix) or "")
	e.slot = item.slot
	e.minLevel, e.maxLevel = lo, hi
	e.curatedRank, e.pipelineScore = 99, 0
	e.specs = { [base] = true }
	e.factions = factions
	e.reserve, e.origin, e.customSpec = nil, nil, nil
	if suffix then
		-- El sufijo de verdad («del hechicero»), no el mejor que GearQuest se imagina.
		e.suffix, e.suffixId, e.suffixChance, e.suffixRange = suffix, 0, nil, ""
	end
	e.tuEquipo = true
	return e
end

-- Puntúa la fila con estas estadísticas y nada más (GearQuest usaría las de su tabla y el
-- mejor sufijo posible del objeto).
local function consumeWith(custom, job, entry, row)
	if not row then return custom:Consume(job, entry) end
	local rolls = GQ.Data.itemRolls
	job.stats = job.stats or {}
	local stats, id = job.stats, entry.itemId
	local oldStat, oldRolls = stats[id], rolls and rolls[id]
	stats[id] = row
	if rolls then rolls[id] = nil end
	local ok, err = pcall(custom.Consume, custom, job, entry)
	stats[id] = oldStat
	if rolls then rolls[id] = oldRolls end
	if not ok then error(err, 0) end
end

local function listHas(list, itemId)
	for i = 1, #list do
		if list[i].itemId == itemId then return true end
	end
	return false
end

local function equippedLink(inv)
	local link = GetInventoryItemLink and GetInventoryItemLink("player", inv)
	if type(link) ~= "string" or issecret(link) then return nil end
	return link
end

-- «Guantes del Crepúsculo del hechicero» → «del hechicero».
local function suffixOf(id, link)
	local full = GQ.Data.ItemLinkFullName and GQ.Data:ItemLinkFullName(link)
	local base = GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(id)
	if type(full) ~= "string" or type(base) ~= "string" then return nil end
	if #full > #base + 1 and full:sub(1, #base + 1) == base .. " " then
		return full:sub(#base + 2)
	end
	return nil
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
	job.stats = stats

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
		if not done[key] then
			done[key] = true
			local link = equippedLink(item.inv)
			local rolled = link and GQ.Data.SuffixIdFromLink and GQ.Data:SuffixIdFromLink(link)
			local row, tipReq
			if rolled then
				-- Con sufijo: sus estadísticas de verdad, sacadas del tooltip.
				row, tipReq = statsFromTooltip(item.inv)
			elseif not stats[item.id] then
				local tipRow
				tipRow, tipReq = statsFromTooltip(item.inv)
				if tipRow then stats[item.id] = tipRow end
			end
			if tipReq then tooltipReq[item.id] = tipReq end
			if (rolled and row) or (not rolled and stats[item.id]) then
				local suffix = rolled and (suffixOf(item.id, link) or "") or nil
				local template = not rolled and templates[key] and templates[key].entry or nil
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
							if rolled then
								-- Fuera las otras versiones del mismo objeto: GearQuest solo deja una
								-- por objeto en cada lista, y la que cuenta es la tuya.
								for i = #list, 1, -1 do
									local other = list[i]
									if other.itemId == item.id then
										if other.suffix and other.suffix ~= "" and GQ.Data.EntrySuffixMatchesLink
											and GQ.Data:EntrySuffixMatchesLink(other, link) then
											present[band.level] = true
										else
											table.remove(list, i)
										end
									end
								end
							elseif listHas(list, item.id) then
								present[band.level] = true
							end
							local cur = target[band.level]
							if not cur or #list > #cur then
								target[band.level] = list
								top[band.level] = hi
							end
						end
					end
				end
				for level, list in pairs(target) do
					if not present[level] and list[1] then
						consumeWith(custom, job, newEntry(classFile, base, template, fact, item, level, top[level], list[1].factions, suffix), row)
					end
				end
			end
		end
	end
end

-- Puesto de un objeto suelto que no está en la lista (otro sufijo, uno que GearQuest ya quitó a
-- tu nivel…), con las estadísticas de su tooltip y la misma puntuación.
local LOC_SLOT = {
	INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder",
	INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest", INVTYPE_WAIST = "Waist",
	INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet", INVTYPE_WRIST = "Wrist",
	INVTYPE_HAND = "Hands", INVTYPE_FINGER = "Finger", INVTYPE_TRINKET = "Trinket",
	INVTYPE_CLOAK = "Back", INVTYPE_WEAPON = "MainHand", INVTYPE_WEAPONMAINHAND = "MainHand",
	INVTYPE_2HWEAPON = "MainHand", INVTYPE_WEAPONOFFHAND = "SecondaryHand", INVTYPE_SHIELD = "SecondaryHand",
	INVTYPE_HOLDABLE = "SecondaryHand", INVTYPE_RANGED = "Ranged", INVTYPE_RANGEDRIGHT = "Ranged",
	INVTYPE_THROWN = "Ranged", INVTYPE_RELIC = "Ranged",
}
local HOVER_TEXT = "Puesto n.º %d de %d para tu nivel (%s; calculado con su tooltip, no está en la lista)."
local scoringBy = {} -- por especialización: lo necesario para puntuar un objeto suelto
local version = 0
local hoverCache, hoverKey = {}, nil

local function scoreLink(scoring, link, id)
	local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not getInstant then return nil end
	local okInfo, _, _, _, equipLoc = pcall(getInstant, link)
	local slot = okInfo and LOC_SLOT[equipLoc]
	if not slot then return nil end
	local row, req = statsFromLink(link)
	if not row then return nil end
	local level = (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or 1
	if req and req > level then return nil end
	local job = {
		record = scoring.record, classFile = scoring.classFile, specId = scoring.specId,
		armorClass = scoring.armorClass, weightsAt = scoring.weightsAt, bands = {}, stats = {},
	}
	local e = newEntry(scoring.classFile, scoring.record.base, nil, nil,
		{ id = id, slot = slot, hand = HAND_OF[equipLoc] }, level, level, nil, nil)
	consumeWith(GQ.Custom, job, e, row)
	for _, band in pairs(job.bands) do
		local list = band.slots[slot]
		if list and list[1] then return list[1].pipelineScore, slot end
	end
end

local function scoresFor(scoring, slot)
	local cache = hoverCache.scores
	if not cache then
		cache = {}
		hoverCache.scores = cache
	end
	if cache[slot] then return cache[slot] end
	local best = {}
	for _, e in ipairs(GQ.Data.entries or {}) do
		if e.customSpec == scoring.specId and e.slot == slot and type(e.pipelineScore) == "number"
			and GQ.Data.EntryMatchesPlayerBand and GQ.Data:EntryMatchesPlayerBand(e) then
			local k = tostring(e.itemId) .. ":" .. tostring(e.suffix or "")
			if not best[k] or best[k] < e.pipelineScore then best[k] = e.pipelineScore end
		end
	end
	local list = {}
	for _, score in pairs(best) do list[#list + 1] = score end
	table.sort(list, function(x, y) return x > y end)
	cache[slot] = list
	return list
end

-- Lo que GearQuest no puntúa para tu clase (o tu facción) se queda con su texto.
local function refused(text)
	local L = GQ.L or {}
	return text == L["GearQuest is not scoring this item for your class."]
		or text == L["Not ranked for your class."] or text == L["Not ranked for your faction."]
end

local function hoverText(link, gqText)
	if type(link) ~= "string" or refused(gqText) then return nil end
	local classFile = playerClass()
	local scoring = classFile and GQ.Spec and GQ.Spec.GetDisplaySpec and scoringBy[GQ.Spec:GetDisplaySpec(classFile) or ""]
	if not scoring then return nil end
	local id = GQ.Data.ItemLinkToId and GQ.Data:ItemLinkToId(link)
	if not id then return nil end
	local okKey, band = pcall(GQ.Data.GetActiveBandCacheKey, GQ.Data)
	local key = version .. ":" .. (okKey and tostring(band) or "")
	if key ~= hoverKey then
		hoverCache, hoverKey = {}, key
	end
	local hit = hoverCache[link]
	if hit ~= nil then return hit or nil end
	local ok, score, slot = pcall(scoreLink, scoring, link, id)
	local text = false
	if ok and type(score) == "number" then
		local list = scoresFor(scoring, slot)
		local rank = 1
		for i = 1, #list do
			if list[i] > score then rank = rank + 1 else break end
		end
		text = string.format(HOVER_TEXT, rank, #list + 1, scoring.record.name or "?")
	end
	hoverCache[link] = text
	return text or nil
end

local function hookGearQuest()
	if GQ.Custom._tuEquipoHooked or leveoPresent() then return end
	GQ.Custom._tuEquipoHooked = true
	local finish = GQ.Custom.Finish
	GQ.Custom.Finish = function(self, job, ...)
		if job and job.record and job.specId and job.classFile == playerClass() then
			scoringBy[job.specId] = {
				record = job.record, classFile = job.classFile, specId = job.specId,
				armorClass = job.armorClass, weightsAt = job.weightsAt,
			}
			version = version + 1
		end
		local ok, err = pcall(addEquipped, self, job)
		if not ok and not self._tuEquipoWarned then
			self._tuEquipoWarned = true
			print("|cffff8800GearQuest: con tu equipo|r: no he podido añadir tu equipo (" .. tostring(err) .. ").")
		end
		return finish(self, job, ...)
	end
	-- «Sin puesto para c:1» → «Sin puesto para Fuego leveo»; y lo que puedes llevar y no está en
	-- la lista, con el puesto que tendría.
	if GQ.Data and GQ.Data.GearScoreMissText then
		local miss = GQ.Data.GearScoreMissText
		GQ.Data.GearScoreMissText = function(self, link, ...)
			local text = miss(self, link, ...)
			if text then
				local ok, mine = pcall(hoverText, link, text)
				if ok and mine then return mine end
			end
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

-- Ventana para elegir qué pesos usa cada especialización -----------------------------------
-- cfg: frameName, title, intro, mainTitle, secondTitle, hint, mainOptions(), secondOptions(),
-- get() -> principal, segunda; set(principal|nil, segunda|nil); onClose().
local function buildChooser(cfg)
	local ok, f = pcall(CreateFrame, "Frame", cfg.frameName, UIParent, "BasicFrameTemplateWithInset")
	if not (ok and f) then f = CreateFrame("Frame", cfg.frameName, UIParent) end
	f:Hide()
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetPoint("CENTER")
	if f.TitleText then f.TitleText:SetText(cfg.title) end
	if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, cfg.frameName) end -- Esc la cierra
	local W, PAD, COLS, BW, BH = 470, 16, 3, 142, 22
	local y = -32
	local function text(font, body)
		local fs = f:CreateFontString(nil, "OVERLAY", font)
		fs:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
		fs:SetWidth(W - 2 * PAD)
		fs:SetJustifyH("LEFT")
		fs:SetText(body)
		local h = fs.GetStringHeight and fs:GetStringHeight()
		y = y - ((type(h) == "number" and h > 0) and h or 28) - 10
		return fs
	end
	text("GameFontHighlightSmall", cfg.intro)
	local function group(title, options, onPick)
		local head = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		head:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, y)
		head:SetText(title)
		y = y - 20
		local buttons = {}
		for i, opt in ipairs(options) do
			local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
			b:SetSize(BW, BH)
			local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
			b:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + col * (BW + 6), y - row * (BH + 4))
			b:SetText(opt.label)
			b.optId = opt.id
			b:SetScript("OnClick", function() onPick(opt.id) end)
			buttons[#buttons + 1] = b
		end
		y = y - math.ceil(#options / COLS) * (BH + 4) - 10
		return buttons
	end
	f.mainButtons = group(cfg.mainTitle, cfg.mainOptions(), function(id) cfg.set(id, nil); f:Refresh() end)
	f.secondButtons = group(cfg.secondTitle, cfg.secondOptions(), function(id) cfg.set(nil, id); f:Refresh() end)
	text("GameFontDisableSmall", cfg.hint)
	local done = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	done:SetSize(110, 22)
	done:SetPoint("TOP", f, "TOP", 0, y)
	done:SetText("Listo")
	done:SetScript("OnClick", function() f:Hide() end)
	f:SetSize(W, -(y - 22 - PAD))
	local function mark(buttons, selected)
		for _, b in ipairs(buttons) do
			local fs = b.GetFontString and b:GetFontString()
			if b.optId == selected then
				b:LockHighlight()
				if fs then fs:SetTextColor(0.25, 1, 0.25) end
			else
				b:UnlockHighlight()
				if fs then fs:SetTextColor(1, 0.82, 0) end
			end
		end
	end
	function f:Refresh()
		local main, second = cfg.get()
		mark(self.mainButtons, main)
		mark(self.secondButtons, second)
	end
	f:SetScript("OnShow", function(self) self:Refresh() end)
	f:SetScript("OnHide", function() if cfg.onClose then cfg.onClose() end end)
	return f
end

-- Un botón más en la lista de la izquierda de GearQuest → Ajustes, debajo de «Donaciones».
local function hookSettingsButton(GQ, flag, label, onClick)
	if not (GQ and GQ.Log and GQ.Log.EnsureSettingsPage and hooksecurefunc) or GQ.Log[flag] then return end
	GQ.Log[flag] = true
	hooksecurefunc(GQ.Log, "EnsureSettingsPage", function(_, frame)
		pcall(function()
			local list, after = frame and frame.settingsList, frame and frame.settingsDonationsBtn
			if not (list and after) or frame.gqPesosBtn then return end
			local b = CreateFrame("Button", nil, list)
			b:SetHeight(22)
			b:SetPoint("TOPLEFT", after, "BOTTOMLEFT", 0, -2)
			b:SetPoint("TOPRIGHT", after, "BOTTOMRIGHT", 0, -2)
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			fs:SetPoint("LEFT", b, "LEFT", 8, 0)
			fs:SetPoint("RIGHT", b, "RIGHT", -8, 0)
			fs:SetJustifyH("LEFT")
			fs:SetText(label)
			local hover = b:CreateTexture(nil, "HIGHLIGHT")
			hover:SetAllPoints()
			hover:SetColorTexture(0.62, 0.50, 0.18, 0.55)
			b:SetHighlightTexture(hover)
			b:SetScript("OnClick", onClick)
			frame.gqPesosBtn = b
		end)
	end)
end

local chooser
local function showChooser()
	if InCombatLockdown and InCombatLockdown() then
		print("|cffff8800GearQuest: con tu equipo|r: espera a salir de combate.")
		return
	end
	local classFile = playerClass()
	if not classFile then return end
	if not chooser then
		local specs = specOptions(classFile)
		local main = { { id = "auto", label = "Según mis talentos" } }
		local second = { { id = "same", label = "La misma" }, { id = "auto", label = "Según mis talentos" } }
		for _, opt in ipairs(specs) do
			main[#main + 1] = opt
			second[#second + 1] = opt
		end
		chooser = buildChooser({
			frameName = "GearQuestTuEquipoPesos",
			title = "GearQuest: con tu equipo",
			intro = "Elige con qué rama puntúa GearQuest tu equipo. Son sus pesos con unos ajustes para "
				.. "subir de nivel (varitas, crítico y golpe de los lanzadores). «Según mis talentos» "
				.. "elige sola la rama en la que tengas más puntos.\n\nSi tienes doble especialización, "
				.. "elige también la segunda: al cambiar de especialización en el juego, GearQuest pasa a "
				.. "los puestos de la otra al momento.",
			mainTitle = "Especialización principal",
			secondTitle = "Segunda especialización",
			hint = "Lo puedes cambiar cuando quieras: GearQuest → Ajustes → Pesos y especialización.",
			mainOptions = function() return main end,
			secondOptions = function() return second end,
			get = function() local d = settings() return d.main, d.second end,
			set = function(m, sec)
				local d = settings()
				if m then d.main = m end
				if sec then d.second = sec end
				later(0.2)
			end,
		})
	end
	settings().asked = true
	chooser:Show()
end
hookSettingsButton(GQ, "_tuEquipoPesosHooked", "Pesos y especialización", function() showChooser() end)

-- La primera vez que entras con el addon (y ya tienes talentos), te pregunta.
local function maybeAsk(tries)
	local d = settings()
	if d.asked then return end
	local level = UnitLevel and UnitLevel("player") or 0
	if level < 10 then return end
	if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then
		if (tries or 0) < 20 then C_Timer.After(15, function() maybeAsk((tries or 0) + 1) end) end
		return
	end
	if #specOptions(playerClass() or "") == 0 then return end
	showChooser()
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
			C_Timer.After(12, function() maybeAsk(0) end)
		end
	end
end)
