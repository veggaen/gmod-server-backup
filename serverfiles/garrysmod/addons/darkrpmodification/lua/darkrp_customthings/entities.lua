/*---------------------------------------------------------------------------
/*---------------------------------------------------------------------------
DarkRP custom entities
---------------------------------------------------------------------------

This file contains your custom entities.
This file should also contain entities from DarkRP that you edited.

Note: If you want to edit a default DarkRP entity, first disable it in darkrp_config/disabled_defaults.lua
	Once you've done that, copy and paste the entity to this file and edit it.

The default entities can be found here:
<TODO: INSERT URL HERE>

Add entities under the following line:
---------------------------------------------------------------------------*/

DarkRP.createEntity("Bronze Printer", {
	ent = "bronze_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 1,
	price = 1000,
	max = 2,
	cmd = "buybronzeprinter",
	category = "Printers"
})

DarkRP.createEntity("Donator Printer", {
	ent = "donator_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 3,
	price = 1000,
	max = 2,
	cmd = "buydonatorprinter",
	category = "Printers",
	customCheck = function(ply)
		return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin()
	end,
	CustomCheckFailMsg = "This Printer is for Donators only!"
})

DarkRP.createEntity("Silver Printer", {
	ent = "silver_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 7,
	price = 3000,
	max = 2,
	cmd = "buysilverprinter",
	category = "Printers"
})

DarkRP.createEntity("Gold Printer", {
	ent = "gold_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 12,
	price = 8000,
	max = 1,
	cmd = "buygoldprinter",
	category = "Printers"
})

DarkRP.createEntity("Emerald Printer", {
	ent = "emerald_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 18,
	price = 12500,
	max = 1,
	cmd = "buyemeraldprinter",
	category = "Printers"
})

DarkRP.createEntity("Ruby Printer", {
	ent = "ruby_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 28,
	price = 25000,
	max = 1,
	cmd = "buyrubyprinter",
	category = "Printers"
})

DarkRP.createEntity("Diamond Printer", {
	ent = "diamond_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 40,
	price = 30000,
	max = 1,
	cmd = "buydiamondprinter",
	category = "Printers"
})

DarkRP.createEntity("Unobtainium Printer", {
	ent = "unobtainium_money_printer",
	model = "models/props_c17/consolebox01a.mdl",
	level = 60,
	price = 35000,
	max = 1,
	cmd = "buyunobprinter",
	category = "Printers"
})

DarkRP.createEntity("Ammo Machine", {
	ent = "ammo_machine_nxp",
	model = "models/props_lab/reciever_cart.mdl",
	price = 5000,
	max = 2,
	cmd = "buyammomachine",
	category = "Utilities",
	customCheck = function(ply)
		return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin()
	end,
	CustomCheckFailMsg = "This entity is for Donators only!"
})

DarkRP.createEntity("SMG Extra", {
	ent = "smg_extra",
	model = "models/props_lab/reciever01c.mdl",
	price = 1250,
	max = 2,
	cmd = "buysmgextra",
	category = "Utilities",
	customCheck = function(ply)
		return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin()
	end,
	CustomCheckFailMsg = "This entity is for Donators only!"
})

DarkRP.createEntity("Piano", {
	ent = "gmt_instrument_piano",
	model = "models/fishy/furniture/piano.mdl",
	price = 1000,
	max = 1,
	cmd = "buypiano",
	category = "Utilities",
	allowed = {TEAM_BDEALER, TEAM_SAGENT, TEAM_STHEIF, TEAM_ARMS, TEAM_THEIF, TEAM_DRUGZ, TEAM_CITIZEN, TEAM_GANG, TEAM_MOB, TEAM_CRIPS, TEAM_CRIPSLEADER, TEAM_BLOODZ, TEAM_BLOODZLEADER}
})

DarkRP.createEntity("TV", {
	ent = "wyozi_screen_tv",
	model = "models/props/cs_office/tv_plasma.mdl",
	price = 1000,
	level = 5,
	max = 1,
	cmd = "buyatv",
	category = "Utilities"
})

DarkRP.createEntity("Money Detector", {
	ent = "gmod_wire_moneydetector",
	model = "models/jaanus/wiretool/wiretool_siren.mdl",
	price = 2500,
	max = 1,
	cmd = "buymoneydetector",
	category = "Utilities"
})

DarkRP.createEntity("Pirate Box", {
	ent = "pirate_box",
	model = "models/props_c17/oildrum001.mdl",
	price = 4000,
	level = 8,
	max = 1,
	cmd = "buypiratebox",
	category = "Utilities"
})

DarkRP.createEntity("Printer Yield Upgrade", {
	ent = "printer_amount",
	model = "models/props_lab/reciever01b.mdl",
	price = 1500,
	max = 2,
	cmd = "buyprinteramount",
	category = "Printer Upgrades"
})

DarkRP.createEntity("Printer Armor Upgrade", {
	ent = "printer_armor",
	model = "models/Items/car_battery01.mdl",
	price = 1400,
	max = 2,
	cmd = "buyprinterarmor",
	category = "Printer Upgrades"
})

DarkRP.createEntity("Printer Cooler Upgrade", {
	ent = "printer_cooler",
	model = "models/props_c17/FurnitureBoiler001a.mdl",
	price = 1200,
	max = 2,
	cmd = "buyprintercooler",
	category = "Printer Upgrades"
})

DarkRP.createEntity("Printer Silencer Upgrade", {
	ent = "printer_silencer",
	model = "models/props_lab/tpswitch.mdl",
	price = 1000,
	max = 2,
	cmd = "buyprintersilencer",
	category = "Printer Upgrades"
})

DarkRP.createEntity("Printer Timer Upgrade", {
	ent = "printer_timer",
	model = "models/props_lab/huladoll.mdl",
	price = 1750,
	max = 2,
	cmd = "buyprintertimer",
	category = "Printer Upgrades"
})


