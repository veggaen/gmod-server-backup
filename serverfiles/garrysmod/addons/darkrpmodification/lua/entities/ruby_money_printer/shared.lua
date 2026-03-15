ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Ruby Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Ruby Printer"
	self.DisplayName = "Ruby Printer"
	self.MoneyCount = 750
	self.OverheatChance = 20
	self.MinTimer = 70
	self.MaxTimer = 180
	self.SeizeReward = 3000
	self:Setprice(5000)
end