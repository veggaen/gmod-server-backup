
local zonegreetent = NULL
local zonegreetentlast = NULL
local zonegreetlast = -1
local zonegreetsettings = {}
local zonegreetsettingsprocessed = {}

// Only create fonts once
local fonts = {}
local function getFont(str, size)
	if not str or str == "" then return "TargetID" end
	if not fonts[tostring(str) .. tostring(size)] then
		surface.CreateFont( tostring(str) .. tostring(size), {font = str, size = size} )
		fonts[tostring(str) .. tostring(size)] = true
	end
	return tostring(str) .. tostring(size)
end

local function zonegreetsettingsprocess()
	if zonegreetent ~= zonegreetentlast then
		zonegreetentlast = zonegreetent
		zonegreetsettingsprocessed = {
			length = zonegreetsettings.length or 3,
			fadein = zonegreetsettings.fadein or .15,
			fadeout = zonegreetsettings.fadeout or .85,
			startendoffset = zonegreetsettings.startendoffset or 300,
			startendoffsetmid = zonegreetsettings.startendoffsetmid or 30,
			border = zonegreetsettings.border or 5,
			screenY = zonegreetsettings.screenY or 100,
			topbgcolor = zonegreetsettings.topbgcolor or Color(0, 0, 0, 200),
			toptxtcolor = zonegreetsettings.toptxtcolor or Color(255, 255, 255, 255),
			toptxtfont = zonegreetsettings.toptxtfont or {font = "Arial Black", size = 60},
			botbgcolor = zonegreetsettings.botbgcolor or Color(0, 0, 0, 200),
			bottxtcolor = zonegreetsettings.bottxtcolor or Color(255, 255, 255, 150),
			bottxtfont = zonegreetsettings.bottxtfont or {font = "Arial", size = 50},
		}
	end
	zonegreetsettingsprocessed["name"] = IsValid(zonegreetent) and zonegreetent:GetZoneTitle() or ""
	zonegreetsettingsprocessed["subname"] = IsValid(zonegreetent) and zonegreetent:GetZoneSubTitle() or ""
	return zonegreetsettingsprocessed
end

hook.Add("HUDPaint", "zonegreetdraw", function()
	if zonegreetlast < 0 or table.Count(zonegreetsettings) == 0 then return end
	if not IsValid(zonegreetent) then return end
	
	// Settings and values
	local settings = zonegreetsettingsprocess()
	
	// Percentage calc
	local percentdone = ((CurTime() - zonegreetlast) / settings.length)
	local midpercentdone = 0
	if percentdone > 1 then return end
	local fadeprocess = 1
	local posoffset = 0
	if percentdone < settings.fadein then
		fadeprocess = percentdone / settings.fadein
		posoffset = settings.startendoffsetmid + (settings.startendoffset * (1 - fadeprocess))
	elseif percentdone > settings.fadeout then
		fadeprocess = (1 - percentdone) / (1 - settings.fadeout)
		posoffset = -settings.startendoffsetmid + (settings.startendoffset * (-1 + fadeprocess))
	else
		midpercentdone = (percentdone - settings.fadein) / (settings.fadeout - settings.fadein)
		posoffset = settings.startendoffsetmid * -((midpercentdone - 0.5)*2)
	end
	
	// Reset texture
	surface.SetTexture(0)
	
	// Top bar
	surface.SetFont(getFont(settings.toptxtfont.font, settings.toptxtfont.size))
	
	local widthname, heightname = surface.GetTextSize(settings.name)
	local namex, namey = (ScrW() / 2) - 100 - (widthname / 2) - posoffset, 100
	surface.SetTextPos( namex, namey )
	
	local poly_name_background = {
		{x = namex - settings.border * 15, y = namey - settings.border}, // Upper left corner
		{x = namex, y = namey + heightname + settings.border}, // Bottom left corner
		{x = namex + widthname + settings.border * 15, y = namey + heightname + settings.border}, // Right bottom corner
		{x = namex + widthname, y = namey - settings.border} // Upper left corner
	}
		
	if settings.name:len() > 0 then
		surface.SetDrawColor(Color(settings.topbgcolor.r, settings.topbgcolor.g, settings.topbgcolor.b, math.Round(settings.topbgcolor.a * math.abs(fadeprocess))))
		surface.DrawPoly(poly_name_background)
		surface.SetTextColor(Color(settings.toptxtcolor.r, settings.toptxtcolor.g, settings.toptxtcolor.b, math.Round(settings.toptxtcolor.a * math.abs(fadeprocess))))
		surface.DrawText(settings.name)
	end
	
	// Bot bar
	if settings.subname:len() > 0 then
		surface.SetFont(getFont(settings.bottxtfont.font, settings.bottxtfont.size))
		
		local widthsubname, heightsubname = surface.GetTextSize(settings.subname)
		local subnamex, subnamey = (ScrW() / 2) + 100 - (widthsubname / 2) + posoffset, namey + heightname + (settings.border * 3)
		surface.SetTextPos( subnamex, subnamey )
		
		local poly_subname_background = {
			{x = subnamex - settings.border * 15, y = subnamey - settings.border}, // Upper left corner
			{x = subnamex, y = subnamey + heightsubname + settings.border}, // Bottom left corner
			{x = subnamex + widthsubname + settings.border * 15, y = subnamey + heightsubname + settings.border}, // Right bottom corner
			{x = subnamex + widthsubname, y = subnamey - settings.border} // Upper left corner
		}
		
		surface.SetDrawColor(Color(settings.botbgcolor.r, settings.botbgcolor.g, settings.botbgcolor.b, settings.botbgcolor.a * fadeprocess))
		surface.DrawPoly(poly_subname_background)
		surface.SetTextColor(Color(settings.bottxtcolor.r, settings.bottxtcolor.g, settings.bottxtcolor.b, settings.bottxtcolor.a * fadeprocess))
		surface.DrawText(settings.subname)
	end
end)


local function zoneSplash (um)
	local zone = um:ReadEntity()
	if IsValid(zone) then
		zonegreetent = zone
		zonegreetlast = CurTime()
	end
end
usermessage.Hook("zoneSplash", zoneSplash)

net.Receive( "zoneGreetSettings", function()
	zonegreetsettings = net.ReadTable()
end)