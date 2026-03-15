	hook.Add("zone.Draw", "zone.draw", function(zone)
		local shouldDraw = hook.Call("zone.ShouldDrawDefault", nil, zone)
		if shouldDraw == nil then shouldDraw = true end
		if shouldDraw and (zone:IsVisibleTo() or LocalPlayer().see_zone_model) then
			zone:DrawVisualAid()
			if LocalPlayer().see_zone_model then
				zone:SetColor(zone:GetZoneColor())
				zone:DrawModel()
			end
		end
	end)
	
	local function toggleZoneVis(um)
		LocalPlayer().see_zone_model = um:ReadBool()
	end
	usermessage.Hook("toggleZoneVis", toggleZoneVis)

	net.Receive("zone.updateVisibility", function()
		local visTable = net.ReadTable()
		if IsValid(visTable.zone) then 
			visTable.zone.visibleTo = visTable.zone.visibleTo or {}
			visTable.zone.visibleTo[LocalPlayer():UniqueID()] = visTable.visible 
			if visTable.zone:IsVisibleTo(LocalPlayer()) then
				visTable.zone.renderLength = visTable.zone:GetZoneLength()
				visTable.zone:SetRenderBounds(Vector(1, 1, 1) * -visTable.zone:GetZoneLength(), Vector(1, 1, 1) * visTable.zone:GetZoneLength())
			end
		end
	end)

	net.Receive("zones.updateVisibility", function()
		local visTable = net.ReadTable()
		for k, v in pairs(visTable) do
			if IsValid(v.zone) then
				v.zone.visibleTo[LocalPlayer():UniqueID()] = v.visible
				if v.zone:IsVisibleTo() then
					v.zone.renderLength = v.zone:GetZoneLength()
					v.zone:SetRenderBounds(Vector(1, 1, 1) * -v.zone:GetZoneLength(), Vector(1, 1, 1) * v.zone:GetZoneLength())
				end
			end
		end
		LocalPlayer().zonesLoadingVisibility = false
	end)