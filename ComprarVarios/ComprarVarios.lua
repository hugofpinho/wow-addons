-- Comprar varios 1.0 (2026-11-18)
--
-- En un mercader, Alt + clic en un objeto abre una ventanita para comprar de golpe
-- tantos como quieras (60 aguas, 200 flechas...). El juego solo deja comprar un montón
-- cada vez (Mayús + clic, hasta 20 aguas); esto hace las compras seguidas por ti.
--
-- La ventanita dice el precio total, cuántos huecos de las bolsas ocupa y cuántos puedes
-- pagar. Botones: −/+ y +1 montón, «Lo que pueda pagar» y «Comprar». Compra un montón
-- cada cuarto de segundo y para sola si cierras el mercader, te quedas sin oro o sin
-- sitio, se agota o cambia la lista del mercader. Solo objetos que se pagan con oro.
--
-- Cómo: escucha GLOBAL_MOUSE_UP con Alt pulsado y mira si bajo el ratón hay un botón de
-- objeto del mercader (MerchantItemNItemButton, su ID es el número del objeto); compra con
-- BuyMerchantItem(número, cantidad), como hace el juego. No toca nada de Blizzard.

local STEP_SECONDS = 0.25

local issecret = issecretvalue or function() return false end
local function ok(v) if v == nil or issecret(v) then return nil end return v end

local function itemInfo(index)
	if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
		local info = C_MerchantFrame.GetItemInfo(index)
		if type(info) == "table" then
			return {
				name = ok(info.name), texture = ok(info.texture), price = ok(info.price) or 0,
				stackCount = ok(info.stackCount) or 1, numAvailable = ok(info.numAvailable) or -1,
				extended = ok(info.hasExtendedCost) and true or false,
			}
		end
	end
	if GetMerchantItemInfo then
		local name, texture, price, stackCount, numAvailable, _, _, extended = GetMerchantItemInfo(index)
		if name then
			return { name = name, texture = texture, price = price or 0, stackCount = stackCount or 1,
				numAvailable = numAvailable or -1, extended = extended and true or false }
		end
	end
end

local function itemID(index)
	local id = GetMerchantItemID and ok(GetMerchantItemID(index))
	if id then return id end
	local link = GetMerchantItemLink and ok(GetMerchantItemLink(index))
	return link and tonumber(link:match("item:(%d+)"))
end

