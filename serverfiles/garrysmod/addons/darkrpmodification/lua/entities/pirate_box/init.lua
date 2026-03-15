AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.SeizeReward = 950

function ENT:Initialize()
	self:SetModel("models/props_c17/oildrum001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(25)
		phys:Wake()
	end

	self.damage = 140
	self:SetHasStoredPrinter(false)
	self:SetStoredPrinterClass("")
	self:SetStoredPrinterMoney(0)
	self:SetStoredCooler(false)
	self:SetStoredAmountUpgrade(false)
	self:SetStoredTimerUpgrade(false)
	self:SetStoredSilencer(false)
	self:SetStoredArmor(false)
end

function ENT:OnTakeDamage(dmg)
	self.damage = (self.damage or 140) - dmg:GetDamage()
	if self.damage > 0 then
		return
	end

	local effectdata = EffectData()
	effectdata:SetStart(self:GetPos())
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)
	self:Remove()
end

local function isPackablePrinter(ent)
	return IsValid(ent)
		and ent.IsMoneyPrinter
		and isfunction(ent.GetStoredMoney)
		and isfunction(ent.SetStoredMoney)
		and ent.Base == "custom_moneyprinter"
end

function ENT:Touch(ent)
	if self:GetHasStoredPrinter() or not isPackablePrinter(ent) then
		return
	end

	local owner = self:Getowning_ent()
	local printerOwner = ent:Getowning_ent()
	if IsValid(owner) and IsValid(printerOwner) and owner ~= printerOwner then
		return
	end

	self:SetStoredPrinterClass(ent:GetClass())
	self:SetStoredPrinterMoney(ent:GetStoredMoney())
	self:SetStoredCooler(ent.GetHasCooler and ent:GetHasCooler() or false)
	self:SetStoredAmountUpgrade(ent.GetHasAmountUpgrade and ent:GetHasAmountUpgrade() or false)
	self:SetStoredTimerUpgrade(ent.GetHasTimerUpgrade and ent:GetHasTimerUpgrade() or false)
	self:SetStoredSilencer(ent.GetHasSilencer and ent:GetHasSilencer() or false)
	self:SetStoredArmor(ent.GetHasArmor and ent:GetHasArmor() or false)
	self:Setprice(ent.Getprice and ent:Getprice() or self:Getprice())
	self:SetHasStoredPrinter(true)

	if IsValid(owner) then
		DarkRP.notify(owner, 0, 4, "Printer packed into Pirate Box.")
	end

	ent:Remove()
	self:EmitSound("items/itempickup.wav", 70, 95)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then
		return
	end

	if not self:GetHasStoredPrinter() then
		DarkRP.notify(activator, 1, 4, "This Pirate Box does not contain a printer.")
		return
	end

	local className = self:GetStoredPrinterClass()
	if className == "" then
		DarkRP.notify(activator, 1, 4, "Stored printer data is invalid.")
		return
	end

	local ent = ents.Create(className)
	if not IsValid(ent) then
		DarkRP.notify(activator, 1, 4, "Could not redeploy the stored printer.")
		return
	end

	ent:SetPos(self:GetPos() + Vector(0, 0, 36))
	ent:SetAngles(self:GetAngles())
	ent:Spawn()
	ent:Setowning_ent(activator)
	ent:Setprice(self:Getprice())
	ent:SetStoredMoney(self:GetStoredPrinterMoney())
	ent:SetNWInt("PrintA", self:GetStoredPrinterMoney())
	ent:SetHasCooler(self:GetStoredCooler())
	ent:SetHasAmountUpgrade(self:GetStoredAmountUpgrade())
	ent:SetHasTimerUpgrade(self:GetStoredTimerUpgrade())
	ent:SetHasSilencer(self:GetStoredSilencer())
	ent:SetHasArmor(self:GetStoredArmor())

	if activator.addXP then
		activator:addXP(15, "Pirate Box redeploy")
	end

	DarkRP.notify(activator, 0, 4, "Stored printer redeployed.")
	self:SetHasStoredPrinter(false)
	self:SetStoredPrinterClass("")
	self:SetStoredPrinterMoney(0)
	self:SetStoredCooler(false)
	self:SetStoredAmountUpgrade(false)
	self:SetStoredTimerUpgrade(false)
	self:SetStoredSilencer(false)
	self:SetStoredArmor(false)
	self:EmitSound("items/suitchargeok1.wav", 70, 100)
end