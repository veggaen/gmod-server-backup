AddCSLuaFile()

ENT.Base = "wyozi_screenbase"

ENT.Author = "Wyozi"
ENT.PrintName = "Wyozi Screen: Radio"
ENT.Category = "Wyozi"

ENT.Spawnable = true
ENT.AdminSpawnable = true

ENT.Model = Model("models/props_lab/citizenradio.mdl")

ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.RenderData = {
	AudioOnly = true
}

if CLIENT then

	--[[ Can possibly crash the server :/

	function ENT:Initialize()

		self.RadioEmitter = ParticleEmitter( self:GetPos() )

		self.BaseClass.Initialize(self)
	end

	function ENT:Think()

		if self:GetLink() ~= "" and (not self.NextRParticle or self.NextRParticle < CurTime()) then

			local rnd = self:NearestPoint(self:GetPos() + Vector(0, 0, 10) + VectorRand() * 20)

			local emitter = self.RadioEmitter

			local particle = emitter:Add( "sprites/light_glow02_add", rnd )
			particle:SetVelocity( ( Vector( 0, 0, 1 ) + ( VectorRand() * 0.1 ) ) * math.random( 15, 30 ) )
			particle:SetDieTime( math.random( 0.3, 0.5 ) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( 1.5 )
			particle:SetRoll( math.random(0.5, 10) )
			particle:SetRollDelta( math.Rand(-0.2, 0.2) )
			particle:SetColor( 255*math.random(), 255*math.random(), 255*math.random() )
			particle:SetCollide( false )

			local grav = Vector(0, 0, math.random(30, 40))
			particle:SetGravity( grav )
			grav = grav + Vector(0, 0, math.random(-10, -5))

			self.NextRParticle = CurTime() + 0.1
			
		end

		return self.BaseClass.Think(self)
	end

	function ENT:OnRemove()
		self.RadioEmitter:Finish()

		self.BaseClass.OnRemove(self)
	end
	]]

	function ENT:GetTickerText(str)
		local tickertick = math.Remap(math.sin(CurTime()), -1, 1, 0, 1)
		
		surface.SetFont("Trebuchet18")
		local ts = surface.GetTextSize(str)

		local clippedextra = 0

		local extra = ts - 160
		local xmod = -extra*tickertick

		if xmod < 0 then
			str = str:sub(math.Round(math.abs(xmod) * 0.20))
		end

		local tsplus = xmod + extra
		if tsplus > 0 then
			local cutat = string.len(str) - math.Round(math.abs(tsplus) * 0.2)
			clippedextra = clippedextra - surface.GetTextSize(str:sub(cutat))

			str = str:sub(1, cutat)
		end

		return str, xmod + ts + clippedextra, TEXT_ALIGN_RIGHT
	end

	function ENT:Draw()
		self:DrawModel()

		local pos = self:GetPos()
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), 90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		pos = pos + ang:Up() * 8.5
		pos = pos + ang:Right() * -15.3
		pos = pos + ang:Forward() * -5.7

		cam.Start3D2D(pos, ang, 0.1)

			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawRect(0, 0, 170, 40)
			if self.QueryData then
				local str, xmod, align = self:GetTickerText(self.QueryData.Title or "")
				draw.SimpleText(str, "Trebuchet18", xmod, 8, Color(255, 255, 255), align)
			end

		cam.End3D2D()
	end
end