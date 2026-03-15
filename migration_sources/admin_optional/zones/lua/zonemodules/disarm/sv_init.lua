
	local confiscated_weapons = {}
	
	function DelMods.zoneTable:Disarm(ply)
		local removeall, whitelist, blacklist = self:GetConfig("disarm", "disarm_all"), self:GetConfig("disarm", "whitelist"), self:GetConfig("disarm", "blacklist")
		confiscated_weapons[ply:UniqueID()] = {}
		for k, v in pairs(ply:GetWeapons()) do
			if not table.HasValue(whitelist, v:GetClass()) and (removeall or table.HasValue(blacklist, v:GetClass())) then
				table.insert(confiscated_weapons[ply:UniqueID()], v:GetClass())
				ply:StripWeapon(v:GetClass())
			end
		end
		ply:SendLua( "notification.AddLegacy( [[You were disarmed!]], NOTIFY_HINT, 5 )" )
	end
	
	hook.Add("zone.PlayerEnteredZone", "zone.disarm.PlayerEnteredZone", function(zone, ply)
		if zone:IsZoneType("disarm") then
			local plywhitelist = zone:GetConfig("disarm", "player_whitelist")
			if table.HasValue(plywhitelist, ply:SteamID()) or table.HasValue(plywhitelist, ply:Team()) then return end
			zone:Disarm(ply)
		end
	end)
	
	hook.Add("zone.PlayerLeftZone", "zone.disarm.PlayerLeftZone", function(zone, ply)
		if zone:IsZoneType("disarm") and zone:GetConfig("disarm", "rearm") and confiscated_weapons[ply:UniqueID()] then
			for k, v in pairs(confiscated_weapons[ply:UniqueID()]) do
				ply:Give(v)
				ply:SelectWeapon(v)
			end
			confiscated_weapons[ply:UniqueID()] = nil
			ply:SendLua( "notification.AddLegacy( [[You were rearmed!]], NOTIFY_HINT, 5 )" )
		end
	end)