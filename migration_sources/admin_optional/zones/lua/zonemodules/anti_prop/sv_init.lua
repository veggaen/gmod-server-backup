	
	hook.Add("zone.ItemEnteredZone", "antiprop", function(zone, item)
		if zone:IsZoneType("noprop") then
			if IsValid(item) and not item.Removed then
				if (table.HasValue(DelMods.zones.noprop_blacklist or {}, item:GetClass()) or 
					(!(table.HasValue(zone.blockzonewhitelist, item:GetClass()) or item:IsPlayer() or item:IsVehicle() or item:IsWeapon() or (item:GetParent():IsValid() and 
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
						local dissolve = ents.Create("env_entity_dissolver");
						dissolve:SetPos(item:GetPos())
						item:SetName(tostring(item:GetCreationID()))
						dissolve:SetKeyValue("target", item:GetName())
						dissolve:SetKeyValue("dissolvetype", "0")
						dissolve:Spawn()
						dissolve:Fire("Dissolve", "", 0)
						dissolve:Fire("kill", "", 1)
						item.Removed = true
						
						local phys = item:GetPhysicsObject()
						if IsValid(phys) then
							phys:EnableGravity(false)
						end
						
						local ply = player.GetByUniqueID(item.EntityOwner or 0)
						if ply then
							ply:SendLua( "notification.AddLegacy( 'You may not bring or spawn props here', NOTIFY_ERROR, 5 )" )
						end
					end
				end
			end
		end
	end)