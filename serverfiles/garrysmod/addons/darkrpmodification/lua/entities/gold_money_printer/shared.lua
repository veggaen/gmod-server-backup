ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Gold Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Gold Printer"
	self.DisplayName = "Gold Printer"
	self.MoneyCount = 850
	self.OverheatChance = 19
	self.MinTimer = 72
	self.MaxTimer = 180
	self.SeizeReward = 3200
	self:Setprice(8000)
end