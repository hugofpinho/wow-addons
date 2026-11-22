-- Polestar: probabilidad real (PolestarProbabilidad)
--
-- Polestar enseña cuánto suelta cada enemigo un objeto de misión (en la lista de enemigos de
-- abajo, al pasar el ratón por una fila, y en el recuadro del enemigo si se activa en sus
-- opciones), pero muchas veces no lo sabe (los objetos nuevos de Forever salen a 0) o el
-- número es de otro sitio: de Classic contando muertes de gente sin la misión (sale bajo) o
-- un 80 % de relleno de la base de datos del servidor (sale alto).
--
-- Este addon cambia ese número por el real:
--   * lo que miden en Forever los jugadores de EG Link (Datos.lua, lo genera
--     ~/.local/bin/wow-probabilidad-datos): solo muertes de quien tenía la misión;
--   * lo que te cae a ti: apunta cada enemigo que matas (tú o tu esbirro) mientras tienes la
--     misión sin acabar, y si al abrirlo estaba el objeto (PolestarProbabilidadDB). Sin el
--     registro de combate (en Forever es solo de Blizzard): ver «Tus muertes».
-- Las muertes de EG Link en grupo salen más bajas (EG Link las apunta a todas las misiones
-- del registro): se usan solo si no hay 10 muertes a solas, y se avisa.
-- Con pocas muertes de un enemigo, su número se apoya en la media de todos los que lo
-- sueltan (10 muertes «de prueba» con la media).
--
-- Además añade al recuadro de cada enemigo una línea por objeto que te falta y que suelta,
-- con el porcentaje y cuántas muertes hay detrás.
--
-- Solo lee: no toca los datos de Polestar (envuelve dos funciones de Polestar.QuestDB) ni
-- nada de Blizzard. En Forever algunos valores pueden ser «secretos» (en combate): se ignoran.

-- 1.2 (2026-11-21): la lista de enemigos de Polestar no pregunta la probabilidad cuando el
-- paso de la guía trae sus propios enemigos por punto (`fromNpcsAt`: los Velasangre del Barril
-- de tabaco), y la fila salía sin %. Ahora se rellena aquí (ver «La lista de enemigos»).

local VERSION = "1.2"
local DATOS = PolestarProbabilidad_Datos or {}
local EG = DATOS.objetos or {}
local MISIONES = DATOS.misiones or {}

local K = 10          -- muertes «de prueba» con la media del objeto
local MIN = 10        -- muertes para fiarse de la media del objeto
local PROPIAS_SOLAS = 20 -- muertes de un enemigo a partir de las que no se mezcla con la media

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

local DB -- PolestarProbabilidadDB.propios[objeto][enemigo] = { caídas, muertes }
local Q  -- Polestar.QuestDB
local origDroppers, origChance

---------------------------------------------------------------------------
-- La cuenta
---------------------------------------------------------------------------

local function propias(itemID)
	return DB and DB.propios[itemID]
end

-- Polestar sabe que este enemigo lo suelta (aunque no sepa cuánto).
local function polestarLoSabe(itemID, npcID)
	return origChance and call(origChance, itemID, npcID) ~= nil
end

local function conocido(itemID, npcID)
	local e, p = EG[itemID], propias(itemID)
	return (e and e[npcID]) or (p and p[npcID]) or polestarLoSabe(itemID, npcID)
end

-- Por enemigo: { caídas solas, muertes solas, caídas grupo, muertes grupo, tuyas caídas, tuyas muertes }
local function filas(itemID)
	local out = {}
	local e = EG[itemID]
	if e then
		for npc, r in pairs(e) do out[npc] = { r[1], r[2], r[3], r[4], 0, 0 } end
	end
	local p = propias(itemID)
	if p then
		for npc, r in pairs(p) do
			local f = out[npc] or { 0, 0, 0, 0, 0, 0 }
			f[5], f[6] = r[1], r[2]
			out[npc] = f
		end
	end
	return out
end

