-- GearQuest: con tu equipo 1.4 (2026-11-22)
--
-- 1.4: el pícaro, por manos y por ramas. GearQuest puntúa las armas del pícaro igual en las
--   tres ramas y da a la mano izquierda el mismo valor que a la derecha (su código lo dice:
--   «An off-hand weapon keeps the full weapon-damage weight»), y el tooltip de un arma de una
--   mano solo la compara con la de la derecha. Ahora, en las especializaciones de este addon:
--   · Mano izquierda: 1 de daño por segundo vale lo que mide ForeverSim (simulador de Forever,
--     sus pesos vienen en Does It Die Plus) frente a la derecha: Combate 0,29, Sutileza 0,36 y
--     Asesinato 0,56 (Mutilar golpea con las dos; sin dagas, como Sutileza).
--   · Mano derecha: los golpes especiales (Golpe siniestro, Hemorragia…) suman el golpe del
--     arma, así que un arma lenta pega más en cada uno (las guías de Combate de Forever: lenta
--     en la derecha, rápida en la izquierda). Sutileza: Hemorragia hace el 145 % con daga.
--     Asesinato desde el 30 (Mutilar, que pide dagas en las dos manos): lo que no es daga vale
--     menos.
--   · El tooltip de un arma de una mano dice además su puesto en la mano izquierda y si es
--     mejor o peor que lo que llevas en esa mano.
--   Las cifras y de dónde sale cada una, en la tabla PICARO.
--   Mago: el daño de cada escuela según la rama, con lo que mide ForeverSim (la rama Arcana de
--   GearQuest valoraba el daño Arcano en 0,5 y el de Escarcha en 0,35; el simulador, 0,92 y 0,08).
--   Las dos manos del mago (arma y objeto de la izquierda frente a bastón) ya las junta GearQuest.
--
-- 1.3: los objetos de sufijo aleatorio salen dos veces. Con su mejor sufijo, como lo pone
--   GearQuest («Cinta real de ira de las sombras», la n.º 1 si te toca), pero diciendo que es
--   SOLO con ese sufijo y cuántas veces sale; y sin sufijo («Cinta real»), con la nota media de
--   todos sus sufijos, que es lo que vale la que te cae normalmente. La aclaración va en la
--   línea «Encantamiento aleatorio» del tooltip y de la ficha.
--   Pesos nuevos: brujo de Aflicción completos y chamán de Mejora (fuerza por delante).
--
-- 1.2:
--   · Todo lo que existe. GearQuest trae unas decenas de objetos por hueco y nivel. Ahora, en
--     el tramo de tu nivel de cada hueco, entra además todo lo que puedes llevar a tu nivel: lo
--     de las tablas de estadísticas de GearQuest y, si tienes Polestar, lo de su Polestar_ItemDB
--     (sin lo que la revisión de Forever de GearQuest da por inexistente, lo de otras clases ni
--     lo que es solo de la otra facción). Qué tipos de armadura y de arma entran en cada hueco
--     lo dice el propio GearQuest: los que ya lista para tu clase en ese hueco.
--   · Sufijos de Forever. En Forever el sufijo aleatorio («de cólera de las Sombras») va en el
--     enlace como «bonus», no en el campo clásico, que es el único que mira GearQuest: una
--     pieza con sufijo se puntuaba como el objeto pelado. Ahora cuenta como «con sufijo» por el
--     campo clásico, por el nombre o por llevar bonus, y su puesto sale de su tooltip. El
--     puesto calculado dice además si es mejor o peor que lo que llevas en ese hueco.
--   · Sin congelar el juego. Añadir todo esto se hacía de una vez al cerrar GearQuest su
--     puntuación (más de un segundo parado). Ahora va a trozos de 3 ms, por el mismo sitio por
--     el que GearQuest reparte lo suyo (una «fila fantasma» al final de sus filas).
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
--   Brujo de Aflicción (1.2): los pesos completos de un plan de subida con Drenar vida de
--   relleno y la varita solo para rematar, sacados estadística por estadística de guías de
--   Forever (Crix, Skill Capped, Warcraft Tavern). 1 punto = 1 de daño de Sombras; aguante,
--   intelecto y espíritu 0,5 (vida y maná son el combustible de Transfusión de vida); Fuego
--   0,2 (solo Inmolar); varita 0,3 por punto de daño por segundo. Como van todos escritos, no
--   pasan por el multiplicador de subida de nivel de GearQuest.
--   Chamán de Mejora (1.2): las guías de subida de Forever (wow.gg, Warcraft Tavern, Icy Veins)
--   coinciden en arma a dos manos y en poner la fuerza por delante de la agilidad; GearQuest
--   trae la agilidad por delante (pesos de banda). Se cambian solo esas dos; daño del arma,
--   golpe y crítico se quedan como los trae GearQuest. Las guías no coinciden en el resto.
--   Cuerpo a cuerpo (salvo eso), cazadores, tanques y sanadores: los de GearQuest.
--   Mago (1.4): el daño de cada escuela según la rama, de ForeverSim (simulador de Forever,
--   27-09-2026, builds de nivel 60; sus pesos vienen en Does It Die Plus), por cada punto de daño
--   con hechizos: Arcano 0,92 de Arcano y 0,08 de Escarcha; Fuego 1 de Fuego; Escarcha 1 de
--   Escarcha; las demás escuelas, 0. GearQuest trae Arcano 0,5 y Escarcha 0,35 en la rama Arcana
--   (el Arcano por debajo de la mitad de lo que mide el simulador) y 0,92 + 0,03 de la otra en
--   Fuego y Escarcha. El Mago de batalla usa los de su escuela. Intelecto, espíritu y maná se
--   quedan como los trae GearQuest (con su multiplicador de subida de nivel): ForeverSim los mide
--   en peleas de banda, no subiendo de nivel con descansos.
local MAGO_ARCANO = { spArcane = 0.9238, spFrost = 0.0762, spFire = 0 }
local MAGO_FUEGO = { spFire = 1, spFrost = 0, spArcane = 0 }
local MAGO_ESCARCHA = { spFrost = 1, spFire = 0, spArcane = 0 }
local function con(base, extra)
	local t = {}
	for k, v in pairs(base) do t[k] = v end
	for k, v in pairs(extra) do t[k] = v end
	return t
