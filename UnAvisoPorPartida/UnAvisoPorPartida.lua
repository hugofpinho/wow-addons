-- Un aviso por partida (2026-11-24)
--
-- Varios addons avisan de que hay una versión nueva cada vez que se carga la interfaz, y
-- la interfaz se recarga a menudo (/reload, «Enviar a Claude»…): el mismo aviso salía una
-- y otra vez. Con este addon cada aviso sale una sola vez por partida, es decir, desde que
-- abres el juego hasta que lo cierras. Al volver a abrirlo, si sigues sin actualizar, sale
-- otra vez.
--
--   Polestar          la tarjeta «POLESTAR UPDATE» (UI.UpdateCard). La línea de la ventana
--                     de la guía no se toca: va dentro de la ventana, no salta sola.
--   GearQuest         la línea del chat «A newer version of GearQuest is available».
--   OpenMap           las líneas del chat «Ya ha salido OpenMap…» y «Actualizado a…:
--                     consulta Novedades».
--   Dungeon Journal   la línea del chat «Version … is available».
--
-- Details no hace falta: ya avisa como mucho una vez cada 20 horas.
--
-- No cambia ningún archivo de esos addons (así sus actualizaciones no lo deshacen):
-- envuelve sus funciones desde fuera. Si un addon cambia y la función ya no está, con ese
-- no hace nada y el aviso vuelve a salir como antes.
--
-- Cómo sabe que es la misma partida: GetSessionTime() (segundos desde que se abrió el
-- juego) da la hora de arranque, que no cambia al recargar; y PLAYER_ENTERING_WORLD dice
-- si es una recarga. Lo ya avisado se guarda en UnAvisoPorPartidaDB.vistos.

local ADDON = ...
local MARGEN = 120 -- segundos de diferencia que aún cuentan como el mismo arranque

local DB
local decidido = false

local function ahora() return time and time() or 0 end

-- Hora a la que se abrió el juego, o nil si no se puede saber.
local function arranque()
	if type(GetSessionTime) ~= "function" or not time then return nil end
	local ok, s = pcall(GetSessionTime)
	if ok and type(s) == "number" and s >= 0 then return ahora() - s end
end

local function base()
	if not DB then
		DB = type(UnAvisoPorPartidaDB) == "table" and UnAvisoPorPartidaDB or {}
		UnAvisoPorPartidaDB = DB
		DB.vistos = type(DB.vistos) == "table" and DB.vistos or {}
	end
	return DB
end

-- ¿Sigue siendo la partida de lo que hay apuntado? recarga: true (recarga de la interfaz),
-- false (entrada con el personaje) o nil (aún no se sabe).
local function decidir(recarga)
	if decidido then return end
	decidido = true
	local d = base()
	local a = arranque()
	local misma
	if recarga then
		misma = true
	elseif a and tonumber(d.arranque) then
		misma = math.abs(a - d.arranque) <= MARGEN
	else
		misma = false
	end
	if not misma then
		d.vistos = {}
		d.arranque = a
	elseif not d.arranque then
		d.arranque = a
	end
	-- Las últimas cargas, para comprobar desde fuera que GetSessionTime se porta como se espera.
	d.registro = type(d.registro) == "table" and d.registro or {}
	table.insert(d.registro, 1, { t = ahora(), sesion = a and (ahora() - a) or nil, recarga = recarga, misma = misma })
	while #d.registro > 10 do table.remove(d.registro) end
end

local function yaVisto(clave)
	decidir(nil)
	return base().vistos[clave] ~= nil
end

local function apuntar(clave)
	decidir(nil)
	base().vistos[clave] = ahora()
end

-- true la primera vez en esta partida (y lo apunta); false las demás.
local function puede(clave)
	if yaVisto(clave) then return false end
	apuntar(clave)
	return true
end

---------------------------------------------------------------------------
-- Los enganches (cada uno una sola vez)
---------------------------------------------------------------------------

local hecho = {}

