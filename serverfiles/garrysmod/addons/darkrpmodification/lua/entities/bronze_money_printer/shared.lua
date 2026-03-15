ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Bronze Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Bronze Printer"
	self.DisplayName = "Bronze Printer"
	self.MoneyCount = 300
	self.OverheatChance = 28
	self.MinTimer = 95
	self.MaxTimer = 230
	self.SeizeReward = 900
	self:Setprice(1000)
end