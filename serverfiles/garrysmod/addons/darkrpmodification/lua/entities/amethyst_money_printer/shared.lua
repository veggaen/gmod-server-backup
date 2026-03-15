ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Amethyst Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Amethyst Printer"
	self.DisplayName = "Amethyst Printer"
	self.MoneyCount = 375
	self.OverheatChance = 28
	self.MinTimer = 90
	self.MaxTimer = 220
	self.SeizeReward = 1250
	self:Setprice(1500)
end