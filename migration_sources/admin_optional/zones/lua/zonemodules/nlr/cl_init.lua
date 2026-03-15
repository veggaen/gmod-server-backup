local zone = NULL
local displaywarning = false
local displaykicktimer = false
local kicktimerend = 0

surface.CreateFont("NLRFont", { size = 60 })
hook.Add("HUDPaint", "zonenlrdraw", function()
	if not IsValid(zone) then return end
	// NLR
	if displaywarning then
		local tab = {}
		tab[ "$pp_colour_addr" ] = 0
		tab[ "$pp_colour_addg" ] = 0
		tab[ "$pp_colour_addb" ] = 0
		tab[ "$pp_colour_brightness" ] = -0.20
		tab[ "$pp_colour_contrast" ] = 0.8
		tab[ "$pp_colour_colour" ] = 0
		tab[ "$pp_colour_mulr" ] = 0
		tab[ "$pp_colour_mulg" ] = 0
		tab[ "$pp_colour_mulb" ] = 0 
	 
		DrawColorModify( tab )
		
		surface.SetFont("NLRFont")
		local textsize = surface.GetTextSize(zone:GetZoneTitle())
		draw.DrawText(zone:GetZoneTitle(), "NLRFont", ScrW()/2-(textsize/2), 120, Color(255, 0, 0, 200))
		textsize = surface.GetTextSize(zone:GetZoneSubTitle())
		draw.DrawText(zone:GetZoneSubTitle(), "NLRFont", ScrW()/2-(textsize/2), 180, Color(255, 0, 0, 200))
		if displaykicktimer then
			draw.DrawText("You will be kicked in " .. Format("%.1f", math.Max(0, kicktimerend - CurTime())) .. " seconds", "NLRFont", ScrW()/2-(textsize/2), 240, Color(255, 0, 0, 200))
		end
	end
end)

usermessage.Hook("nlrzonealert", function(um)
	displaywarning = um:ReadBool()
	if displaywarning then
		zone = um:ReadEntity()
		displaykicktimer = um:ReadBool()
		if displaykicktimer then
			kicktimerend = CurTime() + um:ReadFloat()
		end
	end
end)

usermessage.Hook("nlrzonealertadmin", function(um)
	local ply = um:ReadEntity()
	if IsValid(ply) then
		notification.AddLegacy( ply:GetName() .. " is breaking NLR!", NOTIFY_ERROR, 10 )
		MsgC( Color(255, 0, 0), os.date() .. ": (" .. ply:SteamID() .. ") " .. ply:GetName() .. " is breaking NLR!\n" )
	end
end)