-- Aviso de versiones nuevas (este archivo va igual dentro de cada addon de
-- github.com/hugofpinho/wow-addons; el que se carga primero hace el trabajo y los demás
-- solo se apuntan).
--
-- Como Polestar: los addons no pueden mirar en internet, así que cada uno dice su versión
-- a los demás jugadores que también los tienen, por el canal oculto de los addons:
--   * al entrar (a los 20 s, como mucho cada 30 min): a tu grupo, a tus amigos de Battle.net
--     que estén en WoW Forever (aunque sean de otro reino) y a los miembros conectados de la
--     comunidad «El reino de Lordran» (un susurro oculto de addon a cada uno);
--   * al entrar en un grupo: al grupo.
-- A la hermandad no se le manda nada (versión 2, 2026-11-22): puede ser grande y de gente que
-- no tiene nada que ver con estos addons. Si tus versiones han cambiado desde el último
-- anuncio, no se esperan los 30 min (versión 3).
-- Si alguien tiene una versión más nueva de un addon que tú tienes, sale el aviso: una
-- línea en el chat y una ventanita con el enlace para copiarlo. Y si el que va atrasado es
-- el otro, se lo dices tú (una vez por persona y sesión). Lo que se sabe se guarda 14 días,
-- así que el aviso sale hasta que actualices, aunque no haya nadie: una vez cada vez que
-- abres el juego, no en cada recarga de la interfaz (versión 4, 2026-11-24).
--
-- Solo se mandan los nombres y versiones de estos addons. Nada más.

local ADDON = ...
local LIB_VERSION = 4
local URL = "github.com/hugofpinho/wow-addons"
local PREFIX = "HugoAddons"
local HELLO_GAP, HELLO_DELAY, KEEP_DAYS = 1800, 20, 14
-- Comunidades (de personajes) a cuyos miembros conectados se anuncia, por nombre.
local COMUNIDADES = { ["El reino de Lordran"] = true }
local MAX_SUSURROS, PAUSA_SUSURRO = 40, 1.2 -- el juego deja ~1 mensaje de addon por segundo

local lib = _G.HugoAddonsAviso
if lib and (lib.libVersion or 0) >= LIB_VERSION then
	lib.addons[ADDON] = true
	return
end
local old = lib
lib = { libVersion = LIB_VERSION, addons = old and old.addons or {}, frame = old and old.frame }
_G.HugoAddonsAviso = lib
lib.addons[ADDON] = true

local issecret = issecretvalue or function() return false end
local function ok(v) if v == nil or issecret(v) then return nil end return v end
local function now() return time and time() or 0 end

local function meta(name, field)
	local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	return get and ok(get(name, field))
end

