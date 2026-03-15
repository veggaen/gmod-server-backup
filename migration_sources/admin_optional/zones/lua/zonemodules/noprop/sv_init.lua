	local ent = FindMetaTable("Entity")
	
	function ent:DestroyItem(msg)
		if not msg then msg = "You may not bring or spawn props here" end
		local dissolve = ents.Create("env_entity_dissolver");
		dissolve:SetPos(self:GetPos())
		self:SetName(tostring(self:GetCreationID()))
		dissolve:SetKeyValue("target", self:GetName())
		dissolve:SetKeyValue("dissolvetype", "0")
		dissolve:Spawn()
		dissolve:Fire("Dissolve", "", 0)
		dissolve:Fire("kill", "", 1)
		self.Removed = true
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableGravity(false)
		end
		
		local ply = player.GetByUniqueID(self.EntityOwner or 0)
		if ply and msg then
			ply:SendLua( "notification.AddLegacy( [[" .. msg .. "]], NOTIFY_ERROR, 5 )" )
		end
	end
	
	hook.Add("zone.ItemEnteredZone", "zone.noprop.ItemEnteredZone", function(zone, item)
		if zone:IsZoneType("noprop") then
			local ply = player.GetByUniqueID(item.EntityOwner or 0)
			if ply and ply:IsPlayer() and (table.HasValue(DelMods.zones:GetConfig("noprop", "whitelist"), ply:SteamID()) or table.HasValue(DelMods.zones:GetConfig("noprop", "whitelist"), ply:Team())) then
				return
			end
			if IsValid(item) and not item.Removed then
				if (table.HasValue(DelMods.zones:GetConfig("noprop", "blacklist_item") or {}, item:GetClass()) or 
					(!(table.HasValue(DelMods.zones:GetConfig("noprop", "whitelist_item"), item:GetClass()) or item:IsPlayer() or item:IsVehicle() or item:IsWeapon() or (item:GetParent():IsValid() and 
					(item:GetParent():IsPlayer() or item:GetParent():IsVehicle() or item:GetParent():IsWeapon()))) and (tonumber(item.EntityOwner) or item.NormalProp))) then
					local destroy = true
					if item:IsConstrained() then
						local con = constraint.GetAllConstrainedEntities(item)
						for _, i in pairs(con) do
							if i:IsPlayer() or i:IsVehicle() or i:IsWeapon() then
								destroy = false
								break
							end
						end
					end
					if destroy then
						if tonumber(DelMods.zones:GetConfig("noprop", "warn_delay")) >= 1 then 
							local ply = player.GetByUniqueID(item.EntityOwner or 0)
							if ply then
								ply:SendLua( "notification.AddLegacy( [[You can't bring or spawn props here. Move it away, or it will be deleted.]], NOTIFY_ERROR, 5 )" )
							end
						end
						timer.Create("zone.noprop.deleteitem" .. tostring(zone:GetCreationID()) .. tostring(item:GetCreationTime()), DelMods.zones:GetConfig("noprop", "warn_delay"), 1, function()
							if IsValid(item) then
								item:DestroyItem()
							end
						end)
					end
				end
			end
		end
	end)
	
	hook.Add("zone.ItemLeftZone", "zone.noprop.ItemLeftZone", function(zone, item)
		if zone:IsZoneType("noprop") and IsValid(item) then
			if timer.Exists("zone.noprop.deleteitem" .. tostring(zone:GetCreationID()) .. tostring(item:GetCreationTime())) then
				timer.Destroy("zone.noprop.deleteitem" .. tostring(zone:GetCreationID()) .. tostring(item:GetCreationTime()))
			end
		end
	end)