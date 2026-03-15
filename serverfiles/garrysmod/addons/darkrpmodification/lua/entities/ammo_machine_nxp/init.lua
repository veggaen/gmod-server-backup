AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.SeizeReward = 2000

local ammoTypes = {
	"pistol",
	"357",
	"smg1",
	"ar2",
	"buckshot",
	"slam",
	"SniperPenetratedRound",
	"AirboatGun",
}

function ENT:Initialize()
	self:SetModel("models/props_lab/reciever_cart.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(15)
		phys:Wake()
	end

	self.damage = 100
	self.sparking = false
	self:SetAmmoStored(0)
	self:SetHasSmgExtra(false)
	self:SetNWInt("ammoA", 0)
	self:SetNWBool("smg_extra", false)
	self.nextPrintAt = CurTime() + 3
	self.nextOverheatRoll = CurTime() + 15
end

function ENT:OnTakeDamage(dmg)
	if self.burningup then
		return
	end

	self.damage = (self.damage or 100) - dmg:GetDamage()
	if self.damage <= 0 then
		if math.random(1, 10) < 6 then
			self:BurstIntoFlames()
		else
			self:Destruct()
			self:Remove()
		end
	end
end

function ENT:Destruct()
	local effectdata = EffectData()
	effectdata:SetStart(self:GetPos())
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetScale(1)
	util.Effect("Explosion", effectdata)

	local owner = self:Getowning_ent()
	if IsValid(owner) then
		DarkRP.notify(owner, 1, 4, "Your Ammo Machine blew up!")
	end
end

function ENT:BurstIntoFlames()
	local owner = self:Getowning_ent()
	if IsValid(owner) then
		DarkRP.notify(owner, 1, 4, "Your Ammo Machine is overheating!")
	end

	self.burningup = true
	self.fireballAt = CurTime() + math.random(8, 18)
	self:Ignite(self.fireballAt - CurTime(), 0)
end

function ENT:Fireball()
	if not self:IsOnFire() then
		self.burningup = false
		return
	end

	local dist = math.random(5, 50)
	self:Destruct()

	for _, victim in ipairs(ents.FindInSphere(self:GetPos(), dist)) do
		if victim == self then
			continue
		end

		if victim:IsPlayer() then
			local distance = math.max(victim:GetPos():Distance(self:GetPos()), 1)
			victim:TakeDamage((1 - math.min(distance / dist, 1)) * 100, self, self)
		elseif not victim:IsWeapon() and victim:GetClass() ~= "predicted_viewmodel" and not victim.IsMoneyPrinter then
			victim:Ignite(math.random(5, 22), 0)
		end
	end

	self:Remove()
end

function ENT:CreateAmmo()
	if self:IsOnFire() then
		return
	end

	local stored = self:GetAmmoStored() + math.random(2, 6)
	self:SetAmmoStored(stored)
	self:SetNWInt("ammoA", stored)
	self.sparking = false
	self.nextPrintAt = CurTime() + 3
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then
		return
	end

	local stored = self:GetAmmoStored()
	if stored <= 0 then
		return
	end

	for _, ammoType in ipairs(ammoTypes) do
		activator:GiveAmmo(stored, ammoType)
	end

	if self:GetHasSmgExtra() then
		activator:GiveAmmo(stored, "smg1")
	end

	DarkRP.notify(activator, 0, 4, "You collected " .. stored .. " rounds from an Ammo Machine.")
	self:SetAmmoStored(0)
	self:SetNWInt("ammoA", 0)
end

function ENT:Touch(hitEnt)
	if not IsValid(hitEnt) or not hitEnt.IsSmgExtra or self:GetHasSmgExtra() then
		return
	end

	self:SetHasSmgExtra(true)
	self:SetNWBool("smg_extra", true)
	hitEnt:Remove()

	local owner = self:Getowning_ent()
	if IsValid(owner) then
		DarkRP.notify(owner, 0, 4, "SMG Extra installed on your Ammo Machine.")
	end
	self:EmitSound("items/ammo_pickup.wav", 70, 100)
end

function ENT:Think()
	if self:WaterLevel() > 0 then
		self:Destruct()
		self:Remove()
		return
	end

	if self.burningup and self.fireballAt and CurTime() >= self.fireballAt then
		self:Fireball()
		return
	end

	if CurTime() >= (self.nextPrintAt or 0) then
		self:CreateAmmo()
	end

	if not self.burningup and CurTime() >= (self.nextOverheatRoll or 0) then
		self.nextOverheatRoll = CurTime() + 15
		if math.random(1, 450) == 3 then
			self:BurstIntoFlames()
		end
	end

	self:NextThink(CurTime() + 0.25)
	return true
end