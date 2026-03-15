ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ammo Machine"
ENT.Author = "v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "price")
	self:NetworkVar("Entity", 0, "owning_ent")
	self:NetworkVar("Int", 1, "AmmoStored")
	self:NetworkVar("Bool", 0, "HasSmgExtra")
end