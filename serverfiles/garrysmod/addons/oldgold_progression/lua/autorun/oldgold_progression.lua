if SERVER then
	AddCSLuaFile()
end

OldGoldProgression = OldGoldProgression or {}

local addon = OldGoldProgression

addon.Config = addon.Config or {
	startLevel = 1,
	startXP = 0,
	maxLevel = 99,
	npcKillXP = 25,
	underdogKillXPScale = 100,
	underdogKillCashReward = 1000,
	victimDeathCashPenalty = 1000,
	hudEnabled = true,
}

local function getPlayerIdentifier(ply)
	return MySQLite.SQLStr(ply:UniqueID())
end

function addon.GetRequiredXP(level)
	level = math.max(tonumber(level) or addon.Config.startLevel, addon.Config.startLevel)

	return 10 + (level * (level + 1) * 90)
end

local function getPlayerLevel(ply)
	if not IsValid(ply) or not ply.getDarkRPVar then
		return addon.Config.startLevel
	end

	return tonumber(ply:getDarkRPVar("level")) or addon.Config.startLevel
end

local function getPlayerXP(ply)
	if not IsValid(ply) or not ply.getDarkRPVar then
		return addon.Config.startXP
	end

	return tonumber(ply:getDarkRPVar("xp")) or addon.Config.startXP
end

local function setPlayerLabel(entry)
	if not istable(entry) or not entry.level then
		return
	end

	local suffix = " - Level " .. entry.level
	entry.label = entry.label or entry.name

	if string.EndsWith(entry.label, suffix) then
		return
	end

	entry.label = entry.label .. suffix
	entry.oldGoldTagged = true
	entry.buttonColor = entry.buttonColor or Color(0, 100, 0)
end

function addon.RefreshRequirementLabels()
	for _, entry in pairs(DarkRPEntities or {}) do
		setPlayerLabel(entry)
	end

	for _, entry in pairs(RPExtraTeams or {}) do
		setPlayerLabel(entry)
	end

	for _, entry in pairs(CustomVehicles or {}) do
		setPlayerLabel(entry)
	end

	for _, entry in pairs(CustomShipments or {}) do
		setPlayerLabel(entry)
	end

	if GAMEMODE and GAMEMODE.AmmoTypes then
		for _, entry in pairs(GAMEMODE.AmmoTypes) do
			setPlayerLabel(entry)
		end
	end
end

local meta = FindMetaTable("Player")

function meta:getLevel()
	return getPlayerLevel(self)
end

function meta:setLevel(level)
	level = math.Clamp(math.floor(tonumber(level) or addon.Config.startLevel), addon.Config.startLevel, addon.Config.maxLevel)

	return self:setDarkRPVar("level", level)
end

function meta:getXP()
	return getPlayerXP(self)
end

function meta:setXP(xp)
	xp = math.max(math.floor(tonumber(xp) or addon.Config.startXP), addon.Config.startXP)

	return self:setDarkRPVar("xp", xp)
end

function meta:getMaxXP()
	return addon.GetRequiredXP(self:getLevel())
end

function meta:hasLevel(level)
	return self:getLevel() >= (tonumber(level) or addon.Config.startLevel)
end

