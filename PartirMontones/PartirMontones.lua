-- Partir montones 1.1 (2026-11-18; 1.1 del 19-11: dar solo una parte en el comercio)
--
-- Mayús + clic izquierdo en un montón de las bolsas abre la ventanita de Blizzard para
-- partirlo (eliges cuántos con las flechas o escribiendo el número y Aceptar). Lo que
-- coges se queda en el ratón: lo sueltas en la ventana de comercio, en una casilla vacía,
-- encima de otro montón o en el suelo (para tirarlo).
--
-- Es una red de seguridad: si la ventanita ya la abre el juego, no hace nada. Solo actúa
-- cuando, tras un Mayús + clic izquierdo en una casilla de las bolsas (las de Blizzard o
-- las de Baganator), la ventanita no se ha abierto:
--   * si el objeto está en un montón de más de 1, la abre;
--   * si es un objeto que no se apila (cada uno ocupa su casilla; Baganator los enseña
--     juntos con un número), avisa de que no se puede partir y de que se cogen de uno en uno.
-- Si estás escribiendo (chat u otra caja de texto), Mayús + clic sigue poniendo el enlace
-- del objeto como siempre.
-- Con la ventana de comercio abierta, al aceptar, la parte va sola al comercio (ver abajo).
--
-- Cómo: escucha GLOBAL_MOUSE_UP, mira qué casilla hay bajo el ratón (GetMouseFoci) y en el
-- fotograma siguiente comprueba si StackSplitFrame se ha abierto. Para abrirla usa un marco
-- propio encima de la casilla como «dueño» de la ventanita; al aceptar, llama a
-- C_Container.SplitContainerItem. No cambia nada de Blizzard ni de Baganator: solo los lee.

local C = C_Container
if not (C and C.SplitContainerItem and StackSplitFrame and StackSplitFrame.OpenStackSplitFrame) then return end

local issecret = issecretvalue or function() return false end
local function readable(v)
	if v == nil or issecret(v) then return nil end
	return v
end

-- Dueño de la ventanita: un marco propio puesto encima de la casilla.
local owner = CreateFrame("Frame", nil, UIParent)
owner:SetSize(1, 1)
owner:Hide()

local function closeIfOurs()
	if StackSplitFrame.owner == owner and StackSplitFrame:IsShown() then
		StackSplitFrame:Hide()
	end
end

-- Si la casilla desaparece (cierras las bolsas), se cierra también la ventanita.
owner:SetScript("OnUpdate", function(self)
	if StackSplitFrame.owner ~= self or not StackSplitFrame:IsShown() then
		self:Hide()
		return
	end
	if not (self.button and self.button:IsVisible()) then
		closeIfOurs()
		self:Hide()
	end
end)

owner.SplitStack = function(self, amount)
	amount = tonumber(amount)
	if not (amount and amount > 0 and self.bag and self.slot) then return end
	if CursorHasItem() then return end
	local info = C.GetContainerItemInfo(self.bag, self.slot)
	local id = info and readable(info.itemID)
	if id ~= self.itemID or readable(info.isLocked) then return end
	C.SplitContainerItem(self.bag, self.slot, amount)
end

-- La casilla de bolsa que hay bajo el ratón, si la hay: botón, bolsa y casilla.
local function bagSlotUnderMouse()
	local foci
	if GetMouseFoci then
		foci = GetMouseFoci()
	elseif GetMouseFocus then
		foci = { GetMouseFocus() }
	end
	if type(foci) ~= "table" then return end
	for _, f in ipairs(foci) do
		if type(f) == "table" and f.GetBagID and f.GetID then
			local okBag, bag = pcall(f.GetBagID, f)
			local okSlot, slot = pcall(f.GetID, f)
			bag, slot = okBag and readable(bag), okSlot and readable(slot)
			if type(bag) == "number" and type(slot) == "number" and slot > 0 then
				return f, bag, slot
			end
		end
	end
end

local function say(text)
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage(text, 1, 0.82, 0)
	end
end

local function afterClick(button, bag, slot)
	if StackSplitFrame:IsShown() then return end -- ya la ha abierto el juego
	if CursorHasItem() then return end -- el clic ha cogido algo
	if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then return end -- enlace al chat
	if not button:IsVisible() then return end
	local info = C.GetContainerItemInfo(bag, slot)
	if not info then return end
	local count = readable(info.stackCount)
	local id = readable(info.itemID)
	if not (count and id) then return end
	if readable(info.isLocked) then return end
	if count <= 1 then
		local maxStack
		if C_Item and C_Item.GetItemMaxStackSizeByID then
			maxStack = readable(C_Item.GetItemMaxStackSizeByID(id))
		end
		if not maxStack and C_Item and C_Item.GetItemInfo then
			maxStack = readable((select(8, C_Item.GetItemInfo(id))))
		end
		if maxStack == 1 then
			say("Este objeto no se apila: cada uno va en su casilla y se coge de uno en uno.")
		else
			say("En esta casilla solo hay 1.")
		end
		return
	end
	owner.bag, owner.slot, owner.itemID, owner.button = bag, slot, id, button
	owner:ClearAllPoints()
	owner:SetAllPoints(button)
	owner:Show()
	StackSplitFrame:OpenStackSplitFrame(count, owner, "BOTTOMRIGHT", "TOPRIGHT")