end
local LEVELING = {
	MAGE = {
		arcane = con({ crit = 0.2, hit = 0.4, dpsWeightRanged = 1 }, MAGO_ARCANO),
		fire = con({ crit = 0.3, hit = 0.4, dpsWeightRanged = 1 }, MAGO_FUEGO),
		frost = con({ crit = 0.2, hit = 0.4, dpsWeightRanged = 1 }, MAGO_ESCARCHA),
		battlemage_arcane = con({ crit = 0.2, hit = 0.4, dpsWeightRanged = 1 }, MAGO_ARCANO),
		battlemage_fire = con({ crit = 0.3, hit = 0.4, dpsWeightRanged = 1 }, MAGO_FUEGO),
		battlemage_frost = con({ crit = 0.2, hit = 0.4, dpsWeightRanged = 1 }, MAGO_ESCARCHA),
	},
	PRIEST = {
		shadow = { crit = 0.2, hit = 0.4, dpsWeightRanged = 2 },
		holy = { dpsWeightRanged = 2.5 },
		discipline = { dpsWeightRanged = 2.5 },
	},
	WARLOCK = {
		affliction = {
			sp = 1, spShadow = 1, spFire = 0.2, spFrost = 0, spArcane = 0, spNature = 0, spHoly = 0,
			spi = 0.5, sta = 0.5, int = 0.5, mp5 = 0.8, armor = 0.01,
			crit = 4 / CRIT_UNIT, hit = 1 / HIT_UNIT, haste = 1 / CRIT_UNIT,
			health = 0.05, hp5 = 0.1, mana = 0.033, resist = 0,
			str = 0, agi = 0, ap = 0, rap = 0, defense = 0, dodge = 0, parry = 0,
			heal = 0, sp_from_heal = 0,
			dpsWeight = 0, dpsWeightRanged = 0.3, speedWeight = 0,
		},
		demonology = { crit = 0.2, hit = 0.4, int = 0.5, dpsWeightRanged = 1 },
		destruction = { crit = 0.3, hit = 0.4, int = 0.5, dpsWeightRanged = 0.7 },
	},
	DRUID = { balance = { crit = 0.2, hit = 0.4 } },
	SHAMAN = { elemental = { crit = 0.25, hit = 0.4 }, enhancement = { str = 1, agi = 0.75 } },
}
local function levelingFor(classFile, base)
	local byClass = LEVELING[classFile]
	return byClass and byClass[base] or {}
end

-- Pícaro: las armas según la mano y la rama (1.4). GearQuest suma por cada arma «daño por
-- segundo × dpsWeight» (15 en las tres ramas), en las dos manos igual. Aquí ese término se
-- cambia por «dpsWeight × valor», con valor:
--   mano izquierda: daño por segundo × izquierda[rama]
--   mano derecha:   daño por segundo × (1 + golpes × (velocidad × daga[rama] − velocidadMedia))
-- y en Asesinato desde nivelMutilar, × sinMutilar si no es daga. Lo demás (estadísticas, efectos
-- al golpear) se queda como lo puntúa GearQuest.
local PICARO = {
	-- Cuánto vale 1 de daño por segundo en la mano izquierda frente a la derecha. ForeverSim
	-- (lozstokes.co.uk/foreversim, sobre los simuladores de WoWSims para Forever), ejecución del
	-- 27-09-2026 con builds de nivel 60, tal como la trae Does It Die Plus (StatsInfo/Weights.lua):
	-- Combate 3,188 / 11,021; Sutileza 3,581 / 10,034; Asesinato (con Mutilar) 4,488 / 8,047.
	izquierda = { combat = 3.188 / 11.021, subtlety = 3.581 / 10.034, assassination = 4.488 / 8.047 },
	-- Asesinato sin Mutilar (antes del 30, o con algo que no sea daga en esa mano): como Sutileza.
	izquierdaSinMutilar = 3.581 / 10.034,
	-- Golpes especiales por segundo que suman el golpe del arma de la derecha (Golpe siniestro,
	-- Hemorragia, Puñalada): 10 de energía por segundo, unos dos tercios a golpes de 40-45 de
	-- energía. Es una estimación mía: ninguna guía da la cifra.
	golpes = 0.15,
	-- Velocidad de referencia (la media de un arma de una mano): más lenta suma y más rápida resta.
	velocidadMedia = 2.4,
	-- Sutileza: Hemorragia hace el 145 % del arma con daga y el 100 % con otra cosa (Conquest Capped,
	-- talentos de Forever; el anuncio de Blizzard solo dice que con daga pega más).
	daga = { subtlety = 1.45 },
	-- Asesinato: Mutilar es el talento de 21 puntos (desde el 30) y pide dagas en las dos manos
	-- (anuncio de Blizzard). Con otra arma te quedas sin él: un 15 % menos (estimación mía: Mutilar
	-- golpea con las dos armas por el 90 % + 40 y da 2 puntos de combo por 60 de energía, Golpe
	-- siniestro 1 por 40-45; sale entre un 15 y un 20 % más de daño, sin contar los puntos de combo).
	nivelMutilar = 30,
	sinMutilar = 0.85,
}
local DAGA = 2 * 100 + 15 -- clase de objeto (clase × 100 + subclase): arma, daga

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

local builtSig = {}   -- por especialización: firma (equipo y nivel) con la que se puntuó
local tooltipReq = {} -- nivel requerido leído del tooltip, por objeto
local UNLISTED = "No está en las listas de GearQuest: lo ha añadido «GearQuest: con tu equipo»."

-- Reparto entre fotogramas (1.2). Lo pesado corre en una corrutina; `deadline` es hasta cuándo
-- puede seguir en este fotograma (debugprofilestop, en ms). Sin `deadline` (el camino de una
-- vez) respirar() no hace nada. `dentro`: este addon está mandando sus filas a GQ.Custom:Consume.
local SLICE_MS = 3
local deadline
local dentro = false
local function respirar()
	if deadline and debugprofilestop() >= deadline then coroutine.yield() end
end

local function nivelActual()
	return (GQ.GetEffectiveLevel and GQ:GetEffectiveLevel()) or (UnitLevel and UnitLevel("player")) or 1
end

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
		if not e.sourceType then
			e.sourceType = "unsourced"
			e.instructions = UNLISTED
		end
		e.hand = item.hand or handOf(item.id)
	end
	e.tuEquipoAll = item.all or nil
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

-- Número de «bonus» del enlace (campo 13 de «item:…»). En Forever el sufijo aleatorio es un bonus.
local function bonusCount(link)
	local fields = type(link) == "string" and link:match("item:([%-%d:]+)")
	if not fields then return 0 end
	local i = 0
	for field in (fields .. ":"):gmatch("([^:]*):") do
		i = i + 1
		if i == 13 then return tonumber(field) or 0 end
	end
	return 0
end

-- ¿La pieza de este enlace lleva sufijo aleatorio? Por el campo clásico del enlace, por el
-- nombre (más largo que el del objeto base) o por llevar bonus.
local function isRolled(id, link)
	if type(link) ~= "string" then return false end
	if GQ.Data.SuffixIdFromLink and GQ.Data:SuffixIdFromLink(link) then return true end
	if suffixOf(id, link) then return true end
	return bonusCount(link) > 0
end

