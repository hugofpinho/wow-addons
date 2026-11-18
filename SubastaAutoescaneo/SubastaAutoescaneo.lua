-- Subasta: escaneo automático 1.0 (2026-11-18)
--
-- Auctionator ya sabe escanear la casa de subastas él solo al abrirla (opción
-- «Ejecutar escaneo automático al abrir la casa de subastas», autoscan_2), pero viene
-- apagada. Este addon la enciende al entrar en el juego si está apagada; nada más.
-- El escaneo lo hace Auctionator: al abrir la subasta, si han pasado al menos los minutos
-- de su «Intervalo entre escaneos automáticos» (15 por defecto) desde el último, pide la
-- lista completa (búsqueda vacía) y guarda los precios en su registro.

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	local A = Auctionator
	local C = A and A.Config
	if not (C and C.Get and C.Set and C.Options and C.Options.AUTOSCAN) then return end
	if not C.Get(C.Options.AUTOSCAN) then
		pcall(C.Set, C.Options.AUTOSCAN, true)
	end
end)
