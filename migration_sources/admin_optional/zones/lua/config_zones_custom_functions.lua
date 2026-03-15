	DelMods = DelMods or {}
	DelMods.zones = DelMods.zones or {}
	DelMods.zones.config_cust_functions = {
		// Who can edit zones? Return true if the player is allowed to edit/create/delete zones, and also edit global config options
		zone_canedit = function(ply)
			return ply:IsSuperAdmin()
		end,
		
		// Custom push whitelist function. Return true to not push, false to push, nil to let default functionality handle it
		zone_push_whitelist = function(ply, zone)
			return nil
		end,
		
		// Custom NLR whitelist function. Return true to not be affected by NLR, false to be affected, nil to let default functionality handle it
		zone_nlr_whitelist = function(ply, inflictor, killer)
			return nil
		end
	}