-- Antes de GQ.Custom:Finish, con las filas de la especialización ya puntuadas y
-- repartidas por tramos (job.bands), sin ordenar todavía.
local function addEquipped(custom, job)
	local classFile = playerClass()
	if not (job and job.record and job.classFile == classFile and job.specId) then return end
	if not (GQ.Data and GQ.Data.CopyEntry and custom.Consume) then return end
	local base = job.record.base
	local items = equipped()
	if #items == 0 or not base then return end
	local stats = job.stats or GQ.Data.itemStats or {}
	job.stats = stats

	local wanted = {}
	for _, item in ipairs(items) do wanted[item.id .. "|" .. item.slot] = true end
	local templates = {}
	for i, e in ipairs(job.entries or {}) do
		if i % 500 == 0 then respirar() end
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
		respirar()
		local key = item.id .. "|" .. item.slot
		if not done[key] then
			done[key] = true
			local link = equippedLink(item.inv)
			local rolled = link and isRolled(item.id, link)
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
									if type(other.itemId) == "number" and math.floor(other.itemId) == item.id then
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
local HOVER_TEXT = "Puesto n.º %d de %d para tu nivel (%s; calculado con su tooltip)."
local HOVER_BETTER = "|cff40ff40Mejor que lo que llevas: +%s.|r"
local HOVER_WORSE = "|cffff5050Peor que lo que llevas: -%s.|r"
local HOVER_SAME = "Igual que lo que llevas."
local scoringBy = {} -- por especialización: lo necesario para puntuar un objeto suelto
local version = 0
local hoverCache, hoverKey = {}, nil

-- Todo lo que existe (1.2) --------------------------------------------------------------

-- Clase en las máscaras de clase de los objetos.
local CLASS_BIT = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024 }
-- Estadísticas de Polestar_ItemDB → las de GearQuest. Crítico y golpe vienen en % y GearQuest
-- los cuenta en sus unidades. Un objeto con una estadística que no esté aquí no se añade:
-- mejor que falte a que salga mal puntuado.
local PS_KEY = {
	armor = "armor", sta = "sta", int = "int", spi = "spi", str = "str", agi = "agi",
	sp = "damageDone", heal = "heal", spShadow = "spShadow", spFire = "spFire", spFrost = "spFrost",
	spArcane = "spArcane", spNature = "spNature", spHoly = "spHoly", spellHit = "spellHit",
	spellCrit = "spellCrit", crit = "crit", hit = "hit", mp5 = "mp5", hp5 = "hp5",
	defense = "defense", dodge = "dodge", parry = "parry", ap = "ap", rap = "rap",
	blockValue = "blockValue", block = "blockPct", dps = "dps",
}
local PS_UNIT = { spellCrit = CRIT_UNIT, crit = CRIT_UNIT, spellHit = HIT_UNIT, hit = HIT_UNIT }
local ARMOR_KIND = { [1] = "Cloth", [2] = "Leather", [3] = "Mail", [4] = "Plate", [7] = "Libram", [8] = "Idol", [9] = "Totem" }

-- Hueco, tipo de equipo y «clase de objeto» (armadura de tela, espada de una mano…: clase y
-- subclase del juego en un número) de un objeto, o nil si no se equipa o el juego no lo conoce.
local function kindOf(id)
	local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not getInstant then return nil end
	local ok, _, _, _, equipLoc, _, classID, subclassID = pcall(getInstant, id)
	if not ok then return nil end
	local slot = LOC_SLOT[equipLoc]
	if not slot or type(classID) ~= "number" or type(subclassID) ~= "number" then return nil end
	return slot, equipLoc, classID * 100 + subclassID
end

-- Pícaro (1.4) ------------------------------------------------------------------------------

local esDagaCache = {}
local function esDaga(id)
	id = type(id) == "number" and math.floor(id) or id
	local hit = esDagaCache[id]
	if hit == nil then
		local _, _, kind = kindOf(id)
		hit = kind == DAGA
		esDagaCache[id] = hit
	end
	return hit
end

-- Lo que vale el arma en esa mano para esa rama, en «daño por segundo» de GearQuest (ver PICARO).
local function valorArma(base, slot, dps, speed, daga, nivel)
	local mutilar = base == "assassination" and (nivel or 1) >= PICARO.nivelMutilar
	if slot == "SecondaryHand" then
		local r = PICARO.izquierda[base] or 0.5
		if base == "assassination" and not (mutilar and daga) then r = PICARO.izquierdaSinMutilar end
		return dps * r
	end
	if not (type(speed) == "number" and speed > 0) then speed = PICARO.velocidadMedia end
	local m = daga and PICARO.daga[base] or 1
	local v = dps * (1 + PICARO.golpes * (speed * m - PICARO.velocidadMedia))
	if mutilar and not daga then v = v * PICARO.sinMutilar end
	return v
end

local function armaDePicaro(job, entry)
	return type(job) == "table" and job.classFile == "ROGUE" and job.record and job.record.tuEquipo
		and PICARO.izquierda[job.record.base] ~= nil and type(job.weightsAt) == "function"
		and type(entry) == "table" and (entry.slot == "MainHand" or entry.slot == "SecondaryHand") or false
end

-- La fila recién puntuada por GearQuest: cambia su «daño por segundo × dpsWeight» por el de esa mano.
local function ajustarArma(job, entry, fila)
	local row = job.stats and job.stats[math.floor(entry.itemId)]
	local dps = row and tonumber(row.dps) or 0
	if dps <= 0 or type(fila.pipelineScore) ~= "number" then return end
	local _, weight = job.weightsAt(entry.minLevel or 1)
	weight = tonumber(weight) or 0
	if weight == 0 then return end
	local valor = valorArma(job.record.base, entry.slot, dps, tonumber(row.spd), esDaga(entry.itemId), entry.minLevel or 1)
	fila.pipelineScore = math.floor((fila.pipelineScore + weight * (valor - dps)) * 100 + 0.5) / 100
	fila.tuEquipoMano = entry.slot
end

-- Polestar_ItemDB trae las estadísticas de todos los objetos que se pueden equipar, pero no
-- deja listarlos: se apuntan sus números al registrarse (es un addon que se carga a petición).
local polestarIds
local catalog, catalogKinds -- lo que puedes llevar, y con qué clases de objeto se hizo la lista
local function watchPolestar()
	local DB = _G.Polestar and _G.Polestar.ItemDB
	if not (DB and DB.Register) or DB._tuEquipoWatch then return end
	DB._tuEquipoWatch = true
	if DB.IsLoaded and DB.IsLoaded() then return end -- ya cargado: no se puede listar
	local register = DB.Register
	DB.Register = function(m, items, ...)
		if type(items) == "table" then
			polestarIds = polestarIds or {}
			for id in pairs(items) do
				if type(id) == "number" then polestarIds[id] = true end
			end
			catalog = nil
		end
		return register(m, items, ...)
	end
end
watchPolestar()

local function rowFromPolestar(rec)
	local row, any = {}, false
	for key, value in pairs(rec.stats or {}) do
		if type(value) == "number" and value ~= 0 then
			local mine = PS_KEY[key]
			if not mine then return nil end
			row[mine] = value * (PS_UNIT[key] or 1)
			any = true
		end
	end
	if not any then return nil end
	if rec.speed then row.spd = rec.speed / 1000 end
	if rec.class == 4 then row.kind = ARMOR_KIND[rec.subclass] end
	row.ilvl = rec.ilvl
	return row
end