local function money(copper)
	copper = math.floor(copper + 0.5)
	if GetCoinTextureString then return GetCoinTextureString(copper) end
	local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
	local out = {}
	if g > 0 then out[#out + 1] = g .. " o" end
	if s > 0 then out[#out + 1] = s .. " p" end
	if c > 0 or #out == 0 then out[#out + 1] = c .. " c" end
	return table.concat(out, " ")
end

-- Huecos libres en las bolsas normales y sitio que queda en montones ya empezados.
local function bagRoom(id, stackSize)
	local C = C_Container
	if not C then return nil, nil end
	local free, partial = 0, 0
	for bag = 0, (NUM_BAG_SLOTS or 4) do
		local n, family = C.GetContainerNumFreeSlots(bag)
		if (family or 0) == 0 then free = free + (n or 0) end
		for slot = 1, C.GetContainerNumSlots(bag) or 0 do
			local info = C.GetContainerItemInfo(bag, slot)
			if info and ok(info.itemID) == id and ok(info.stackCount) then
				partial = partial + math.max(0, stackSize - info.stackCount)
			end
		end
	end
	return free, partial
end

---------------------------------------------------------------------------
-- Ventanita
---------------------------------------------------------------------------

local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local frame = CreateFrame("Frame", "ComprarVariosFrame", UIParent)
frame:SetSize(260, 196)
frame:SetFrameStrata("DIALOG")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local function texture(parent, r, g, b, a, layer)
	local t = parent:CreateTexture(nil, layer or "BACKGROUND")
	t:SetColorTexture(r, g, b, a)
	return t
end
texture(frame, 0.04, 0.04, 0.06, 1):SetAllPoints()
for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
	{ "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
	local t = texture(frame, 0.75, 0.6, 0.2, 1, "BORDER")
	t:SetPoint(side[1]); t:SetPoint(side[2])
	if side[3] then t:SetHeight(1) else t:SetWidth(1) end
end
local function text(size, r, g, b)
	local fs = frame:CreateFontString(nil, "OVERLAY")
	fs:SetFont(FONT, size, "")
	fs:SetTextColor(r or 1, g or 1, b or 1)
	fs:SetJustifyH("LEFT")
	return fs
end
local function button(label, w, h)
	local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	b:SetSize(w, h or 22)
	b:SetText(label)
	return b
end

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(30, 30)
icon:SetPoint("TOPLEFT", 10, -10)
local title = text(13)
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
title:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
title:SetWordWrap(true)
local unitText = text(11, 0.8, 0.8, 0.8)
unitText:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -6)
unitText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

local minus = button("-", 24)
minus:SetPoint("TOPLEFT", 10, -76)
local box = CreateFrame("EditBox", nil, frame)
box:SetSize(64, 22)
box:SetPoint("LEFT", minus, "RIGHT", 4, 0)
box:SetFont(FONT, 14, "")
box:SetTextColor(1, 1, 1)
box:SetJustifyH("CENTER")
box:SetAutoFocus(false)
box:SetNumeric(true)
box:SetMaxLetters(5)
texture(box, 0, 0, 0, 0.7):SetAllPoints()
local plus = button("+", 24)
plus:SetPoint("LEFT", box, "RIGHT", 4, 0)
local stackBtn = button("+1 montón", 90)
stackBtn:SetPoint("LEFT", plus, "RIGHT", 6, 0)

local totalText = text(12)
totalText:SetPoint("TOPLEFT", 10, -108)
totalText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
local roomText = text(11, 0.8, 0.8, 0.8)
roomText:SetPoint("TOPLEFT", totalText, "BOTTOMLEFT", 0, -4)
roomText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
local statusText = text(11, 1, 0.82, 0)
statusText:SetPoint("TOPLEFT", roomText, "BOTTOMLEFT", 0, -4)
statusText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)

local maxBtn = button("Lo que pueda pagar", 130)
maxBtn:SetPoint("BOTTOMLEFT", 10, 10)
local buyBtn = button("Comprar", 100)
buyBtn:SetPoint("BOTTOMRIGHT", -10, 10)

---------------------------------------------------------------------------
-- Lógica
---------------------------------------------------------------------------

local state = { index = nil, id = nil, amount = 0, buying = false }

-- Datos del objeto elegido: unidad (precio por objeto), lote (se vende de N en N),
-- tope por compra, cuántos puedes pagar y cuántos quedan.
local function current()
	if not state.index then return nil end
	local info = itemInfo(state.index)
	if not info or itemID(state.index) ~= state.id then return nil end
	local lot = math.max(1, info.stackCount or 1)
	local perBuy = math.max(lot, (GetMerchantItemMaxStack and ok(GetMerchantItemMaxStack(state.index))) or lot)
	local unit = (info.price or 0) / lot
	local afford = unit > 0 and math.floor(GetMoney() / unit) or 99999
	afford = afford - afford % lot
	local left = info.numAvailable and info.numAvailable >= 0 and info.numAvailable * lot or nil
	local stackSize = (C_Item and C_Item.GetItemMaxStackSizeByID and ok(C_Item.GetItemMaxStackSizeByID(state.id))) or perBuy
	return { info = info, lot = lot, perBuy = perBuy, unit = unit, afford = afford, left = left, stackSize = math.max(1, stackSize) }
end

local function clampAmount(c, n)
	n = math.max(0, math.floor(tonumber(n) or 0))
	n = n - n % c.lot
	if c.left then n = math.min(n, c.left) end
	return math.min(n, 99999)
end

local function refresh()
	local c = current()
	if not c then
		frame:Hide()
		return
	end
	local info = c.info
	icon:SetTexture(info.texture)
	local quality = C_Item and C_Item.GetItemQualityByID and ok(C_Item.GetItemQualityByID(state.id))
	local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	title:SetText((color and color.hex or "|cffffffff") .. (info.name or "?") .. "|r")
	local unitLine = "Precio: " .. money(c.unit) .. " cada uno"
	if c.lot > 1 then unitLine = unitLine .. " (se vende de " .. c.lot .. " en " .. c.lot .. ")" end
	if c.left then unitLine = unitLine .. " · quedan " .. c.left end
	unitText:SetText(unitLine)
	if not box:HasFocus() then box:SetText(tostring(state.amount)) end
	local total = c.unit * state.amount
	local canPay = total <= GetMoney()
	totalText:SetText("Total: " .. money(total) .. (canPay and "" or "  |cffff4040(no te llega)|r"))
	local free, partial = bagRoom(state.id, c.stackSize)
	if free then
		local slots = math.max(0, math.ceil((state.amount - partial) / c.stackSize))
		local fits = slots <= free
		roomText:SetText((fits and "" or "|cffff4040") .. "Ocupa " .. slots .. (slots == 1 and " hueco" or " huecos")
			.. " (tienes " .. free .. " libres)" .. (fits and "" or "|r"))
	else
		roomText:SetText("")
	end
	if info.extended then
		statusText:SetText("Este se paga con algo más que oro: cómpralo como siempre.")
		buyBtn:Disable()
	elseif state.buying then
		statusText:SetText("Comprando… quedan " .. state.remaining .. ".")
		buyBtn:SetText("Parar")
		buyBtn:Enable()
	else
		buyBtn:SetText("Comprar")
		buyBtn:SetEnabled(state.amount > 0 and canPay)
		if not statusText.keep then statusText:SetText("") end
	end
	minus:SetEnabled(not state.buying)
	plus:SetEnabled(not state.buying)
	stackBtn:SetEnabled(not state.buying)
	maxBtn:SetEnabled(not state.buying)
	if state.buying then box:Disable() else box:Enable() end
end

local function setAmount(n)
	local c = current()
	if not c then return end
	state.amount = clampAmount(c, n)
	statusText.keep = nil
	refresh()
end

local ticker
local function stop(message)
	if ticker then ticker:Cancel() ticker = nil end
	state.buying = false
	if message then
		statusText:SetText(message)
		statusText.keep = true
	end
	refresh()
end

local function step()
	local c = current()
	if not c or not (MerchantFrame and MerchantFrame:IsShown()) then
		return stop("Se ha cerrado el mercader o ha cambiado su lista.")
	end
	if state.remaining <= 0 then
		return stop("Hecho: " .. state.bought .. " comprados.")
	end
	local q = math.min(state.remaining, c.perBuy)
	q = q - q % c.lot
	if c.left then q = math.min(q, c.left) end
	if q <= 0 then return stop("No quedan más en el mercader.") end
	if GetMoney() < c.unit * q then
		return stop("Sin oro: " .. state.bought .. " comprados.")
	end
	BuyMerchantItem(state.index, q)
	state.remaining = state.remaining - q
	state.bought = state.bought + q
	refresh()
end

local function startBuying()
	local c = current()
	if not c or state.amount <= 0 or c.info.extended then return end
	if InCombatLockdown and InCombatLockdown() then
		statusText:SetText("Espera a salir de combate.")
		statusText.keep = true
		return
	end
	state.buying = true
	state.remaining = state.amount
	state.bought = 0
	step()
	if state.buying then
		ticker = C_Timer.NewTicker(STEP_SECONDS, step)
	end
end

local function open(index)
	if state.buying then return end
	local id = itemID(index)
	local info = id and itemInfo(index)
	if not info then return end
	state.index, state.id = index, id
	local lot = math.max(1, info.stackCount or 1)
	local perBuy = (GetMerchantItemMaxStack and ok(GetMerchantItemMaxStack(index))) or lot
	state.amount = math.max(lot, perBuy)
	statusText.keep = nil
	frame:ClearAllPoints()
	if MerchantFrame and MerchantFrame:IsShown() then
		frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, -60)
	else
		frame:SetPoint("CENTER")
	end
	frame:Show()
	local c = current()
	if c then state.amount = clampAmount(c, state.amount) end
	refresh()
