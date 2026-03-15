ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Silver Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Silver Printer"
	self.DisplayName = "Silver Printer"
	self.MoneyCount = 500
	self.OverheatChance = 24
	self.MinTimer = 82
	self.MaxTimer = 205
	self.SeizeReward = 1700
	self:Setprice(3000)
end