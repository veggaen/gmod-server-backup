
local ProjectorPositions = {
	["rp_downtown_v4c_v2"] = {
		Position = Vector(-1812.943604, 1668.797119, 28.431726),
		Angles = Angle(23.568, 69.257, -2.687),
		WhiteScale = 0.85
	},
	["rp_downtown_v4c_v3"] = {
		Position = Vector(-1812.943604, 1668.797119, 28.431726),
		Angles = Angle(23.568, 69.257, -2.687),
		WhiteScale = 0.85
	}
}

local function AddProjs()
	local pp = ProjectorPositions[game.GetMap()]
	if pp then

		wyozimc.Debug("PP Found for ", game.GetMap())

		local projector = ents.Create("wyozi_screen_projector")
		projector:SetPos(pp.Position)
		projector:SetAngles(pp.Angles)
		projector:Spawn()
		projector:SetMoveType(MOVETYPE_NONE)

		projector:SetAllowFunc(function(ent, ply)
			if ply:Team() == TEAM_CINEMAOWNER or wyozimc.HasPermission(ply, "PlayAll") then return true end
			GAMEMODE:Notify(ply, 1, 4, "You need to be a cinema owner to use this projector.")
			return false
		end)
		projector:SetWhiteScale(pp.WhiteScale)

		wyozimc.Debug("Added pp ", projector, " ", projector:GetPos())


	else
		wyozimc.Debug("No pp found for ", game.GetMap())
	end
end

hook.Add("InitPostEntity", "WyoziMCAddDarkRPProjectors", AddProjs)

--AddProjs()