-- ¿Lo puede conseguir tu facción? Polestar sabe de qué misiones sale cada recompensa y de qué
-- bando es cada misión. Si no sabe nada, lo que GearQuest solo lista para la otra facción no entra.
local OTHER_SIDE = { Alliance = 2, Horde = 1 }
local function factionOk(DB, id, classFile)
	local faction = UnitFactionGroup and UnitFactionGroup("player")
	local other = OTHER_SIDE[faction]
	if not other then return true end
	if DB and DB.Sources and polestarIds and polestarIds[id] then
		local ok, sources = pcall(DB.Sources, id)
		if ok and type(sources) == "table" and sources[1] then
			for _, src in ipairs(sources) do
				if src.kind ~= "quest" or src.side ~= other then return true end
			end
			return false
		end
	end
	local okRows, otherRows = false, nil
	if GQ.Data.UnexpandedRowSpecs then okRows, otherRows = pcall(GQ.Data.UnexpandedRowSpecs, GQ.Data, id) end
	if okRows and otherRows then
		local rows = GQ.Data.GetEntriesByItemId and GQ.Data:GetEntriesByItemId(id) or {}
		for _, e in ipairs(rows) do
			if not e.customSpec and e.classes and e.classes[classFile] then return true end
		end
		return false
	end
	return true
end

