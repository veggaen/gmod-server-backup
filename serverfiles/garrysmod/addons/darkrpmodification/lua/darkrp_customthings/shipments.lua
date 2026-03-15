/*---------------------------------------------------------------------------
/*---------------------------------------------------------------------------
DarkRP custom shipments and guns
---------------------------------------------------------------------------

This file contains your custom shipments and guns.
This file should also contain shipments and guns from DarkRP that you edited.

Note: If you want to edit a default DarkRP shipment, first disable it in darkrp_config/disabled_defaults.lua
	Once you've done that, copy and paste the shipment to this file and edit it.

The default shipments and guns can be found here:
<TODO: INSERT URL HERE>

For examples and explanation please visit this wiki page:
http://wiki.darkrp.com/index.php/DarkRP:CustomShipmentFields


Add shipments and guns under the following line:
---------------------------------------------------------------------------*/

AddCustomShipment("Health Kit", {
	model = "models/Items/HealthKit.mdl",
	entity = "item_healthkit",
	price = 500,
	amount = 10,
	seperate = true,
	pricesep = 50,
	noship = false,
	allowed = {TEAM_MEDIC, TEAM_BDEALER}
})

AddCustomShipment("Armor", {
	model = "models/combine_vests/elitevest.mdl",
	entity = "heavy kevlar armor",
	price = 1000,
	amount = 10,
	seperate = true,
	pricesep = 200,
	noship = false,
	allowed = {TEAM_MEDIC, TEAM_BDEALER, TEAM_CHIEF, TEAM_POLICE}
})

AddCustomShipment("HK usp", {
	model = "models/weapons/w_pist_fokkususp.mdl",
	entity = "m9k_usp",
	price = 2150,
	amount = 10,
	seperate = true,
	pricesep = 380,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})


AddCustomShipment("Python", {
	model = "models/weapons/w_colt_python.mdl",
	entity = "m9k_coltpython",
	price = 2850,
	amount = 10,
	seperate = true,
	pricesep = 385,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Beretta M92", {
	model = "models/weapons/w_beretta_m92.mdl",
	entity = "m9k_m92beretta",
	price = 2550,
	amount = 10,
	seperate = true,
	pricesep = 350,
	noship = false,
	allowed = {TEAM_BDEALER, TEAM_GUN, TEAM_ARMS}
})

AddCustomShipment("Deagle", {
	model = "models/weapons/w_tcom_deagle.mdl",
	entity = "m9k_deagle",
	price = 2550,
	amount = 10,
	seperate = true,
	pricesep = 350,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER, TEAM_ARMS}
})

AddCustomShipment("Gang Leader Deagle", {
	model = "models/weapons/w_tcom_deagle.mdl",
	entity = "m9k_deagle",
	price = 3350,
	amount = 10,
	seperate = true,
	pricesep = 475,
	noship = false,
	allowed = {TEAM_CRIPSLEADER, TEAM_BLOODZLEADER}
})


AddCustomShipment("Glock 17", {
	model = "models/weapons/w_dmg_glock.mdl",
	entity = "m9k_glock",
	price = 2950,
	amount = 10,
	seperate = true,
	pricesep = 390,
	noship = false,
	allowed = {TEAM_ARMS, TEAM_BDEALER}
})