-- "1.2.1" → {1, 2, 1}
local function parse(v)
	if type(v) ~= "string" or #v > 16 or not v:match("^%d+[%.%d]*$") then return nil end
	local out = {}
	for n in v:gmatch("%d+") do out[#out + 1] = tonumber(n) end
	return out
end
local function newer(a, b)
	local pa, pb = parse(a), parse(b)
	if not (pa and pb) then return false end
	for i = 1, math.max(#pa, #pb) do
		local x, y = pa[i] or 0, pb[i] or 0
		if x ~= y then return x > y end
	end
	return false
end

local function db()
	HugoAddonsAvisoDB = type(HugoAddonsAvisoDB) == "table" and HugoAddonsAvisoDB or {}
	local d = HugoAddonsAvisoDB
	d.latest = type(d.latest) == "table" and d.latest or {}
	return d
end

local function mine()
	local out = {}
	for name in pairs(lib.addons) do
		local v = meta(name, "Version")
		if parse(v) then out[name] = v end
	end
	return out
end

local function encode(kind)
	local parts = {}
	for name, v in pairs(mine()) do parts[#parts + 1] = name .. "=" .. v end
	table.sort(parts)
	return "1" .. kind .. "|" .. table.concat(parts, ",")
end

local function decode(text)
	if type(text) ~= "string" or #text > 255 then return nil end
	local kind, body = text:match("^1([VR])|(.*)$")
	if not kind then return nil end
	local list = {}
	for name, v in body:gmatch("([%w_]+)=([%d%.]+)") do
		if #name <= 40 and parse(v) then list[name] = v end
	end
	return kind, list
end

---------------------------------------------------------------------------
-- El aviso
---------------------------------------------------------------------------

local popup

-- Lo ya avisado en esta partida (desde que se abre el juego hasta que se cierra), guardado en
-- HugoAddonsAvisoDB para que una recarga no lo repita. La hora de arranque sale de
-- GetSessionTime (segundos desde que se abrió el juego) y PLAYER_ENTERING_WORLD dice si la
-- carga es una recarga (lib.recarga).
local function arranque()
	if type(GetSessionTime) ~= "function" then return nil end
	local okS, s = pcall(GetSessionTime)
	if okS and type(s) == "number" and s >= 0 then return now() - s end
end
local function vistosEnPartida(d)
	if lib.vistos then return lib.vistos end
	local a = arranque()
	local misma = lib.recarga == true or (a ~= nil and tonumber(d.arranque) ~= nil and math.abs(a - d.arranque) <= 120)
	if not misma or type(d.vistos) ~= "table" then
		d.vistos = {}
		if not misma or not d.arranque then d.arranque = a end
	end
	lib.vistos = d.vistos
	return d.vistos
end

local function title(name)
	return meta(name, "Title") or name
end

local function showPopup(lines)
	if not popup then
		local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
		popup = CreateFrame("Frame", "HugoAddonsAvisoFrame", UIParent)
		popup:SetSize(360, 150)
		popup:SetPoint("TOP", UIParent, "TOP", 0, -140)
		popup:SetFrameStrata("DIALOG")
		popup:EnableMouse(true)
		popup:SetMovable(true)
		popup:RegisterForDrag("LeftButton")
		popup:SetScript("OnDragStart", popup.StartMoving)
		popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
		local bg = popup:CreateTexture(nil, "BACKGROUND")
		bg:SetColorTexture(0.04, 0.04, 0.06, 0.96)
		bg:SetAllPoints()
		local edge = popup:CreateTexture(nil, "BORDER")
		edge:SetColorTexture(0.75, 0.6, 0.2, 1)
		edge:SetPoint("TOPLEFT"); edge:SetPoint("TOPRIGHT"); edge:SetHeight(2)
		popup.title = popup:CreateFontString(nil, "OVERLAY")
		popup.title:SetFont(FONT, 14, "")
		popup.title:SetTextColor(1, 0.82, 0)
		popup.title:SetPoint("TOPLEFT", 12, -12)
		popup.title:SetText("Hay versiones nuevas de tus addons")
		popup.body = popup:CreateFontString(nil, "OVERLAY")
		popup.body:SetFont(FONT, 12, "")
		popup.body:SetPoint("TOPLEFT", popup.title, "BOTTOMLEFT", 0, -8)
		popup.body:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
		popup.body:SetJustifyH("LEFT")
		popup.hint = popup:CreateFontString(nil, "OVERLAY")
		popup.hint:SetFont(FONT, 11, "")
		popup.hint:SetTextColor(0.75, 0.75, 0.75)
		popup.hint:SetPoint("BOTTOMLEFT", 12, 40)
		popup.hint:SetText("Haz clic en el enlace y Ctrl + C para copiarlo:")
		popup.box = CreateFrame("EditBox", nil, popup)
		popup.box:SetSize(250, 22)
		popup.box:SetPoint("BOTTOMLEFT", 12, 12)
		popup.box:SetFont(FONT, 12, "")
		popup.box:SetAutoFocus(false)
		popup.box:SetTextInsets(6, 6, 0, 0)
		local boxBg = popup.box:CreateTexture(nil, "BACKGROUND")
		boxBg:SetColorTexture(0, 0, 0, 0.7)
		boxBg:SetAllPoints()
		popup.box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
		popup.box:SetScript("OnTextChanged", function(self) if self:GetText() ~= "https://" .. URL then self:SetText("https://" .. URL); self:HighlightText() end end)
		popup.box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		local close = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
		close:SetSize(76, 22)
		close:SetPoint("BOTTOMRIGHT", -12, 12)
		close:SetText("Cerrar")
		close:SetScript("OnClick", function() popup:Hide() end)
	end
	popup.body:SetText(table.concat(lines, "\n"))
	popup.box:SetText("https://" .. URL)
	popup:Show() -- sin coger el teclado: el enlace se selecciona al hacer clic en él
end

-- Mira lo guardado y avisa de lo que vas atrasado (una vez por sesión y versión).
local function notify()
	local d = db()
	local have = mine()
	local lines, fresh = {}, false
	local vistos = vistosEnPartida(d)
	for name, info in pairs(d.latest) do
		local v = type(info) == "table" and info.v
		if have[name] and v and newer(v, have[name]) and now() - (tonumber(info.at) or 0) < KEEP_DAYS * 86400 then
			lines[#lines + 1] = title(name) .. ": tienes " .. have[name] .. ", hay " .. v
			if not vistos[name .. v] then fresh = true; vistos[name .. v] = true end
		elseif not (have[name] and v and newer(v, have[name])) and have[name] then
			d.latest[name] = nil -- ya está al día
		end
	end
	if #lines == 0 or not fresh then return end
	table.sort(lines)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Addons de Hugo:|r hay versiones nuevas (" .. table.concat(lines, "; ")
			.. "). Descárgalas de |cffffd100" .. URL .. "|r")
	end
	showPopup(lines)
end

---------------------------------------------------------------------------
-- Mensajes
---------------------------------------------------------------------------

local replied = {}

local function send(channel, target, text)
	if channel == "BN" then
		if BNSendGameData then pcall(BNSendGameData, target, PREFIX, text) end
	elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
		pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, channel, target)
	end
end

local function groupChannel()
	if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid and IsInRaid() then return "RAID" end
	if IsInGroup and IsInGroup() then return "PARTY" end
end

local function wowFriends()
	local out = {}
	if not (BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendNumGameAccounts) then return out end
	local okN, n = pcall(BNGetNumFriends)
	for i = 1, (okN and tonumber(n)) or 0 do
		for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) or 0 do
			local info = C_BattleNet.GetFriendGameAccountInfo(i, j)
			if info and info.isOnline and info.clientProgram == (BNET_CLIENT_WOW or "WoW") and info.gameAccountID
				and (not WOW_PROJECT_ID or info.wowProjectID == nil or info.wowProjectID == WOW_PROJECT_ID) then
				out[#out + 1] = info.gameAccountID
			end
		end
	end
	return out
end

-- Las comunidades de COMUNIDADES en las que estás: { clubId, ... }.
local function comunidades()
	local out = {}
	local C = C_Club
	if not (C and C.GetSubscribedClubs) then return out end
	local okC, clubs = pcall(C.GetSubscribedClubs)
	clubs = okC and ok(clubs)
	if type(clubs) ~= "table" then return out end
	for _, club in ipairs(clubs) do
		local name, id = type(club) == "table" and ok(club.name), type(club) == "table" and ok(club.clubId)
		if name and id and COMUNIDADES[name] then out[#out + 1] = id end
	end
	return out
end

-- Sus miembros conectados al juego (en línea, ausentes u ocupados), sin ti: { nombre, ... }.
local function miembrosConectados()
	local out, seen = {}, {}
	local C = C_Club
	if not (C and C.GetClubMembers and C.GetMemberInfo) then return out end
	for _, clubId in ipairs(comunidades()) do
		local okM, members = pcall(C.GetClubMembers, clubId)
		members = okM and ok(members)
		for _, memberId in ipairs(type(members) == "table" and members or {}) do
			local okI, info = pcall(C.GetMemberInfo, clubId, memberId)
			info = okI and ok(info)
			if type(info) == "table" and not ok(info.isSelf) then
				local who, presence = ok(info.name), ok(info.presence)
				if type(who) == "string" and who ~= "" and not seen[who] and (presence == 1 or presence == 4 or presence == 5) then
					seen[who] = true
					out[#out + 1] = who
				end
			end
		end
	end
	return out
end

-- Si un miembro se desconectó justo antes, el juego diría «No se encuentra a un jugador
-- llamado X» en el chat: esa línea se calla para los nombres recién susurrados.
local callados = {}
local function callar(who) callados[who] = (GetTime and GetTime() or 0) + 8 end
do
	local addFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
	local plantilla = ERR_CHAT_PLAYER_NOT_FOUND_S
	if not lib.filtro and type(addFilter) == "function" and type(plantilla) == "string" then
		local patron = "^" .. plantilla:gsub("[%^%$%(%)%.%[%]%*%+%-%?]", "%%%0"):gsub("%%s", "(.+)") .. "$"
		lib.filtro = pcall(addFilter, "CHAT_MSG_SYSTEM", function(_, _, msg)
			msg = ok(msg)
			local who = type(msg) == "string" and msg:match(patron)
			local hasta = who and callados[who]
			if hasta and hasta > (GetTime and GetTime() or 0) then return true end
			return false
		end)
	end
end

local function hello()
	local d = db()
	local text = encode("V")
	local falta = HELLO_GAP - (now() - (tonumber(d.helloAt) or 0))
	-- Como mucho cada 30 min… salvo que tus versiones hayan cambiado desde el último anuncio
	-- (versión 3): si acabas de actualizar, se anuncia ya, no media hora después.
	if falta > 0 and d.helloText == text then
		-- Demasiado pronto desde el último: se deja para cuando toque (antes no se reintentaba
		-- y, entrando dos veces seguidas, no se anunciaba nada en toda la sesión).
		if not lib.reintento then
			lib.reintento = true
			C_Timer.After(falta + 5, function() lib.reintento = nil; hello() end)
		end
		return
	end
	d.helloAt, d.helloText = now(), text
	local g = groupChannel()
	if g then send(g, nil, text) end
	for _, id in ipairs(wowFriends()) do send("BN", id, text) end
	for i, who in ipairs(miembrosConectados()) do
		if i > MAX_SUSURROS then break end
		C_Timer.After((i - 1) * PAUSA_SUSURRO, function()
			callar(who)
			send("WHISPER", who, text)
		end)
	end
end

local function heard(kind, list, channel, sender)
	local d = db()
	local have = mine()
	local behindThem = false
	for name, v in pairs(list) do
		if have[name] and newer(v, have[name]) then
			local cur = d.latest[name]
			if not (type(cur) == "table" and cur.v and not newer(v, cur.v)) then
				d.latest[name] = { v = v, at = now() }
			else
				cur.at = now()
			end
			behindThem = true
		end
	end
	if behindThem then notify() end
	-- Si el que va atrasado es el otro, se lo decimos (no a una respuesta: así no hay bucles).
	if kind == "V" and sender and not replied[sender] then
		for name, v in pairs(list) do
			if have[name] and newer(have[name], v) then
				replied[sender] = true
				local text = encode("R")
				C_Timer.After(1 + math.random() * 4, function()
					if channel == "BN" then send("BN", sender, text) else send("WHISPER", sender, text) end
				end)
				break
			end
		end
	end
end

local function me()
	local name = UnitName and ok(UnitName("player"))
	local realm = GetNormalizedRealmName and ok(GetNormalizedRealmName())
	return name, realm
end

local frame = lib.frame or CreateFrame("Frame")
lib.frame = frame
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON", "BN_CHAT_MSG_ADDON", "GROUP_JOINED" }) do
	pcall(frame.RegisterEvent, frame, e)
end
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
frame:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
	if event == "PLAYER_ENTERING_WORLD" then
		if lib.recarga == nil then lib.recarga = a2 == true end -- a2 = isReloadingUi (solo la primera)
	elseif event == "PLAYER_LOGIN" then
		C_Timer.After(5, notify)
		-- La lista de miembros de una comunidad llega cuando se le pide: se pide antes de anunciar.
		C_Timer.After(8, function()
			if C_Club and C_Club.FocusMembers then
				for _, clubId in ipairs(comunidades()) do pcall(C_Club.FocusMembers, clubId) end
			end
		end)
		C_Timer.After(HELLO_DELAY, hello)
	elseif event == "GROUP_JOINED" then
		C_Timer.After(3, function()
			local g = groupChannel()
			if g then send(g, nil, encode("V")) end
		end)
	elseif event == "CHAT_MSG_ADDON" then
		if ok(a1) ~= PREFIX then return end
		local sender = ok(a4)
		local name, realm = me()
		if not sender or sender == name or (name and realm and sender == name .. "-" .. realm) then return end
		local kind, list = decode(ok(a2))
		if kind then heard(kind, list, ok(a3), sender) end
	elseif event == "BN_CHAT_MSG_ADDON" then
		if ok(a1) ~= PREFIX then return end
		local kind, list = decode(ok(a2))
		if kind then heard(kind, list, "BN", ok(a4)) end
	end
end)
