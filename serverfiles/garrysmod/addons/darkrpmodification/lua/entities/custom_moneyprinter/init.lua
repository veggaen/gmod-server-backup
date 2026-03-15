--[[---------------------------------------------------------------------------
This is an example of a custom entity.
---------------------------------------------------------------------------]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.SeizeReward = 950

function ENT:Initialize()
    self:initVars()
    self:SetModel("models/props_c17/consolebox01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    self.sparking = false
    self.damage = self.BaseHealth or 100
    self.IsMoneyPrinter = true
    self:SetStoredMoney(0)
    self:SetNWInt("PrintA", 0)
    self:SetNWString("PrinterName", self.DisplayName or self.PrintName or "Money Printer")
    self:SetHasCooler(false)
    self:SetHasAmountUpgrade(false)
    self:SetHasTimerUpgrade(false)
    self:SetHasSilencer(false)
    self:SetHasArmor(false)
    self.NextPrintAt = CurTime() + self:GetPrintDelay()

    self.sound = CreateSound(self, Sound("ambient/levels/labs/equipment_printer_loop1.wav"))
    self.sound:SetSoundLevel(52)
    self.sound:PlayEx(1, 100)
end

function ENT:GetPrintDelay()
    local minTimer = self.MinTimer or 100
    local maxTimer = self.MaxTimer or 350

    if self:GetHasTimerUpgrade() then
        minTimer = math.max(10, math.floor(minTimer * self.TimerUpgradeMultiplier))
        maxTimer = math.max(minTimer, math.floor(maxTimer * self.TimerUpgradeMultiplier))
    end

    return math.random(minTimer, maxTimer)
end

function ENT:GetPrintAmount()
    local amount = self.MoneyCount or (GAMEMODE.Config.mprintamount > 0 and GAMEMODE.Config.mprintamount) or 250
    if self:GetHasAmountUpgrade() then
        amount = math.floor(amount * self.AmountUpgradeMultiplier)
    end

    return amount
end

function ENT:GetEffectiveOverheatChance()
    local chance = self.OverheatChance or 22
    if self:GetHasCooler() then
        chance = math.floor(chance * self.CoolerOverheatMultiplier)
    end

    return math.max(chance, 4)
end

function ENT:OnTakeDamage(dmg)
    if self.burningup then return end

    local appliedDamage = dmg:GetDamage()
    if self:GetHasArmor() then
        appliedDamage = appliedDamage * self.ArmorDamageMultiplier
    end

    self.damage = (self.damage or 100) - appliedDamage
    if self.damage <= 0 then
        local rnd = math.random(1, 10)
        if rnd < 3 then
            self:BurstIntoFlames()
        else
            self:Destruct()
            self:Remove()
        end
    end
end

function ENT:Destruct()
    local vPoint = self:GetPos()
    local effectdata = EffectData()
    effectdata:SetStart(vPoint)
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(1)
    util.Effect("Explosion", effectdata)
    local owner = self:Getowning_ent()
    if IsValid(owner) then
    	DarkRP.notify(owner, 1, 4, DarkRP.getPhrase("money_printer_exploded"))
    end
end

function ENT:BurstIntoFlames()
    local owner = self:Getowning_ent()
    if IsValid(owner) then
    	DarkRP.notify(owner, 0, 4, DarkRP.getPhrase("money_printer_overheating"))
    end
    self.burningup = true
    local burntime = math.random(8, 18)
    self:Ignite(burntime, 0)
    timer.Simple(burntime, function() self:Fireball() end)
end

function ENT:Fireball()
    if not self:IsOnFire() then self.burningup = false return end
    local dist = math.random(20, 280) -- Explosion radius
    self:Destruct()
    for k, v in pairs(ents.FindInSphere(self:GetPos(), dist)) do
        if not v:IsPlayer() and not v:IsWeapon() and v:GetClass() ~= "predicted_viewmodel" and not v.IsMoneyPrinter then
            v:Ignite(math.random(5, 22), 0)
        elseif v:IsPlayer() then
            local distance = v:GetPos():Distance(self:GetPos())
            v:TakeDamage(distance / dist * 100, self, self)
        end
    end
    self:Remove()
end

function ENT:CreateMoneybag()
    if not IsValid(self) or self:IsOnFire() then return end

    if GAMEMODE.Config.printeroverheat then
        local overheatchance = self:GetEffectiveOverheatChance()
        if math.random(1, overheatchance) == 3 then self:BurstIntoFlames() end
    end

    local stored = self:GetStoredMoney() + self:GetPrintAmount()
    self:SetStoredMoney(stored)
    self:SetNWInt("PrintA", stored)
    self.sparking = false
    self.NextPrintAt = CurTime() + self:GetPrintDelay()
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then
        return
    end

    local amount = self:GetStoredMoney()
    if amount <= 0 then
        return
    end

    activator:addMoney(amount)
    DarkRP.notify(activator, 0, 4, "You collected $" .. amount .. " from the " .. (self.DisplayName or self.PrintName or "printer") .. ".")
    self:SetStoredMoney(0)
    self:SetNWInt("PrintA", 0)

    if not self:GetHasSilencer() then
        self:EmitSound("items/ammo_pickup.wav", 65, 95)
    end
end

local upgradeMap = {
    printer_cooler = "HasCooler",
    printer_amount = "HasAmountUpgrade",
    printer_timer = "HasTimerUpgrade",
    printer_silencer = "HasSilencer",
    printer_armor = "HasArmor",
}

function ENT:Touch(ent)
    if not IsValid(ent) then
        return
    end

    local setter = upgradeMap[ent:GetClass()]
    if not setter or self["Get" .. setter](self) then
        return
    end

    self["Set" .. setter](self, true)
    ent:Remove()

    local owner = self:Getowning_ent()
    if IsValid(owner) then
        DarkRP.notify(owner, 0, 4, (ent.UpgradeName or "Printer upgrade") .. " installed on your printer.")
    end

    self:EmitSound("items/suitchargeok1.wav", 70, 100)
end

function ENT:Think()

    if self:WaterLevel() > 0 then
        self:Destruct()
        self:Remove()
        return
    end

    if CurTime() >= (self.NextPrintAt or 0) and not self.sparking then
        self.sparking = true
        timer.Simple(3, function()
            if IsValid(self) then
                self:CreateMoneybag()
            end
        end)
        self.NextPrintAt = math.huge
    end

    if not self.sparking then
        self:NextThink(CurTime() + 0.25)
        return true
    end

    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetMagnitude(1)
    effectdata:SetScale(1)
    effectdata:SetRadius(2)
    util.Effect("Sparks", effectdata)

    self:NextThink(CurTime() + 0.25)
    return true
end

function ENT:OnRemove()
    if self.sound then
        self.sound:Stop()
    end
end
