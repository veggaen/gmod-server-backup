	
	/*
		Do not edit any of these settings. These are only meta settings, giving a default and creating ingame panels.
		Use the ingame configuration panel to change these settings.
		Type zones into console, followed by "Open configuration panel"
	*/
		
	DelMods.zones:AddConfigMeta("mysql_enable", "Enable MySQL", "Please note, MySQL module must be installed beforehand. Also, you must restart server after enabling.", "mysql", false, "core")
	DelMods.zones:AddConfigMeta("mysql_host", "Host", "IP to your MySQL server", "mysql", "127.0.0.1", "core", -1)
	DelMods.zones:AddConfigMeta("mysql_module", "Module", "Which gmod MySQL module to use", "mysql", "gmsv_mysqloo", "core", -1)
	DelMods.zones:AddConfigMeta("mysql_port", "Port", "Which port to use", "mysql", "root", "core", -1)
	DelMods.zones:AddConfigMeta("mysql_database", "Database", "Which database to use in MySQL", "mysql", "zones", "core", -1)
	DelMods.zones:AddConfigMeta("mysql_username", "Username", "Username for MySQL", "mysql", "root", "core", -1)
	DelMods.zones:AddConfigMeta("mysql_password", "Password", "Password for MySQL", "mysql", "password", "core", -1)