local function polestar()
	local P = _G.Polestar
	local UC = type(P) == "table" and type(P.UI) == "table" and P.UI.UpdateCard
	if hecho.polestar or type(UC) ~= "table" or type(UC.Wanted) ~= "function" or type(UC.Show) ~= "function" then return end
	hecho.polestar = true
	local wanted, show = UC.Wanted, UC.Show
	UC.Wanted = function(...)
		if yaVisto("Polestar") then return false end
		return wanted(...)
	end
	-- Show(force): force es el botón «Actualizar» de la ventana o /polestar update; esa
	-- siempre sale. Show() sin force devuelve true cuando la tarjeta se ha puesto.
	UC.Show = function(force, ...)
		local r = show(force, ...)
		if r and not force then apuntar("Polestar") end
		return r
	end
end

local function gearquest()
	local GQ = _G.GearQuest
	if hecho.gearquest or type(GQ) ~= "table" or type(GQ.NoteNewerVersion) ~= "function" then return end
	hecho.gearquest = true
	local orig = GQ.NoteNewerVersion
	GQ.NoteNewerVersion = function(self, remote, ...)
		if type(self) == "table" and not self.versionWarned and type(remote) == "string" and not puede("GearQuest") then
			self.versionWarned = true -- lo mismo que hace GearQuest tras avisar: no lo vuelve a intentar
			return
		end
		return orig(self, remote, ...)
	end
end

local OPENMAP = {
	["OpenMap %s is out (you have %s). Update through CurseForge."] = "OpenMap",
	["Updated to %s: see What's new in the OpenMap menu."] = "OpenMap novedades",
}
local function openmap()
	local OM = _G.OpenMap
	if hecho.openmap or type(OM) ~= "table" or type(OM.Print) ~= "function" or type(OM.L) ~= "table" then return end
	hecho.openmap = true
	local orig = OM.Print
	OM.Print = function(self, fmt, ...)
		if type(fmt) == "string" then
			for ingles, clave in pairs(OPENMAP) do
				local ok, texto = pcall(function() return OM.L[ingles] end)
				if ok and fmt == texto then
					if not puede(clave) then return end
					break
				end
			end
		end
		return orig(self, fmt, ...)
	end
end

-- Dungeon Journal escribe «<etiqueta> <texto de UPDATE_AVAILABLE>» con FDJ.ChatLine. Se
-- reconoce por los trozos fijos del texto en el idioma que use el addon.
local function trozosFDJ(FDJ)
	if type(FDJ.L) ~= "function" then return nil end
	local ok, plantilla = pcall(FDJ.L, "UPDATE_AVAILABLE", "\1", "\1")
	if not ok or type(plantilla) ~= "string" or not plantilla:find("\1", 1, true) then return nil end
	local trozos = {}
	for t in plantilla:gmatch("[^\1]+") do
		if #t >= 3 then trozos[#trozos + 1] = t end
	end
	return #trozos > 0 and trozos or nil
end
local function esAvisoFDJ(FDJ, texto)
	if type(texto) ~= "string" or not texto:find("DungeonJournal", 1, true) then return false end
	local trozos = trozosFDJ(FDJ)
	if not trozos then return false end
	local desde = 1
	for _, t in ipairs(trozos) do
		local i, j = texto:find(t, desde, true)
		if not i then return false end
		desde = j + 1
	end
	return true
end
local function dungeonjournal()
	local FDJ = _G.ForeverDungeonJournal_NS
	if hecho.fdj or type(FDJ) ~= "table" or type(FDJ.ChatLine) ~= "function" then return end
	hecho.fdj = true
	local orig = FDJ.ChatLine
	FDJ.ChatLine = function(texto, ...)
		if esAvisoFDJ(FDJ, texto) and not puede("DungeonJournal") then return end
		return orig(texto, ...)
	end
end

local function enganchar()
	pcall(polestar)
	pcall(gearquest)
	pcall(openmap)
	pcall(dungeonjournal)
end

---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, a1, a2)
	if event == "ADDON_LOADED" then
		if a1 == ADDON then DB = nil; base() end -- aquí ya está cargado UnAvisoPorPartidaDB
		enganchar()
	elseif event == "PLAYER_LOGIN" then
		enganchar()
	elseif event == "PLAYER_ENTERING_WORLD" then
		-- a1 = isInitialLogin, a2 = isReloadingUi
		decidir(a2 == true)
	end
end)
