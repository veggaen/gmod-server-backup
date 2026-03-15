
	hook.Add("zone.PlayerEnteredZone", "spawn_protect", function(zone, ply)
		if not zone:IsZoneType("spawnprotect") then return end
			
		if DelMods.zones.spawn_protect_disableweapons then
			zone:DisableWeapons(ply)
		end
		if not DelMods.zones.spawn_protect_godmode then return end
		if DelMods.zones.spawn_protect_godonce then
			if ply.zoneSpawnProtectGodOnceMarked and ply.zoneSpawnProtectGodOnceMarked >= ply:Deaths() then
				return
			end
		end
		ply.zoneSpawnGodModeProtected = true
		ply:GodEnable()
	end)
	
	hook.Add("zone.PlayerInZone", "spawn_protect", function(zone, ply)
		if not zone:IsZoneType("spawnprotect") then return end
		if DelMods.zones.spawn_protect_disableweapons then
			zone:DisableWeapons(ply)
		end
	end)
	
	hook.Add("zone.PlayerLeftZone", "spawn_protect", function(zone, ply)
		if not zone:IsZoneType("spawnprotect") then return end
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply.zoneSpawnGodModeProtected then 
			ply.zoneSpawnProtectGodOnceMarked = ply:Deaths()
			ply.zoneSpawnGodModeProtected = nil
			ply:GodDisable()
		end
	end)