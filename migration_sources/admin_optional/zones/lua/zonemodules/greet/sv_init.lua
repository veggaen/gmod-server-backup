	
	hook.Add("zone.PlayerEnteredZone", "zonegreet", function(zone, ply)
		if zone:IsZoneType("zonegreet") then
			if ply.zoneLastGreeted and ply.zoneLastGreeted[zone:EntIndex()] and ply.zoneLastGreeted[zone:EntIndex()] + DelMods.zones.greet_delay >= CurTime() then return end
			if not zone.sentGreetSettings[ply:UniqueID()] or not IsValid(zone.sentGreetSettings[ply:UniqueID()]) then
				net.Start("zoneGreetSettings")
					net.WriteTable(DelMods.zones.greet)
				net.Send(ply)
				zone.sentGreetSettings[ply:UniqueID()] = ply
			end
			umsg.Start("zoneSplash", ply)
				umsg.Entity(zone)
			umsg.End()
		end
	end)
	
	hook.Add("zone.PlayerLeftZone", "zonegreet", function(zone, ply)
		if zone:IsZoneType("zonegreet") then
			ply.zoneLastGreeted = ply.zoneLastGreeted or {}
			ply.zoneLastGreeted[zone:EntIndex()] = CurTime()
		end
	end)