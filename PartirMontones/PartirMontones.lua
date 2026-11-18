-- Partir montones 1.0 (2026-11-18)
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