if SERVER then
	function addon.InitializeDatabase()
		if not MySQLite or not MySQLite.query then
			return
		end

		MySQLite.query([[CREATE TABLE IF NOT EXISTS darkrp_levels(
			uid VARCHAR(32) NOT NULL,
			level INT NOT NULL,
			xp INT NOT NULL,
			UNIQUE(uid)
		);]])
	end

	function addon.CreatePlayerData(ply)
		if not IsValid(ply) or not MySQLite or not MySQLite.query then
			return
		end

		MySQLite.query("REPLACE INTO darkrp_levels (uid, level, xp) VALUES (" .. getPlayerIdentifier(ply) .. ", '" .. addon.Config.startLevel .. "', '" .. addon.Config.startXP .. "')")
	end

	function addon.SavePlayerData(ply, level, xp)
		if not IsValid(ply) or not MySQLite or not MySQLite.query then
			return
		end

		MySQLite.query("REPLACE INTO darkrp_levels (uid, level, xp) VALUES (" .. getPlayerIdentifier(ply) .. ", " .. MySQLite.SQLStr(level) .. ", " .. MySQLite.SQLStr(xp) .. ")")
	end

	function addon.LoadPlayerData(ply)
		if not IsValid(ply) or not MySQLite or not MySQLite.query then
			return
		end

		MySQLite.query("SELECT level, xp FROM darkrp_levels WHERE uid = " .. getPlayerIdentifier(ply) .. ";", function(data)
			if not IsValid(ply) then
				return
			end

			local row = data and data[1]
			if not row then
				addon.CreatePlayerData(ply)
				ply:setLevel(addon.Config.startLevel)
				ply:setXP(addon.Config.startXP)
				return
			end

			ply:setLevel(row.level)
			ply:setXP(row.xp)
		end)
	end

	function addon.AddXP(ply, amount, reason)
		if not IsValid(ply) or not ply:IsPlayer() then
			return false
		end

		amount = math.floor(tonumber(amount) or 0)
		if amount <= 0 then
			return false
		end

		local currentLevel = ply:getLevel()
		if currentLevel >= addon.Config.maxLevel then
			return false
		end

		local currentXP = ply:getXP() + amount
		local leveledUp = false

		while currentLevel < addon.Config.maxLevel and currentXP >= addon.GetRequiredXP(currentLevel) do
			currentXP = currentXP - addon.GetRequiredXP(currentLevel)
			currentLevel = currentLevel + 1
			leveledUp = true
		end

		ply:setLevel(currentLevel)
		ply:setXP(currentXP)
		addon.SavePlayerData(ply, currentLevel, currentXP)

		if leveledUp then
			DarkRP.notifyAll(0, 4, ply:Nick() .. " reached level " .. currentLevel .. "!")
			ply:EmitSound("buttons/button15.wav", 75, 110)
			hook.Run("PlayerLevelChanged", ply, currentLevel, currentXP, amount, reason)
		else
			hook.Run("PlayerXPChanged", ply, currentXP, amount, reason)
		end

		if reason and reason ~= "" then
			DarkRP.notify(ply, 0, 4, "+" .. amount .. " XP - " .. reason)
		else
			DarkRP.notify(ply, 0, 4, "+" .. amount .. " XP")
		end

		return true
	end

	function meta:addXP(amount, reason)
		return addon.AddXP(self, amount, reason)
	end

	local function denyForLevel(ply, requiredLevel, message)
		requiredLevel = tonumber(requiredLevel)
		if not requiredLevel or ply:hasLevel(requiredLevel) then
			return
		end

		DarkRP.notify(ply, 1, 4, message or ("You need level " .. requiredLevel .. " for that."))

		return false, true
	end

	hook.Add("DarkRPDBInitialized", "OldGoldProgression_DB", addon.InitializeDatabase)

	hook.Add("PlayerInitialSpawn", "OldGoldProgression_LoadData", function(ply)
		timer.Simple(1, function()
			if IsValid(ply) then
				addon.LoadPlayerData(ply)
			end
		end)
	end)

	hook.Add("canBuyPistol", "OldGoldProgression_Pistols", function(ply, entity)
		return denyForLevel(ply, entity and entity.level, "You are not the right level to buy this.")
	end)

	hook.Add("canBuyAmmo", "OldGoldProgression_Ammo", function(ply, entity)
		return denyForLevel(ply, entity and entity.level, "You are not the right level to buy this.")
	end)

	hook.Add("canBuyShipment", "OldGoldProgression_Shipments", function(ply, entity)
		return denyForLevel(ply, entity and entity.level, "You are not the right level to buy this.")
	end)

	hook.Add("canBuyVehicle", "OldGoldProgression_Vehicles", function(ply, entity)
		return denyForLevel(ply, entity and entity.level, "You are not the right level to buy this.")
	end)

	hook.Add("canBuyCustomEntity", "OldGoldProgression_Entities", function(ply, entity)
		return denyForLevel(ply, entity and entity.level, "You are not the right level to buy this.")
	end)

	hook.Add("playerCanChangeTeam", "OldGoldProgression_Jobs", function(ply, teamIndex)
		local job = RPExtraTeams and RPExtraTeams[teamIndex]
		return denyForLevel(ply, job and job.level, "You are not the right level to become this.")
	end)

	hook.Add("OnNPCKilled", "OldGoldProgression_NPCKills", function(_, attacker)
		if not IsValid(attacker) or not attacker:IsPlayer() then
			return
		end

		attacker:addXP(addon.Config.npcKillXP, "NPC kill")
	end)

	hook.Add("PlayerDeath", "OldGoldProgression_PlayerKills", function(victim, _, attacker)
		if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then
			return
		end

		if attacker:getLevel() >= victim:getLevel() then
			return
		end

		local xpReward = addon.Config.underdogKillXPScale * victim:getLevel()
		attacker:addXP(xpReward, "Higher-level player kill")

		if addon.Config.underdogKillCashReward > 0 then
			attacker:addMoney(addon.Config.underdogKillCashReward)
		end

		if addon.Config.victimDeathCashPenalty > 0 and victim.canAfford and victim:canAfford(addon.Config.victimDeathCashPenalty) then
			victim:addMoney(-addon.Config.victimDeathCashPenalty)
		end
	end)

	hook.Add("InitPostEntity", "OldGoldProgression_Labels", function()
		timer.Simple(0, addon.RefreshRequirementLabels)
		timer.Simple(5, addon.RefreshRequirementLabels)
	end)
