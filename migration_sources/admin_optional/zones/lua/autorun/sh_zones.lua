	/*
		Utility functions
	*/
	DelMods = DelMods or {}
	DelMods.zonemodules = DelMods.zonemodules or {}
	DelMods.zoneInstallModule = DelMods.zoneInstallModule or function(typeid, name, nicename, color, allowcreate)
		DelMods.zonemodules[name] = {
			typeid = typeid,
			name = name,
			nicename = nicename,
			color = color,
			allowcreate = allowcreate // Whether the ingame zone config menu should allow creating these zones
		}
	end
	
	if SERVER then
		AddCSLuaFile()
		AddCSLuaFile("zonemodules/zonemodules.lua")
	end
	include("zonemodules/zonemodules.lua")
	
	/*
		Include the modules
	*/
	local _, folders = file.Find("zonemodules/*", "LUA")
	for _, folder in pairs(folders) do
		local files = file.Find("zonemodules/" .. folder .. "/*.lua", "LUA")
		for _, File in pairs(files) do
			if SERVER then
				if File:Left(3) == "cl_" then
					AddCSLuaFile("zonemodules/" .. folder .. "/" .. File)
				elseif File:Left(3) == "sh_" then
					include("zonemodules/" .. folder .. "/" .. File)
					AddCSLuaFile("zonemodules/" .. folder .. "/" .. File)
				elseif File:Left(3) == "sv_" then
					include("zonemodules/" .. folder .. "/" .. File)
				end
			else
				include("zonemodules/" .. folder .. "/" .. File)
			end
			if File == "sh_install_module.lua" and DelMods.zonemodules[folder] then
				DelMods.zonemodules[folder].installed = true
			end
		end
	end
	