-- Probabilidad en % de que npcID suelte itemID por muerte (con la misión), y cómo se sacó:
-- { d, n (de este enemigo), D, N (de todos), tuyasD, tuyasN, grupo, pocos, fuente }.
-- polestar: lo que dice Polestar (o nil). nil si no hay nada.
local function estimar(itemID, npcID, polestar, rows)
	rows = rows or filas(itemID)
	local D, N = 0, 0
	for _, f in pairs(rows) do D, N = D + f[1] + f[5], N + f[2] + f[6] end
	local grupo = false
	if N < MIN then
		local Dg, Ng = D, N
		for _, f in pairs(rows) do Dg, Ng = Dg + f[3], Ng + f[4] end
		if Ng > N then grupo, D, N = true, Dg, Ng end
	end
	local f = rows[npcID]
	local info = { D = D, N = N, grupo = grupo, pocos = N < MIN, tuyasD = f and f[5] or 0, tuyasN = f and f[6] or 0 }
	if N < 5 and type(polestar) == "number" and polestar > 0 then
		info.fuente = "polestar"
		return polestar, info
	end
	if N == 0 then return nil, info end
	local d, n = 0, 0
	if f then
		d, n = f[1] + f[5], f[2] + f[6]
		if grupo then d, n = d + f[3], n + f[4] end
	end
	info.d, info.n, info.fuente = d, n, "real"
	local p
	if n >= PROPIAS_SOLAS then
		p = d / n
	else
		p = (d + K * D / N) / (n + K)
	end
	return 100 * p, info
end

---------------------------------------------------------------------------
-- Polestar
---------------------------------------------------------------------------

local function nombreNpc(npcID)
	local N = Polestar and Polestar.Names
	local name = N and N.Npc and call(N.Npc, npcID)
	if type(name) == "string" and name ~= "" then return name end
	local rec = Q and Q.NpcRecord and call(Q.NpcRecord, npcID)
	if type(rec) == "table" and type(rec[1]) == "string" then return rec[1] end
	return nil
end

local function nombreObjeto(itemID)
	local name = C_Item and C_Item.GetItemNameByID and call(C_Item.GetItemNameByID, itemID)
	if type(name) ~= "string" or name == "" then name = GetItemInfo and (call(GetItemInfo, itemID)) end
	if type(name) ~= "string" or name == "" then
		local N = Polestar and Polestar.Names
		name = N and N.Item and call(N.Item, itemID)
	end
	return type(name) == "string" and name ~= "" and name or ("objeto " .. itemID)
end

