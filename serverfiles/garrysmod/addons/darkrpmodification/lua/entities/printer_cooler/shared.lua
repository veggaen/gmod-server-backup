ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Printer Cooler Upgrade"
ENT.Author = "v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.UpgradeName = "Cooler Upgrade"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "price")
	self:NetworkVar("Entity", 0, "owning_ent")
end