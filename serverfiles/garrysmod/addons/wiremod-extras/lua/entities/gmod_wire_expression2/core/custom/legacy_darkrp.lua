E2Lib.RegisterExtension("legacy_darkrp", true,
	"Restores archived DarkRP-oriented Expression2 helper functions.")

local printerClasses = {
	["money_printer"] = true,
	["amethyst_money_printer"] = true,
	["emerald_money_printer"] = true,
	["ruby_money_printer"] = true,
	["sapphire_money_printer"] = true,
	["vrondakis_printer"] = true,
	["normal_money_printer"] = true,
	["gold_money_printer"] = true,
	["nuclear_money_printer"] = true,
}

local function isShipmentEntity(ent)
	if not IsValid(ent) then return false end

	if ent.IsSpawnedShipment or ent:GetClass() == "spawned_shipment" then
		return true
	end

	if not isfunction(ent.Getcontents) then return false end
	if not CustomShipments then return false end

	local contents = ent:Getcontents()
	return contents ~= nil and contents ~= "" and CustomShipments[contents] ~= nil
end

local function getPrintedAmount(ent)
	if not IsValid(ent) then return 0 end

	local className = ent:GetClass()
	if not printerClasses[className] and not ent.IsMoneyPrinter then
		return 0
	end

	if ent.GetNWInt then
		local legacyPrinted = ent:GetNWInt("PrintA", -1)
		if legacyPrinted >= 0 then
			return legacyPrinted
		end
	end

	if isnumber(ent.MoneyCount) and ent.MoneyCount > 0 then
		return ent.MoneyCount
	end

	if GAMEMODE and GAMEMODE.Config then
		local defaultAmount = GAMEMODE.Config.mprintamount or 0
		if defaultAmount > 0 then
			return defaultAmount
		end
	end

	return 250
end

__e2setcost(5)

e2function number entity:isShipmentName()
	return isShipmentEntity(this) and 1 or 0
end

e2function number entity:getPrinted()
	return getPrintedAmount(this)
end