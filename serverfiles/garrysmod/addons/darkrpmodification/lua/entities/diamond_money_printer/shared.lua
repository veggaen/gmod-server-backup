ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Diamond Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Diamond Printer"
	self.DisplayName = "Diamond Printer"
	self.MoneyCount = 1450
	self.OverheatChance = 11
	self.MinTimer = 48
	self.MaxTimer = 122
	self.SeizeReward = 9000
	self:Setprice(30000)
end