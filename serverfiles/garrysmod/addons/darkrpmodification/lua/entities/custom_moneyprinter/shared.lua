--[[---------------------------------------------------------------------------
This is an example of a custom entity.
---------------------------------------------------------------------------]]
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Money Printer"
ENT.Author = "DarkRP Developers and <enter name here>"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:initVars()
    self.DisplayName = self.PrintName or "Money Printer"
    self.MoneyCount = self.MoneyCount or (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.mprintamount) or 250
    self.OverheatChance = self.OverheatChance or 22
    self.MinTimer = self.MinTimer or 100
    self.MaxTimer = self.MaxTimer or 350
    self.SeizeReward = self.SeizeReward or 950
    self.BaseHealth = self.BaseHealth or 100
    self.AmountUpgradeMultiplier = self.AmountUpgradeMultiplier or 1.5
    self.TimerUpgradeMultiplier = self.TimerUpgradeMultiplier or 0.7
    self.CoolerOverheatMultiplier = self.CoolerOverheatMultiplier or 1.8
    self.ArmorDamageMultiplier = self.ArmorDamageMultiplier or 0.55
    self:Setprice(self:Getprice() > 0 and self:Getprice() or 0)
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "price")
    self:NetworkVar("Entity", 0, "owning_ent")
    self:NetworkVar("Int", 1, "StoredMoney")
    self:NetworkVar("Bool", 0, "HasCooler")
    self:NetworkVar("Bool", 1, "HasAmountUpgrade")
    self:NetworkVar("Bool", 2, "HasTimerUpgrade")
    self:NetworkVar("Bool", 3, "HasSilencer")
    self:NetworkVar("Bool", 4, "HasArmor")
end
