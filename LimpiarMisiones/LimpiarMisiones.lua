-- Limpiar misiones 1.0 (Huguillo, 2026-11-22)
--
-- Dos cosas:
--
-- 1) El panel de objetivos («Todos los objetivos») se queda plegado. El juego no guarda si
--    lo tenías plegado (ObjectiveTrackerContainerMixin: isCollapsed = false al cargar), así
--    que al entrar y al recargar la interfaz salía desplegado. Aquí se pliega al cargar y se
--    vuelve a plegar si el juego lo despliega por su cuenta (ForceExpand). Si lo despliegas
--    tú con su botón, se queda desplegado hasta la próxima carga.
--
-- 2) El botón «Limpiar misiones» (se puede arrastrar a donde quieras) abre en el
--    centro de la pantalla la lista de misiones del registro con el motivo por el que cada
--    una sobra o se queda, y un botón que abandona las marcadas.
--
--    SE QUEDA (sin marcar) si:
--      · está lista para entregar;
--      · es de clase;
--      · es de mazmorra, banda o élite (las guías no las llevan);
--      · la usa tu ruta de Polestar (la guía activa de aquí en adelante o una posterior);
--      · no la usa tu ruta, pero es de tu nivel y tu ruta aún pasa por su zona.
--    SE PROPONE ABANDONAR (marcada) si no es nada de lo de arriba y:
--      · te la saltaste en Polestar; o
--      · la guía activa ya pasó todos sus pasos sin hacerla y ninguna posterior la usa; o
--      · ninguna guía de tu ruta la usa y además se ha quedado atrás: es 6 niveles o más
--        por debajo del tuyo (da el 80 %, el 60 % o el 50 % de la experiencia) o tu ruta ya
--        no pasa por su zona.
--    Sin Polestar (o si no sabe decir la ruta) solo se mira el nivel, y nada sale marcado.
--    Tú decides: puedes desmarcar o marcar cualquiera antes de abandonar.
--
-- De Polestar solo se lee: RoutePlan.OffRoute (misiones que ninguna guía de la ruta usa),
-- Engine.GetGuide / GetLiveStep / NextGuide, Guides.Get, CharState().skippedQuests,
-- QuestDB.QuestRecord y Levels.Share. Abandonar es lo mismo que hace el botón del registro
-- del juego: C_QuestLog.SetSelectedQuest, SetAbandonQuest y AbandonQuest (sin restricciones
-- en la documentación de la API de Forever).

local VERSION = "1.0"
local LM = {}
_G.LimpiarMisiones = LM

local issecret = issecretvalue or function() return false end
local function ok(v)
	if v == nil or issecret(v) then return nil end
	return v
end
local function call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local r = { pcall(fn, ...) }
	if not r[1] then return nil end
	return r[2], r[3], r[4]
end

---------------------------------------------------------------------------
-- La decisión (sin nada del juego: se prueba fuera)
---------------------------------------------------------------------------

-- Parte de la experiencia que da una misión según cuántos niveles le sacas (lo que paga
-- Forever según Polestar.Levels.Share: entera hasta 5 niveles, 80 % a 6, 60 % a 7, 50 % desde 8).
function LM.Parte(nivel, nivelMision, share)
	if type(nivel) ~= "number" or type(nivelMision) ~= "number" then return 1 end
	if type(share) == "function" then
		local okShare, v = pcall(share, nivel, nivelMision)
		if okShare and type(v) == "number" then return v end
	end
	local d = nivel - nivelMision
	if d <= 5 then return 1 elseif d == 6 then return 0.8 elseif d == 7 then return 0.6 end
	return 0.5
end

local function pct(v) return ("%d %%"):format(math.floor(v * 100 + 0.5)) end