end

minus:SetScript("OnClick", function()
	local c = current(); if c then setAmount(state.amount - c.lot) end
end)
plus:SetScript("OnClick", function()
	local c = current(); if c then setAmount(state.amount + c.lot) end
end)
stackBtn:SetScript("OnClick", function()
	local c = current(); if c then setAmount(state.amount + math.max(c.lot, c.stackSize - c.stackSize % c.lot)) end
end)
maxBtn:SetScript("OnClick", function()
	local c = current()
	if not c then return end
	local n = c.afford
	local free, partial = bagRoom(state.id, c.stackSize)
	if free then n = math.min(n, free * c.stackSize + partial) end
	setAmount(n)
end)
buyBtn:SetScript("OnClick", function()
	if state.buying then stop("Parado: " .. state.bought .. " comprados.") else startBuying() end
end)
box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); setAmount(self:GetText()) end)
box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); refresh() end)
box:SetScript("OnEditFocusLost", function(self) setAmount(self:GetText()) end)
close:SetScript("OnClick", function() frame:Hide() end)
frame:SetScript("OnHide", function() if state.buying then stop() end end)

---------------------------------------------------------------------------
-- Alt + clic en un objeto del mercader
---------------------------------------------------------------------------

local function merchantButtonUnderMouse()
	local foci = GetMouseFoci and GetMouseFoci() or (GetMouseFocus and { GetMouseFocus() })
	if type(foci) ~= "table" then return end
	for _, f in ipairs(foci) do
		local name = type(f) == "table" and f.GetName and f:GetName()
		if type(name) == "string" and name:match("^MerchantItem%d+ItemButton$") and f.GetID then
			return f:GetID()
		end
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("GLOBAL_MOUSE_UP")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("PLAYER_MONEY")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:SetScript("OnEvent", function(_, event, a1, a2)
	if event == "GLOBAL_MOUSE_UP" then
		if not (IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown()) then return end
		if not (MerchantFrame and MerchantFrame:IsShown() and (MerchantFrame.selectedTab or 1) == 1) then return end
		local index = merchantButtonUnderMouse()
		if index and index > 0 then
			C_Timer.After(0, function() open(index) end)
		end
	elseif event == "MERCHANT_CLOSED" then
		frame:Hide()
	elseif event == "UI_ERROR_MESSAGE" then
		if state.buying then
			-- Bolsas llenas, sin oro, agotado…: el juego lo dice y se para.
			stop("Parado: " .. tostring(ok(a2) or "error") .. " (" .. state.bought .. " comprados).")
		end
	elseif frame:IsShown() then
		refresh()
	end
end)
