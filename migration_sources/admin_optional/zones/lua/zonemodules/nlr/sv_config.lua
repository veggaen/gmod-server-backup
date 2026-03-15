	
	/*
		Do not edit any of these settings. These are only meta settings, giving a default and creating ingame panels.
		Use the ingame configuration panel to change these settings.
		Type zones into console, followed by "Open configuration panel"
	*/
	
	DelMods.zones:AddConfigMeta("enabled", "NLR enabled", "Enable or disable NLR zones", "nlr", false, nil, true)
	DelMods.zones:AddConfigMeta("time", "Time", "How many seconds NLR should last", "nlr", 120, nil, true)
	DelMods.zones:AddConfigMeta("distance", "Size", "How large the NLR zone should be", "nlr", 1000, nil, true)
	DelMods.zones:AddConfigMeta("ignoresuicide", "Ignore suicide", "If enabled, NLR won't trigger on suicide", "nlr", false)
	DelMods.zones:AddConfigMeta("damage", "Damage trespassers", "Whether to harm NLR trespassers", "nlr", true)
	DelMods.zones:AddConfigMeta("enable_push", "Push", "Enable push", "nlr", false, "push")
	DelMods.zones:AddConfigMeta("disable_weapons", "Disable weapons", "Disable weapons of NLR trespassers", "nlr", false, "spawnprotect")
	DelMods.zones:AddConfigMeta("whitelist", "Whitelist", "Players or teams/jobs that should be unaffected by NLR", "nlr", {})
	DelMods.zones:AddConfigMeta("show_visual_aid", "Show visual aid", "Whether to show the zone outline to the victim", "nlr", true)
	DelMods.zones:AddConfigMeta("kick", "Kick", "Whether NLR trespassers should be kicked", "nlr", false, nil, true)
	DelMods.zones:AddConfigMeta("kick_delay", "Kick delay", "How many seconds warning a player get before being kicked", "nlr", 10, nil, true)
	DelMods.zones:AddConfigMeta("kick_message", "Kick message", "What message is given to the kicked player", "nlr", "You were automatically kicked due to breaking NLR.")
	DelMods.zones:AddConfigMeta("alert_admins", "Alert admins", "Alert admins when someone breaks NLR", "nlr", true)