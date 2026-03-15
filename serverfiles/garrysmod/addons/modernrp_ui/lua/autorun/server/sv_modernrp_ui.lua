-- ==========================================================================
-- ModernRP UI - Server Side (/played command)
-- ==========================================================================

util.AddNetworkString("MUI_ShowPlayed")
util.AddNetworkString("MUI_AdminPlayerAction")

local function notifyPlayer(ply, message, isError)
	if not IsValid(ply) then return end
	if DarkRP and DarkRP.notify then
		DarkRP.notify(ply, isError and 1 or 0, 4, message)
		return
	end
	ply:ChatPrint(message)
end

local function saveProgressData(target)
	if not IsValid(target) or not target.getLevel or not target.getXP then return end
	if not OldGoldProgression or not OldGoldProgression.SavePlayerData then return end
	OldGoldProgression.SavePlayerData(target, target:getLevel(), target:getXP())
end

local function setPlayerMoney(target, amount)
	amount = math.max(math.floor(tonumber(amount) or 0), 0)
	local currentMoney = tonumber(target.getDarkRPVar and target:getDarkRPVar("money")) or 0
	amount = hook.Call("playerWalletChanged", GAMEMODE, target, amount - currentMoney, currentMoney) or amount
	if DarkRP and DarkRP.storeMoney then
		DarkRP.storeMoney(target, amount)
	end
	if target.setDarkRPVar then
		target:setDarkRPVar("money", amount)
	end
	return amount
end

net.Receive("MUI_AdminPlayerAction", function(_, ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:IsAdmin() then return end

	local target = net.ReadEntity()
	local action = net.ReadString()
	local amount = math.floor(net.ReadInt(32) or 0)
	local reason = string.Trim(net.ReadString() or "")

	if not IsValid(target) or not target:IsPlayer() then
		notifyPlayer(ply, "Invalid target player.", true)
		return
	end

	if action == "set_level" then
		if not target.setLevel then
			notifyPlayer(ply, "Level API is not available on this server.", true)
			return
		end

		local maxLevel = OldGoldProgression and OldGoldProgression.Config and OldGoldProgression.Config.maxLevel or 99
		amount = math.Clamp(amount, 1, maxLevel)
		target:setLevel(amount)
		if target.getXP and target.getMaxXP and target.setXP then
			local maxXP = math.max(tonumber(target:getMaxXP()) or 1, 1)
			target:setXP(math.Clamp(tonumber(target:getXP()) or 0, 0, maxXP - 1))
		end
		saveProgressData(target)
		notifyPlayer(ply, "Set " .. target:Nick() .. " to level " .. amount .. ".")
		notifyPlayer(target, ply:Nick() .. " set your level to " .. amount .. ".")
		return
	end

	if action == "set_xp" then
		if not target.setXP then
			notifyPlayer(ply, "XP API is not available on this server.", true)
			return
		end

		local maxXP = target.getMaxXP and math.max(tonumber(target:getMaxXP()) or 1, 1) or math.huge
		amount = math.Clamp(amount, 0, maxXP - 1)
		target:setXP(amount)
		saveProgressData(target)
		notifyPlayer(ply, "Set " .. target:Nick() .. " to " .. amount .. " XP.")
		notifyPlayer(target, ply:Nick() .. " set your XP to " .. amount .. ".")
		return
	end

	if action == "add_xp" then
		if amount <= 0 then
			notifyPlayer(ply, "XP amount must be above 0.", true)
			return
		end
		if not target.addXP then
			notifyPlayer(ply, "XP API is not available on this server.", true)
			return
		end

		target:addXP(amount, reason ~= "" and reason or "Staff adjustment")
		notifyPlayer(ply, "Added " .. amount .. " XP to " .. target:Nick() .. ".")
		return
	end

	if action == "remove_xp" then
		if amount <= 0 then
			notifyPlayer(ply, "XP amount must be above 0.", true)
			return
		end
		if not target.getXP or not target.setXP then
			notifyPlayer(ply, "XP API is not available on this server.", true)
			return
		end

		local newXP = math.max((tonumber(target:getXP()) or 0) - amount, 0)
		target:setXP(newXP)
		saveProgressData(target)
		notifyPlayer(ply, "Removed " .. amount .. " XP from " .. target:Nick() .. ".")
		notifyPlayer(target, ply:Nick() .. " removed " .. amount .. " XP from you.")
		return
	end

	if action == "set_money" then
		local total = setPlayerMoney(target, amount)
		notifyPlayer(ply, "Set " .. target:Nick() .. " to " .. DarkRP.formatMoney(total) .. ".")
		notifyPlayer(target, ply:Nick() .. " set your money to " .. DarkRP.formatMoney(total) .. ".")
		return
	end

	if action == "add_money" then
		if not target.addMoney then
			notifyPlayer(ply, "Money API is not available on this server.", true)
			return
		end

		local currentMoney = tonumber(target.getDarkRPVar and target:getDarkRPVar("money")) or 0
		if currentMoney + amount < 0 then
			amount = -currentMoney
		end
		target:addMoney(amount)
		local label = amount >= 0 and "Added " or "Removed "
		notifyPlayer(ply, label .. DarkRP.formatMoney(math.abs(amount)) .. (amount >= 0 and " to " or " from ") .. target:Nick() .. ".")
		notifyPlayer(target, ply:Nick() .. (amount >= 0 and " adjusted your wallet by +" or " adjusted your wallet by -") .. DarkRP.formatMoney(math.abs(amount)) .. ".")
		return
	end

	if action == "give_money" then
		if amount <= 0 then
			notifyPlayer(ply, "Transfer amount must be above 0.", true)
			return
		end
		if not DarkRP or not DarkRP.payPlayer or not ply.canAfford or not ply:canAfford(amount) then
			notifyPlayer(ply, "You cannot afford that transfer.", true)
			return
		end

		DarkRP.payPlayer(ply, target, amount)
		notifyPlayer(ply, "Transferred " .. DarkRP.formatMoney(amount) .. " to " .. target:Nick() .. ".")
		notifyPlayer(target, ply:Nick() .. " transferred " .. DarkRP.formatMoney(amount) .. " to you.")
		return
	end

	notifyPlayer(ply, "Unknown admin action.", true)
end)

hook.Add("PlayerSay", "MUI_PlayedCommand", function(ply, text)
	local cmd = string.lower(string.Trim(text))
	if cmd == "/played" or cmd == "!played" then
		net.Start("MUI_ShowPlayed")
		net.Send(ply)
		return ""
	end
end)