else
	function meta:addXP()
		return false
	end

	surface.CreateFont("OldGoldProgression_Title", {
		font = "Tahoma",
		size = 19,
		weight = 800,
		antialias = true,
	})

	surface.CreateFont("OldGoldProgression_Body", {
		font = "Tahoma",
		size = 15,
		weight = 600,
		antialias = true,
	})

	local panelColor = Color(12, 18, 27, 220)
	local accentColor = Color(41, 163, 255)
	local accentGlow = Color(100, 205, 255, 255)
	local trackColor = Color(255, 255, 255, 16)
	local textColor = Color(235, 242, 250)
	local subtextColor = Color(159, 180, 201)

	local function updateRequirementColors(entries)
		local level = getPlayerLevel(LocalPlayer())
		for _, entry in pairs(entries or {}) do
			if istable(entry) and entry.level then
				entry.buttonColor = level >= entry.level and Color(0, 110, 70) or Color(120, 35, 35)
			end
		end
	end

	hook.Add("InitPostEntity", "OldGoldProgression_ClientLabels", function()
		addon.RefreshRequirementLabels()
		updateRequirementColors(DarkRPEntities)
		updateRequirementColors(RPExtraTeams)
		updateRequirementColors(CustomVehicles)
		updateRequirementColors(CustomShipments)
		if GAMEMODE and GAMEMODE.AmmoTypes then
			updateRequirementColors(GAMEMODE.AmmoTypes)
		end
	end)

	hook.Add("PlayerLevelChanged", "OldGoldProgression_ClientRefresh", function()
		updateRequirementColors(DarkRPEntities)
		updateRequirementColors(RPExtraTeams)
		updateRequirementColors(CustomVehicles)
		updateRequirementColors(CustomShipments)
		if GAMEMODE and GAMEMODE.AmmoTypes then
			updateRequirementColors(GAMEMODE.AmmoTypes)
		end
	end)

	hook.Add("HUDPaint", "OldGoldProgression_HUD", function()
		if not addon.Config.hudEnabled or not IsValid(LocalPlayer()) then
			return
		end

		local level = getPlayerLevel(LocalPlayer())
		local xp = getPlayerXP(LocalPlayer())
		local maxXP = addon.GetRequiredXP(level)
		local progress = math.Clamp(maxXP > 0 and (xp / maxXP) or 0, 0, 1)

		local width = 260
		local height = 64
		local x = ScrW() - width - 24
		local y = 24

		draw.RoundedBox(12, x, y, width, height, panelColor)
		draw.SimpleText("Progression", "OldGoldProgression_Title", x + 14, y + 10, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Level " .. level, "OldGoldProgression_Body", x + 14, y + 33, subtextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(xp .. " / " .. maxXP .. " XP", "OldGoldProgression_Body", x + width - 14, y + 33, subtextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		draw.RoundedBox(6, x + 14, y + height - 16, width - 28, 8, trackColor)
		draw.RoundedBox(6, x + 14, y + height - 16, (width - 28) * progress, 8, accentColor)
		surface.SetDrawColor(accentGlow)
		surface.DrawOutlinedRect(x + 14, y + height - 16, width - 28, 8, 1)
	end)
end