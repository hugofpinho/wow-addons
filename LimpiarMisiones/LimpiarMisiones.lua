-- Panel de objetivos plegado 1.1 (Huguillo, 2026-11-22; la carpeta sigue llamándose
-- LimpiarMisiones para no cambiar de addon)
--
-- El panel de objetivos («Todos los objetivos») se queda plegado. El juego no guarda si
-- lo tenías plegado (ObjectiveTrackerContainerMixin: isCollapsed = false al cargar), así
-- que al entrar y al recargar la interfaz salía desplegado. Aquí se pliega al cargar y se
-- vuelve a plegar si el juego lo despliega por su cuenta (ForceExpand). Si lo despliegas
-- tú con su botón, se queda desplegado hasta la próxima carga.
--
-- La 1.0 traía además un botón «Limpiar misiones» con la lista de misiones que sobran. Se
-- quitó en la 1.1: Polestar ya lo hace (su ventana «Haz sitio en tu registro de misiones»),
-- y lo hace mejor: mira toda la ruta, también las guías que ya pasaste, y la 1.0 solo la
-- guía activa y las siguientes.

local VERSION = "1.1"
local LM = {}
_G.LimpiarMisiones = LM

-- quiere: true = plegado (lo normal), false = lo has desplegado tú en esta sesión.
local quierePlegado = true
local enganchado = false
local esperandoCombate = false

local function panel() return _G.ObjectiveTrackerFrame end

local function plegar()
	local t = panel()
	if not (quierePlegado and t and t.SetCollapsed and t.IsCollapsed) then return false end
	if InCombatLockdown and InCombatLockdown() then
		esperandoCombate = true -- el panel lleva botones protegidos: fuera de combate
		return false
	end
	if not t:IsCollapsed() then pcall(t.SetCollapsed, t, true) end
	return true
end
LM.Plegar = plegar

local function enganchar()
	local t = panel()
	if enganchado or not (t and t.SetCollapsed and hooksecurefunc) then return enganchado end
	enganchado = true
	-- Su botón: lo que hagas tú manda hasta la próxima carga.
	local b = t.Header and t.Header.MinimizeButton
	if b and b.HookScript then
		b:HookScript("OnClick", function()
			if t.IsCollapsed then quierePlegado = t:IsCollapsed() and true or false end
		end)
	end
	-- El juego lo despliega solo (una misión nueva, un módulo que lo pide): se vuelve a plegar.
	if t.ForceExpand then
		hooksecurefunc(t, "ForceExpand", function()
			if quierePlegado and C_Timer and C_Timer.After then C_Timer.After(0, plegar) end
		end)
	end
	return true
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event, a1, a2)
	if event == "PLAYER_REGEN_ENABLED" then
		if esperandoCombate then
			esperandoCombate = false
			plegar()
		end
		return
	end
	LimpiarMisionesDB = type(LimpiarMisionesDB) == "table" and LimpiarMisionesDB or {}
	LimpiarMisionesDB.version = VERSION
	if a1 or a2 then quierePlegado = true end -- entrada o recarga: plegado otra vez
	-- El juego monta el panel justo después de entrar: varios intentos.
	for _, s in ipairs({ 0.5, 2, 5 }) do
		C_Timer.After(s, function()
			enganchar()
			plegar()
		end)
	end
end)
