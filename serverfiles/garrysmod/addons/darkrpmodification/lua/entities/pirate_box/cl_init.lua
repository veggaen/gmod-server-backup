include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local state = self:GetHasStoredPrinter() and self:GetStoredPrinterClass() or "Empty"
	local storedMoney = self:GetHasStoredPrinter() and ("Stored: " .. DarkRP.formatMoney(self:GetStoredPrinterMoney())) or "Touch a printer to pack it"

	ang:RotateAroundAxis(ang:Up(), 90)

	surface.SetFont("HUDNumber5")
	local width1 = surface.GetTextSize("Pirate Box")
	local width2 = surface.GetTextSize(state)
	local width3 = surface.GetTextSize(storedMoney)

	cam.Start3D2D(pos + ang:Up() * 26, ang, 0.11)
		draw.WordBox(2, -width1 * 0.5, -44, "Pirate Box", "HUDNumber5", Color(80, 40, 0, 140), Color(255, 255, 255, 255))
		draw.WordBox(2, -width2 * 0.5, -2, state, "HUDNumber5", Color(20, 20, 20, 140), Color(255, 220, 120, 255))
		draw.WordBox(2, -width3 * 0.5, 40, storedMoney, "HUDNumber5", Color(20, 20, 20, 140), Color(200, 255, 200, 255))
	cam.End3D2D()
end