-- Pawn: arreglos para Forever (addon propio, 2026-11-13)
--
-- 1) Textos. Pawn 2.14.1 busca en los objetos los textos del Classic de
--    siempre, pero Forever en español escribe otros (los TOOLTIP_ITEM_STAT_* de
--    sus GlobalStrings): «Aumenta hasta 6 p. el daño infligido con hechizos y
--    efectos de las Sombras.», «+5 resistencia a Fuego»... Pawn no los entendía
--    y esas estadísticas le valían 0. Aquí se añaden AL FINAL de su tabla de
--    expresiones (PawnRegexes), con los mismos nombres de estadística que usa
--    Pawn para los textos antiguos. No se cambia ni se quita ninguna suya, y
--    los archivos de Pawn no se tocan: actualizar Pawn no borra esto.
--
-- 2) Escalas. Las escalas que trae Pawn para Classic (Haw's Jon) son de nivel
--    máximo: la varita vale 0 y el espíritu pesa 4 veces lo que el aguante.
--    Aquí se crea el proveedor «Polestar (subir de nivel)» con los pesos que
--    usa Polestar para tu clase, tu nivel y tu raza (Polestar.Gear), una escala
--    por especialización. La primera vez en cada personaje se muestran estas y
--    se esconden las de serie; después se puede cambiar a mano en Pawn.
--    Si Polestar falta o cambia, se usan los últimos pesos guardados.
--
-- wow-addons-actualizar prueba cada Pawn nuevo con este addon fuera del juego
-- (~/.local/share/wow-addons/pruebas/pawn); si deja de entender estas líneas,
-- no instala esa versión de Pawn.

local ADDON = ...

PawnForeverES = {}
local M = PawnForeverES

-- Un número, igual que lo pone Pawn en sus textos (TooltipParsing.lua).
local NUMERO = "(-?[%%d%%., ]+)"

-- { patrón de Lua con «#» por cada número, estadística, número, estadística, número... }
-- El número es cuál de los «#» se lee (1, 2...); en negativo, se resta.
local LINEAS_ES = {
	-- Daño y sanación con hechizos (el más común: más de 1.000 objetos)
	{ "^Equipar: Aumenta hasta # p%. el daño infligido y la sanación realizada con hechizos y efectos mágicos%.$", "SpellDamage", 1, "Healing", 1 },
	{ "^Equipar: Reduce hasta # p%. el daño infligido y la sanación realizada con hechizos y efectos mágicos%.$", "SpellDamage", -1, "Healing", -1 },
	-- Solo daño con hechizos (el «Aumenta» ya lo entiende Pawn)
	{ "^Equipar: Reduce hasta # p%. el daño infligido con hechizos y efectos mágicos%.$", "SpellDamage", -1 },
	-- Solo sanación
	{ "^Equipar: Aumenta hasta # p%. la sanación realizada con hechizos y efectos mágicos%.$", "Healing", 1 },
	{ "^Equipar: Reduce hasta # p%. la sanación realizada con hechizos y efectos mágicos%.$", "Healing", -1 },
	-- Sanación y daño con números distintos
	{ "^Equipar: Aumenta hasta # p%. la sanación realizada y hasta # p%. el daño infligido con todos los hechizos y efectos mágicos%.$", "Healing", 1, "SpellDamage", 2 },
	{ "^Equipar: Aumenta hasta # p%. la sanación que realizas y reduce hasta # p%. el daño que infliges con todos los hechizos y efectos mágicos%.$", "Healing", 1, "SpellDamage", -2 },
	{ "^Equipar: Reduce hasta # p%. la sanación que realizas y aumenta hasta # p%. el daño que infliges con todos los hechizos y efectos mágicos%.$", "Healing", -1, "SpellDamage", 2 },
	{ "^Equipar: Reduce hasta # p%. la sanación realizada y hasta # p%. el daño infligido con todos los hechizos y efectos mágicos%.$", "Healing", -1, "SpellDamage", -2 },
	-- Arma, escudo, perforación y celeridad
	{ "^Equipar: %+?# p%. de daño de arma%.$", "MinDamage", 1, "MaxDamage", 1 },
	{ "^Equipar: Aumenta # p%. el valor de bloqueo de tu escudo%.$", "BlockValue", 1 },
	{ "^Equipar: Reduce # p%. el valor de bloqueo de tu escudo%.$", "BlockValue", -1 },
	{ "^Equipar: Tus hechizos perforan # p%. de resistencia mágica%.$", "SpellPenetration", 1 },
	{ "^Equipar: Tus hechizos perforan # p%. menos de resistencia mágica%.$", "SpellPenetration", -1 },
	{ "^Equipar: Tus ataques perforan hasta # p%. de armadura%.$", "ArmorPenetration", 1 },
	{ "^Equipar: Tus ataques perforan hasta # p%. menos de armadura%.$", "ArmorPenetration", -1 },
	{ "^Equipar: Aumenta un #%% tus velocidades de ataque y de lanzamiento de hechizos%.$", "HasteRating", 1, "SpellHasteRating", 1 },
	{ "^Equipar: Reduce un #%% tus velocidades de ataque y de lanzamiento de hechizos%.$", "HasteRating", -1, "SpellHasteRating", -1 },
	-- Lo que Pawn ya entiende cuando sube, pero no cuando baja
	{ "^Equipar: Reduce un #%% tu probabilidad de golpear%.$", "HitRating", -1, "SpellHitRating", -1 },
	{ "^Equipar: Reduce un #%% tu probabilidad de conseguir un golpe crítico%.$", "CritRating", -1, "SpellCritRating", -1 },
	{ "^Equipar: Reduce # p%. la regeneración de maná cada 5 s%.$", "Mp5", -1 },
	{ "^Equipar: Reduce # p%. la regeneración de salud cada 5 s%.$", "Hp5", -1 },
	{ "^Equipar: Defensa reducida # p%.$", "DefenseRating", -1 },
	{ "^Equipar: # p%. de poder de ataque%.$", "Ap", 1 },
	{ "^Equipar: # p%. de poder de ataque a distancia%.$", "Rap", 1 },
	{ "^Equipar: Aumenta un #%% la probabilidad de que esquiven o paren tus ataques%.$", "ExpertiseRating", -1 },
	{ "^Equipar: Reduce un #%% la probabilidad de esquivar un ataque%.$", "DodgeRating", -1 },
	{ "^Equipar: Reduce un #%% la probabilidad de parar un ataque%.$", "ParryRating", -1 },
	{ "^Equipar: Reduce un #%% la probabilidad de bloquear ataques con un escudo%.$", "BlockRating", -1 },
	-- Armadura extra
	{ "^%+?# p%. de armadura$", "Armor", 1 },
	{ "^%+?# bonus de armadura$", "Armor", 1 },
	-- Todas las resistencias
	{ "^%+?# a todas las resistencias$", "ArcaneResist", 1, "FireResist", 1, "FrostResist", 1, "NatureResist", 1, "ShadowResist", 1 },
	-- Como los escribe Wowhead, por si el juego los pone así en algún objeto
	{ "^Restaura %+# p%. de maná cada 5 s%.?$", "Mp5", 1 },
	{ "^Restaura %+# p%. de salud cada 5 s%.?$", "Hp5", 1 },
	{ "^Aumenta el poder de ataque a distancia %+# p%.$", "Rap", 1 },
	{ "^Aumenta el valor de bloqueo de tu escudo %+# p%.$", "BlockValue", 1 },
}
-- Daño de una sola escuela
for _, e in ipairs({
	{ "Sagrados", "HolySpellDamage" }, { "de Fuego", "FireSpellDamage" }, { "de Naturaleza", "NatureSpellDamage" },
	{ "de Escarcha", "FrostSpellDamage" }, { "Arcanos", "ArcaneSpellDamage" }, { "de las Sombras", "ShadowSpellDamage" },
}) do
	tinsert(LINEAS_ES, { "^Equipar: Aumenta hasta # p%. el daño infligido con hechizos y efectos " .. e[1] .. "%.$", e[2], 1 })
	tinsert(LINEAS_ES, { "^Equipar: Reduce hasta # p%. el daño infligido con hechizos y efectos " .. e[1] .. "%.$", e[2], -1 })
end
-- Resistencias (Pawn las busca como «+5 Fuego Resistencia», el texto de Classic Era)
for _, r in ipairs({
	{ "Fuego", "FireResist" }, { "Escarcha", "FrostResist" }, { "Naturaleza", "NatureResist" },
	{ "Sombras", "ShadowResist" }, { "Arcano", "ArcaneResist" },
}) do
	tinsert(LINEAS_ES, { "^%+?# resistencia a " .. r[1] .. "$", r[2], 1 })
end
M.LINEAS_ES = LINEAS_ES

local avisos = {}
local function avisar(texto)
	avisos[#avisos + 1] = texto
end
M.avisos = avisos

-- 1) Textos --------------------------------------------------------------

function M.AnadirLineas()
	local loc = GetLocale()
	if loc ~= "esES" and loc ~= "esMX" then return 0 end
	if type(PawnRegexes) ~= "table" or PawnMultipleStatsExtract == nil then
		avisar("Pawn ha cambiado por dentro (no encuentro PawnRegexes): no puedo enseñarle los textos de Forever.")
		return 0
	end
	local n = 0
	for _, d in ipairs(LINEAS_ES) do
		local entrada = { (gsub(d[1], "#", NUMERO)) }
		for i = 2, #d, 2 do
			entrada[#entrada + 1] = d[i]
			entrada[#entrada + 1] = d[i + 1]
			entrada[#entrada + 1] = PawnMultipleStatsExtract
		end
		PawnRegexes[#PawnRegexes + 1] = entrada
		n = n + 1
	end
	M.lineasAnadidas = n
	return n
end

M.AnadirLineas()

-- 2) Escalas de subir de nivel ---------------------------------------------

local PROVEEDOR = "PolestarNivel"
M.PROVEEDOR = PROVEEDOR
local COLORES = { "b08cff", "8fa8ff", "ff9a5c" }

local function copiar(t)
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end

-- Pesos de Polestar (sus claves: sta, int, rdps...) con los nombres de Pawn.
local function pesosDePolestar(clase, clave, nivel)
	local G = type(Polestar) == "table" and Polestar.Gear
	if not (G and type(G.WeightsFor) == "function" and type(G.PAWN_STATS) == "table") then return nil end
	local ok, w = pcall(G.WeightsFor, clase, clave, nivel)
	if not ok or type(w) ~= "table" then return nil end
	-- Rasgos raciales que Polestar cuenta multiplicando una estadística
	-- (gnomo: +5 % de intelecto).
	local mult = {}
	if type(G.GetRacial) == "function" then
		local ok2, r = pcall(G.GetRacial)
		if ok2 and type(r) == "table" and type(r.statMult) == "table" then mult = r.statMult end
	end
	local nombre = {}
	for _, e in ipairs(G.PAWN_STATS) do
		if not e.generic and type(e.to) == "table" and #e.to == 1 and nombre[e.to[1]] == nil then
			nombre[e.to[1]] = e.pawn
		end
	end
	local v = {}
	for k, x in pairs(w) do
		local n = nombre[k]
		if n and type(x) == "number" and x ~= 0 then
			v[n] = x * (tonumber(mult[k]) or 1)
		end
	end
	return next(v) and v or nil
end

-- Lista de { clave, indice, valores } para la clase del personaje.
local function escalasDeLaClase(nivel)
	local _, clase, idClase = UnitClass("player")
	local db = PawnForeverESDB
	db.pesos = db.pesos or {}
	local lista = {}
	local G = type(Polestar) == "table" and Polestar.Gear
	local info = G and type(G.CLASSES) == "table" and G.CLASSES[clase]
	if info and type(info.specs) == "table" then
		for i, s in ipairs(info.specs) do
			local v = s.key and pesosDePolestar(clase, s.key, nivel)
			if v then lista[#lista + 1] = { clave = s.key, indice = i, valores = v } end
		end
	end
	if #lista > 0 then
		local guardar = {}
		for i, e in ipairs(lista) do guardar[i] = { clave = e.clave, indice = e.indice, valores = copiar(e.valores) } end
		db.pesos[clase] = { nivel = nivel, lista = guardar }
	elseif db.pesos[clase] then
		lista = db.pesos[clase].lista
		avisar("Polestar no me da sus pesos: uso los últimos guardados (nivel " .. tostring(db.pesos[clase].nivel) .. ").")
	end
	return lista, clase, idClase
end

function M.PonerEscalas(nivel)
	nivel = nivel or UnitLevel("player") or 1
	local lista, clase, idClase = escalasDeLaClase(nivel)
	local n = 0
	for _, e in ipairs(lista) do
		local nombreEsp
		if PawnGetSpecializationInfoForClassID then
			local ok, _, nom = pcall(PawnGetSpecializationInfoForClassID, idClase, e.indice)
			if ok then nombreEsp = nom end
		end
		PawnAddPluginScale(PROVEEDOR, clase .. "-" .. e.clave, (nombreEsp or e.clave) .. " (nivel)",
			COLORES[e.indice] or "b08cff", copiar(e.valores))
		n = n + 1
	end
	M.escalasPuestas = n
	return n
end

-- La primera vez en cada personaje: se ven estas y no las de serie de Pawn.
function M.Visibilidad()
	local db = PawnForeverESDB
	if db.visibilidadHecha then return true end
	if not (PawnIsInitialized and type(PawnCommon) == "table" and type(PawnCommon.Scales) == "table" and PawnSetScaleVisible) then
		return false
	end
	local _, clase = UnitClass("player")
	local mias = {}
	for nombre, escala in pairs(PawnCommon.Scales) do
		if escala.Provider == PROVEEDOR and escala.ProviderActive and escala.Values
			and strfind(nombre, ":" .. clase .. "-", 1, true) then
			mias[#mias + 1] = nombre
		end
	end
	if #mias == 0 then return false end
	for _, nombre in ipairs(mias) do PawnSetScaleVisible(nombre, true) end
	for nombre, escala in pairs(PawnCommon.Scales) do
		if escala.Provider == "Classic" then PawnSetScaleVisible(nombre, false) end
	end
	db.visibilidadHecha = true
	return true
end

local function contarAvisos()
	if #avisos == 0 or not DEFAULT_CHAT_FRAME then return end
	for _, t in ipairs(avisos) do
		DEFAULT_CHAT_FRAME:AddMessage("|cffb08cffPawn (arreglos de Forever):|r " .. t)
	end
	wipe(avisos)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:SetScript("OnEvent", function(self, evento, arg1)
	if evento == "ADDON_LOADED" and arg1 == ADDON then
		self:UnregisterEvent("ADDON_LOADED")
		PawnForeverESDB = type(PawnForeverESDB) == "table" and PawnForeverESDB or {}
		if type(PawnAddPluginScaleProvider) == "function" and type(PawnAddPluginScale) == "function" then
			PawnAddPluginScaleProvider(PROVEEDOR, "Polestar (subir de nivel)", function()
				local ok, err = pcall(M.PonerEscalas)
				if not ok then avisar("no he podido poner las escalas: " .. tostring(err)) end
			end)
		else
			avisar("Pawn ha cambiado por dentro (no encuentro PawnAddPluginScale): no puedo poner las escalas de Polestar.")
		end
	elseif evento == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		local intentos = 0
		local function probar()
			intentos = intentos + 1
			local ok, hecho = pcall(M.Visibilidad)
			if ok and not hecho and intentos < 10 then
				C_Timer.After(3, probar)
			else
				contarAvisos()
			end
		end
		C_Timer.After(2, probar)
	elseif evento == "PLAYER_LEVEL_UP" then
		-- Los pesos de Polestar cambian con el nivel (a 60, otra tabla).
		local nivel = tonumber(arg1)
		C_Timer.After(1, function()
			if not PawnScaleProvidersInitialized then return end
			local ok = pcall(M.PonerEscalas, nivel)
			if ok then
				if PawnResetTooltips then pcall(PawnResetTooltips) end
				if PawnInvalidateBestItems then pcall(PawnInvalidateBestItems) end
			end
			contarAvisos()
		end)
	end
end)
