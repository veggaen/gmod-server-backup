ENT.Type = "anim"
ENT.Base = "custom_moneyprinter"
ENT.PrintName = "Unobtainium Printer"
ENT.Author = "DarkRP Developers and v3gga"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
	self.BaseClass.initVars(self)
	self.PrintName = "Unobtainium Printer"
	self.DisplayName = "Unobtainium Printer"
	self.MoneyCount = 2200
	self.OverheatChance = 8
	self.MinTimer = 38
	self.MaxTimer = 95
	self.SeizeReward = 12000
	self:Setprice(35000)
end