end

local events = CreateFrame("Frame")
events:RegisterEvent("GLOBAL_MOUSE_UP")
events:SetScript("OnEvent", function(_, _, mouseButton)
	if mouseButton ~= "LeftButton" then return end
	if not IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then return end
	local button, bag, slot = bagSlotUnderMouse()
	if not button then return end
	-- El clic del botón todavía se está procesando: se mira en el fotograma siguiente.
	C_Timer.After(0, function() afterClick(button, bag, slot) end)
end)

---------------------------------------------------------------------------
-- Con la ventana de comercio abierta (1.1)
---------------------------------------------------------------------------
-- El comercio no guarda cantidades: cada casilla del comercio apunta a una casilla de tus
-- bolsas y se da lo que haya en ella. Si partes 3 de un montón de 12 y sueltas esos 3 en el
-- comercio, se ponen los 12. Por eso, con el comercio abierto, al aceptar la ventanita el
-- addon deja la parte en un hueco libre de las bolsas y mete ese hueco en el comercio.
-- Sin hueco libre devuelve la parte a su montón y avisa (si no, darías el montón entero).
-- Solo lee la ventanita de Blizzard (cuánto elegiste); no engancha nada de Blizzard.

local abiertaHasta = -math.huge -- última vez que se vio abierta la ventanita
local enCurso                   -- { bag, slot, id, n, hasta }: parte dejada en un hueco

local function comercioAbierto()
	return TradeFrame and TradeFrame:IsShown()
end

local function huecoLibre(itemID)
	local family = C_Item and C_Item.GetItemFamily and readable(C_Item.GetItemFamily(itemID)) or 0
	for bag = 0, NUM_BAG_SLOTS or 4 do
		local free, bagFamily = C.GetContainerNumFreeSlots(bag)
		free, bagFamily = readable(free), readable(bagFamily)
		if free and free > 0 and (bagFamily == 0 or (bagFamily and bit.band(family, bagFamily) ~= 0)) then
			for slot = 1, readable(C.GetContainerNumSlots(bag)) or 0 do
				if not C.GetContainerItemInfo(bag, slot) then return bag, slot end
			end
		end
	end
end

local function casillaDeComercioLibre()
	for i = 1, MAX_TRADABLE_ITEMS or 6 do
		local name, texture = GetTradePlayerItemInfo(i)
		if not (readable(name) or readable(texture)) then return i end
	end
end

-- Justo después de aceptar la ventanita: la parte está en el ratón.
local function alCambiarCursor()
	if enCurso or not comercioAbierto() or StackSplitFrame:IsShown() then return end
	if GetTime() - abiertaHasta > 0.2 then return end -- no viene de la ventanita
	if not CursorHasItem() then return end           -- cancelada
	local n, total = tonumber(StackSplitFrame.split), tonumber(StackSplitFrame.maxStack)
	if not (n and total and n < total) then return end -- el montón entero: ya va bien
	local loc = C_Cursor and C_Cursor.GetCursorItem and C_Cursor.GetCursorItem()
	if loc and loc.IsBagAndSlot and not loc:IsBagAndSlot() then return end -- no es de tus bolsas
	local kind, id = GetCursorInfo()
	if kind ~= "item" or not readable(id) then return end
	local bag, slot = huecoLibre(id)
	if not bag then
		ClearCursor()
		say(("Para dar solo %d necesitas un hueco libre en las bolsas: el comercio da siempre el montón entero."):format(n))
		return
	end
	C.PickupContainerItem(bag, slot) -- deja la parte en el hueco
	enCurso = { bag = bag, slot = slot, id = id, n = n, hasta = GetTime() + 5 }
end

-- Cuando la parte ya está en su hueco (el servidor la ha creado), al comercio.
local function seguir()
	local e = enCurso
	if not e then return end
	if not comercioAbierto() or GetTime() > e.hasta then enCurso = nil; return end
	if CursorHasItem() then return end
	local info = C.GetContainerItemInfo(e.bag, e.slot)
	if not info or readable(info.itemID) ~= e.id or readable(info.isLocked) then return end
	enCurso = nil
	local i = casillaDeComercioLibre()
	if not i then
		say(("El comercio está lleno: los %d se quedan en tus bolsas."):format(e.n))
		return
	end
	C.PickupContainerItem(e.bag, e.slot)
	ClickTradeButton(i)
	if CursorHasItem() then ClearCursor() end
end

local trade = CreateFrame("Frame")
trade:Hide()
trade:SetScript("OnUpdate", function()
	if StackSplitFrame:IsShown() then abiertaHasta = GetTime() end
	if enCurso then seguir() end
end)
trade:RegisterEvent("TRADE_SHOW")
trade:RegisterEvent("TRADE_CLOSED")
trade:RegisterEvent("CURSOR_CHANGED")
trade:SetScript("OnEvent", function(self, event)
	if event == "TRADE_SHOW" then
		self:Show()
	elseif event == "TRADE_CLOSED" then
		self:Hide()
		enCurso = nil
	elseif event == "CURSOR_CHANGED" and self:IsShown() then
		-- El cursor cambia mientras se procesa el clic: se mira en el fotograma siguiente.
		C_Timer.After(0, alCambiarCursor)
	end
end)