-- Envuelve Polestar.QuestDB.GetItemDroppers y GetDropChance: quien los llame (la lista de
-- enemigos, el recuadro, el motor de la guía) recibe el número real.
local function envolver()
	Q = Polestar and Polestar.QuestDB
	if not Q or Q._probabilidadReal or type(Q.GetItemDroppers) ~= "function" or type(Q.GetDropChance) ~= "function" then return end
	Q._probabilidadReal = VERSION
	origDroppers, origChance = Q.GetItemDroppers, Q.GetDropChance

	Q.GetItemDroppers = function(itemID)
		local list = origDroppers(itemID)
		if not itemID or not (EG[itemID] or propias(itemID)) then return list end
		local rows = filas(itemID)
		local out, seen = {}, {}
		for i, e in ipairs(type(list) == "table" and list or {}) do
			local pct = estimar(itemID, e.id, e.chance, rows)
			out[#out + 1] = { id = e.id, name = e.name, chance = pct or e.chance, orden = i }
			seen[e.id] = true
		end
		-- Los que Polestar no tiene y que se ha visto soltarlo.
		for npc, f in pairs(rows) do
			if not seen[npc] and f[1] + f[3] + f[5] > 0 then
				out[#out + 1] = { id = npc, name = nombreNpc(npc), chance = (estimar(itemID, npc, nil, rows)), orden = 1000 + npc }
			end
		end
		if #out == 0 then return list end
		table.sort(out, function(a, b)
			local ca, cb = a.chance or 0, b.chance or 0
			if ca ~= cb then return ca > cb end
			return a.orden < b.orden
		end)
		for _, e in ipairs(out) do e.orden = nil end
		return out
	end

	Q.GetDropChance = function(itemID, npcID)
		local c = origChance(itemID, npcID)
		local e, p = EG[itemID], propias(itemID)
		if c == nil and not ((e and e[npcID]) or (p and p[npcID])) then return nil end
		local pct = estimar(itemID, npcID, c)
		return pct or c
	end
end

---------------------------------------------------------------------------
-- Qué te falta
---------------------------------------------------------------------------

local necesarios, sucio = {}, true

-- objeto -> misión, de los objetivos de objeto sin acabar del registro.
local function calcularNecesarios()
	local need = {}
	local QL = C_QuestLog
	if not (QL and QL.GetNumQuestLogEntries and QL.GetInfo and QL.GetQuestObjectives) then return need end
	for i = 1, ok(call(QL.GetNumQuestLogEntries)) or 0 do
		local info = call(QL.GetInfo, i)
		local q = type(info) == "table" and not ok(info.isHeader) and ok(info.questID)
		local orden = q and MISIONES[q]
		if not orden and q and Q and Q.QuestRecord then
			-- Misión que Datos.lua no tiene (Polestar más nuevo): su registro, si está cargado.
			local rec = call(Q.QuestRecord, q)
			local obj = type(rec) == "table" and rec[12]
			if type(obj) == "table" then
				orden = {}
				for k = 1, #obj, 3 do orden[#orden + 1] = obj[k] == 2 and obj[k + 1] or 0 end
			end
		end
		if orden then
			local objs = call(QL.GetQuestObjectives, q)
			if type(objs) == "table" then
				for oi, o in ipairs(objs) do
					local it, tipo = orden[oi], ok(o.type)
					if it and it ~= 0 and (tipo == nil or tipo == "item") and ok(o.finished) == false then need[it] = q end
				end
			end
		end
	end
	return need
end

local function objetosQueTeFaltan()
	if sucio then necesarios, sucio = calcularNecesarios(), false end
	return necesarios
end

---------------------------------------------------------------------------
-- La lista de enemigos
---------------------------------------------------------------------------

-- Cada fila de la lista de Polestar (PolestarTargetRow1, 2…) guarda en `info` el enemigo
-- (npc), el nombre del objeto que suelta para el paso (item) y su probabilidad (chance), que
-- es lo que enseña al pasar el ratón por la fila. Polestar solo rellena `chance` cuando saca
-- los enemigos de su base de datos; si los trae la propia guía, se queda vacía. Aquí se le
-- pone la misma que da GetDropChance (la real, o la de Polestar si no hay datos). Solo se
-- escribe ese número, y solo si falta.
local MAX_FILAS = 40

local function rellenarLista()
	if not Q or type(Q.GetDropChance) ~= "function" then return 0 end
	local need, puestas = nil, 0
	for i = 1, MAX_FILAS do
		local r = _G["PolestarTargetRow" .. i]
		if type(r) ~= "table" then break end
		local info = r.info
		if type(info) == "table" and type(info.npc) == "number" and type(info.item) == "string"
			and not (type(info.chance) == "number" and info.chance > 0) then
			need = need or objetosQueTeFaltan()
			-- El objeto de la fila: el que te falta con ese nombre; si el nombre no casa (otro
			-- idioma en los datos de Polestar), el único que te falta y que suelta ese enemigo.
			local elegido, unico, cuantos = nil, nil, 0
			for it in pairs(need) do
				if conocido(it, info.npc) then
					cuantos, unico = cuantos + 1, it
					if nombreObjeto(it) == info.item then elegido = it end
				end
			end
			elegido = elegido or (cuantos == 1 and unico) or nil
			local pct = elegido and call(Q.GetDropChance, elegido, info.npc)
			if type(pct) == "number" and pct > 0 then
				info.chance = pct
				puestas = puestas + 1
			end
		end
	end
	return puestas
end

---------------------------------------------------------------------------
-- Tus muertes
---------------------------------------------------------------------------

-- En Forever los addons no pueden escuchar el registro de combate (COMBAT_LOG_EVENT_UNFILTERED
-- está reservado a Blizzard: registrarlo saca el aviso de «acción bloqueada»). Así que se miran
-- los enemigos que el juego deja ver (objetivo, foco, objetivo del esbirro, placas de nombre…):
-- uno que pelea contigo o con tu esbirro y que se ve muerto poco después cuenta como muerte tuya.
-- Solo cuentan las muertes vistas al momento (no al pasar el ratón por un cadáver un rato
-- después), para no contar más los cadáveres con botín, que son los que uno va a mirar.

local vivos = {}      -- guid -> { t = última vez que se le vio vivo peleando contigo, denegado }
local pendientes = {} -- guid -> { npc, items = { objeto, ... }, abierto }
local VENTANA = 5     -- s entre verlo vivo peleando contigo y verlo muerto
local ultimoCombate = -math.huge

local FIJOS = { "target", "focus", "pettarget", "softenemy", "mouseover" }
local PLACAS = {}
for i = 1, 40 do PLACAS[i] = "nameplate" .. i end

local function npcDeGUID(guid)
	guid = ok(guid)
	if type(guid) ~= "string" then return nil end
	local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
	if kind ~= "Creature" then return nil end
	return tonumber(id)
end

local function apuntar(itemID, npcID, cayo)
	local t = DB.propios[itemID]
	if not t then t = {}; DB.propios[itemID] = t end
	local r = t[npcID]
	if not r then r = { 0, 0 }; t[npcID] = r end
	r[1], r[2] = r[1] + (cayo and 1 or 0), r[2] + 1
end

local function cerrar(guid, cayeron)
	local p = pendientes[guid]
	pendientes[guid] = nil
	if not (p and DB) then return end
	for _, it in ipairs(p.items) do
		local cayo = cayeron and cayeron[it]
		if cayo or conocido(it, p.npc) then apuntar(it, p.npc, cayo) end
	end
end

local function sinBotin(guid)
	if not CanLootUnit then return nil end
	local success, hasLoot = pcall(CanLootUnit, guid)
	if not success then return nil end
	hasLoot = ok(hasLoot)
	if hasLoot == nil then return nil end
	return not hasLoot
end

local function muerto(guid)
	local npc = npcDeGUID(guid)
	if not npc or pendientes[guid] then return end
	local items = {}
	for it in pairs(objetosQueTeFaltan()) do items[#items + 1] = it end
	if #items == 0 then return end
	pendientes[guid] = { npc = npc, items = items }
	-- Cadáver sin nada para ti: muerte sin el objeto. Se mira dos veces por si el botín
	-- tarda en llegar; si tiene botín, se espera a que lo abras.
	C_Timer.After(1.5, function()
		local p = pendientes[guid]
		if not p or p.abierto or sinBotin(guid) ~= true then return end
		C_Timer.After(2.5, function()
			local p2 = pendientes[guid]
			if p2 and not p2.abierto and sinBotin(guid) == true then cerrar(guid, nil) end
		end)
	end)
	-- Si no lo abres en 3 minutos, no cuenta (ni a favor ni en contra).
	C_Timer.After(180, function()
		local p = pendientes[guid]
		if p and not p.abierto then pendientes[guid] = nil end
	end)
end

-- ¿Pelea contigo o con tu esbirro? (en su lista de amenaza, o te tiene a ti o al esbirro de objetivo)
local function peleaContigo(u)
	if ok(call(UnitThreatSituation, "player", u)) ~= nil then return true end
	if ok(call(UnitExists, "pet")) and ok(call(UnitThreatSituation, "pet", u)) ~= nil then return true end
	if ok(call(UnitAffectingCombat, u)) then
		local tt = u .. "target"
		if ok(call(UnitIsUnit, tt, "player")) or ok(call(UnitIsUnit, tt, "pet")) then return true end
	end
	return false
end

local function mirar(u, now)
	if not ok(call(UnitExists, u)) then return end
	local g = ok(call(UnitGUID, u))
	if not npcDeGUID(g) then return end
	local e = vivos[g]
	if ok(call(UnitIsDead, u)) then
		if e then
			vivos[g] = nil
			if now - e.t <= VENTANA and not e.denegado then muerto(g) end
		end
		return
	end
	if not e and not ok(call(UnitCanAttack, "player", u)) then return end
	if peleaContigo(u) then
		if not e then e = {}; vivos[g] = e end
		e.t = now
	end
	-- Si lo ha marcado otro jugador (no podrás abrirlo), no cuenta.
	if e then
		local denied = ok(call(UnitIsTapDenied, u))
		if denied ~= nil then e.denegado = denied and true or false end
	end
end

local function explorar()
	if not DB then return end
	if not next(objetosQueTeFaltan()) then
		if next(vivos) then wipe(vivos) end
		return
	end
	local now = GetTime()
	if ok(call(UnitAffectingCombat, "player")) or ok(call(UnitAffectingCombat, "pet")) then ultimoCombate = now end
	if now - ultimoCombate > 10 and not next(vivos) then return end
	for _, u in ipairs(FIJOS) do mirar(u, now) end
	for _, u in ipairs(PLACAS) do mirar(u, now) end
end

-- Al morir, la vida baja a 0 (y la placa de nombre se quita): se mira en ese momento.
local function alCambiarUnidad(u)
	if type(u) ~= "string" or not next(vivos) then return end
	local g = ok(call(UnitGUID, u))
	if g and vivos[g] then mirar(u, GetTime()) end
end

local function alAbrirBotin()
	local n = ok(call(GetNumLootItems)) or 0
	local porCadaver = {}
	for slot = 1, n do
		local link = ok(call(GetLootSlotLink, slot))
		local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
		local src = { pcall(GetLootSourceInfo, slot) }
		if src[1] then
			for i = 2, #src, 2 do
				local g = ok(src[i])
				if type(g) == "string" then
					local t = porCadaver[g]
					if not t then t = {}; porCadaver[g] = t end
					if id then t[id] = true end
				end
			end
		end
	end
	for g, items in pairs(porCadaver) do
		local p = pendientes[g]
		if p and not p.abierto then
			p.abierto = true
			cerrar(g, items)
		end
	end
end

-- Limpieza de enemigos con los que dejaste de pelear (se fueron, otro los mató lejos…).
local function limpiar()
	local now = GetTime()
	for g, e in pairs(vivos) do
		if now - e.t > 60 then vivos[g] = nil end
	end
end

---------------------------------------------------------------------------
-- El recuadro del enemigo
---------------------------------------------------------------------------

local function porcentaje(p)
	if p >= 10 then return ("%d %%"):format(math.floor(p + 0.5)) end
	return (("%.1f"):format(p):gsub("%.", ",")) .. " %"
end

local function texto(pct, info)
	if not pct then return "sin datos todavía", 0.6, 0.6, 0.6 end
	if info.fuente == "polestar" then
		return porcentaje(pct) .. " (de Polestar, sin datos reales)", 0.8, 0.8, 0.8
	end
	local s = (info.pocos and "~" or "") .. porcentaje(pct)
	local function muertes(n) return n == 1 and "1 muerte" or ("%d muertes"):format(n) end
	local detalle = info.n and info.n > 0 and ("%d de %s"):format(info.d, muertes(info.n)) or ("media de %s"):format(muertes(info.N))
	if info.grupo then detalle = detalle .. ", en grupo: puede salir bajo" end
	if info.tuyasN > 0 then detalle = detalle .. (" · tú %d de %d"):format(info.tuyasD, info.tuyasN) end
	return s .. " (" .. detalle .. ")", 1, 1, 1
end

local ultimo = {}

local function alRecuadro(tooltip, data)
	if tooltip ~= GameTooltip or not DB then return end
	if tooltip.IsForbidden and call(tooltip.IsForbidden, tooltip) ~= false then return end
	local guid = ok(type(data) == "table" and data.guid)
	local npc = npcDeGUID(guid)
	if not npc then return end
	local lines = ok(call(tooltip.NumLines, tooltip))
	if ultimo.guid == guid and lines and ultimo.lines and lines >= ultimo.lines then return end
	local added = 0
	for it in pairs(objetosQueTeFaltan()) do
		local pol = origChance and call(origChance, it, npc)
		local e, p = EG[it], propias(it)
		if pol ~= nil or (e and e[npc]) or (p and p[npc]) then
			local pct, info = estimar(it, npc, pol)
			local t, r, g, b = texto(pct, info)
			tooltip:AddDoubleLine(nombreObjeto(it), t, 1, 0.82, 0, r, g, b)
			added = added + 1
		end
	end
	if added > 0 then
		ultimo.guid, ultimo.lines = guid, ok(call(tooltip.NumLines, tooltip))
	end
end

---------------------------------------------------------------------------
-- /probabilidad: lo de cada objeto que te falta, por chat
---------------------------------------------------------------------------

local function listar()
	local any = false
	for it in pairs(objetosQueTeFaltan()) do
		local list = Q and call(Q.GetItemDroppers, it)
		if type(list) == "table" and #list > 0 then
			any = true
			print("|cffffd200" .. nombreObjeto(it) .. "|r")
			local rows = filas(it)
			for _, e in ipairs(list) do
				local pol = origChance and call(origChance, it, e.id)
				local pct, info = estimar(it, e.id, pol, rows)
				print("   " .. (e.name or nombreNpc(e.id) or ("PNJ " .. e.id)) .. ": " .. (texto(pct, info)))
			end
		end
	end
	if not any then print("Polestar: probabilidad real: no te falta ningún objeto que suelten enemigos.") end
	print(("Datos de EG Link del %s (%s), CC BY 4.0."):format(DATOS.fecha or "?", DATOS.commit or "?"))
end

---------------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= "PolestarProbabilidad" then return end
		PolestarProbabilidadDB = type(PolestarProbabilidadDB) == "table" and PolestarProbabilidadDB or {}
		DB = PolestarProbabilidadDB
		DB.version = 1
		DB.propios = type(DB.propios) == "table" and DB.propios or {}
		envolver()
	elseif event == "PLAYER_LOGIN" then
		envolver()
		local P, T = TooltipDataProcessor, Enum and Enum.TooltipDataType
		if P and P.AddTooltipPostCall and T and T.Unit then
			P.AddTooltipPostCall(T.Unit, function(tooltip, data) pcall(alRecuadro, tooltip, data) end)
		end
		-- Ojo: nada de COMBAT_LOG_EVENT_UNFILTERED (en Forever es solo de Blizzard).
		for _, ev in ipairs({ "LOOT_READY", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED",
			"PLAYER_REGEN_ENABLED", "UNIT_HEALTH", "NAME_PLATE_UNIT_REMOVED" }) do
			pcall(self.RegisterEvent, self, ev)
		end
		if C_Timer and C_Timer.NewTicker then
			local vuelta = 0
			C_Timer.NewTicker(0.25, function()
				pcall(explorar)
				vuelta = vuelta + 1
				if vuelta % 2 == 0 then pcall(rellenarLista) end -- cada 0,5 s
			end)
		end
	elseif event == "UNIT_HEALTH" or event == "NAME_PLATE_UNIT_REMOVED" then
		pcall(alCambiarUnidad, arg1)
	elseif event == "LOOT_READY" then
		pcall(alAbrirBotin)
	elseif event == "PLAYER_REGEN_ENABLED" then
		limpiar()
	else
		sucio = true
	end
end)

SLASH_POLESTARPROBABILIDAD1 = "/probabilidad"
SlashCmdList.POLESTARPROBABILIDAD = listar