-- mundo = {
--   nivel = 42, share = función | nil,
--   misiones = { { id, titulo, nivel, zona, lista, clase, grupo }, ... },   -- en el orden del registro
--   ruta = nil | { fuera = { [id] = true }, saltadas = { [id] = true },
--                  pasadas = { [id] = true } | nil, zonas = { [nombre] = true } | nil },
-- }
-- Devuelve una fila por misión: { id, titulo, nivel, zona, accion = "abandonar" | "quedar",
-- marcada = bool, motivo = texto }.
function LM.Decidir(mundo)
	local out = {}
	local nivel, ruta = mundo.nivel, mundo.ruta
	for _, m in ipairs(mundo.misiones or {}) do
		local fila = { id = m.id, titulo = m.titulo, nivel = m.nivel, zona = m.zona, accion = "quedar", marcada = false }
		local parte = LM.Parte(nivel, m.nivel, mundo.share)
		local atrasNivel = parte < 1
		local textoNivel = atrasNivel and type(m.nivel) == "number"
			and ("es de nivel %d y tú eres %d (da el %s de la experiencia)"):format(m.nivel, nivel, pct(parte)) or nil
		if m.lista then
			fila.motivo = "Lista para entregar."
		elseif m.clase then
			fila.motivo = "Es una misión de clase."
		elseif m.grupo then
			fila.motivo = "Es de mazmorra, banda o élite: las guías no las llevan."
		elseif not ruta then
			if atrasNivel then
				fila.accion = "abandonar"
				fila.motivo = "Se ha quedado atrás: " .. textoNivel .. ". No puedo leer tu ruta de Polestar: decide tú."
			else
				fila.motivo = "No puedo leer tu ruta de Polestar y es de tu nivel."
			end
		elseif ruta.saltadas and ruta.saltadas[m.id] then
			fila.accion, fila.marcada = "abandonar", true
			fila.motivo = "Te la saltaste en Polestar" .. (textoNivel and (", y " .. textoNivel) or "") .. "."
		elseif ruta.pasadas and ruta.pasadas[m.id] then
			fila.accion, fila.marcada = "abandonar", true
			fila.motivo = "Se ha quedado atrás: tu guía ya pasó todos sus pasos sin hacerla y ninguna posterior la usa"
				.. (textoNivel and ("; " .. textoNivel) or "") .. "."
		elseif not (ruta.fuera and ruta.fuera[m.id]) then
			fila.motivo = "La usa tu ruta de Polestar."
		else
			local atrasZona = ruta.zonas ~= nil and type(m.zona) == "string" and not ruta.zonas[m.zona]
			if atrasNivel or atrasZona then
				fila.accion, fila.marcada = "abandonar", true
				local partes = {}
				if textoNivel then partes[#partes + 1] = textoNivel end
				if atrasZona then partes[#partes + 1] = "tu ruta ya no pasa por " .. m.zona end
				fila.motivo = "Se ha quedado atrás: ninguna guía de tu ruta la usa; " .. table.concat(partes, " y ") .. "."
			else
				fila.motivo = "No está en tu ruta, pero es de tu nivel"
					.. (type(m.zona) == "string" and ruta.zonas and (" y tu ruta aún pasa por " .. m.zona) or "") .. "."
			end
		end
		out[#out + 1] = fila
	end
	return out
end

---------------------------------------------------------------------------
-- Lo que hay en el juego
---------------------------------------------------------------------------

-- Etiquetas de misión de grupo (Enum.QuestTag): grupo/élite, banda, mazmorra y sus variantes.
local ETIQUETA_GRUPO = { [1] = true, [62] = true, [81] = true, [85] = true, [88] = true, [89] = true }

function LM.LeerRegistro()
	local out = {}
	local Q = C_QuestLog
	if not (Q and Q.GetNumQuestLogEntries and Q.GetInfo) then return out end
	local claseLocal = ok((call(UnitClass, "player")))
	local QDB = _G.Polestar and _G.Polestar.QuestDB
	local cabecera
	for i = 1, ok((call(Q.GetNumQuestLogEntries))) or 0 do
		local info = call(Q.GetInfo, i)
		if type(info) == "table" then
			if ok(info.isHeader) then
				cabecera = ok(info.title)
			elseif ok(info.questID) and not ok(info.isHidden) and not ok(info.isTask) and not ok(info.isBounty) then
				local id = info.questID
				local m = { id = id, titulo = ok(info.title) or ("misión " .. tostring(id)), nivel = ok(info.level), zona = cabecera }
				m.lista = (ok(call(Q.ReadyForTurnIn, id)) or ok(call(Q.IsComplete, id))) and true or false
				local tag = call(Q.GetQuestTagInfo, id)
				local tagID = type(tag) == "table" and ok(tag.tagID) or nil
				m.grupo = ((tonumber(ok(info.suggestedGroup)) or 0) > 1 or (tagID and ETIQUETA_GRUPO[tagID])) and true or false
				m.clase = (cabecera ~= nil and cabecera == claseLocal) or false
				if not m.clase and QDB and QDB.QuestRecord then
					local rec = call(QDB.QuestRecord, id)
					local clases = type(rec) == "table" and rec[5]
					if type(clases) == "number" and clases ~= 0 then m.clase = true end
				end
				out[#out + 1] = m
			end
		end
	end
	return out
end

local function nombreMapa(map)
	local P = _G.Polestar
	local n = P and P.Compat and P.Compat.MapName and call(P.Compat.MapName, map)
	if type(n) ~= "string" or n == "" then
		local info = C_Map and C_Map.GetMapInfo and call(C_Map.GetMapInfo, map)
		n = type(info) == "table" and ok(info.name) or nil
	end
	return type(n) == "string" and n ~= "" and n or nil
end

-- La ruta según Polestar, o nil si no está o no sabe decirla.
function LM.LeerRuta(nombreDeMapa)
	nombreDeMapa = nombreDeMapa or nombreMapa
	local P = _G.Polestar
	local E, Plan, G = P and P.Engine, P and P.RoutePlan, P and P.Guides
	if not (E and Plan and Plan.OffRoute and E.GetGuide) then return nil end
	local guia = call(E.GetGuide)
	if type(guia) ~= "table" or type(guia.steps) ~= "table" then return nil end
	local lista = call(Plan.OffRoute)
	if type(lista) ~= "table" then return nil end
	local ruta = { fuera = {}, saltadas = {}, guia = guia.id }
	for _, e in ipairs(lista) do
		if type(e) == "table" and e.quest then ruta.fuera[e.quest] = true end
	end
	local st = P.CharState and call(P.CharState)
	if type(st) == "table" and type(st.skippedQuests) == "table" then
		for q, v in pairs(st.skippedQuests) do
			if v == true then ruta.saltadas[q] = true end
		end
	end

	-- Las guías posteriores de la cadena. Si hay una elección pendiente (NextGuide nil con
	-- guías por delante) no se sabe: sin «pasadas» ni zonas, solo lo que dice OffRoute.
	local vivo = tonumber(call(E.GetLiveStep)) or tonumber(call(E.GetStepIndex)) or 1
	local despues, zonas, sabe = {}, {}, true
	local function apuntar(steps, desde, quests)
		for j = desde, #steps do
			local goals = type(steps[j]) == "table" and steps[j].goals
			for _, goal in ipairs(type(goals) == "table" and goals or {}) do
				if type(goal) == "table" then
					if goal.quest and quests then quests[goal.quest] = true end
					if goal.map then
						local n = nombreDeMapa(goal.map)
						if n then zonas[n] = true end
					end
				end
			end
		end
	end
	local delante = {}
	apuntar(guia.steps, vivo, delante)
	local cur, vistas = guia, { [guia.id or guia] = true }
	for _ = 1, 40 do
		if cur.nextChoices and not cur.next then
			local sig = E.NextGuide and call(E.NextGuide, cur.id)
			if not sig then sabe = false break end
			cur = G and G.Get and call(G.Get, sig)
		elseif cur.next or cur.nextChoices then
			local sig = (E.NextGuide and call(E.NextGuide, cur.id)) or cur.next
			if not sig then sabe = false break end
			cur = G and G.Get and call(G.Get, sig)
		else
			break
		end
		if type(cur) ~= "table" or type(cur.steps) ~= "table" then sabe = false break end
		if vistas[cur.id or cur] then break end
		vistas[cur.id or cur] = true
		apuntar(cur.steps, 1, despues)
	end
	-- Lo que usan las guías de las otras pestañas abiertas tampoco se da por pasado.
	for _, tab in ipairs((E.TabLiveSteps and call(E.TabLiveSteps)) or {}) do
		local g = type(tab) == "table" and tab.guide
		if type(g) == "table" and g ~= guia and type(g.steps) == "table" then apuntar(g.steps, 1, despues) end
	end
	if sabe then
		ruta.zonas = zonas
		-- Pasadas: en la guía activa solo antes del paso en curso, y en ninguna posterior.
		local antes = {}
		for j = 1, math.min(vivo - 1, #guia.steps) do
			local goals = type(guia.steps[j]) == "table" and guia.steps[j].goals
			for _, goal in ipairs(type(goals) == "table" and goals or {}) do
				if type(goal) == "table" and goal.quest then antes[goal.quest] = true end
			end
		end
		ruta.pasadas = {}
		for q in pairs(antes) do
			if not delante[q] and not despues[q] and not ruta.fuera[q] then ruta.pasadas[q] = true end
		end
	end
	return ruta
end

function LM.Analizar()
	local P = _G.Polestar
	return LM.Decidir({
		nivel = ok((call(UnitLevel, "player"))) or 1,
		share = P and P.Levels and P.Levels.Share or nil,
		misiones = LM.LeerRegistro(),
		ruta = LM.LeerRuta(),
	})
end

-- Abandona una misión como el botón del registro del juego. true si se pidió.
function LM.Abandonar(id)
	local Q = C_QuestLog
	if not (Q and Q.SetSelectedQuest and Q.SetAbandonQuest and Q.AbandonQuest) then return false end
	if Q.IsOnQuest and not ok(call(Q.IsOnQuest, id)) then return false end
	local okA = pcall(function()
		Q.SetSelectedQuest(id)
		Q.SetAbandonQuest()
		Q.AbandonQuest()
	end)
	return okA
end

local function decir(texto) print("|cffffd100Limpiar misiones|r: " .. texto) end

---------------------------------------------------------------------------
-- La ventana
---------------------------------------------------------------------------

local ventana
local ANCHO, ALTO, FILA, MARGEN = 680, 500, 46, 14

local function crearVentana()
	local okF, f = pcall(CreateFrame, "Frame", "LimpiarMisionesVentana", UIParent, "BasicFrameTemplateWithInset")
	if not (okF and f) then
		f = CreateFrame("Frame", "LimpiarMisionesVentana", UIParent)
		local fondo = f:CreateTexture(nil, "BACKGROUND")
		fondo:SetAllPoints()
		fondo:SetColorTexture(0, 0, 0, 0.9)
	end
	f:Hide()
	f:SetSize(ANCHO, ALTO)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	if f.TitleText then f.TitleText:SetText("Limpiar misiones") end
	if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "LimpiarMisionesVentana") end -- Esc la cierra

	f.resumen = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.resumen:SetPoint("TOPLEFT", f, "TOPLEFT", MARGEN, -30)
	f.resumen:SetWidth(ANCHO - 2 * MARGEN)
	f.resumen:SetJustifyH("LEFT")

	local okS, scroll = pcall(CreateFrame, "ScrollFrame", "LimpiarMisionesScroll", f, "UIPanelScrollFrameTemplate")
	if not (okS and scroll) then scroll = CreateFrame("ScrollFrame", "LimpiarMisionesScroll", f) end
	scroll:SetPoint("TOPLEFT", f, "TOPLEFT", MARGEN, -62)
	scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MARGEN - 22, 44)
	local contenido = CreateFrame("Frame", nil, scroll)
	contenido:SetSize(ANCHO - 2 * MARGEN - 22, 10)
	scroll:SetScrollChild(contenido)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local tope = math.max(0, contenido:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(tope, math.max(0, self:GetVerticalScroll() - delta * FILA * 2)))
	end)
	f.scroll, f.contenido, f.filas, f.cabeceras = scroll, contenido, {}, {}

	f.abandonar = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.abandonar:SetSize(230, 24)
	f.abandonar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", MARGEN, 12)
	f.cerrar = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.cerrar:SetSize(110, 24)
	f.cerrar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MARGEN, 12)
	f.cerrar:SetText("Cerrar")
	f.cerrar:SetScript("OnClick", function() f:Hide() end)
	return f
end

local function filaDe(f, i)
	local r = f.filas[i]
	if r then return r end
	r = CreateFrame("Frame", nil, f.contenido)
	r:SetSize(f.contenido:GetWidth(), FILA)
	local okC, c = pcall(CreateFrame, "CheckButton", nil, r, "UICheckButtonTemplate")
	if not (okC and c) then c = CreateFrame("CheckButton", nil, r) end
	c:SetSize(24, 24)
	c:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2)
	r.check = c
	r.titulo = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	r.titulo:SetPoint("TOPLEFT", r, "TOPLEFT", 28, -2)
	r.titulo:SetWidth(r:GetWidth() - 30)
	r.titulo:SetJustifyH("LEFT")
	if r.titulo.SetWordWrap then r.titulo:SetWordWrap(false) end
	r.motivo = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	r.motivo:SetPoint("TOPLEFT", r, "TOPLEFT", 28, -17)
	r.motivo:SetWidth(r:GetWidth() - 30)
	r.motivo:SetJustifyH("LEFT")
	r.motivo:SetJustifyV("TOP")
	if r.motivo.SetWordWrap then r.motivo:SetWordWrap(true) end
	if r.motivo.SetMaxLines then r.motivo:SetMaxLines(2) end
	f.filas[i] = r
	return r
