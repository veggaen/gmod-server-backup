
hook.Add("WyoziMCTabs", "WyoziMCAddSettingsTab", function(dtabs)

	local padding = dtabs:GetPadding()

	padding = padding * 2

	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0,0,padding,0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	do
		local dgui = vgui.Create("DForm", dsettings)
		dgui:SetName("General settings")

		local cb = nil

		dgui:CheckBox("Enable WMC", "wyozimc_enabled")

		dgui:CheckBox("Play music even if game is unfocused", "wyozimc_playwhenalttabbed")

		dgui:CheckBox("Don't play globally started (using Play for All) media", "wyozimc_ignoreglobalplays")

		dgui:CheckBox("Enable debug mode", "wyozimc_debug")

		dsettings:AddItem(dgui)

	end

	wyozimc.CallHook("WyoziMCAddToSettings", dsettings)

	dtabs:AddSheet( "Settings", dsettings, "icon16/wrench_orange.png", false, false, "" )
end)