	// Load config 
	//include("../../config_zones.lua")
	include("../../config_zones_custom_functions.lua")
	AddCSLuaFile("../client/cl_zones.lua")
	AddCSLuaFile("../client/cl_zones_menu.lua")
	
	util.AddNetworkString( "zone.updateVisibility" ) // Pools this string
	util.AddNetworkString( "zones.updateVisibility" ) // Pools this string

	/*
		Hooks
	*/
	//Physgun
	local function zonepickup(ply, ent)
		if IsValid(ent) and ent:GetClass() == "zones" then
			if DelMods.zones.config_cust_functions.zone_canedit(ply, ent) and ply.see_zone_model then
				if not ent.heldby[ply:UniqueID()] then
					ent.heldby[ply:UniqueID()] = ply
				end
				return true
			else
				return false
			end
		end
	end
	hook.Add("PhysgunPickup", "zonepreventtravelpickup", zonepickup)

	local function zonedrop(ply, ent)
		if IsValid(ent) and ent:GetClass() == "zones" then
			if ent.heldby[ply:UniqueID()] then
				ent.heldby[ply:UniqueID()] = nil
			end
		end
	end
	hook.Add("PhysgunDrop", "zonepreventtraveldrop", zonedrop)

	/* 	
		There is no universal method of attaining owner of an entity, or even if the entity was created by a player. Thus, we tag the entities ourselves.
		NB: Still relies on sandbox, so gamemode has to derive from sandbox for this to work. Yet, gamemodes not derived from sandbox are likely to have a completely different
		Entity system where noprop zones are unlikely to be useful in the first place.
	*/
	local function addOwnershipTag(ply, ent, _)
		if IsValid(_) then ent = _ end
		if IsValid(ent) then ent.EntityOwner = ply:UniqueID() end
	end
	hook.Add("PlayerSpawnedEffect", "zoneTagEffect", addOwnershipTag)
	hook.Add("PlayerSpawnedNPC", "zoneTagNPC", addOwnershipTag)
	hook.Add("PlayerSpawnedProp", "zoneTagProp", addOwnershipTag)
	hook.Add("PlayerSpawnedRagdoll", "zoneTagRagdoll", addOwnershipTag)
	hook.Add("PlayerSpawnedSENT", "zoneTagSENT", addOwnershipTag)
	hook.Add("PlayerSpawnedSWEP", "zoneTagSWEP", addOwnershipTag)
	hook.Add("PlayerSpawnedVehicle", "zoneTagVehicle", addOwnershipTag)
	/*
		Some tools, like stacker, doesn't call these hooks. So we have to add additional mechanisms to ensure detection of player spawned props
		This hack creates a proxy in undo and cleanup that registers ownership before calling base functionality.
		This clever hack was invented by FTPje(http://steamcommunity.com/id/FPtje/) for FPP long before I thought of it, and he deserves a mention
	*/
	if undo then
		DelMods.undo = DelMods.undo or {
			AddEntity = undo.AddEntity,
			SetPlayer = undo.SetPlayer,
			Finish = undo.Finish,
		}
		local entities = {}
		local undoply = NULL
		function undo.AddEntity(ent, ...)
			if type(ent) ~= "boolean" and IsValid(ent) then table.insert(entities, ent) end
			DelMods.undo.AddEntity(ent, ...)
		end

		function undo.SetPlayer(ply, ...)
			undoply = ply
			DelMods.undo.SetPlayer(ply, ...)
		end

		function undo.Finish(...)
			if IsValid(undoply) then
				for _, ent in pairs(entities) do
					addOwnershipTag(undoply, ent)
				end
			end
			entities = {}
			undoply = nil

			DelMods.undo.Finish(...)
		end
	end
	if cleanup then
		DelMods.cleanup = DelMods.cleanup or {Add = cleanup.Add}
		function cleanup.Add(ply, entitytype, ent)
			if IsValid(ply) and IsValid(ent) then
				addOwnershipTag(ply, ent)
			end
			return DelMods.cleanup.Add(ply, entitytype, ent)
		end
	end

	/*
		Visibility
	*/
	hook.Add("SetupPlayerVisibility", "zone.updateVisibility", function( ply, pViewEntity )
		local zones = ents.FindByClass("zones")
		for _, zone in pairs(zones) do
			if zone:IsVisibleTo(ply) then
				AddOriginToPVS(zone:GetPos())
			end
		end
	end)

	/*
		Commands
	*/
	local function create_zone (ply, cmd, args)
		if not DelMods.zones.config_cust_functions.zone_canedit(ply) then return end
		// DB part
		local map = string.lower(game.GetMap())
		DelMods.Query("SELECT MAX(id) as id FROM zones", function(query)
			local id = 1
			local zone = ents.Create("zones")
			zone:SetPos(ply:GetEyeTrace().HitPos)
			zone:Spawn()
			
			local physics = false
			for k, v in pairs(player.GetAll()) do if v.see_zone_model then physics = true break end end
			if physics then zone:SetSolid(SOLID_VPHYSICS) end
			
			zone:SetZoneLength(args[1] or 500)
			zone:SetZoneType(args[2] or 0)
			zone:SetZoneTitle(args[3] or "")
			zone:SetZoneSubTitle(args[4] or "")
			if query then
				query = query[1]
				if query["id"] and query["id"] ~= "NULL" then
					id = tonumber(query["id"]) + 1
				end
			end
			zone:SetDBID(id)
			DelMods.Query("INSERT INTO zones VALUES(" .. id .. ", " .. sql.SQLStr(map) .. ", " .. zone:GetZoneLength() .. ", " .. zone:GetPos().x .. ", " .. zone:GetPos().y .. ", " .. zone:GetPos().z .. ", " .. zone:GetZoneType() .. ", " .. sql.SQLStr(zone:GetZoneTitle()) .. ", " .. sql.SQLStr(zone:GetZoneSubTitle()) .. ");")
			timer.Simple(0.1, function()
				umsg.Start("zone_new_id", ply)
					umsg.Long(zone:EntIndex())
				umsg.End()
			end)
		end)
	end
	concommand.Add("_zone_create", create_zone)

	local function edit_zone (ply, cmd, args)
		if not DelMods.zones.config_cust_functions.zone_canedit(ply) then return end
		if not ply.see_zone_model then ply.see_zone_model = false end
		if not args[1] or args[1] == "togglephys" then
			local toggle = args[2] and tobool(args[2]) or !ply.see_zone_model
			ply.see_zone_model = toggle
			umsg.Start("toggleZoneVis", ply)
				umsg.Bool(ply.see_zone_model)
			umsg.End()
			if ply.see_zone_model then
				local zones = ents.FindByClass("zones")
				for k, v in pairs(zones) do
					v:SetSolid(SOLID_VPHYSICS)
				end
			else
				local othersediting = {}
				for k, v in pairs(player.GetAll()) do
					if v.see_zone_model then
						table.insert(othersediting, v)
					end
				end
				if #othersediting ~= 0 then
					for k, v in pairs(othersediting) do
						if not v or not IsValid(v) then
							table.remove(othersediting, k)
						else
							ply:PrintMessage(HUD_PRINTCONSOLE, v:Name().." is editing zones.")
						end
					end
				end
				if #othersediting == 0 then
					local zones = ents.FindByClass("zones")
					for k, v in pairs(zones) do
						v:SetSolid(SOLID_NONE)
					end
				else
					ply:PrintMessage(HUD_PRINTCONSOLE, "Others are editing the zone. Keeping unlocked for now.")
				end
			end
		end
	end
	concommand.Add("_zone_edit", edit_zone)

	local function update_zone(ply, cmd, args)
		if tonumber(args[1]) and tonumber(args[2]) and args[3] then
			local zone = Entity(tonumber(args[1]))
			if not IsValid(zone) then return end
			if not DelMods.zones.config_cust_functions.zone_canedit(ply, zone) then return end
			zone:SetZoneLength(tonumber(args[2]))
			zone:SetZoneType(tonumber(args[3]))
			zone:SetZoneTitle(args[4] and tostring(args[4]) or "")
			zone:SetZoneSubTitle(args[5] and tostring(args[5]) or "")
			DelMods.Query("UPDATE zones SET length = "..zone:GetZoneLength()..", type = ".. zone:GetZoneType() ..", name = "..sql.SQLStr(zone:GetZoneTitle())..", subname = "..sql.SQLStr(zone:GetZoneSubTitle()).." WHERE id = "..zone:GetDBID()..";")
		end
	end
	concommand.Add("_zone_update", update_zone)

	local function remove_zone (ply, cmd, args)
		local target = args[1] and tonumber(args[1]) and Entity(tonumber(args[1])) or GetZone(ply)
		if target and IsEntity(target) and IsValid(target) then
			DelMods.zones.config_cust_functions.zone_canedit(ply, target)
			if target:GetDBID() then
				DelMods.Query("DELETE FROM zones WHERE id = "..target:GetDBID()..";")
			end
			target.AllowRemove = true
			target:Remove()
		end
	end
	concommand.Add("_zone_remove", remove_zone)

	local function remove_all_zones(ply, cmd, args)
		if not DelMods.zones.config_cust_functions.zone_canedit(ply) then return end
		local map = string.lower(game.GetMap())
		DelMods.Query("DELETE FROM zones WHERE map = " .. sql.SQLStr(map) .. ";")
		for k, v in pairs(ents.FindByClass("zones")) do
			v.AllowRemove = true
			v:Remove()
		end
	end
	concommand.Add("_zone_remove_all", remove_all_zones)

	local function telezone(ply, cmd, args)
		if args[1] and tonumber(args[2]) then
			local zone = Entity(args[2])
			if !IsValid(zone) then return end
			if not DelMods.zones.config_cust_functions.zone_canedit(ply, zone) then return end
			if args[1] == "tome" then
				zone:PhysicsUpdate(zone:GetPhysicsObject())
				zone:SetPos(ply:GetPos())
			elseif args[1] == "metoit" then
				ply:SetPos(zone:GetPos())
			elseif args[1] == "totarget" then
				zone:PhysicsUpdate(zone:GetPhysicsObject())
				zone:SetPos(ply:GetEyeTrace().HitPos)
			end
		end
	end
	concommand.Add("_zone_tele", telezone)

	local function fetchZoneVisibility(ply)
		local visTable = {}
		for k, v in pairs(ents.FindByClass("zones")) do
			table.insert(visTable, {zone = v, visible = v:IsVisibleTo(ply)})
		end
		net.Start("zones.updateVisibility")
			net.WriteTable(visTable)
		net.Send(ply)
	end
	concommand.Add("_zones_fetch_visibility", fetchZoneVisibility)