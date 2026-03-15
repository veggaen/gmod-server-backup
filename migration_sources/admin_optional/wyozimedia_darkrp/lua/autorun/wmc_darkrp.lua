
-- Stupid? Yes. Required? Yes.
wyozimc = wyozimc or {}

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

AddShared("sh_wmc_darkrpconfig.lua")
AddShared("sh_wmc_darkrpjob.lua")
AddShared("sh_wmc_darkrpmain.lua")
AddServer("sv_wmc_darkrpents.lua")

