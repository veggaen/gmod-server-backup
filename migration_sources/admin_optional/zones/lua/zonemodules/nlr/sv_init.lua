	hook.Add("PlayerSpawn", "zonesNLRSpawn", function(ply)
		ply.zonesnlrspawnpos = ply:GetPos()
	end)

	hook.Add("PlayerDeath", "zonesNLRDeath", function(ply, inflictor, killer)
		if not DelMods.zones.nlr_enabled then return end
		if not IsValid(killer) or killer:GetClass() ~= "zones" then
			nlrzone = ents.Create("zones")
			nlrzone:Spawn()
			nlrzone:SetPos(ply:GetPos())
			nlrzone:SetNLRTarget(ply)
			nlrzone:SetZoneLength(DelMods.zones.nlr_distance)
			nlrzone:SetZoneType(table.KeyFromValue(nlrzone.zonetypes, "nlr")) // Activates the NLR protocol on the zone
			nlrzone:SetZoneTitle("NLR ZONE")
			nlrzone:SetZoneSubTitle("You are too close to where you died!")
			nlrzone:SetDisplayVisualAid(DelMods.zones.nlr_show_visual_aid)
			nlrzone:Fire("Kill", "", DelMods.zones.nlr_time)
			timer.Simple(DelMods.zones.nlr_time+2, function()
				if IsEntity(nlrzone) and IsValid(nlrzone) then
					nlrzone:Remove()
				end
			end)
		end
	end)

	hook.Add("zone.PlayerInZone", "NLRTick", function (zone, ply)
		if not zone:IsZoneType("nlr") or not DelMods.zones.nlr_damage then return end
		if zone:GetNLRTarget() ~= ply then return end
		// Whitelists
		if table.HasValue(DelMods.zones.nlr_jobwhitelist or {}, ply:Team()) then return end
		if table.HasValue(DelMods.zones.nlr_steamwhitelist or {}, ply:SteamID()) then return end
		if DelMods.zones.nlr_whitelist_custom_check(ply, zone) then return end
		// A simple safety-net to remove zone if the other time didn't do it for any reason.
		if zone:GetCreationTime() + DelMods.zones.nlr_time < CurTime() then zone:Remove() return end
		// Disable the players weapons, if the setting for it is enabled
		if DelMods.zones.nlr_disable_weapons then zone:DisableWeapons(ply) end
		// Make sure the player is never harmed if zone is too close to where he spawned.
		if isvector(ply.zonesnlrspawnpos) and ply.zonesnlrspawnpos:Distance(zone:GetPos()) <= (DelMods.zones.nlr_distance * 2) then return end
		// Time it
		ply.zonesLastNLRDamaged = ply.zonesLastNLRDamaged or 0
		if ply.zonesLastNLRDamaged + .5 > CurTime() then return end
		ply.zonesLastNLRDamaged = CurTime()
		// Calculate damage based on how close the player is to the zone. The further away, lesser the damage.
		local damage_amount = math.Round(((zone:GetZoneLength() / ply:NearestPoint(zone:GetPos()):Distance(zone:GetPos()))-1) * 5) // length divided on distance calculated into damage. 
		// Don't bother with 0 damage.
		if damage_amount > 0 then
			ply:TakeDamage(damage_amount, zone, zone)
		end
	end)
	
	local adminsalerted = {}
	hook.Add("zone.PlayerEnteredZone", "NLRKickTimer", function(zone, ply)
		if zone:IsZoneType("nlr") and ply == zone:GetNLRTarget() and ply:Alive() then
			if DelMods.zones.nlr_alert_admins and (not adminsalerted[zone:GetCreationID()] or not adminsalerted[zone:GetCreationID()][ply:UniqueID()] or adminsalerted[zone:GetCreationID()][ply:UniqueID()] + 10 < CurTime()) then
				adminsalerted[zone:GetCreationID()] = adminsalerted[zone:GetCreationID()] or {}
				adminsalerted[zone:GetCreationID()][ply:UniqueID()] = CurTime()
				for k, v in pairs(player.GetAll()) do
					if v:IsAdmin() then
						umsg.Start("nlrzonealertadmin", v)
							umsg.Entity(ply)
						umsg.End()
					end
				end
			end
			umsg.Start("nlrzonealert", ply)
				umsg.Bool(true)
				umsg.Entity(zone)
				umsg.Bool(tobool(DelMods.zones.nlr_kick))
				umsg.Float(DelMods.zones.nlr_kick_delay)
			umsg.End()
			if not DelMods.zones.nlr_kick then return end
			timer.Create("zoneNLRKickPlayerTimer" .. tostring(zone:GetDBID()) .. tostring(ply:UniqueID()), DelMods.zones.nlr_kick_delay, 1, function()
				if IsValid(zone) and IsValid(ply) and ply:IsPlayer() and ply:Alive() and calcdistance(zone, ply) <= zone:GetZoneLength() and zone:GetCreationTime() + DelMods.zones.nlr_time > CurTime() then
					ply:Kick(DelMods.zones.nlr_kick_message)
				end
			end)
		end
	end)

	hook.Add("zone.PlayerLeftZone", "NLRStopKickTimer", function(zone, ply)
		if zone:IsZoneType("nlr") and ply == zone:GetNLRTarget() then
			if not IsValid(zone) or not IsValid(ply) or not ply:IsPlayer() then return end
			umsg.Start("nlrzonealert", ply)
				umsg.Bool(false)
			umsg.End()
			if timer.Exists("zoneNLRKickPlayerTimer" .. tostring(zone:GetDBID()) .. tostring(ply:UniqueID())) then
				timer.Destroy("zoneNLRKickPlayerTimer" .. tostring(zone:GetDBID()) .. tostring(ply:UniqueID()))
			end
		end
	end)
	
	// Notify admins?