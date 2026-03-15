
	DelMods = DelMods or {}
	DelMods.fonts = {}
	if CLIENT then
		function DelMods.getFont(fontdata)
			if not DelMods.typeEx(fontdata) == "fontdata" then return "TargetID" end
			if not fontdata.crc then 
				fontdata.crc = tostring(util.CRC(util.TableToJSON(fontdata)))
			end
			if not DelMods.fonts["DelMods." .. fontdata.crc] then
				surface.CreateFont( "DelMods." .. fontdata.crc, fontdata )
				DelMods.fonts["DelMods." .. fontdata.crc] = true
			end
			return "DelMods." .. fontdata.crc
		end
	end
	DelMods.zones = DelMods.zones or {}
	DelMods.zones.config = DelMods.zones.config or {}
	DelMods.zones.configmetadata = DelMods.zones.configmetadata or {}
	DelMods.zones.datatypes = {
		["number"] = 0, 
		["string"] = "", 
		["boolean"] = false, 
		["color"] = Color(0, 0, 0, 0), 
		["table"] = {},
		["fontdata"] = {
			crc = "",
			font = "Arial",
			size = 13,
			weight = 500,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false
		}
	}
	
	local function typeEx(val)
		if type(val) == "table" then
			if type(val.r) == "number" and type(val.g) == "number" and type(val.b) == "number" and type(val.a) == "number" then
				return "color"
			else
				local isFont = tobool(table.Count(val))
				for key, value in pairs(val) do
					if type(DelMods.zones.datatypes.fontdata[key]) == "nil" then
						isFont = false
						break
					end
				end
				if isFont then return "fontdata" end
			end
		end
		return type(val)
	end
	DelMods.typeEx = typeEx
	
	function DelMods.zones:GetConfig(zonemodule, option)
		if self.config[zonemodule] and self.config[zonemodule][option] ~= nil then
			return self.config[zonemodule][option]
		else
			local meta = self:GetConfigMeta(zonemodule, option)
			if meta and meta.defaultvalue ~= nil and self.datatypes[typeEx(meta.defaultvalue)] ~= nil then
				if CLIENT and meta.allowedOnClient and not LocalPlayer()["zonesConfigOptionLoading" .. tostring(option) .. tostring(zonemodule)] then
					LocalPlayer()["zonesConfigOptionLoading" .. tostring(option) .. tostring(zonemodule)] = true
					RunConsoleCommand("_zones_get_config", tostring(zonemodule), tostring(option))
				end
				return meta.defaultvalue
			else
				ErrorNoHalt("Zones config error. No such config exists.(" .. zonemodule .. ", " .. option .. ")\n")
				return
			end
		end
		return 0
	end

	/**
		SetConfig -- Sets a module option to a given value
		@param string zonemodule Which module this config option belongs to
		@param string option
		@param any value Config option value
	*/
	function DelMods.zones:SetConfig(zonemodule, option, value)
		if SERVER then
			local meta = self:GetConfigMeta(zonemodule, option)
			if meta and typeEx(meta.defaultvalue) ~= "nil" then
				if typeEx(value) == typeEx(meta.defaultvalue) then
					self.config[meta.zonemodule] = self.config[meta.zonemodule] or {}
					self.config[meta.zonemodule][meta.optionname] = value
					self:SaveConfig()
					if meta.allowedOnClient then
						net.Start("zone.configoption")
							net.WriteString(meta.zonemodule)
							net.WriteString(meta.optionname)
							net.WriteType(value)
						net.Broadcast()
					end
					return true
				else
					ErrorNoHalt("Zones config failed! Tried to set config option to an invalid value (Got '" .. typeEx(value) .. "', expected '" .. typeEx(meta.defaultvalue) .. "'\n")
				end
			else
				ErrorNoHalt("Zones config failed! Tried to set an unknown config option.(" .. zonemodule .. ", " .. option .. ")\n")
			end
			return false
		else
			timer.Create("zone.SetConfig" .. option .. zonemodule, .3, 1, function()
				net.Start("zone.setconfigoption")
					net.WriteString(zonemodule)
					net.WriteString(option)
					net.WriteType(value)
				net.SendToServer()
			end)
		end
	end
	
	/**
		GetConfigMeta -- Get a given config option template
		@param string zonemodule Which module this config option belongs to
		@param string option
	*/
	function DelMods.zones:GetConfigMeta(zonemodule, option)
		if not zonemodule or not option then return false end
		for _, metaoption in pairs(self.configmetadata[tostring(zonemodule)] and self.configmetadata[tostring(zonemodule)] or {}) do
			if option == metaoption.optionname then
				return metaoption
			end
		end
		return false
	end
	
	/**
		AddConfigMeta -- Add a config option template
		@param string optionname The short name of the config option
		@param string nicename The nice name of the config option (this is displayed in menus)
		@param string zonemodule Which module this config option belongs to
		@param string requires Which module this config option requires
		@param string defaultvalue What the default value should be
		@param boolean allowedOnClient Whether client should be allowed to request this variable
	*/
	function DelMods.zones:AddConfigMeta(optionname, nicename, details, zonemodule, defaultvalue, requires, allowedOnClient)
		if not requires then requires = zonemodule end
		if not allowedOnClient then allowedOnClient = false end
		if not optionname or not nicename or not zonemodule or not requires then Error("Zones config failed! Tried to add invalid config metadata\n") debug.Trace( ) return end
		if typeEx(self.datatypes[typeEx(defaultvalue)]) == "nil" then Error("Zones config failed! Tried to add invalid defaultvalue type (" .. typeEx(defaultvalue) .. ") to config metadata\n") debug.Trace( ) return end
		self.configmetadata[zonemodule] = self.configmetadata[zonemodule] or {}
		local data = {
			optionname = optionname, 
			nicename = nicename, 
			details = details,
			zonemodule = zonemodule, 
			requires = requires, 
			defaultvalue = defaultvalue,
			allowedOnClient = allowedOnClient,
		}
		for k, v in pairs(self.configmetadata[zonemodule]) do
			if v.optionname == optionname then
				self.configmetadata[zonemodule][k] = data
				return
			end
		end
		table.insert(self.configmetadata[zonemodule], data)
	end
	
	if SERVER then
		/*
			Handle SetConfig from clients
		*/
		local function receiveSetConfigCommand(len, ply)
			local zonemodule, optionname, value = net.ReadString(), net.ReadString(), net.ReadType(net.ReadUInt( 8 ))
			if DelMods.zones.config_cust_functions.zone_canedit(ply) then // Check if the bugger is allowed to change settings
				if DelMods.zones:SetConfig(zonemodule, optionname, value) then
					local meta = DelMods.zones:GetConfigMeta(zonemodule, optionname)
					if meta then
						if (meta.allowedOnClient or DelMods.zones.config_cust_functions.zone_canedit(ply)) and not tonumber(meta.allowedOnClient) ~= -1 then
							net.Start("zone.configoption")
								net.WriteString(meta.zonemodule)
								net.WriteString(meta.optionname)
								net.WriteType(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname))
							net.Send(ply)
						end
					else
						ErrorNoHalt("Zones config error. Tried to get an unknown config.\n")
					end
				end
			end
		end
		net.Receive("zone.setconfigoption", receiveSetConfigCommand)
		/*
			Load zone settings from file
		*/
		function DelMods.zones:LoadConfig()
			loaded_data = util.JSONToTable(file.Read("zonesconfig.txt", "DATA") or "") or {}
			for zonemodule, moduleoptions in pairs(loaded_data) do
				for option, value in pairs(moduleoptions) do
					DelMods.zones:SetConfig(zonemodule, option, value)
				end
			end
		end
		
		/*
			Send updated config options to connecting player
		*/
		hook.Add("PlayerInitialSpawn", "zone.getsharedconfigoptions", function(ply)
			local metatable, values = {}, {}
			for zonemodulekey, zonemodule in pairs(DelMods.zones.configmetadata) do
				for _, meta in pairs(zonemodule) do
					if meta.allowedOnClient and tonumber(meta.allowedOnClient) ~= 1 then
						metatable[zonemodulekey] = metatable[zonemodulekey] or {}
						table.insert(metatable[zonemodulekey], meta)
						
						values[zonemodulekey] = values[zonemodulekey] or {}
						values[zonemodulekey][meta.optionname] = DelMods.zones:GetConfig(zonemodulekey, meta.optionname)
					end
				end
			end
			net.Start("zone.configsettings")
				net.WriteTable(metatable)
				net.WriteTable(values)
			net.Send(ply)
		end)
		
		/*
			Save zone settings to file
		*/
		function DelMods.zones:SaveConfig()
			file.Write("zonesconfig.txt", util.TableToJSON(DelMods.zones.config))
		end

		util.AddNetworkString("zone.configoption") // Pools this string
		util.AddNetworkString("zone.setconfigoption") // Pools this string
		util.AddNetworkString("zone.configsettings") // Pools this string
		
		/*
			Fetch a single config option to client
		*/
		function DelMods.zones.FetchConfigOption(ply, cmd, args)
			if args[1] and args[2] then
				local meta = DelMods.zones:GetConfigMeta(tostring(args[1]), tostring(args[2]))
				if meta then
					if (meta.allowedOnClient or DelMods.zones.config_cust_functions.zone_canedit(ply)) and not tonumber(meta.allowedOnClient) ~= -1 then
						net.Start("zone.configoption")
							net.WriteString(meta.zonemodule)
							net.WriteString(meta.optionname)
							net.WriteType(DelMods.zones:GetConfig(meta.zonemodule, meta.optionname))
						net.Send(ply)
					end
				else
					ErrorNoHalt("Zones config error. Tried to get an unknown config.\n")
				end
			end
		end
		concommand.Add("_zones_get_config", DelMods.zones.FetchConfigOption)
		
		/*
			Fetch all config options for client (to build config panel, etc)
		*/
		function DelMods.zones.FetchConfigOptions(ply)
			if DelMods.zones.config_cust_functions.zone_canedit(ply) then // Possibly sensitive info. Only send to authorized peeps
				local config = table.Copy(DelMods.zones.config) // Filter out config options that should never ever be sent to clients (like MySQL info)
				for zonemodulekey, zonemodule in pairs(config) do
					for optionname, option in pairs(zonemodule) do
						local meta = DelMods.zones:GetConfigMeta(zonemodulekey, optionname)
						if meta.allowedOnClient == -1 and config[zonemodule] and config[zonemodule][optionname] then
							config[zonemodule][optionname] = nil
						end
					end
				end
				net.Start("zone.configsettings")
					net.WriteTable(DelMods.zones.configmetadata)
					net.WriteTable(config)
				net.Send(ply)
			end
		end
		concommand.Add("_zones_get_configsettings", DelMods.zones.FetchConfigOptions)
	elseif CLIENT then
		/*
			Read and set incoming config option
		*/
		net.Receive("zone.configoption", function()
			local zonemodule = net.ReadString()
			local optionname = net.ReadString()
			LocalPlayer()["zonesConfigOptionLoading" .. tostring(option) .. tostring(zonemodule)] = nil
			DelMods.zones.config[zonemodule] = DelMods.zones.config[zonemodule] or {}
			DelMods.zones.config[zonemodule][optionname] = net.ReadType(net.ReadUInt( 8 ))
		end)
		/*
			Read and set incoming config settings (all of them)
		*/
		net.Receive("zone.configsettings", function()
			DelMods.zones.configmetadata = net.ReadTable()
			DelMods.zones.config = net.ReadTable()
			LocalPlayer().zonesConfigLoading = nil
			hook.Call("zone.config.loaded")
		end)
	end