AddCustomShipment("P229", {
	model = "models/weapons/w_sig_229r.mdl",
	entity = "m9k_sig_p229r",
	price = 2150,
	amount = 10,
	seperate = true,
	pricesep = 345,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Colt 1911", {
	model = "models/weapons/s_dmgf_co1911.mdl",
	entity = "m9k_colt1911",
	price = 2000,
	amount = 10,
	seperate = true,
	pricesep = 375,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("M29 satan", {
	model = "models/weapons/w_m29_satan.mdl",
	entity = "m9k_m29satan",
	price = 2500,
	amount = 10,
	seperate = true,
	pricesep = 420,
	noship = false,
	allowed = {TEAM_BDEALER}
})

AddCustomShipment("Lunger", {
	model = "models/weapons/w_luger_p08.mdl",
	entity = "m9k_luger",
	price = 2000,
	amount = 10,
	seperate = true,
	pricesep = 375,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})


AddCustomShipment("HK 45C", {
	model = "models/weapons/w_hk45c.mdl",
	entity = "m9k_hk45",
	price = 2100,
	amount = 10,
	seperate = true,
	pricesep = 380,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Mp 7", {
	model = "models/weapons/w_mp7_silenced.mdl",
	entity = "m9k_mp7",
	price = 5000,
	amount = 10,
	seperate = false,
	pricesep = nil,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Vector", {
	model = "models/weapons/w_kriss_vector.mdl",
	entity = "m9k_vector",
	price = 6200,
	amount = 10,
	seperate = true,
	pricesep = 720,
	noship = false,
	allowed = {TEAM_ARMS, TEAM_BDEALER}
})

AddCustomShipment("Magpul", {
	model = "models/weapons/w_magpul_pdr.mdl",
	entity = "m9k_magpulpdr",
	price = 6000,
	amount = 10,
	seperate = true,
	pricesep = 700,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("tec9", {
	model = "models/weapons/w_intratec_tec9.mdl",
	entity = "m9k_tec9",
	price = 4500,
	amount = 10,
	seperate = true,
	pricesep = 550,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Gang Leader tec9", {
	model = "models/weapons/w_intratec_tec9.mdl",
	entity = "m9k_tec9",
	price = 5450,
	amount = 10,
	seperate = true,
	pricesep = 675,
	noship = false,
	allowed = {TEAM_CRIPSLEADER, TEAM_BLOODZLEADER}
})

AddCustomShipment("Uzi", {
	model = "models/weapons/w_uzi_imi.mdl",
	entity = "m9k_uzi",
	price = 4550,
	amount = 10,
	seperate = true,
	pricesep = 550,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("Gang Leader Uzi", {
	model = "models/weapons/w_uzi_imi.mdl",
	entity = "m9k_uzi",
	price = 5550,
	amount = 10,
	seperate = true,
	pricesep = 675,
	noship = false,
	allowed = {TEAM_CRIPSLEADER, TEAM_BLOODZLEADER}
})

AddCustomShipment("Hk Badger", {
	model = "models/weapons/w_aac_honeybadger.mdl",
	entity = "m9k_honeybadger",
	price = 6550,
	amount = 10,
	seperate = true,
	pricesep = 750,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER}
})

AddCustomShipment("M4A1", {
	model = "models/weapons/w_m4a1_iron.mdl",
	entity = "m9k_m4a1",
	price = 4350,
	amount = 10,
	seperate = true,
	pricesep = 530,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER, TEAM_ARMS}
})

AddCustomShipment("AK 47", {
	model = "models/weapons/w_ak47_m9k.mdl",
	entity = "m9k_ak47",
	price = 4350,
	amount = 10,
	seperate = true,
	pricesep = 450,
	noship = false,
	allowed = {TEAM_ARMS, TEAM_BDEALER}
})

AddCustomShipment("Barrett m98b", {
	model = "models/weapons/w_barrett_m98b.mdl",
	entity = "m9k_m98b",
	price = 9050,
	amount = 10,
	seperate = true,
	pricesep = 1000,
	noship = false,
	allowed = {TEAM_BDEALER}
})

AddCustomShipment("M3", {
	model = "models/weapons/w_benelli_m3.mdl",
	entity = "m9k_m3",
	price = 3750,
	amount = 10,
	seperate = true,
	pricesep = 450,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER, TEAM_ARMS}
})

AddCustomShipment("spas 12", {
	model = "models/weapons/w_spas_12.mdl",
	entity = "m9k_spas12",
	price = 3750,
	amount = 10,
	seperate = true,
	pricesep = 450,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER, TEAM_ARMS}
})


AddCustomShipment("P90", {
	model = "models/weapons/w_fn_p90.mdl",
	entity = "m9k_smgp90",
	price = 3950,
	amount = 10,
	seperate = true,
	pricesep = 435,
	noship = false,
	allowed = {TEAM_GUN, TEAM_BDEALER, TEAM_ARMS}
})

AddCustomShipment("FN scar", {
	model = "models/weapons/w_fn_scar_h.mdl",
	entity = "m9k_scar",
	price = 6150,
	amount = 10,
	seperate = true,
	pricesep = 700,
	noship = false,
	allowed = {TEAM_BDEALER, TEAM_ARMS}
})

AddCustomShipment("HK G36", {
	model = "models/weapons/w_hk_g36c.mdl",
	entity = "m9k_g36",
	price = 3750,
	amount = 10,
	seperate = true,
	pricesep = 475,
	noship = false,
	allowed = {TEAM_ARMS, TEAM_BDEALER}
})

AddCustomShipment("mp5", {
	model = "models/weapons/w_hk_mp5sd.mdl",
	entity = "m9k_mp5sd",
	price = 5550,
	amount = 10,
	seperate = true,
	pricesep = 650,
	noship = false,
	allowed = {TEAM_BDEALER, TEAM_ARMS}
})


AddCustomShipment("M24", {
	model = "models/weapons/w_snip_m24_6.mdl",
	entity = "m9k_m24",
	price = 8575,
	amount = 10,
	seperate = false,
	pricesep = nil,
	noship = false,
	allowed = {TEAM_BDEALER}
})



AddCustomShipment("MP9", {
	model = "models/weapons/w_brugger_thomet_mp9.mdl",
	entity = "m9k_mp9",
	price = 4550,
	amount = 10,
	seperate = true,
	pricesep = 550,
	noship = false,
	allowed = {TEAM_BDEALER}
})

AddCustomShipment("Tommy Gun", {
	model = "models/weapons/w_tommy_gun.mdl",
	entity = "m9k_thompson",
	price = 5250,
	amount = 10,
	seperate = false,
	pricesep = nil,
	noship = false,
	allowed = {TEAM_BDEALER}
})


AddCustomShipment("HK usc", {
	model = "models/weapons/w_hk_usc.mdl",
	entity = "m9k_usc",
	price = 5250,
	amount = 10,
	seperate = true,
	pricesep = 625,
	noship = false,
	allowed = {TEAM_BDEALER}
})

AddCustomShipment("HK sten", {
	model = "models/weapons/w_sten.mdl",
	entity = "m9k_sten",
	price = 4550,
	amount = 10,
	seperate = true,
	pricesep = 550,
	noship = false,
	allowed = {TEAM_BDEALER}
})

AddCustomShipment("Cross bow ammo", {
	model = "models/items/crossbowrounds.mdl",
	entity = "item_ammo_crossbow",
	price = 500,
	amount = 10,
	seperate = true,
	pricesep = 75,
	noship = false,
	allowed = {TEAM_SAGENT}
})

AddCustomShipment("Ammo", {
	model = "models/Items/BoxMRounds.mdl",
	entity = "item_ammo_smg1",
	price = 750,
	amount = 10,
	seperate = false,
	pricesep = nil,
	noship = false,
})

AddCustomShipment("mini gun", {
	model = "models/weapons/w_m134_minigun.mdl",
	entity = "m9k_minigun",
	price = 15000,
	amount = 10,
	seperate = true,
	pricesep = 1500,
	noship = false,
	allowed = {TEAM_BDEALER}
})
