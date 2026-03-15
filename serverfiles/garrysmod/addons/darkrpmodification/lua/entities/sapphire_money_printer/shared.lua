ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Sapphire Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Sapphire Printer"
	self.DisplayName = "Sapphire Printer"
	self.MoneyCount = 1000
	self.OverheatChance = 16
	self.MinTimer = 60
	self.MaxTimer = 160
	self.SeizeReward = 4500
	self:Setprice(7500)
end