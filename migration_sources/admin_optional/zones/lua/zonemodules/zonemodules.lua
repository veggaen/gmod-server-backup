	--[[
		This is a list of modules available.
		The function to add one follows this format
		zoneInstallModule(
			typeid, -- Its unique ID. Uses the power of 2 (think binary flag). 1, 2, 4, 8, 16, 32, and so on
			name, -- Short name
			nicename, -- Nice name, the one displayed in debug display and menu
			color, -- Which color the zone has
			allowcreate -- Whether to permit ingame menu control over the zone. Make this false if its a zone that controls itself (like NLR zones)
		)
	]]
	DelMods = DelMods or {}
	DelMods.zoneInstallModule(-1, "core", "Core", Color(0, 0, 0), true)
	DelMods.zoneInstallModule(1, "noprop", "No-prop", Color(0, 150, 0), true)
	DelMods.zoneInstallModule(2, "greet", "Greet", Color(0, 0, 150), true)
	DelMods.zoneInstallModule(4, "spawnprotect", "Spawn protection", Color(150, 0, 0), true)
	DelMods.zoneInstallModule(8, "push", "Push", Color(100, 100, 0), true)
	DelMods.zoneInstallModule(16, "nlr", "New Life Rule", Color(0, 100, 100, 150), false)
	DelMods.zoneInstallModule(32, "basewars", "Basewar buildzone", Color(255, 0, 0), false)
	DelMods.zoneInstallModule(64, "serverconnector", "Server connector", Color(0, 255, 0), true)
	DelMods.zoneInstallModule(128, "disarm", "Disarm", Color(0, 0, 255), true)
	DelMods.zoneInstallModule(256, "wmc", "Wyozi Media Center", Color(255, 127, 0), true)