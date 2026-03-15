	
	ENT.PrintName = "Zones"
	ENT.Type = "anim"
	ENT.Author = "Dellkan"
	ENT.Contact = "http://steamcommunity.com/id/dellkan"
	ENT.Purpose = "Multi-purpose server tool"
	ENT.Instructions = "Type zones into console"
	
	ENT.Spawnable = false
	ENT.AdminSpawnable = false

	function ENT:Initialize()
		if SERVER then
			self:DrawShadow( false )
			self:SetModel("models/Roller_Spikes.mdl")
			self:SetCollisionGroup(COLLISION_GROUP_WORLD)
			self:SetColor(Color(255, 0, 0, 200))
			self:SetKeyValue("renderfx", 15.00)
			self:SetRenderMode(1)
			self:PhysicsInit(SOLID_VPHYSICS)
			self:GetPhysicsObject():EnableCollisions(false)
			self:GetPhysicsObject():EnableMotion(false)
			self:GetPhysicsObject():EnableGravity(false)
			self:SetSolid(SOLID_NONE)
		end
		self.items = {}
		self.players = {}
		self.heldby = {}
		self.visibleTo = {}
		timer.Create("zonesCheckPerimeter" .. tostring(self:EntIndex()), DelMods.zones:GetConfig("core", "check_timer"), 0, function () if self and IsValid(self) then self:CheckZone() end end)
	end

	function ENT:CheckZone()
		local trespassing_props = ents.FindInSphere( self:GetPos(), self:GetZoneLength() or 0 )
		local found = {}
		if CLIENT then for k, v in pairs(trespassing_props) do if v == LocalPlayer() then trespassing_props[k] = nil break end end end
		if CLIENT and calcdistance(self, LocalPlayer()) <= self:GetZoneLength() then table.insert(trespassing_props, LocalPlayer()) end
		for k, v in pairs(trespassing_props) do
			local id = SERVER and v:GetCreationID() or tostring(v:EntIndex() .. " " .. v:GetCreationTime())
			found[id] = v
			if not self.items[id] then
				hook.Call("zone.ItemEnteredZone", nil, self, v)
				if v:IsPlayer() then 
					hook.Call("zone.PlayerEnteredZone", nil, self, v) 
					self.players[id] = v
				end
				self.items[id] = v
			else
				hook.Call("zone.ItemInZone", nil, self, v)
				if v:IsPlayer() then hook.Call("zone.PlayerInZone", nil, self, v) end
			end
		end
		for index, ent in pairs(self.items) do
			if not found[index] then
				hook.Call("zone.ItemLeftZone", nil, self, ent)
				if IsValid(ent) and ent:IsPlayer() then hook.Call("zone.PlayerLeftZone", nil, self, ent) end
				self.items[index] = nil
				if self.players[index] then self.players[index] = nil end
			end
		end
	end

	function ENT:SetupDataTables()
		self:NetworkVar("Int", 0, "ZoneLength")
		self:NetworkVar("Int", 1, "DBID")
		self:NetworkVar("Int", 2, "ZoneType")
		self:NetworkVar("String", 0, "ZoneTitle")
		self:NetworkVar("String", 1, "ZoneSubTitle")
	end
	
	function ENT:GetItems(raw)
		return raw and self.items or table.Copy(self.items) or {}
	end
	
	function ENT:GetPlayers(raw)
		return raw and self.players or table.Copy(self.players) or {}
	end

	function ENT:IsZoneType(t)
		DelMods = DelMods or {}
		DelMods.zonemodules = DelMods.zonemodules or {}
		if type(t) ~= "number" then
			t = DelMods.zonemodules[tostring(t)] and DelMods.zonemodules[tostring(t)].typeid or 0
		end
		if not tonumber(t) then return false end
		return tobool(bit.band(self:GetZoneType(), t))
	end

	function ENT:GetZoneColor()
		local inactive = true
		local color = Color(0, 0, 0, 50)
		for _, zonemodule in pairs(DelMods.zonemodules) do
			if self:IsZoneType(zonemodule.typeid) then
				inactive = false
				color.r = color.r + zonemodule.color.r
				color.g = color.g + zonemodule.color.g
				color.b = color.b + zonemodule.color.b
			end
		end
		if inactive then
			color = Color(50, 50, 50, 50)
		end
		return color
	end

	function ENT:IsVisibleTo(ply)
		if CLIENT and not IsValid(ply) then ply = LocalPlayer() end
		if CLIENT and ply.see_zone_model then return true end
		if type(self.visibleTo[0]) ~= "nil" then
			return self.visibleTo[0]
		elseif type(self.visibleTo[ply:UniqueID()]) ~= "nil" then
			return self.visibleTo[ply:UniqueID()]
		end
		if SERVER then self.visibleTo[ply:UniqueID()] = false end
		if CLIENT and not ply.zonesLoadingVisibility then ply.zonesLoadingVisibility = true RunConsoleCommand("_zones_fetch_visibility") end
		return false
	end

	function calcdistance(ent1, ent2)
		local distance = ent1:NearestPoint(ent2:GetPos()):Distance(ent2:NearestPoint(ent1:GetPos()))
		return distance
	end

	function GetZone(ply)
		if not ply then return end
		if IsValid(ply:GetEyeTrace().Entity) and ply:GetEyeTrace().Entity:GetClass() == "zones" then
			return ply:GetEyeTrace().Entity
		else
			local zones = ents.FindByClass("zones")
			local inZones = {}
			for k, v in pairs(zones) do
				if calcdistance(ply, v) <= v:GetZoneLength() then
					table.insert(inZones, v)
				end
			end
			local leastlength = false
			for k, v in pairs(inZones) do
				if not leastlength then
					leastlength = v
				elseif v:GetZoneLength() <= leastlength:GetZoneLength() then
					leastlength = v
				end
			end
			if leastlength then
				return leastlength
			else
				return nil
			end
		end
	end