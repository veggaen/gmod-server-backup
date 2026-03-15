local registeredWorkshopIds = {}

local function sortIds(ids)
	table.sort(ids, function(left, right)
		return tonumber(left) < tonumber(right)
	end)
	return ids
end

local function loadWorkshopIdsFromMountedAddons()
	if not engine or not engine.GetAddons then return {} end

	local ids = {}
	local seen = {}

	for _, addon in ipairs(engine.GetAddons() or {}) do
		local workshopId = tostring(addon.wsid or addon.file or ""):match("(%d+)")
		if addon.mounted and workshopId and not seen[workshopId] then
			seen[workshopId] = true
			ids[#ids + 1] = workshopId
		end
	end

	return sortIds(ids)
end

local function loadWorkshopIdsFromConfig()
	local contents = nil
	local candidatePaths = {
		{ path = "cfg/srcds_addons.txt", realm = "MOD" },
		{ path = "cfg/srcds_addons.txt", realm = "GAME" },
		{ path = "/cfg/srcds_addons.txt", realm = "MOD" },
		{ path = "/cfg/srcds_addons.txt", realm = "GAME" },
	}

	for _, candidate in ipairs(candidatePaths) do
		contents = file.Read(candidate.path, candidate.realm)
		if contents and contents ~= "" then
			local ids = {}
			local seen = {}

			for workshopId in contents:gmatch('"(%d+)"%s*%{') do
				if not seen[workshopId] then
					seen[workshopId] = true
					ids[#ids + 1] = workshopId
				end
			end

			return sortIds(ids), string.format("%s:%s", candidate.realm, candidate.path)
		end
	end

	return {}, nil
end

local function loadWorkshopIds()
	local mountedIds = loadWorkshopIdsFromMountedAddons()
	if #mountedIds > 0 then
		return mountedIds, "engine.GetAddons"
	end

	local configIds, configSource = loadWorkshopIdsFromConfig()
	if #configIds > 0 then
		return configIds, configSource or "cfg/srcds_addons.txt"
	end

	return {}, nil
end

local function addWorkshopResources(reason)
	local ids, source = loadWorkshopIds()
	local added = 0
	local failed = 0
	local skipped = 0

	if #ids == 0 then
		print(string.format("[WorkshopSync] No workshop IDs available during %s.", reason or "startup"))
		return
	end

	for _, workshopId in ipairs(ids) do
		if registeredWorkshopIds[workshopId] then
			skipped = skipped + 1
		else
			local ok, err = pcall(resource.AddWorkshop, workshopId)
			if ok then
				registeredWorkshopIds[workshopId] = true
				added = added + 1
			else
				failed = failed + 1
				print(string.format("[WorkshopSync] Failed to add workshop %s: %s", workshopId, tostring(err)))
			end
		end
	end

	print(string.format("[WorkshopSync] %s: registered %d workshop addons, skipped %d already registered, %d failed (source: %s).", reason or "startup", added, skipped, failed, source or "none"))
end

hook.Add("Initialize", "ModernRP.WorkshopResourceSync.Initialize", function()
	addWorkshopResources("Initialize")
end)

hook.Add("InitPostEntity", "ModernRP.WorkshopResourceSync.InitPostEntity", function()
	addWorkshopResources("InitPostEntity")
end)

timer.Simple(10, function()
	addWorkshopResources("DelayedRetry")
end)