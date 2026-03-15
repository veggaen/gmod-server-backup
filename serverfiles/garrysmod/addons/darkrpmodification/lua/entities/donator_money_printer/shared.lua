ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Donator Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Donator Printer"
	self.DisplayName = "Donator Printer"
	self.MoneyCount = 360
	self.OverheatChance = 27
	self.MinTimer = 90
	self.MaxTimer = 220
	self.SeizeReward = 1000
	self:Setprice(1000)
end