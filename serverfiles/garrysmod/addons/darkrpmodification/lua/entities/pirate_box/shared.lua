ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Pirate Box"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "price")
	self:NetworkVar("Entity", 0, "owning_ent")
	self:NetworkVar("Bool", 0, "HasStoredPrinter")
	self:NetworkVar("String", 0, "StoredPrinterClass")
	self:NetworkVar("Int", 1, "StoredPrinterMoney")
	self:NetworkVar("Bool", 1, "StoredCooler")
	self:NetworkVar("Bool", 2, "StoredAmountUpgrade")
	self:NetworkVar("Bool", 3, "StoredTimerUpgrade")
	self:NetworkVar("Bool", 4, "StoredSilencer")
	self:NetworkVar("Bool", 5, "StoredArmor")
end