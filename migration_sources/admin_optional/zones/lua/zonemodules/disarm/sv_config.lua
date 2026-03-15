	
	--[[
		Do not edit any of these settings. These are only meta settings, giving a default and creating ingame panels.
		Use the ingame configuration panel to change these settings.
		Type zones into console, followed by "Open configuration panel"
	]]
	
	DelMods.zones:AddConfigMeta("disarm_all", "Disarm all", "Remove all weapons not in whitelist", "disarm", true)
	DelMods.zones:AddConfigMeta("rearm", "Rearm upon departure", "Rearm confiscated weapons when leaving the zone", "disarm", false)
	DelMods.zones:AddConfigMeta("player_whitelist", "Player whitelist", "Players or teams/jobs that should be unaffected by disarm modules", "disarm", {})
	DelMods.zones:AddConfigMeta("whitelist", "Whitelist", "List of weapons that will never be removed", "disarm", {"keys", "weapon_physcannon", "gmod_camera", "gmod_tool", "weapon_physgun"})
	DelMods.zones:AddConfigMeta("blacklist", "Blacklist", "List of weapons that will always be removed", "disarm", {})