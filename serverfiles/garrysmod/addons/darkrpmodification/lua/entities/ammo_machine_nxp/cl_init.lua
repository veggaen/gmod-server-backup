include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)

	local title = "Ammo Machine"
	local ammoText = "Ammo " .. self:GetAmmoStored()
	local upgradeText = self:GetHasSmgExtra() and "SMG Extra Installed" or "No SMG Extra"

	surface.SetFont("HUDNumber5")
	local titleWidth = surface.GetTextSize(title)
	local ammoWidth = surface.GetTextSize(ammoText)
	local upgradeWidth = surface.GetTextSize(upgradeText)

	local textAng = ang
	textAng:RotateAroundAxis(textAng:Right(), CurTime() * -180)

	cam.Start3D2D(pos + ang:Right() * -30, textAng, 0.2)
		draw.WordBox(2, -titleWidth * 0.5 + 8, -128, title, "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
		draw.WordBox(2, -ammoWidth * 0.5 + 8, -92, ammoText, "HUDNumber5", Color(140, 0, 0, 100), Color(255, 255, 255, 255))
		draw.WordBox(2, -upgradeWidth * 0.5 + 8, -56, upgradeText, "HUDNumber5", Color(20, 20, 20, 140), Color(130, 220, 255, 255))
	cam.End3D2D()
end