-- Todo lo que existe de las clases de objeto `kinds` y que tu clase y tu facción pueden tener.
local function buildCatalog(classFile, kinds)
	local list, seen = {}, {}
	local stats = GQ.Data.itemStats or {}
	local DB = _G.Polestar and _G.Polestar.ItemDB
	local band = bit and bit.band
	local classBit = CLASS_BIT[classFile]
	local function consider(id)
		if seen[id] then return end
		seen[id] = true
		local slot, equipLoc, kind = kindOf(id)
		if not slot or not kinds[kind] then return end
		-- GearQuest tiene revisado qué objetos del clásico no existen en Forever: esos fuera. De
		-- lo que solo trae Polestar, entra lo que esa revisión da por bueno y lo nuevo de Forever.
		local okStatus, status = false, nil
		if GQ.Data.GetForeverStatus then okStatus, status = pcall(GQ.Data.GetForeverStatus, GQ.Data, id) end
		if okStatus and status == "missing" then return end
		if not stats[id] and status ~= "ok" and id < 200000 then return end
		local rec = polestarIds and polestarIds[id] and DB and DB.Get and DB.Get(id) or nil
		if rec and band and classBit and rec.allow and rec.allow ~= 0 and band(rec.allow, classBit) == 0 then return end
		if not factionOk(DB, id, classFile) then return end
		local row
		if not stats[id] then
			if not rec then return end
			-- Polestar se equivoca con el daño de los objetos nuevos de Forever que sanan.
			if id >= 200000 and rec.stats and rec.stats.heal then return end
			row = rowFromPolestar(rec)
			if not row then return end
		end
		local fact = GQ.Data.GetItemFact and GQ.Data:GetItemFact(id)
		local req = tonumber(fact and fact.reqLevel)
		if not req or req <= 1 then req = rec and rec.req end
		if not req or req <= 1 then
			-- Sin nivel requerido (las recompensas de misión): el de la misión, más o menos.
			local ilvl = (stats[id] and stats[id].ilvl) or (rec and rec.ilvl)
			req = ilvl and math.max(1, ilvl - 5) or 1
		end
		list[#list + 1] = { id = id, slot = slot, hand = HAND_OF[equipLoc], req = req, row = row, kind = kind, all = true }
	end
	-- Primero solo los números (rápido, de una vez: las tablas no cambian a mitad); después se
	-- mira cada objeto, soltando el fotograma cuando toca.
	local ids = {}
	for id in pairs(stats) do
		if type(id) == "number" then ids[#ids + 1] = id end
	end
	if polestarIds then
		for id in pairs(polestarIds) do ids[#ids + 1] = id end
	end
	for i = 1, #ids do
		consider(ids[i])
		if i % 25 == 0 then respirar() end
	end
	return list
end

-- Todo lo demás que existe y puedes llevar a tu nivel, en el tramo que te toca de cada hueco.
local kindNum = {} -- clase de objeto de los que GearQuest lista (false: no se sabe)
local function addAll(custom, job, level)
	local classFile, base = job.classFile, job.record and job.record.base
	if not (classFile and base and job.bands and GQ.Data and custom.Consume) then return 0 end
	local DB = _G.Polestar and _G.Polestar.ItemDB
	if DB and DB._tuEquipoWatch and not polestarIds and DB.Load and not (DB.IsLoaded and DB.IsLoaded()) then
		pcall(DB.Load)
	end
	-- Qué clases de objeto lista GearQuest para tu clase en cada hueco, en los tramos que
	-- cubren tu nivel: solo de esas se añade (un guerrero de nivel 42 no recibe túnicas ni
	-- varitas, aunque GearQuest le listara tela a nivel 5).
	local allowed, union, n = {}, {}, 0
	for _, band in pairs(job.bands) do
		if band.level <= level then
			for slot, list in pairs(band.slots) do
				local hi = band.level
				for i = 1, #list do
					local m = list[i].maxLevel
					if type(m) == "number" and m > hi then hi = m end
				end
				if hi >= level then
					local a = allowed[slot]
					if not a then a = {}; allowed[slot] = a end
					for i = 1, #list do
						local id = list[i].itemId
						local kind = kindNum[id]
						if kind == nil then
							local _, _, k = kindOf(id)
							kind = k or false
							kindNum[id] = kind
						end
						if kind then a[kind] = true; union[kind] = true end
						n = n + 1
						if n % 100 == 0 then respirar() end
					end
				end
			end
		end
	end
	if not next(union) then return 0 end
	local falta = not catalog
	for kind in pairs(union) do
		if not (catalogKinds and catalogKinds[kind]) then falta = true end
	end
	if falta then
		local kinds = {}
		for kind in pairs(catalogKinds or {}) do kinds[kind] = true end
		for kind in pairs(union) do kinds[kind] = true end
		local built = buildCatalog(classFile, kinds)
		catalog, catalogKinds = built, kinds
	end
	-- Por hueco, el tramo que cubre tu nivel (el que empieza más tarde, como GearQuest).
	local bySlot = {}
	for _, band in pairs(job.bands) do
		if band.level <= level then
			for slot, list in pairs(band.slots) do
				if list[1] then
					local hi = band.level
					for i = 1, #list do
						local m = list[i].maxLevel
						if type(m) == "number" and m > hi then hi = m end
					end
					local cur = bySlot[slot]
					if hi >= level and (not cur or band.level > cur.band.level
						or (band.level == cur.band.level and #list > #cur.list)) then
						bySlot[slot] = { band = band, list = list, hi = hi }
					end
				end
			end
		end
	end
	for _, t in pairs(bySlot) do
		t.have = {}
		for i = 1, #t.list do t.have[t.list[i].itemId] = true end
		t.factions = t.list[1].factions
	end
	local added = 0
	for _, item in ipairs(catalog) do
		respirar()
		local t = item.req <= level and bySlot[item.slot]
		if t and not t.have[item.id] and allowed[item.slot] and allowed[item.slot][item.kind] then
			t.have[item.id] = true
			local fact = GQ.Data.GetItemFact and GQ.Data:GetItemFact(item.id)
			consumeWith(custom, job, newEntry(classFile, base, nil, fact, item, t.band.level, t.hi, t.factions, nil), item.row)
			added = added + 1
		end
	end
	return added
end

-- Puesto calculado -------------------------------------------------------------------------

-- Nota de un objeto con estas estadísticas, puntuado como las filas de la lista.
local function scoreRow(scoring, id, slot, equipLoc, row)
	local level = nivelActual()
	local job = {
		record = scoring.record, classFile = scoring.classFile, specId = scoring.specId,
		armorClass = scoring.armorClass, weightsAt = scoring.weightsAt, bands = {}, stats = {},
	}
	local e = newEntry(scoring.classFile, scoring.record.base, nil, nil,
		{ id = id, slot = slot, hand = HAND_OF[equipLoc] }, level, level, nil, nil)
	local antes = dentro
	dentro = true
	local ok, err = pcall(consumeWith, GQ.Custom, job, e, row)
	dentro = antes
	if not ok then error(err, 0) end
	for _, band in pairs(job.bands) do
		local list = band.slots[slot]
		if list and list[1] then return list[1].pipelineScore end
	end
end

local function slotOfLink(x)
	local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not getInstant then return nil end
	local okInfo, _, _, _, equipLoc = pcall(getInstant, x)
	local slot = okInfo and LOC_SLOT[equipLoc]
	if not slot then return nil end
	return slot, equipLoc
end

local function scoreLink(scoring, link, id)
	local slot, equipLoc = slotOfLink(link)
	if not slot then return nil end
	local row, req = statsFromLink(link)
	if not row then return nil end
	local level = nivelActual()
	if req and req > level then return nil end
	return scoreRow(scoring, id, slot, equipLoc, row), slot, equipLoc
end

-- Nota de lo que llevas en ese hueco, con las estadísticas de su tooltip (la más baja si hay
-- dos: anillos y abalorios, que es la que cambiarías). nil si no hay con qué comparar: un
-- hueco vacío, o un arma de otro tipo (una mano contra tu arma a dos manos).
local function wornScore(scoring, slot, equipLoc)
	local cache = hoverCache.worn
	if not cache then
		cache = {}
		hoverCache.worn = cache
	end
	local twoHand = HAND_OF[equipLoc] == "two"
	local key = slot .. (twoHand and ":2" or ":1")
	if cache[key] ~= nil then return cache[key] or nil end
	local worst, complete = nil, true
	for inv = 1, 18 do
		if SLOT_OF[inv] == slot then
			local id = GetInventoryItemID and GetInventoryItemID("player", inv)
			local score
			if type(id) == "number" and not issecret(id) then
				local wornSlot, wornLoc = slotOfLink(id)
				local row = statsFromTooltip(inv)
				-- Un arma de una mano en la izquierda cuenta como de la izquierda (1.4: antes no se encontraba).
				if wornSlot ~= slot and slot == "SecondaryHand" and wornLoc == "INVTYPE_WEAPON" then wornSlot = slot end
				if wornSlot == slot and row and (slot ~= "MainHand" or (HAND_OF[wornLoc] == "two") == twoHand) then
					score = scoreRow(scoring, id, slot, wornLoc, row)
				end
			end
			if type(score) ~= "number" then
				complete = false
			elseif not worst or score < worst then
				worst = score
			end
		end
	end
	local result = complete and worst or nil
	cache[key] = result or false
	return result
end

local function decimal1(n)
	return (string.format("%.1f", n):gsub("%.", ","))
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
	local ok, score, slot, equipLoc = pcall(scoreLink, scoring, link, id)
	local text = false
	if ok and type(score) == "number" then
		local list = scoresFor(scoring, slot)
		local rank = 1
		for i = 1, #list do
			if list[i] > score then rank = rank + 1 else break end
		end
		text = string.format(HOVER_TEXT, rank, #list + 1, scoring.record.name or "?")
		local okWorn, worn = pcall(wornScore, scoring, slot, equipLoc)
		if okWorn and type(worn) == "number" then
			local diff = score - worn
			if diff >= 0.05 then
				text = text .. " " .. string.format(HOVER_BETTER, decimal1(diff))
			elseif diff <= -0.05 then
				text = text .. " " .. string.format(HOVER_WORSE, decimal1(-diff))
			else
				text = text .. " " .. HOVER_SAME
			end
		end
	end
	hoverCache[link] = text
	return text or nil
end

-- La mano izquierda en el tooltip (pícaro, 1.4) ---------------------------------------------
-- GearQuest pone el puesto de un arma de una mano en la lista de armas (la derecha) y la compara
-- con lo que llevas en la derecha. Debajo va su puesto como arma de la izquierda y si es mejor o
-- peor que lo que llevas en la izquierda, con la misma puntuación.
local IZQ_TEXT = "Mano izquierda: puesto n.º %d de %d."
local IZQ_MEJOR = "|cff40ff40Mejor que tu %s: +%s.|r"
local IZQ_PEOR = "|cffff5050Peor que tu %s: -%s.|r"
local IZQ_IGUAL = "Igual que tu %s."
local IZQ_LLEVAS = "Es la que llevas en la izquierda."
local IZQ_VACIA = "No llevas nada en la izquierda."
local SIN_MUTILAR = "|cff9d9d9dNo es una daga: con ella no puedes usar Mutilar (pide dagas en las dos manos).|r"

local function cacheAlDia()
	local okKey, band = pcall(GQ.Data.GetActiveBandCacheKey, GQ.Data)
	local key = version .. ":" .. (okKey and tostring(band) or "")
	if key ~= hoverKey then
		hoverCache, hoverKey = {}, key
	end
end

-- La mejor nota de cada objeto en la lista de la izquierda de tu especialización, a tu nivel.
local function izquierdas(scoring)
	local cache = hoverCache.izq
	if cache then return cache end
	cache = {}
	for _, e in ipairs(GQ.Data.entries or {}) do
		if e.customSpec == scoring.specId and e.slot == "SecondaryHand" and type(e.pipelineScore) == "number"
			and type(e.itemId) == "number" and GQ.Data.EntryMatchesPlayerBand and GQ.Data:EntryMatchesPlayerBand(e) then
			local id = math.floor(e.itemId)
			if not cache[id] or cache[id] < e.pipelineScore then cache[id] = e.pipelineScore end
		end
	end
	hoverCache.izq = cache
	return cache
end

-- Lo que llevas en la izquierda: { id, score }, { vacia = true } o nil si no se puede saber.
local function izquierdaPuesta(scoring)
	local cache = hoverCache.wornOff
	if cache ~= nil then return cache or nil end
	local result = false
	local id = GetInventoryItemID and GetInventoryItemID("player", 17)
	if id == nil then
		result = { vacia = true }
	elseif type(id) == "number" and not issecret(id) then
		local _, loc = slotOfLink(id)
		local row = (loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONOFFHAND") and statsFromTooltip(17)
		if row then
			local ok, score = pcall(scoreRow, scoring, id, "SecondaryHand", loc, row)
			if ok and type(score) == "number" then result = { id = id, score = score } end
		end
	end
	hoverCache.wornOff = result
	return result or nil
end

-- La nota del arma en la izquierda: con las estadísticas de su enlace (su sufijo de verdad) o,
-- sin enlace, la de su fila de la izquierda en la lista.
local function notaIzquierda(scoring, id, link, entry)
	if link then
		local row, req = statsFromLink(link)
		if row and not (req and req > nivelActual()) then
			local ok, score = pcall(scoreRow, scoring, id, "SecondaryHand", "INVTYPE_WEAPON", row)
			if ok and type(score) == "number" then return score end
		end
	end
	if entry and GQ.Data.GetEntriesByItemId then
		local best
		for _, e in ipairs(GQ.Data:GetEntriesByItemId(id) or {}) do
			if e.customSpec == scoring.specId and e.slot == "SecondaryHand" and (e.suffix or "") == (entry.suffix or "")
				and type(e.pipelineScore) == "number" and GQ.Data:EntryMatchesPlayerBand(e)
				and (not best or e.pipelineScore > best) then
				best = e.pipelineScore
			end
		end
		return best
	end
end

local function nombreDe(id)
	local name = GetItemInfo and GetItemInfo(id)
	if type(name) ~= "string" or issecret(name) then
		name = GQ.Data.GetItemDisplayName and GQ.Data:GetItemDisplayName(id)
	end
	return type(name) == "string" and name or "arma de la izquierda"
end

-- Texto de la mano izquierda (o nil) y una nota aparte (o nil).
local function lineaIzquierda(id, link, entry)
	local classFile = playerClass()
	if classFile ~= "ROGUE" or not (GQ.Spec and GQ.Spec.GetDisplaySpec) then return nil end
	local scoring = scoringBy[GQ.Spec:GetDisplaySpec(classFile) or ""]
	if not (scoring and scoring.record and PICARO.izquierda[scoring.record.base]) then return nil end
	local _, equipLoc = slotOfLink(link or id)
	if not (equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND") then
		return nil
	end
	cacheAlDia()
	local key = "izq:" .. tostring(link or id) .. ":" .. tostring(entry and entry.suffix or "")
	local hit = hoverCache[key]
	if hit ~= nil then return hit.text, hit.nota end
	local text, nota
	-- La línea de la izquierda, solo en las de una mano (las de solo una mano ya las compara GearQuest).
	local score = equipLoc == "INVTYPE_WEAPON" and notaIzquierda(scoring, id, link, entry) or nil
	if type(score) == "number" then
		local rank, total, enLista = 1, 0, false
		for other, s in pairs(izquierdas(scoring)) do
			total = total + 1
			if other == id then
				enLista = true
			elseif s > score + 0.005 then
				rank = rank + 1
			end
		end
		if not enLista then total = total + 1 end
		text = string.format(IZQ_TEXT, rank, total)
		local worn = izquierdaPuesta(scoring)
		if worn and worn.vacia then
			text = text .. " " .. IZQ_VACIA
		elseif worn and worn.id == id then
			text = text .. " " .. IZQ_LLEVAS
		elseif worn then
			local diff, name = score - worn.score, nombreDe(worn.id)
			if diff >= 0.05 then
				text = text .. " " .. string.format(IZQ_MEJOR, name, decimal1(diff))
			elseif diff <= -0.05 then
				text = text .. " " .. string.format(IZQ_PEOR, name, decimal1(-diff))
			else
				text = text .. " " .. string.format(IZQ_IGUAL, name)
			end
		end
	end
	if scoring.record.base == "assassination" and nivelActual() >= PICARO.nivelMutilar and not esDaga(id) then
		nota = SIN_MUTILAR
	end
	hoverCache[key] = { text = text, nota = nota }
	return text, nota
end

local function hookGearQuest()
	if GQ.Custom._tuEquipoHooked or leveoPresent() then return end
	GQ.Custom._tuEquipoHooked = true
	local function nuestro(job)
		return type(job) == "table" and job.record and job.specId and job.bands and job.classFile == playerClass()
	end
	local finish = GQ.Custom.Finish
	GQ.Custom.Finish = function(self, job, ...)
		if nuestro(job) then
			-- Lo añadido ya está hecho a trozos (la fila fantasma, abajo) si su estado es de estas mismas listas.
			local st = job._tuEquipo
			local hecho = st and st.done and st.bands == job.bands
			local level = (hecho and st.level) or nivelActual()
			local _, sig = equipped()
			builtSig[job.specId] = sig .. "|" .. tostring(level)
			scoringBy[job.specId] = {
				record = job.record, classFile = job.classFile, specId = job.specId,
				armorClass = job.armorClass, weightsAt = job.weightsAt,
			}
			local ok, err
			if hecho then
				ok, err = not st.err, st.err
			else
				local antes = dentro
				dentro = true
				ok, err = pcall(addEquipped, self, job)
				if ok then ok, err = pcall(addAll, self, job, level) end
				dentro = antes
			end
			if not ok and not self._tuEquipoWarned then
				self._tuEquipoWarned = true
				print("|cffff8800GearQuest: con tu equipo|r: no he podido añadir objetos (" .. tostring(err) .. ").")
			end
			version = version + 1
			-- Las filas «con su mejor sufijo» recuperan su número de objeto (ver arriba) y el índice
			-- de GearQuest se rehace con los números buenos.
			local res = { finish(self, job, ...) }
			local entries, arregladas = GQ.Data and GQ.Data.entries, 0
			for i = entries and #entries or 0, 1, -1 do
				local e = entries[i]
				if e.customSpec ~= job.specId then break end
				if e.tuEquipoRaro and type(e.itemId) == "number" and e.itemId % 1 ~= 0 then
					e.itemId = math.floor(e.itemId)
					arregladas = arregladas + 1
				end
			end
			if arregladas > 0 then
				if GQ.Data.BuildIndex then pcall(GQ.Data.BuildIndex, GQ.Data) end
				if GQ.Data.InvalidateQueryCache then pcall(GQ.Data.InvalidateQueryCache, GQ.Data) end
			end
			return unpack(res)
		end
		return finish(self, job, ...)
	end

	-- Sufijos aleatorios: dos filas por objeto. GearQuest (ScorePiece) se queda con el mejor de los
	-- sufijos de GQ.Data.itemRolls[objeto] = { { n = nombre, c = % de salir, r = texto,
	-- <estadística> = cantidad… }, … }, aunque salga 1 de cada 25 veces. Aquí cada objeto de
	-- sufijo aleatorio entra dos veces:
	--   · con su mejor sufijo, como lo pone GearQuest, pero marcado: «solo con este sufijo»;
	--   · sin sufijo, con la nota media de todos sus sufijos según su probabilidad (lo que te
	--     toca de media al conseguirlo). Para eso se le da a GearQuest, en vez de la lista, un
	--     único «sufijo» sin nombre con la media (cada estadística × su probabilidad): la nota
	--     es lineal en las estadísticas, así que sale la nota media.
	-- GearQuest solo deja una fila por número de objeto en cada lista (Finish): la del mejor
	-- sufijo lleva el número + 0,5 hasta que Finish acaba, y ahí se le devuelve el suyo.
	local medias = {}
	local function media(id, rolls)
		local hit = medias[id]
		if hit and hit.de == rolls then return hit.lista end
		local total = 0
		for i = 1, #rolls do total = total + (tonumber(rolls[i].c) or 0) end
		local divisor = math.max(100, total) -- si las probabilidades conocidas no llegan a 100, el resto no suma
		local m = {}
		for i = 1, #rolls do
			local prob = (tonumber(rolls[i].c) or 0) / divisor
			for key, value in pairs(rolls[i]) do
				if type(value) == "number" and key ~= "c" and key ~= "id" then m[key] = (m[key] or 0) + value * prob end
			end
		end
		local lista = { m }
		medias[id] = { de = rolls, lista = lista }
		return lista
	end
	-- La lista del trabajo donde GearQuest mete la fila de `entry` (misma clave que usa Consume).
	local function listaDe(job, entry)
		local faction = "Both"
		if entry.factions then
			local names = {}
			for name, on in pairs(entry.factions) do
				if on then names[#names + 1] = name end
			end
			table.sort(names)
			if names[1] then faction = table.concat(names, "/") end
		end
		local band = job.bands and job.bands[faction .. "|" .. tostring(entry.minLevel or 1)]
		return band and band.slots and band.slots[entry.slot or ""]
	end
	-- Pícaro (1.4): cada arma, con lo que vale en su mano y en tu rama. Va por dentro de los
	-- sufijos y de la fila fantasma, así que cuenta en todas las filas: las de GearQuest, lo que
	-- llevas puesto, todo lo que existe y el puesto calculado con el tooltip.
	local consumeArma = GQ.Custom.Consume
	if consumeArma then
		GQ.Custom.Consume = function(self, job, entry, ...)
			if not armaDePicaro(job, entry) then return consumeArma(self, job, entry, ...) end
			local lista = listaDe(job, entry)
			local n0 = lista and #lista or 0
			consumeArma(self, job, entry, ...)
			lista = lista or listaDe(job, entry)
			local fila = lista and #lista == n0 + 1 and lista[#lista] or nil
			if fila and fila.itemId == entry.itemId then ajustarArma(job, entry, fila) end
		end
	end
	-- Un arma de una mano está en las dos listas. Donde GearQuest se queda con una sola fila por
	-- objeto (la lista de armas que junta las dos manos, el tooltip), la de la derecha: la de la
	-- izquierda vale menos y la hundiría en la lista. La izquierda tiene su línea en el tooltip.
	local prefer = GQ.Data and GQ.Data.PreferEntry
	if prefer then
		GQ.Data.PreferEntry = function(self, a, b, ...)
			if type(a) == "table" and type(b) == "table" and a.tuEquipoMano and b.tuEquipoMano
				and a.tuEquipoMano ~= b.tuEquipoMano and a.customSpec == b.customSpec then
				return a.tuEquipoMano == "MainHand"
			end
			return prefer(self, a, b, ...)
		end
	end
	local consumeBase = GQ.Custom.Consume
	if consumeBase then
		GQ.Custom.Consume = function(self, job, entry, ...)
			local rolls = GQ.Data and GQ.Data.itemRolls
			local suyos = rolls and type(entry) == "table" and entry.itemId and rolls[entry.itemId]
			if not suyos or not (type(job) == "table" and job.record and job.specId and job.classFile == playerClass()) then
				return consumeBase(self, job, entry, ...)
			end
			local id = entry.itemId
			-- 1) Con su mejor sufijo, como lo hace GearQuest.
			local lista = listaDe(job, entry)
			local n0 = lista and #lista or 0
			consumeBase(self, job, entry, ...)
			lista = lista or listaDe(job, entry)
			local mejor = lista and #lista == n0 + 1 and lista[#lista] or nil
			if not (mejor and mejor.itemId == id and mejor.suffix and mejor.suffix ~= "") then return end
			-- 2) Con la media de sus sufijos.
			rolls[id] = media(id, suyos)
			local ok, err = pcall(consumeBase, self, job, entry, ...)
			rolls[id] = suyos
			if not ok then error(err, 0) end
			local med = #lista == n0 + 2 and lista[#lista] or nil
			if not (med and med.itemId == id) then return end
			if (med.pipelineScore or 0) >= (mejor.pipelineScore or 0) - 0.05 then
				table.remove(lista) -- la media no dice nada distinto: una sola fila
				return
			end
			med.suffix, med.suffixId, med.suffixChance, med.suffixRange = nil, nil, nil, nil
			med.tuEquipoMedia = { sufijo = mejor.suffix, prob = mejor.suffixChance, nota = mejor.pipelineScore }
			mejor.tuEquipoRaro = { media = med.pipelineScore }
			mejor.itemId = id + 0.5
		end
	end
	-- La aclaración va en la línea «Encantamiento aleatorio» de GearQuest (tooltip y ficha).
	local function nota1(n) return (string.format("%.1f", tonumber(n) or 0):gsub("%.", ",")) end
	if GQ.Data and GQ.Data.GetSuffixHint then
		local hintBase = GQ.Data.GetSuffixHint
		GQ.Data.GetSuffixHint = function(self, entry, ...)
			local hint = hintBase(self, entry, ...)
			if type(entry) ~= "table" then return hint end
			local raro, med = entry.tuEquipoRaro, entry.tuEquipoMedia
			if raro and hint then
				return hint .. ". SOLO con este sufijo: con cualquier otro vale menos (de media, nota "
					.. nota1(raro.media) .. " frente a " .. nota1(entry.pipelineScore) .. "). También está en la lista sin sufijo, con esa nota media"
			elseif med then
				local L = GQ.L or {}
				local nombre = med.sufijo and (L[med.sufijo] or med.sufijo) or "?"
				return "ninguno en concreto. Esta fila es la nota media de sus sufijos (" .. nota1(entry.pipelineScore)
					.. "): lo que te toca de media. Con «" .. tostring(nombre) .. "»"
					.. (med.prob and (" (sale ~" .. tostring(med.prob) .. " % de las veces)") or "")
					.. " tendría nota " .. nota1(med.nota) .. ": esa variante tiene su propia fila"
			end
			return hint
		end
	end

	-- Lo añadido, a trozos, por la «fila fantasma» (1.2).
	-- GearQuest (Pump) hace, hasta pasarse de 12 ms:  fila = la de job.i;  Consume(job, fila);
	-- job.i = job.i + 1;  y cuando job.i pasa de job.count, cierra (Finish) en esa misma
	-- llamada. Aquí se envuelve Consume: en un trabajo de tu clase que lleva Pump (job.i
	-- numérico y es el trabajo en curso) se sube job.count en 1; al llegar a esa posición (da
	-- igual qué fila le pase GearQuest: no existe) se hace un trozo de lo de aquí en una
	-- corrutina y se baja job.i en 1 para que vuelva a la misma posición. Al acabar se devuelve
	-- job.count a su valor y GearQuest cierra. `dentro` evita tomar por fantasma las filas que
	-- este addon manda a Consume.
	local consume = GQ.Custom.Consume
	if consume and type(debugprofilestop) == "function" and type(coroutine) == "table" and coroutine.create then
		GQ.Custom.Consume = function(self, job, entry, ...)
			if dentro or type(job) ~= "table" or type(job.i) ~= "number" or type(job.count) ~= "number"
				or self._job ~= job or not nuestro(job) then
				return consume(self, job, entry, ...)
			end
			local st = job._tuEquipo
			if not st or st.bands ~= job.bands or (not st.done and st.hold ~= job.count) then
				-- Trabajo nuevo, o GearQuest ha rehecho sus listas o su cuenta: fila fantasma al final.
				st = { bands = job.bands }
				job._tuEquipo = st
				job.count = job.count + 1
				st.hold = job.count
			end
			if st.done or job.i ~= st.hold then return consume(self, job, entry, ...) end
			if not st.co then
				st.level = nivelActual()
				st.co = coroutine.create(function()
					addEquipped(self, job)
					addAll(self, job, st.level)
				end)
			end
			dentro = true
			deadline = debugprofilestop() + SLICE_MS
			local ok, err = coroutine.resume(st.co)
			deadline = nil
			dentro = false
			if ok and coroutine.status(st.co) ~= "dead" then
				st.slices = (st.slices or 0) + 1
				job.i = job.i - 1 -- GearQuest le suma 1 al volver: se queda en la fila fantasma
				return
			end
			st.done, st.err = true, (not ok) and err or nil
			job.count = job.count - 1 -- la cuenta de verdad: GearQuest ve que ha acabado y cierra
		end
	end

	-- Una pieza con sufijo aleatorio no vale con la ficha del objeto pelado: se deja sin ficha
	-- y el puesto sale de su tooltip, por el camino de abajo.
	local function looseSuffix(entry, link)
		if not entry or (entry.suffix and entry.suffix ~= "") then return false end
		if not (entry.customSpec and scoringBy[entry.customSpec]) then return false end
		local ok, rolled = pcall(isRolled, entry.itemId, link)
		return ok and rolled or false
	end
	-- La fila de la mano derecha del mismo objeto (pícaro, 1.4).
	local function filaDerecha(self, entry)
		if not self.GetEntriesByItemId then return nil end
		local best
		for _, e in ipairs(self:GetEntriesByItemId(math.floor(entry.itemId)) or {}) do
			if e.customSpec == entry.customSpec and e.tuEquipoMano == "MainHand" and (e.suffix or "") == (entry.suffix or "")
				and type(e.pipelineScore) == "number" and (not self.EntryMatchesPlayerBand or self:EntryMatchesPlayerBand(e))
				and (not best or e.pipelineScore > best.pipelineScore) then
				best = e
			end
		end
		return best
	end
	local entryFor = GQ.Data and GQ.Data.EntryForItemLink
	if entryFor then
		GQ.Data.EntryForItemLink = function(self, link, ...)
			local entry = entryFor(self, link, ...)
			if entry and looseSuffix(entry, link) then return nil end
			if entry and entry.tuEquipoMano == "SecondaryHand" then
				return filaDerecha(self, entry) or entry
			end
			return entry
		end
	end
	-- «Sin puesto para c:1» → «Sin puesto para Fuego leveo»; y lo que puedes llevar y no está en
	-- la lista, con el puesto que tendría.
	if GQ.Data and GQ.Data.GearScoreMissText then
		local miss = GQ.Data.GearScoreMissText
		GQ.Data.GearScoreMissText = function(self, link, ...)
			local text = miss(self, link, ...)
			local forced = false
			if not text and entryFor then
				local okEntry, entry = pcall(entryFor, self, link)
				forced = okEntry and looseSuffix(entry, link) or false
			end
			if text or forced then
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
	-- La mano izquierda (pícaro, 1.4): una línea más, debajo de la de GearQuest, en el tooltip
	-- del objeto y al pasar por la lista.
	local function anadirIzquierda(tooltip, id, link, entry)
		if not (tooltip and tooltip.AddLine and tooltip.gqScoreLineAdded) or tooltip.tuEquipoIzq or not id then return end
		local ok, text, nota = pcall(lineaIzquierda, id, link, entry)
		if not ok or not (text or nota) then return end
		if not tooltip.tuEquipoLimpia and tooltip.HookScript then
			tooltip.tuEquipoLimpia = true
			tooltip:HookScript("OnTooltipCleared", function(t) t.tuEquipoIzq = nil end)
		end
		tooltip.tuEquipoIzq = true
		if text then tooltip:AddLine(text, 1, 0.82, 0, true) end
		if nota then tooltip:AddLine(nota, 1, 1, 1, true) end
	end
	local function enlaceDe(tooltip, id)
		if not (tooltip and tooltip.GetItem) then return nil end
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		if not ok or type(link) ~= "string" or issecret(link) then return nil end
		if id and GQ.Data.ItemLinkToId and GQ.Data:ItemLinkToId(link) ~= id then return nil end
		return link
	end
	if hooksecurefunc and GQ.Data and GQ.Data.AppendGearScoreLine then
		hooksecurefunc(GQ.Data, "AppendGearScoreLine", function(_, tooltip, entry)
			if type(entry) ~= "table" or type(entry.itemId) ~= "number" then return end
			local id = math.floor(entry.itemId)
			anadirIzquierda(tooltip, id, enlaceDe(tooltip, id), entry)
		end)
	end
	if hooksecurefunc and GQ.Data and GQ.Data.AddGearScoreToItemTooltip then
		hooksecurefunc(GQ.Data, "AddGearScoreToItemTooltip", function(self, tooltip)
			local link = enlaceDe(tooltip, nil)
			local id = link and self.ItemLinkToId and self:ItemLinkToId(link)
			if id then anadirIzquierda(tooltip, id, link, nil) end
		end)
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
	if sig == "" or (sig .. "|" .. tostring(nivelActual())) == builtSig[current] then return end
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
	"PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_LEVEL_UP", "ADDON_LOADED" }) do
	pcall(f.RegisterEvent, f, event)
end
f:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "Polestar" then watchPolestar() end
		return
	end
	if leveoPresent() and not GQ.Custom._tuEquipoHooked then return end
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		gearLater(2)
	elseif event == "PLAYER_LEVEL_UP" then
		gearLater(3) -- otro tramo de nivel: lo que entra a tu nivel cambia
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
