ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Printer Armor Upgrade"
ENT.Author = "v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.UpgradeName = "Armor Upgrade"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "price")
	self:NetworkVar("Entity", 0, "owning_ent")
end