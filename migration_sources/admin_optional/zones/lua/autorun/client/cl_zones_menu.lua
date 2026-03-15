	concommand.Add("zones", function(ply, cmd, args)
	
		local zonecontrol
	
		// Create frame
		local frame = vgui.Create("DFrame")
		DelMods.vguiZoneFrame = frame
		frame:SetTitle("Edit zones")
		frame:SetSize(575, 525)
		frame:SetDraggable(true)
		frame:Center()
		frame:MakePopup()
		frame:SetKeyboardInputEnabled( false )

		// Capture input on textentries
		hook.Add( "OnTextEntryGetFocus", "zonemenugetfocus", function(pnl)
			if not IsValid(DelMods.vguiZoneFrame) then return end
			if pnl:HasParent(DelMods.vguiZoneFrame) then
				frame:SetKeyboardInputEnabled( true )
			end
		end)

		hook.Add( "OnTextEntryLoseFocus", "zonemenureleasefocus", function(pnl)
			if not IsValid(DelMods.vguiZoneFrame) then return end
			if pnl:HasParent(DelMods.vguiZoneFrame) then
				frame:SetKeyboardInputEnabled( false )
			end
		end)
		
		// Create list of zones
		local zonelistContainer = vgui.Create("DCategoryList", frame)
		zonelistContainer:SetWidth(150)
		zonelistContainer:Dock( LEFT )
		frame.zonelist = zonelistContainer:Add( "Zones" )
		function frame.zonelist:UpdateList()
			local zones = ents.FindByClass("zones")
			frame.zonesinfo.zamount:SetValue(#zones)
			// Clear zone list
			local children = frame.zonelist:GetChildren()
			table.remove(children, 1) // Leave the header.
			for k, v in pairs(children) do
				v:Remove()
			end
			for k, v in pairs(zones) do
				local zone = frame.zonelist:Add(v:GetDBID() .. ": " .. v:GetZoneTitle() .. " - " .. v:GetZoneSubTitle())
				zone.z = v
				zone.DoClick = function(panel) 
					zonecontrol:UpdateZone(panel.z)
				end
				if tonumber(zonecontrol.eid:GetValue()) == v:EntIndex() then
					zone:SetSelected(true)
				end
			end
		end
		
		local infocontainer = vgui.Create("DPanel", frame)
		infocontainer:Dock( FILL )
		
		// Create Generic zone control/information panel
		frame.zonesinfo = infocontainer:Add("DForm")
		frame.zonesinfo:SetName("Global info and controls")
		frame.zonesinfo:Dock( TOP )
		zonesinfogrid = vgui.Create("DGrid", frame.zonesinfo)
			zonesinfogrid:SetCols(2)
			zonesinfogrid:SetColWide(200)
			zonesinfogrid:SetRowHeight( 25 )
		frame.zonesinfo:AddItem(zonesinfogrid)
		
		zonesinfogrid.zphysical = vgui.Create("DCheckBoxLabel")
			zonesinfogrid.zphysical:SetText("Zones physical")
			zonesinfogrid.zphysical:SetDark(true)
			zonesinfogrid.zphysical:SetWide(200)
			zonesinfogrid.zphysical:SetChecked(LocalPlayer().zonephys or false)
			function zonesinfogrid.zphysical:OnChange(value)
				RunConsoleCommand("_zone_edit", "togglephys", tostring(value))
				LocalPlayer().zonephys = value
				zonesinfogrid.zvisible:SetChecked(value)
			end
			zonesinfogrid:AddItem(zonesinfogrid.zphysical)
			
		zonesinfogrid.zremoveall = vgui.Create("DButton", zonesinfogrid)
			zonesinfogrid.zremoveall:SetText("Remove all zones on this map")
			zonesinfogrid.zremoveall:StretchToParent(0, 0)
			zonesinfogrid.zremoveall:SetWide(200)
			function zonesinfogrid.zremoveall:DoClick()
				Derma_Query("Are you absolutely sure? There is no reversing this; all zones on this map will be deleted permanently!", "Confirm", 
					"Confirm", function() 
						RunConsoleCommand("_zone_remove_all") 
						
						// Clear zone list
						timer.Simple(0.1, function()
							frame.zonelist:UpdateList()
						end)
					end,
					"Cancel", function() end
				)
			end
			zonesinfogrid:AddItem(zonesinfogrid.zremoveall)
		
		zonesinfogrid.zvisible = vgui.Create("DCheckBoxLabel")
			zonesinfogrid.zvisible:SetText("Zones borders visible")
			zonesinfogrid.zvisible:SetDark(true)
			zonesinfogrid.zvisible:SetWide(200)
			zonesinfogrid.zvisible:SetChecked(LocalPlayer().see_zone_model or false)
			function zonesinfogrid.zvisible:OnChange(value)
				LocalPlayer().see_zone_model = value
			end
			zonesinfogrid:AddItem(zonesinfogrid.zvisible)
		zonesinfogrid.zhelp = vgui.Create("DButton")
			zonesinfogrid.zhelp:SetText("Information and help")
			zonesinfogrid.zhelp:SetDark(true)
			zonesinfogrid.zhelp:SetWide(200)
			function zonesinfogrid.zhelp:DoClick()
				gui.OpenURL("http://coderhire.com/scripts/view/377")
			end
			zonesinfogrid:AddItem(zonesinfogrid.zhelp)
			
		frame.zonesinfo.zamount = frame.zonesinfo:TextEntry("Zone amount:")
			frame.zonesinfo.zamount:SetValue(0)
			frame.zonesinfo.zamount:SetDisabled(true)
			frame.zonesinfo.zamount:SetEnabled(false)
			frame.zonesinfo.zamount:SetWidth(200)
			
		frame.zonesinfo.gsettings = frame.zonesinfo:Button("Open configuration panel")
			function frame.zonesinfo.gsettings.DoClick()
				// Open global settings
				local gsframe = vgui.Create("DFrame")
				gsframe:MakePopup()
				gsframe:SetSize(500, 500)
				gsframe:Center()
				gsframe:SetTitle("Zones: Global settings")
				
				gsframe.tabc = gsframe:Add("DPropertySheet")
				gsframe.tabc:Dock(FILL)
				
				if not LocalPlayer().zonesConfigLoading then
					LocalPlayer().zonesConfigLoading = true
					RunConsoleCommand("_zones_get_configsettings")
				end
				
				gsframe.zonemodules = {}
				
				gsframe.img = gsframe:Add("DPanel")
				//gsframe.img:SetImage("vgui/loading-rotate")
				local mat = Material("vgui/loading-rotate")
				function gsframe.img:Paint()
					surface.SetMaterial(mat)
					surface.SetDrawColor(Color(0, 0, 0, math.abs(math.cos(CurTime())) * 255))
					surface.DrawTexturedRectRotated( self:GetWide() / 2, self:GetTall() / 2, self:GetWide(), self:GetTall(), math.fmod(CurTime() * 300, 359) )
					
					draw.SimpleText("Loading...", "TargetID", self:GetWide() / 2, self:GetTall() / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

				gsframe.img:SetSize(80, 80)
				gsframe.img:Center()
				
				local function doupdate()
					if LocalPlayer().zonesConfigLoading then 
						timer.Simple(math.Rand(0, 1), doupdate)
						return
					end
					if not IsValid(gsframe) then return end
					gsframe.img:Remove()
					
					// Add core tab here, so it is ordered first
					local scrollpanel = gsframe.tabc:Add("DScrollPanel")
					gsframe.zonemodules["core"] = scrollpanel:Add("DForm")
					gsframe.zonemodules["core"]:SetName("Core")
					gsframe.zonemodules["core"]:Dock(FILL)
					scrollpanel:Dock(FILL)
					gsframe.tabc:AddSheet("Core", scrollpanel, nil, nil, nil, "Settings for the core zone module.")
					
					for _, metazonemodule in pairs(DelMods.zones.configmetadata) do
						for _, meta in pairs(metazonemodule) do
							if not gsframe.zonemodules[meta.zonemodule] then
								local scrollpanel = gsframe.tabc:Add("DScrollPanel")
								gsframe.zonemodules[meta.zonemodule] = gsframe.zonemodules[meta.zonemodule] or scrollpanel:Add("DForm")
								local name = DelMods.zonemodules[meta.zonemodule] and DelMods.zonemodules[meta.zonemodule].nicename or meta.zonemodule
								gsframe.zonemodules[meta.zonemodule]:SetName(name)
								gsframe.zonemodules[meta.zonemodule]:Dock(FILL)
								scrollpanel:Dock(FILL)
								gsframe.tabc:AddSheet(name, scrollpanel, nil, nil, nil, "Settings for the " .. name .. " zone module.")
							end
							
							local left, right = NULL
							if DelMods.typeEx(meta.defaultvalue) == "boolean" then
								right = gsframe.zonemodules[meta.zonemodule]:CheckBox(meta.nicename)
								if not DelMods.zonemodules[meta.requires].installed then
									right.Button:SetDisabled(true)
									right.Label:SetDisabled(true)
									right:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								else
									right:SetTooltip(meta.details)
								end
								right:SetChecked( DelMods.zones:GetConfig(meta.zonemodule, meta.optionname) )
								function right:OnChange()
									DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, self:GetChecked())
								end
							elseif DelMods.typeEx(meta.defaultvalue) == "string" then
								right, left = gsframe.zonemodules[meta.zonemodule]:TextEntry(meta.nicename)
								right:SetText( meta.allowedOnClient ~= -1 and DelMods.zones:GetConfig(meta.zonemodule, meta.optionname) or "" )
								if not DelMods.zonemodules[meta.requires].installed then
									right:SetDisabled(true)
									left:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								else
									left:SetTooltip(meta.details)
								end
								function right:OnTextChanged()
									DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, self:GetValue())
								end
							elseif DelMods.typeEx(meta.defaultvalue) == "number" then
								right, left = gsframe.zonemodules[meta.zonemodule]:TextEntry(meta.nicename)
								right:SetNumeric(true)
								right:SetText( meta.allowedOnClient ~= -1 and math.Round(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname) or 0, 6) or "" )
								if not DelMods.zonemodules[meta.requires].installed then
									right:SetDisabled(true)
									left:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								else
									left:SetTooltip(meta.details)
								end
								function right:OnTextChanged()
									DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, tonumber(self:GetValue()))
								end
							elseif DelMods.typeEx(meta.defaultvalue) == "color" then
								local colorpanel = vgui.Create("DColorMixer", textcolorholder)
								colorpanel:SetLabel(meta.nicename)
								function colorpanel:ValueChanged(color)
									if string.FromColor(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname)) ~= string.FromColor(color) then
										DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, color)
									end
								end
								colorpanel:UpdateColor(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname))
								right = gsframe.zonemodules[meta.zonemodule]:AddItem(colorpanel)
								if not DelMods.zonemodules[meta.requires].installed then
									colorpanel:SetDisabled(true)
									colorpanel:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								else
									colorpanel:SetTooltip(meta.details)
								end
							elseif DelMods.typeEx(meta.defaultvalue) == "table" then
								local label = vgui.Create( "DLabel" )
								label:SetText( meta.nicename )
								label:SetDark( true )
								label:SetTooltip(meta.details)
								
								local listcontainer = vgui.Create("DPanel")
								listcontainer:SetDrawBackground(false)
								listcontainer:SetTall(80)
								
								local actions = vgui.Create("DGrid", listcontainer)
								actions:Dock(LEFT)
								actions:SetColWide((listcontainer:GetTall() / 2))
								actions:SetRowHeight((listcontainer:GetTall() / 2))
								actions:SetCols(1)
								actions:SetTall(listcontainer:GetTall())
									local add = vgui.Create("DButton")
									add:SetImage("icon16/add.png")
									add:SetText("")
									add:SetSize((listcontainer:GetTall() / 2), (listcontainer:GetTall() / 2))
									add.m_Image:SetPos(add:GetWide() / 2 - 8, add:GetTall() / 2 - 8)
									add.m_Image = nil // Fuck off, we'll handle positioning, kkthx
									add:SetTooltip("Add to list")
									actions:AddItem(add)
									
									local remove = vgui.Create("DButton")
									remove:SetImage("icon16/delete.png")
									remove:SetText("")
									remove:SetSize((listcontainer:GetTall() / 2), (listcontainer:GetTall() / 2))
									remove.m_Image:SetPos(remove:GetWide() / 2 - 8, remove:GetTall() / 2 - 8)
									remove.m_Image = nil // Fuck off, we'll handle positioning, kkthx
									remove:SetTooltip("Remove selected from list")
									actions:AddItem(remove)
								
								local scroller = vgui.Create( "DScrollPanel", listcontainer )
								scroller:Dock(FILL)
								scroller:SetTall(listcontainer:GetTall())
								scroller:SetPos(25, 0)
								
								local listbox = vgui.Create( "DListView", scroller )
								local typecolumn = listbox:AddColumn("Type")
								typecolumn:SetFixedWidth(75)
								listbox:AddColumn("Value")
								listbox:SetTall(listcontainer:GetTall())
								listbox:Dock(FILL)
								gsframe.zonemodules[meta.zonemodule]:AddItem(label)
								gsframe.zonemodules[meta.zonemodule]:AddItem(listcontainer)
								
								function add:DoClick()
									local addframe = vgui.Create("DFrame")
									addframe:SetTitle("Insert new value..")
									addframe:SetSize(200, 80)
									addframe:MakePopup()
									addframe:Center()
									
									local datatype = addframe:Add("DComboBox")
									datatype:Dock(LEFT)
									datatype:AddChoice("String")
									datatype:AddChoice("Number")
									datatype:ChooseOptionID(1)
									
									local value = addframe:Add("DTextEntry")
									value:Dock(FILL)
									
									function datatype:OnSelect()
										if self:GetValue() == "String" then
											value:SetNumeric(false)
										elseif self:GetValue() == "Number" then
											value:SetNumeric(true)
											value:SetValue(tostring(tonumber(value:GetValue()) or ""))
										end
									end
									
									local okbutton = addframe:Add("DButton")
									okbutton:SetText("Insert value")
									okbutton:Dock(BOTTOM)
									function okbutton:DoClick()
										if value:GetValue():len() ~= 0 then
											local item = listbox:AddLine(datatype:GetValue():lower(), tostring(value:GetValue()))
											if datatype:GetValue() == "String" then
												item.value = tostring(value:GetValue())
											elseif datatype:GetValue() == "Number" then
												item.value = tonumber(value:GetValue())
											end
											
											local items = {}
											for k, v in pairs(listbox:GetLines()) do
												table.insert(items, v.value)
											end
											DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, items)
										end
										addframe:Remove()
									end
								end
								
								function remove:DoClick()
									for k, v in pairs(listbox:GetSelected()) do
										listbox:RemoveLine(v:GetID())
									end
									listbox.SelectedItems = {}

									local items = {}
									for k, v in pairs(listbox:GetLines()) do
										table.insert(items, v.value)
									end
									DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, items)
								end
								
								for k, v in pairs(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname)) do
									local listboxitem = listbox:AddLine(DelMods.typeEx(v), v)
									listboxitem.value = v
								end
								
								if not DelMods.zonemodules[meta.requires].installed then
									add:SetDisabled(true)
									remove:SetDisabled(true)
									listbox:SetDisabled(true)
									label:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								end
							elseif DelMods.typeEx(meta.defaultvalue) == "fontdata" then
								right = gsframe.zonemodules[meta.zonemodule]:Button(meta.nicename)
								right:SetFont(DelMods.getFont(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname)))
								right:SetTall(40)
								if not DelMods.zonemodules[meta.requires].installed then
									right:SetDisabled(true)
									right:SetTooltip("Requires " .. DelMods.zonemodules[meta.requires].nicename .. " module")
								else
									right:SetTooltip(meta.details)
								end
								function right:DoClick()
									local font = DelMods.zones:GetConfig(meta.zonemodule, meta.optionname)
									local fontbackup = DelMods.zones.datatypes.fontdata
									local fontframe = vgui.Create("DFrame")
									fontframe:SetBackgroundBlur(true)
									fontframe:SetSize(350, 400)
									fontframe:SetTitle("Font settings..")
									fontframe:Center()
									fontframe:MakePopup()
									
									local preview = fontframe:Add("DPanel")
									preview:SetTall(100)
									preview:Dock(TOP)
									
									local scroller = fontframe:Add("DScrollPanel")
									scroller:Dock(FILL)
									
									local fontform = scroller:Add("DForm")
									local preview_font = {}
									function preview:Paint()
										local timemultiplier = .1
										local timecolor = math.abs(math.sin(CurTime() * timemultiplier)) * 255
										surface.SetDrawColor(Color(timecolor, timecolor, timecolor))
										surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
										preview_font.crc = nil
										for k, v in pairs(fontform.fontitems) do
											if v.type == "string" then
												preview_font[k] = tostring(v:GetText())
											elseif v.type == "number" then
												preview_font[k] = tonumber(v:GetValue())
											elseif v.type == "boolean" then
												preview_font[k] = tobool(v:GetChecked())
											end
										end
										//surface.DisableClipping(true)
										draw.SimpleText("Font Preview", DelMods.getFont(preview_font), self:GetWide() / 2, self:GetTall() / 2, Color(200, 200, 200, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
									end
									fontform:Dock(FILL)
									fontform:SetName("Font settings")
									
									fontform.fontitems = {}
									
									fontform.fontitems.font = fontform:ComboBox("Font type")
									fontform.fontitems.font:AddChoice("Arial")
									fontform.fontitems.font:AddChoice("Arial Black")
									fontform.fontitems.font:AddChoice("Courier New")
									fontform.fontitems.font:AddChoice("Trebuchet MS")
									fontform.fontitems.font:AddChoice("Tahoma")
									fontform.fontitems.font:AddChoice("Verdana")
									fontform.fontitems.font:SetValue(font.font)
									fontform.fontitems.font.type = "string"
									
									fontform.fontitems.size = fontform:TextEntry("Size")
									fontform.fontitems.size:SetValue(tostring(tonumber(font.size) or fontbackup.size))
									fontform.fontitems.size:SetNumeric(true)
									fontform.fontitems.size.type = "number"
									fontform.fontitems.weight = fontform:TextEntry("Weight")
									fontform.fontitems.weight:SetValue(tostring(tonumber(font.weight) or fontbackup.weight))
									fontform.fontitems.weight:SetNumeric(true)
									fontform.fontitems.weight.type = "number"
									fontform.fontitems.blursize = fontform:TextEntry("Blursize")
									fontform.fontitems.blursize:SetValue(tostring(tonumber(font.blursize) or fontbackup.blursize))
									fontform.fontitems.blursize:SetNumeric(true)
									fontform.fontitems.blursize.type = "number"
									fontform.fontitems.scanlines = fontform:TextEntry("Scanlines")
									fontform.fontitems.scanlines:SetValue(tostring(tonumber(font.scanlines) or fontbackup.scanlines))
									fontform.fontitems.scanlines:SetNumeric(true)
									fontform.fontitems.scanlines.type = "number"
									fontform.fontitems.antialias = fontform:CheckBox("Antialias")
									fontform.fontitems.antialias:SetChecked(tobool(font.antialias))
									fontform.fontitems.antialias.type = "boolean"
									fontform.fontitems.underline = fontform:CheckBox("Underline")
									fontform.fontitems.underline:SetChecked(tobool(font.underline))
									fontform.fontitems.underline.type = "boolean"
									fontform.fontitems.italic = fontform:CheckBox("Italic")
									fontform.fontitems.italic:SetChecked(tobool(font.italic))
									fontform.fontitems.italic.type = "boolean"
									fontform.fontitems.strikeout = fontform:CheckBox("Strikeout")
									fontform.fontitems.strikeout:SetChecked(tobool(font.strikeout))
									fontform.fontitems.strikeout.type = "boolean"
									fontform.fontitems.symbol = fontform:CheckBox("Symbol")
									fontform.fontitems.symbol:SetChecked(tobool(font.symbol))
									fontform.fontitems.symbol.type = "boolean"
									fontform.fontitems.rotary = fontform:CheckBox("Rotary")
									fontform.fontitems.rotary:SetChecked(tobool(font.rotary))
									fontform.fontitems.rotary.type = "boolean"
									fontform.fontitems.shadow = fontform:CheckBox("Shadow")
									fontform.fontitems.shadow:SetChecked(tobool(font.shadow))
									fontform.fontitems.shadow.type = "boolean"
									fontform.fontitems.additive = fontform:CheckBox("Additive")
									fontform.fontitems.additive:SetChecked(tobool(font.additive))
									fontform.fontitems.additive.type = "boolean"
									fontform.fontitems.outline = fontform:CheckBox("Outline")
									fontform.fontitems.outline:SetChecked(tobool(font.outline))
									fontform.fontitems.outline.type = "boolean"
									
									local okbutton = fontframe:Add("DButton")
									okbutton:SetTall(20)
									okbutton:Dock(BOTTOM)
									okbutton:SetText("Save new font")
									function okbutton:DoClick()
										DelMods.zones:SetConfig(meta.zonemodule, meta.optionname, preview_font)
										right:SetFont(DelMods.getFont(preview_font))
										fontframe:Remove()
									end
									
								end
							end
						end
					end
				end
				doupdate()
			end
		
		// Zone specific controls
		zonecontrol = infocontainer:Add("DForm")
		zonecontrol:Dock( TOP )
		zonecontrol:SetName("Zone control")
		zonecontrol.dbid = zonecontrol:TextEntry("Database ID")
			zonecontrol.dbid:SetValue(0)
			zonecontrol.dbid:SetDisabled(true)
			zonecontrol.dbid:SetEnabled(false)
		zonecontrol.eid = zonecontrol:TextEntry("Entity ID")
			zonecontrol.eid:SetValue(0)
			zonecontrol.eid:SetDisabled(true)
			zonecontrol.eid:SetEnabled(false)
		zonecontrol.zname = zonecontrol:TextEntry("Name")
		zonecontrol.zname:SetAllowNonAsciiCharacters(true)
		zonecontrol.zsubname = zonecontrol:TextEntry("Subname")
		zonecontrol.zsubname:SetAllowNonAsciiCharacters(true)
		zonecontrol.sizecontrol = zonecontrol:NumSlider("Zone Size", nil, 75, 3000, 0)
			zonecontrol.sizecontrol:SetValue(75)

		zonecontrol.zonetypesgrid = vgui.Create("DGrid")
		zonecontrol.zonetypesgrid:SetCols(3)
		zonecontrol.zonetypesgrid:SetColWide( 150 )
		zonecontrol:AddItem(zonecontrol.zonetypesgrid)
		for key, zonemodule in pairs(DelMods.zonemodules) do
			if zonemodule.typeid < 0 then continue end
			zonecontrol.zonetypes = zonecontrol.zonetypes or {}
			zonecontrol.zonetypes[zonemodule.name] = vgui.Create("DCheckBoxLabel")
			zonecontrol.zonetypes[zonemodule.name].key = zonemodule.typeid
			zonecontrol.zonetypes[zonemodule.name]:SetText(zonemodule.nicename)
			zonecontrol.zonetypes[zonemodule.name]:SetDark(true)
			zonecontrol.zonetypes[zonemodule.name]:SetWide(150)
			zonecontrol.zonetypes[zonemodule.name]:SetChecked(false)
			zonecontrol.zonetypesgrid:AddItem(zonecontrol.zonetypes[zonemodule.name])
			zonecontrol.zonetypes[zonemodule.name]:SetDisabled(not zonemodule.allowcreate)
			LocalPlayer().tooltip_delay = LocalPlayer().tooltip_delay or GetConVarNumber("tooltip_delay")
			if not zonemodule.installed then
				zonecontrol.zonetypes[zonemodule.name].Label:SetMouseInputEnabled( false )
				zonecontrol.zonetypes[zonemodule.name].Button:SetMouseInputEnabled( false )
				zonecontrol.zonetypes[zonemodule.name]:SetAlpha( 75 )
				zonecontrol.zonetypes[zonemodule.name].OnCursorEntered = function(self)
					local tooltip = vgui.Create("DTooltip")
					zonecontrol.zonetypes[zonemodule.name].tooltip = tooltip
					tooltip.TargetPanel = self
					tooltip:SetVisible(true)
					local tooltiptext = vgui.Create("DLabel", tooltip)
					tooltiptext:SetText("Available in DLC")
					tooltiptext:SetFont("DermaDefaultBold")
					tooltiptext:SizeToContents()
					tooltiptext:SetDark(true)
					tooltip:SetContents(tooltiptext, true)
					tooltiptext:SetVisible(true)
					tooltip:PositionTooltip()
				end
				zonecontrol.zonetypes[zonemodule.name].OnCursorExited = function(self)
					zonecontrol.zonetypes[zonemodule.name].tooltip:Remove()
				end
				zonecontrol.zonetypes[zonemodule.name]:SetTextColor(Color(255, 0, 0))
			end
		end
		
		zonecontrol.controlsgrid = vgui.Create("DGrid")
		zonecontrol.controlsgrid:SetCols(4)
		zonecontrol.controlsgrid:SetColWide( 100 )
		zonecontrol:AddItem(zonecontrol.controlsgrid)
		
		zonecontrol.teletomeb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.teletomeb:SetText("Teleport to me")
			zonecontrol.teletomeb:SetDisabled(true)
			function zonecontrol.teletomeb:DoClick()
				RunConsoleCommand("_zone_tele", "tome", zonecontrol.eid:GetValue())
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.teletomeb)
		zonecontrol.telemetob = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.telemetob:SetText("Teleport me to it")
			zonecontrol.telemetob:SetDisabled(true)
			function zonecontrol.telemetob:DoClick()
				RunConsoleCommand("_zone_tele", "metoit", zonecontrol.eid:GetValue())
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.telemetob)
		zonecontrol.teletotargetb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.teletotargetb:SetText("Teleport to target")
			zonecontrol.teletotargetb:SetDisabled(true)
			function zonecontrol.teletotargetb:DoClick()
				RunConsoleCommand("_zone_tele", "totarget", zonecontrol.eid:GetValue())
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.teletotargetb)
		zonecontrol.saveb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.saveb:SetText("Create")
			function zonecontrol.saveb:DoClick()
				local calcValue = 0
				for name, zonemodule in pairs(DelMods.zonemodules) do
					if zonecontrol.zonetypes[name] and zonecontrol.zonetypes[name]:GetChecked() then
						calcValue = calcValue + zonemodule.typeid
					end
				end
				if tobool(zonecontrol.dbid:GetValue()) then
					// Update existing
					RunConsoleCommand("_zone_update", zonecontrol.eid:GetValue(), zonecontrol.sizecontrol:GetValue(), calcValue, zonecontrol.zname:GetValue(), zonecontrol.zsubname:GetValue())
					timer.Simple(.05, function() DelMods.vguiZoneFrame.zonelist:UpdateList() end)
				else
					// Create new from values in fields
					RunConsoleCommand("_zone_create", zonecontrol.sizecontrol:GetValue(), calcValue, zonecontrol.zname:GetValue(), zonecontrol.zsubname:GetValue())
				end
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.saveb)
		zonecontrol.cloneb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.cloneb:SetText("Clone")
			zonecontrol.cloneb:SetDisabled(true)
			function zonecontrol.cloneb:DoClick()
				local calcValue = 0
				for name, zonemodule in pairs(DelMods.zonemodules) do
					if zonecontrol.zonetypes[name] and zonecontrol.zonetypes[name]:GetChecked() then
						calcValue = calcValue + zonemodule.typeid
					end
				end
				// Create new from values in fields
				RunConsoleCommand("_zone_create", zonecontrol.sizecontrol:GetValue(), calcValue, zonecontrol.zname:GetValue(), zonecontrol.zsubname:GetValue())
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.cloneb)
		zonecontrol.delb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.delb:SetText("Delete")
			zonecontrol.delb:SetDisabled(true)
			function zonecontrol.delb:DoClick()
				RunConsoleCommand("_zone_remove", zonecontrol.eid:GetValue())
				zonecontrol:ClearZone()
				timer.Simple(0.1, function()
					frame.zonelist:UpdateList()
				end)
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.delb)
		zonecontrol.clearb = vgui.Create("DButton", zonecontrol.controlsgrid)
			zonecontrol.clearb:SetText("Clear")
			function zonecontrol.clearb:DoClick()
				zonecontrol:ClearZone()
			end
			zonecontrol.controlsgrid:AddItem(zonecontrol.clearb)
		for k, v in pairs(zonecontrol.controlsgrid:GetItems()) do
			v:SetWide(100)
		end
		
		function zonecontrol:UpdateZone(zone)
			if !IsValid(zone) then return end
			zonecontrol.dbid:SetValue(tostring(zone:GetDBID()))
			zonecontrol.eid:SetValue(tostring(zone:EntIndex()))
			zonecontrol.zname:SetValue(zone:GetZoneTitle())
			zonecontrol.zsubname:SetValue(zone:GetZoneSubTitle())
			zonecontrol.sizecontrol:SetValue(zone:GetZoneLength())
			for k, v in pairs(zonecontrol.zonetypes) do
				v:SetChecked( zone:IsZoneType( v.key ) )
			end
			zonecontrol.teletomeb:SetDisabled(false)
			zonecontrol.telemetob:SetDisabled(false)
			zonecontrol.teletotargetb:SetDisabled(false)
			zonecontrol.cloneb:SetDisabled(false)
			zonecontrol.delb:SetDisabled(false)
			zonecontrol.saveb:SetText("Save")
		end
		
		function zonecontrol:ClearZone()
			zonecontrol.dbid:SetValue(0)
			zonecontrol.eid:SetValue(0)
			zonecontrol.zname:SetValue("")
			zonecontrol.zsubname:SetValue("")
			zonecontrol.sizecontrol:SetValue(75)
			for k, v in pairs(zonecontrol.zonetypes) do
				v:SetChecked(false)
			end
			zonecontrol.teletomeb:SetDisabled(true)
			zonecontrol.telemetob:SetDisabled(true)
			zonecontrol.teletotargetb:SetDisabled(true)
			zonecontrol.cloneb:SetDisabled(true)
			zonecontrol.delb:SetDisabled(true)
			zonecontrol.saveb:SetText("Create")
		end
		
		local zone = GetZone(LocalPlayer())
		if IsValid(zone) then	
			zonecontrol:UpdateZone(zone)
		end
		DelMods.vguiZoneControl = zonecontrol
		frame.zonelist:UpdateList()
	end)
	
	usermessage.Hook("zone_new_id", function(um)
		local id = um:ReadLong()
		DelMods.vguiZoneControl:UpdateZone(Entity(id))
		DelMods.vguiZoneFrame.zonelist:UpdateList()
	end)