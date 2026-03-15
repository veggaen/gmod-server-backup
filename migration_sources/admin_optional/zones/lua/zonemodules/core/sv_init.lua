	local function zonesLoadDatabase()
		-- Load config
		DelMods.zones:LoadConfig()
		--[[
			Set up database type
		]]
		if DelMods.zonesdbloaded then return end
		if DelMods.zones:GetConfig("mysql", "mysql_enable") and DelMods.zones:GetConfig("mysql", "mysql_module") == "gmsv_mysqloo" then -- MySQL
			require( "mysqloo" )
			local queue = {}
			local connected = false
			local db = mysqloo.connect( 
				DelMods.zones:GetConfig("mysql", "mysql_host"), 
				DelMods.zones:GetConfig("mysql", "mysql_username"), 
				DelMods.zones:GetConfig("mysql", "mysql_password"), 
				DelMods.zones:GetConfig("mysql", "mysql_database"), 
				DelMods.zones:GetConfig("mysql", "mysql_port") 
			)
			function db:onConnected()
				connected = true
				for k, v in pairs( queue ) do
					DelMods.Query( v[ 1 ], v[ 2 ] )
				end
				queue = {}
			end
			 
			db:connect()

			function DelMods.Query( SQL, callback )
				if not connected then
					table.insert( queue, { SQL, callback } )
					db:connect()
					return
				end
				local q = db:query( SQL )
				function q:onSuccess( data )
					if type(callback) == "function" then callback( data ) end
				end

				function q:onError( err )
					if db:status() == mysqloo.DATABASE_NOT_CONNECTED then
						table.insert( queue, { SQL, callback } )
						db:connect()
						return
					end
				end
				q:start()
			end
		else -- SQLite
			function DelMods.Query( SQL, callback )
				local query = sql.Query( SQL )
				if type(callback) == "function" then callback(query) end
			end
		end
		
		--[[
			Actually use the database.
		]]
		DelMods.Query("CREATE TABLE IF NOT EXISTS zones(id INTEGER NOT NULL, map char(30) NOT NULL, length NUMERIC NOT NULL, x NUMERIC NOT NULL, y NUMERIC NOT NULL, z NUMERIC NOT NULL, type INTEGER NOT NULL, name char(150) NOT NULL, subname char(150) NOT NULL, PRIMARY KEY(id));")
		local map = string.lower(game.GetMap())
		DelMods.Query("SELECT * FROM zones WHERE map = " .. sql.SQLStr(map) .. ";", function(query)
			if query and type(query) == "table" and #query >= 1 then
				for k, v in pairs(query) do
					local zone = ents.Create("zones")
					zone:SetPos(Vector(tonumber(v["x"]), tonumber(v["y"]), tonumber(v["z"])))
					zone:Spawn()
					zone:SetZoneLength(v["length"] or 0)
					zone:SetZoneType(v["type"])
					zone:SetZoneTitle(v["name"] or "")
					zone:SetZoneSubTitle(v["subname"] or "")
					zone:SetDBID(tonumber(v["id"]))
				end
			end
		end)
		DelMods.zonesdbloaded = true
	end
	hook.Add("InitPostEntity", "zone.database.load", zonesLoadDatabase)