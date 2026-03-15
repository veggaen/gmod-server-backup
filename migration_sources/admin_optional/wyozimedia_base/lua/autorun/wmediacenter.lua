
local wyozimc_debug = SERVER and CreateConVar("wyozimc_debug", "0") or CreateClientConVar("wyozimc_debug", "0", FCVAR_ARCHIVE)

wyozimc = wyozimc or {}
function wyozimc.Debug(...)
	if not wyozimc_debug:GetBool() then return end
	print("[WMZ-DEBUG] ", ...)
end

local function AddClient(fil)
	if SERVER then AddCSLuaFile(fil) end
	if CLIENT then include(fil) end
end

local function AddServer(fil)
	if SERVER then include(fil) end
end

local function AddShared(fil)
	include(fil)
	AddCSLuaFile(fil)
end

AddShared("sh_wmc_config.lua")
AddShared("sh_wmc_utils.lua")
AddShared("sh_wmc_tablemanip.lua")

AddShared("sh_wmc_providers.lua")
AddServer("sv_wmc_storage.lua")
AddClient("cl_wmc_gui.lua")
AddClient("cl_wmc_gui_settings.lua")
AddClient("cl_wmc_player.lua")
AddClient("cl_wmc_toolmenu.lua")

-- TTT integration. This is deprecated but is there if someone is using the old version.
if file.Exists("sh_wmc_ttt.lua", "LUA") then
	wyozimc.Debug("Found old sh_wmc_ttt!")
	AddShared("sh_wmc_ttt.lua")
else
	wyozimc.Debug("Didn't find old sh_wmc_ttt.")
end

wyozimc.IsInitialized = true

wyozimc.CallHook("WyoziMCInitialized")