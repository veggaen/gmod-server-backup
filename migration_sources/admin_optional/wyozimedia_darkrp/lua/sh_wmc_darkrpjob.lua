hook.Add("InitPostEntity", "WyoziMCDarkRPAddJobs", function()

	if not wyozimc.IsDarkRP() then return end

	TEAM_DJ = AddExtraTeam("DJ", {
		color = Color(20, 150, 20, 255),
		model = "models/player/p2_chell.mdl",
		description = [[DJ is able to buy a radio and play music.]],
		weapons = {},
		command = "dj",
		max = 2,
		salary = 90,
		admin = 0,
		vote = false,
		hasLicense = false,
		candemote = false,
		mayorCanSetSalary = true
	})

	TEAM_CINEMAOWNER = AddExtraTeam("Cinema Owner", {
		color = Color(20, 150, 20, 255),
		model = "models/player/magnusson.mdl",
		description = [[Cinema Owner is able to play media using a projector.]],
		weapons = {},
		command = "cinemaowner",
		max = 1,
		salary = 90,
		admin = 0,
		vote = false,
		hasLicense = false,
		candemote = false,
		mayorCanSetSalary = true
	})

	AddEntity("Radio", {
		ent = "wyozi_screen_radio",
		model = "models/props_lab/citizenradio.mdl",
		price = 800,
		max = 1,
		cmd = "/buyradio",
		allowed = {TEAM_DJ}
	})

end)


if SERVER then
	-- Set FPP ownership & allow funcs. Stupid hacky timer hack because owningent isn't available immediately on creation
	hook.Add("OnEntityCreated", "WyoziMCDarkRPFixFptjesBadGamemode", function(ent)
		if ent:GetClass() == "wyozi_screen_radio" then
			timer.Simple(0.1, function()
				if not IsValid(ent) then return end
				local ply = ent.DRP_OwningEnt
				if not IsValid(ply) then return end

				ent:CPPISetOwner(ply)
				ent:SetAllowFunc(function(ent, ply)
					if ply:Team() == TEAM_DJ or wyozimc.HasPermission(ply, "PlayAll") then return true end
					GAMEMODE:Notify(ply, 1, 4, "You need to be a DJ to use this radio.")
					return false
				end)
			end)
		end
	end)

	hook.Add("OnPlayerChangedTeam", "WyoziMCDarkRPRemoveOldRadios", function(ply, oldjob, newjob)
		if oldjob == TEAM_DJ and wyozimc.DRP_RemoveRadiosOnTeamChange then
			for k, v in pairs(ents.FindByClass("wyozi_screen_radio")) do
				if v.SID == ply.SID then
					wyozimc.Debug(ply, " changed job. Removing his old radio ", v)
					v:Remove()
					ply["maxwyozi_screen_radio"] = (ply["maxwyozi_screen_radio"] or 1) - 1 
				end
			end
		end
	end)

end

-- Allow DJs and cinema owners to modify media list
hook.Add("WyoziMCPermission", "WyoziMCDarkRPJobPermissions", function(permission, ply)
	local team = ply:Team()
	if wyozimc.DRP_AllowJobEdit and (team == TEAM_DJ or team == TEAM_CINEMAOWNER) and (permission == "Add" or permission == "Delete") then
		return true
	end
end)