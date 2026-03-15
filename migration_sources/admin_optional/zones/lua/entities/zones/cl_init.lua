	include("shared.lua")

	LocalPlayer().see_zone_model = false

	function ENT:Draw()
		if self:IsVisibleTo() and (not self.renderLength or self.renderLength ~= self:GetZoneLength()) then
			self.renderLength = self:GetZoneLength()
			self:SetRenderBounds(Vector(1, 1, 1) * -self:GetZoneLength(), Vector(1, 1, 1) * self:GetZoneLength())
		elseif not self:IsVisibleTo() and (not self.renderLength or self.renderLength ~= 1) then
			self.renderLength = 1
			self:SetRenderBounds(Vector(1, 1, 1), Vector(1, 1, 1))
		end
		hook.Call("zone.Draw", nil, self)
	end

	function ENT:DrawVisualAid(color)
		if not color then color = self:GetZoneColor() end
		render.SetColorMaterial()
		render.DrawSphere(self:GetPos(), self:GetZoneLength(), 35, 35, color)
		render.DrawWireframeSphere(self:GetPos(), self:GetZoneLength(), 35, 35, Color(50, 50, 50), true)
	end

	function ENT:DrawTranslucent()
		self:Draw()
	end

	local function zonedraw()
		if LocalPlayer().see_zone_model then
			local zone = GetZone(LocalPlayer())
			local height = 20
			local function getheight()
				height = height + 20
				return height
			end
			if IsValid(zone) then
				draw.DrawText("Zone name: " .. zone:GetZoneTitle(), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				draw.DrawText("Zone subname: " .. zone:GetZoneSubTitle() or "nil", "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				draw.DrawText("Zone type: " .. tostring(zone:GetZoneType()), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				for k, v in pairs(DelMods.zonemodules) do
					draw.DrawText("Zone " .. v.nicename .. " enabled: " .. tostring(zone:IsZoneType(k)), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				end
				draw.DrawText("Zone length: " .. tostring(zone:GetZoneLength()), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				draw.DrawText("Zone ID: " .. tostring(zone:EntIndex()), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
				draw.DrawText("Zone DBID: " .. tostring(zone:GetDBID()), "Trebuchet18", 30, getheight(), Color(255, 255, 255, 255))
			end
		end
	end
	hook.Add("HUDPaint", "zonedraw", zonedraw)