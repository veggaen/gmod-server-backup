include("shared.lua")

function ENT:Initialize()
	surface.CreateFont("OldGoldAmmoUpgradeTitle", {
		font = "Tahoma",
		size = 26,
		weight = 500,
		antialias = true,
	})

	surface.CreateFont("OldGoldAmmoUpgradeBody", {
		font = "Tahoma",
		size = 17,
		weight = 1000,
		antialias = true,
	})
end

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), 90)

	cam.Start3D2D(pos + ang:Up() * 3.2, ang, 0.11)
		draw.RoundedBox(0, -100, -40, 198, 75, Color(0, 0, 0, 100))
		draw.WordBox(2, -30, -30, "SMG", "OldGoldAmmoUpgradeTitle", Color(0, 0, 0, 0), Color(255, 255, 255, 255))
		draw.WordBox(2, -90, 0, "Adds extra SMG ammo", "OldGoldAmmoUpgradeBody", Color(0, 0, 0, 0), Color(255, 255, 255, 255))
	cam.End3D2D()
end