	
	/*
		Do not edit any of these settings. These are only meta settings, giving a default and creating ingame panels.
		Use the ingame configuration panel to change these settings.
		Type zones into console, followed by "Open configuration panel"
	*/
	
	DelMods.zones:AddConfigMeta("warn_delay", "Item remove delay", "Amount of seconds from player is warned until item is removed", "noprop", 0)
	DelMods.zones:AddConfigMeta("whitelist", "Player whitelist", "List of steamid's and teams/jobs that aren't affected", "noprop", {})
	DelMods.zones:AddConfigMeta("whitelist_item", "Item whitelist", "List of entity classes that aren't affected", "noprop", {})
	DelMods.zones:AddConfigMeta("blacklist_item", "Item blacklist", "List of entity classes that are always deleted regardless of other settings", "noprop", {})