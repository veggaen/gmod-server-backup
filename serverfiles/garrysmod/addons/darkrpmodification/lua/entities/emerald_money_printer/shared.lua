ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Emerald Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Emerald Printer"
	self.DisplayName = "Emerald Printer"
	self.MoneyCount = 500
	self.OverheatChance = 24
	self.MinTimer = 80
	self.MaxTimer = 200
	self.SeizeReward = 1750
	self:Setprice(2500)
end