end

local function cabeceraDe(f, i)
	local h = f.cabeceras[i]
	if not h then
		h = f.contenido:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		h:SetJustifyH("LEFT")
		f.cabeceras[i] = h
	end
	return h
end

local function contarMarcadas(f)
	local n = 0
	for _, r in ipairs(f.filas) do
		if r:IsShown() and r.check:GetChecked() then n = n + 1 end
	end
	f.abandonar:SetText(n == 1 and "Abandonar la marcada" or ("Abandonar las %d marcadas"):format(n))
	if n > 0 then f.abandonar:Enable() else f.abandonar:Disable() end
	return n
end

local function pintar(f, filas)
	local quitar, quedar = {}, {}
	for _, fila in ipairs(filas) do
		if fila.accion == "abandonar" then quitar[#quitar + 1] = fila else quedar[#quedar + 1] = fila end
	end
	f.resumen:SetText(#filas == 0 and "No tienes misiones en el registro."
		or ("%d misiones en el registro: %d se han quedado atrás y %d se quedan. Desmarca o marca lo que quieras; "
			.. "abandonar no se puede deshacer."):format(#filas, #quitar, #quedar))
	local y, n, c = 0, 0, 0
	local function seccion(titulo, lista, r, g, b)
		if #lista == 0 then return end
		c = c + 1
		local h = cabeceraDe(f, c)
		h:ClearAllPoints()
		h:SetPoint("TOPLEFT", f.contenido, "TOPLEFT", 2, -y - 4)
		h:SetText(titulo)
		h:SetTextColor(r, g, b)
		h:Show()
		y = y + 26
		for _, fila in ipairs(lista) do
			n = n + 1
			local row = filaDe(f, n)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", f.contenido, "TOPLEFT", 0, -y)
			row.fila = fila
			local elegido = f.eleccion and f.eleccion[fila.id]
			if elegido == nil then elegido = fila.marcada and true or false end
			row.check:SetChecked(elegido)
			row.check:SetScript("OnClick", function(self)
				f.eleccion = f.eleccion or {}
				f.eleccion[fila.id] = self:GetChecked() and true or false
				contarMarcadas(f)
			end)
			row.titulo:SetText(("[%s] %s  |cff808080%s|r"):format(tostring(fila.nivel or "?"), fila.titulo or "?", fila.zona or ""))
			row.motivo:SetText(fila.motivo or "")
			row:Show()
			y = y + FILA
		end
		y = y + 6
	end
	seccion("Se han quedado atrás", quitar, 1, 0.35, 0.35)
	seccion("Se quedan", quedar, 0.4, 1, 0.4)
	for i = n + 1, #f.filas do f.filas[i]:Hide(); f.filas[i].fila = nil end
	for i = c + 1, #f.cabeceras do f.cabeceras[i]:Hide() end
	f.contenido:SetHeight(math.max(10, y))
	f.scroll:SetVerticalScroll(0)
	contarMarcadas(f)
end

local abandonando = false
local function abandonarMarcadas(f)
	if abandonando then return end
	local cola = {}
	for _, r in ipairs(f.filas) do
		if r:IsShown() and r.fila and r.check:GetChecked() then cola[#cola + 1] = r.fila end
	end
	if #cola == 0 then return end
	abandonando = true
	f.abandonar:Disable()
	local hechas, i = 0, 0
	local function paso()
		i = i + 1
		local fila = cola[i]
		if not fila then
			abandonando = false
			decir(("abandonadas %d de %d."):format(hechas, #cola))
			-- El registro tarda un instante en enterarse.
			C_Timer.After(0.6, function() if f:IsShown() then pintar(f, LM.Analizar()) end end)
			return
		end
		if LM.Abandonar(fila.id) then
			hechas = hechas + 1
			decir(("abandonada «%s»."):format(fila.titulo or tostring(fila.id)))
		else
			decir(("no he podido abandonar «%s»."):format(fila.titulo or tostring(fila.id)))
		end
		C_Timer.After(0.3, paso)
	end
	paso()
end

function LM.Abrir()
	if not ventana then
		ventana = crearVentana()
		ventana.abandonar:SetScript("OnClick", function() abandonarMarcadas(ventana) end)
	end
	if ventana:IsShown() then ventana:Hide() return end
	local okA, filas = pcall(LM.Analizar)
	if not okA then
		decir("no he podido leer las misiones (" .. tostring(filas) .. ").")
		return
	end
	ventana.eleccion = {} -- análisis nuevo: las marcas vuelven a las propuestas
	pintar(ventana, filas)
	ventana:ClearAllPoints()
	ventana:SetPoint("CENTER")
	ventana:Show()
end

---------------------------------------------------------------------------
-- El botón
---------------------------------------------------------------------------

local boton = CreateFrame("Button", "LimpiarMisionesBoton", UIParent, "UIPanelButtonTemplate")
boton:SetSize(112, 22)
boton:SetText("Limpiar misiones")
boton:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -258)
boton:SetMovable(true)
boton:SetClampedToScreen(true)
boton:RegisterForDrag("LeftButton")
boton:SetScript("OnDragStart", boton.StartMoving)
boton:SetScript("OnDragStop", boton.StopMovingOrSizing)
boton:SetScript("OnClick", function() LM.Abrir() end)
boton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Limpiar misiones")
	GameTooltip:AddLine("Enseña qué misiones del registro se han quedado atrás y por qué, para abandonarlas.", 1, 1, 1, true)
	GameTooltip:AddLine("Arrástralo para moverlo.", 0.7, 0.7, 0.7, true)
	GameTooltip:Show()
end)
boton:SetScript("OnLeave", function() GameTooltip:Hide() end)

---------------------------------------------------------------------------
-- El panel de objetivos, plegado
---------------------------------------------------------------------------

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
