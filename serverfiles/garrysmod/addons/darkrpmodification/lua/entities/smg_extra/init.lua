AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_lab/reciever01c.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	self.damage = 100
	self.IsSmgExtra = true
end

function ENT:OnTakeDamage(dmg)
	self.damage = (self.damage or 100) - dmg:GetDamage()
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

function ENT:Touch(hitEnt)
	if not IsValid(hitEnt) then
		return
	end

	self.Selected = hitEnt
end