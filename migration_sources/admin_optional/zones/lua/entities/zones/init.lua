	AddCSLuaFile("cl_init.lua")
	AddCSLuaFile("shared.lua")
	include("shared.lua")

	function ENT:PhysicsUpdate(phys)
		if table.Count(self.heldby) <= 0 then
			phys:Sleep()
			if not self:IsZoneType("nlr") then
				DelMods.Query("UPDATE zones SET x = "..self:GetPos().x..", y = "..self:GetPos().y..", z = "..self:GetPos().z.." WHERE id = ".. self:GetDBID() .." ;")
			end
		end
	end
	
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	function ENT:CanTool(ply, trace, tool, ENT)
		return false
	end

	function ENT:SetVisibleTo(ply, value)
		self.visibleTo[ply:IsPlayer() and ply:UniqueID() or 0] = value
		timer.Simple(.1, function() // If setting this just after creating a zone, clients won't have the zone yet. Let em register before trying to set visibility.
			for k, v in pairs(player.GetAll()) do
				local visTable = {zone = self, visible = self:IsVisibleTo(v)}
				net.Start("zone.updateVisibility")
					net.WriteTable(visTable)
				net.Send(v)
			end
		end)
	end

	function ENT:GetVisibleToTable()
		return self.visibleTo
	end

	function ENT:SetZoneTypeByName(name)
		DelMods = DelMods or {}
		DelMods.zonemodules = DelMods.zonemodules or {}
		if DelMods.zonemodules[name] then
			self:SetZoneType(DelMods.zonemodules[name].typeid)
		else
			ErrorNoHalt("The zone module " .. name .. " does not exist!")
		end
	end

	function ENT:OnRemove()
		for k, ent in pairs(self:GetItems()) do
			hook.Call("zone.ItemLeftZone", nil, self, ent)
			if IsValid(ent) and ent:IsPlayer() then hook.Call("zone.PlayerLeftZone", nil, self, ent) end
		end
		if self.AllowRemove then return end
		DelMods = DelMods or {}
		DelMods.zonemodules = DelMods.zonemodules or {}
		for _, zonemodule in pairs(DelMods.zonemodules) do
			if not zonemodule.allowcreate and self:IsZoneType(zonemodule.typeid) then return end
		end
		local data = {
			Pos = self:GetPos(),
			ZoneLength = self:GetZoneLength(),
			DBID = self:GetDBID(),
			ZoneType = self:GetZoneType(),
			ZoneTitle = self:GetZoneTitle()
		}
		timer.Simple(.1, function()
			zone = ents.Create("zones")
			zone:Spawn()
			for k, v in pairs(data) do
				zone["Set" .. k](zone, v)
			end
		end)
	end