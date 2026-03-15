/*---------------------------------------------------------------------------
/*---------------------------------------------------------------------------
DarkRP custom jobs
---------------------------------------------------------------------------

This file contains your custom jobs.
This file should also contain jobs from DarkRP that you edited.

Note: If you want to edit a default DarkRP job, first disable it in darkrp_config/disabled_defaults.lua
	Once you've done that, copy and paste the job to this file and edit it.

The default jobs can be found here:
<TODO: INSERT URL HERE>

For examples and explanation please visit this wiki page:
http://wiki.darkrp.com/index.php/DarkRP:CustomJobFields


Add jobs under the following line:
---------------------------------------------------------------------------*/
local function buildModelList(preferredModels, fallbackModels)
	local resolved = {}
	local seen = {}

	local function appendModels(models)
		for _, modelPath in ipairs(models or {}) do
			if not seen[modelPath] and util.IsValidModel(modelPath) then
				seen[modelPath] = true
				table.insert(resolved, modelPath)
			end
		end
	end

	appendModels(preferredModels)
	appendModels(fallbackModels)

	if #resolved == 0 then
		return (fallbackModels and fallbackModels[1]) or (preferredModels and preferredModels[1])
	end

	if #resolved == 1 then
		return resolved[1]
	end

	return resolved
end

TEAM_THEIF = DarkRP.createJob("Thief", {
level = 1,
color = Color(155, 155, 155, 255),
model = "models/player/arctic.mdl",
description = [[You are theif be a good one or you might be put down or arrested]],
weapons = {"weapon_fists","lock_pick","keypad_cracker", "m9k_knife"},
command = "theif",
max = 6,
salary = 45,
admin = 0,
vote = false,
hasLicense = false,
})

TEAM_STHEIF = DarkRP.createJob("Master Thief", {
level = 1,
color = Color(180, 0, 255, 255),
model = buildModelList({"models/player/slow/amberlyn/mkvsdcu/subzero/slow.mdl"}, {"models/player/phoenix.mdl"}),
description = [[You are theif be a good one or you might be put down or arrested]],
weapons = {"weapon_fists", "swep_pickpocket", "m9k_knife", "pro_lockpick_update","keypad_cracker_fast","m9k_tec9" },
command = "stheif",
max = 3,
salary = 45,
admin = 0,
vote = false,
hasLicense = false,
candemote = false,
customCheck = function(ply) return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin() end, 
    CustomCheckFailMsg = "This job is for Donators only!" 
})

TEAM_DEATH = DarkRP.createJob("Assasin of death", {
	level = 8,
	color = Color(25, 25, 25, 255),
	model = buildModelList({
		"models/player/lich_king_wow_maskless.mdl",
		"models/player/lich_king_wow_masked.mdl"
	}, {"models/player/phoenix.mdl"}),
	description = [[Accept hits from citizens and criminals, but stay away from police attention.
	Get paid to raid, rob, and eliminate targets for the underworld.]],
	weapons = {"frostmourne", "climb_swep2", "lock_pick", "weapon_fists", "keypad_cracker_fast"},
	command = "death",
	max = 1,
	salary = 55,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters",
	customCheck = function(ply) return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin() end,
	CustomCheckFailMsg = "This job is for Donators only!"
})

TEAM_NINJA = DarkRP.createJob("Ninja", {
	level = 22,
	color = Color(25, 25, 25, 255),
	model = buildModelList({"models/players/006/006_mi6.mdl"}, {"models/player/phoenix.mdl"}),
	description = [[An elite stealth criminal role with high mobility and raid potential.
	Stay unseen, strike fast, and do not get pinned down by police.]],
	weapons = {"frostmourne", "swep_pickpocket", "lock_pick", "weapon_fists", "keypad_cracker", "climb_swep2"},
	command = "ninja",
	max = 3,
	salary = 55,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters"
})

TEAM_SWAT = DarkRP.createJob("S.W.A.T Medic", {
level = 7,
police = true,
color = Color(0, 0, 255, 255),
model = "models/player/urban.mdl",
description = [[S.W.A.T Tactical Forces Unit.
Very dangerious but very sweet job.
Cleans the streets from high terror attacks.
]],
weapons = {"arrest_stick", "m9k_spas12","weapon_medkit", "unarrest_stick", "weapon_fists","lock_pick","keypad_cracker","m9k_deagle", "stunstick", "door_ram", "weaponchecker" },
command = "swat",
max = 2,
salary = 75,
admin = 0,
vote = true,
hasLicense = true,
candemote = false,
	help = {
		"Abuse of job result in this job geting banned for you.",
		"When you arrest someone they are auto transported to jail.",
		"They are auto let out of jail after some time",
		"Type /warrant [Nick|SteamID|Status ID] to set a search warrant for a player.",
		"Type /wanted [Nick|SteamID|Status ID] to alert everyone to a wanted suspect",
		"Type /unwanted [Nick|SteamID|Status ID] to clear the suspect",
	}
})

TEAM_SECURITY = DarkRP.createJob("Private Security Service", {
	level = 17,
	color = Color(0, 0, 255, 255),
	model = buildModelList({"models/players/oddjob/oddjob.mdl"}, {"models/player/barney.mdl"}),
	description = [[A hired protection role for players who need a guard on-site or during risky deals.
	You can protect property, escort clients, and operate on the criminal edge without becoming police.]],
	weapons = {"m9k_spas12", "weapon_medkit", "unarrest_stick", "weapon_fists", "lock_pick", "keypad_cracker", "m9k_deagle"},
	command = "security",
	max = 4,
	salary = 75,
	admin = 0,
	vote = false,
	hasLicense = true,
	candemote = false,
	category = "Services",
	help = {
		"Protect your client or their base, but do not roleplay as police.",
		"Stay away from police duties unless the situation becomes a standard self-defense encounter.",
	}
})



TEAM_SWATCHEIF = DarkRP.createJob("S.W.A.T", {
level = 1,
chief = true,
police = true,
color = Color(51, 102, 51, 255),
model = "models/player/riot.mdl",
description =  [[S.W.A.T Tactical Forces Unit.
An aggressive tactical police role for major threats, raids, and high-risk contraband enforcement.
Keep the streets under control without flattening normal roleplay.
Oh yeah, you're in charge!
]],
weapons = {"m9k_striker12", "m9k_m98b", "pro_lockpick_update",
"arrest_stick", "door_ram", "stunstick", "unarrest_stick",
"m9k_deagle", "m9k_m4a1", "m9k_honeybadger", "weaponchecker",
"keypad_cracker_fast", "weapon_fists", "m9k_nerve_gas" },
command = "swatcheif",
max = 3,
salary = 95,
admin = 0,
vote = false,
hasLicense = true,
candemote = false,
	help = {
		"Abuse of job result in this job geting banned for you.",
		"When you arrest someone they are auto transported to jail.",
		"They are auto let out of jail after some time",
		"Type /warrant [Nick|SteamID|Status ID] to set a search warrant for a player.",
		"Type /wanted [Nick|SteamID|Status ID] to alert everyone to a wanted suspect",
		"Type /unwanted [Nick|SteamID|Status ID] to clear the suspect",
	},
	customCheck = function(ply) return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin() end, 
    CustomCheckFailMsg = "This job is for Donators only!"
})


TEAM_SAGENT = DarkRP.createJob("Secret agent", {
level = 20,
color = Color(155, 155, 155, 255),
model = buildModelList({"models/player/bond.mdl", "models/player/barney.mdl", "models/player/Barney.mdl"}, {"models/player/Barney.mdl"}),
description = [[your are a secret agent. you can choose if you want to be the good or bad.
you are also friendly with the police. you are allowed to raid!]],
weapons = {"weapon_fists","lock_pick","keypad_cracker", "weapon_crossbow"},
command = "secretaent",
max = 4,
salary = 45,
admin = 0,
vote = false,
hasLicense = true,
})

TEAM_PET = DarkRP.createJob("Pet", {
level = 3,
color = Color(255, 0, 0, 0),
model = buildModelList({"models/AntLion.mdl"}, {"models/Lamarr.mdl"}),
description = [[You are pet be a good one or you might be put down or given away]],
weapons = {"weapon_fists"},
command = "pet",
max = 3,
salary = 15,
admin = 0,
vote = false,
hasLicense = false
})


TEAM_HOBO = DarkRP.createJob("King Hobo", {
	level = 3,
	color = Color(80, 45, 0, 255),
	model = buildModelList({"models/player/scavenger/scavenger.mdl"}, {"models/player/soldier_stripped.mdl"}),
	description = [[The lowest member of society. Everybody laughs at you.
		You have no home.
		Beg for your food and money
		Sing for everyone who passes to get money
		Make your own wooden home somewhere in a corner or outside someone else's door]],
	weapons = {"weapon_bugbait","lock_pick"},
	command = "hobo",
	max = 2,
	salary = 5,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	hobo = true
})

TEAM_CRIPS = DarkRP.createJob("Crips", {
	level = 1,
	color = Color(25, 90, 200, 255),
	model = buildModelList({
		"models/player/cripz/slow_1.mdl",
		"models/player/cripz/slow_2.mdl",
		"models/player/cripz/slow_3.mdl"
	}, {"models/player/slow/amberlyn/mkvsdcu/subzero/slow.mdl"}),
	description = [[A blue street gang member.
	You are part of the gangster side of the city and you are allowed to attack rival Bloodz on sight.
	Do not random kill outside gang warfare and normal criminal roleplay.]],
	weapons = {"weapon_fists", "m9k_knife"},
	command = "crips",
	max = 4,
	salary = 45,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters"
})

TEAM_CRIPSLEADER = DarkRP.createJob("Crips Leader", {
	level = 2,
	color = Color(15, 65, 170, 255),
	model = buildModelList({
		"models/player/cripz/slow_1.mdl",
		"models/player/cripz/slow_2.mdl",
		"models/player/cripz/slow_3.mdl"
	}, {"models/player/slow/amberlyn/mkvsdcu/subzero/slow.mdl"}),
	description = [[Leader of the Crips.
	You direct gang wars, lead robberies and can access extra weapon shipments for your crew.
	Police will treat your gang activity as hostile, so keep it inside criminal roleplay.]],
	weapons = {"weapon_fists", "m9k_knife", "m9k_deagle"},
	command = "cripsleader",
	max = 1,
	salary = 60,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters"
})

TEAM_BLOODZ = DarkRP.createJob("Bloodz", {
	level = 1,
	color = Color(180, 30, 30, 255),
	model = buildModelList({
		"models/player/bloodz/slow_1.mdl",
		"models/player/bloodz/slow_2.mdl",
		"models/player/bloodz/slow_3.mdl"
	}, {"models/player/slow/mario_gxy.mdl"}),
	description = [[A red street gang member.
	You are part of the gangster side of the city and you are allowed to attack rival Crips on sight.
	Do not random kill outside gang warfare and normal criminal roleplay.]],
	weapons = {"weapon_fists", "m9k_knife"},
	command = "bloodz",
	max = 4,
	salary = 45,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters"
})

TEAM_BLOODZLEADER = DarkRP.createJob("Bloodz Leader", {
	level = 2,
	color = Color(150, 20, 20, 255),
	model = buildModelList({
		"models/player/bloodz/slow_1.mdl",
		"models/player/bloodz/slow_2.mdl",
		"models/player/bloodz/slow_3.mdl"
	}, {"models/player/slow/mario_gxy.mdl"}),
	description = [[Leader of the Bloodz.
	You direct gang wars, lead robberies and can access extra weapon shipments for your crew.
	Police will treat your gang activity as hostile, so keep it inside criminal roleplay.]],
	weapons = {"weapon_fists", "m9k_knife", "m9k_deagle"},
	command = "bloodzleader",
	max = 1,
	salary = 60,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters"
})

TEAM_TERRORIST = DarkRP.createJob("Terrorist", {
	level = 3,
	color = Color(110, 90, 40, 255),
	model = "models/player/phoenix.mdl",
	description = [[A high-risk extremist role.
	You enter with access to a suicide bomb after a short arming delay.
	Once you commit to the role, you are locked into it for a while and cannot immediately come back after the run ends.]],
	weapons = {"weapon_fists", "m9k_knife", "lock_pick"},
	command = "terrorist",
	max = 2,
	salary = 35,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Gangsters",
	customCheck = function(ply)
		return CLIENT or not _G.RecoveredTerroristCanJoin or _G.RecoveredTerroristCanJoin(ply)
	end,
	CustomCheckFailMsg = function(ply)
		if not _G.RecoveredTerroristJoinFailMessage then
			return "You cannot become Terrorist right now."
		end

		return _G.RecoveredTerroristJoinFailMessage(ply)
	end,
})

TEAM_BDEALER = DarkRP.createJob("Black Market Dealer", {
level = 1,
color = Color(100, 100, 0, 255),
model = "models/player/odessa.mdl",
description = [[You are the black market salesman, go sell heavy weapons to other criminals.
Police and government are expected to treat you as openly hostile contraband support.]],
weapons = {"weapon_fists","lock_pick","keypad_cracker","m9k_deagle" },
command = "bdealer",
max = 2,
salary = 45,
admin = 0,
vote = false,
hasLicense = false,
candemote = false,
mayorCanSetSalary = false,
customCheck = function(ply) return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin() end, 
CustomCheckFailMsg = "This job is for Donators only!" 
})

TEAM_ARMS = DarkRP.createJob("Superior Arms Dealer", {
	level = 5,
	color = Color(255, 90, 0, 255),
	model = "models/player/Eli.mdl",
	description = [[A Arms Dealer is the only person who can sell Heavy guns to other people.
		Make sure you aren't caught selling illegal firearms to the public! You might get arrested!]],
	weapons = {"weapon_fists"},
	command = "armsdealer",
	max = 2,
	salary = 55,
	admin = 0,
	vote = false,
	hasLicense = false
})

TEAM_FIX = DarkRP.createJob("Mechanic", {
	level = 5,
	color = Color(255, 90, 0, 255),
	model = buildModelList({"models/player/magnusson.mdl"}, {"models/player/eli.mdl"}),
	description = [[Go around town and repair vehicles for money.]],
	weapons = {"weapon_fists", "weapon_scarrepair"},
	command = "mechanic",
	max = 2,
	salary = 50,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Services"
})

TEAM_DRUGZ = DarkRP.createJob("Drug Dealer", {
	level = 8,
	color = Color(255, 150, 150, 255),
	model = buildModelList({"models/player/p2_chell.mdl", "models/player/slow/mario_gxy.mdl"}, {"models/player/Group01/male_09.mdl"}),
	description = [[Sell drugs and keep clear of police attention.
	Do not treat this role like open combat; it is a contraband economy job first.]],
	weapons = {"m9k_luger", "lock_pick", "weapon_fists"},
	command = "drugdealer",
	max = 2,
	salary = 45,
	admin = 0,
	vote = false,
	hasLicense = false,
customCheck = function(ply) return CLIENT or ply:GetNWString("usergroup") == "donator" or ply:IsAdmin() end, 
CustomCheckFailMsg = "This job is for Donators only!" 
})

TEAM_BANK = DarkRP.createJob("Banker", {
	level = 10,
	color = Color(200, 175, 155, 255),
	model = buildModelList({"models/players/valentin/valentin.mdl"}, {"models/player/Hostage/hostage_04.mdl"}),
	description = [[You operate the bank and provide a social hub for storage and money-themed roleplay.]],
	weapons = {"weapon_fists"},
	command = "bank",
	max = 2,
	salary = 45,
	admin = 0,
	vote = true,
	hasLicense = false,
	category = "Services"
})

TEAM_ADMINONDUTY = DarkRP.createJob("Admin on Duty", {
level = 1,
color = Color(255, 0, 0, 255),
model = buildModelList({"models/player/slow/luigi_gxy.mdl"}, {"models/player/combine_super_soldier.mdl"}),
description = [[[You are admin on duty take care of players and be
an admin NO ABUSING!]],
weapons = {"weapon_fists", "unarrest_stick", "door_ram", "keypad_cracker_admin"},
command = "adminonduty",
max = 2,
salary = 0,
admin = 1,
modelScale = 0.3,
vote = false,
hasLicense = false
})

TEAM_SADMINONDUTY = DarkRP.createJob("SuperAdmin on Duty", {
level = 1,
color = Color(255, 191, 0, 255),
model = buildModelList({"models/player/slow/mario_gxy.mdl"}, {"models/player/slow/luigi_gxy.mdl", "models/player/kleiner.mdl"}),
description = [[[You are Super admin on duty take care of players and make sure that no one abuses!]],
weapons = {"weapon_fists", "keypad_cracker_admin"},
command = "sadminonduty",
max = 2,
salary = 1500,
admin = 2,
modelScale = 0.3,
vote = false,
hasLicense = true
})

TEAM_CASINOMANAGER = DarkRP.createJob("Casino Manager", {
	color = Color(255, 255, 0, 255),
	model = "models/player/leet.mdl",
	description = [[You run the casino and keep it under control for the city.]],
	weapons = {},
	command = "casinomanager",
	max = 2,
	salary = 200,
	admin = 0,
	vote = false,
	hasLicense = true,
	candemote = false,
	category = "Services"
})

TEAM_CINEMADIRECTOR = DarkRP.createJob("Cinema Director", {
	color = Color(100, 255, 0, 255),
	model = "models/player/barney.mdl",
	description = [[You run the cinema and build a place where players can watch media.]],
	weapons = {},
	command = "cinemadirector",
	max = 1,
	salary = 300,
	admin = 0,
	vote = true,
	hasLicense = false,
	candemote = false,
	category = "Services"
})

TEAM_BUSDRIVER = DarkRP.createJob("Bus Driver", {
	color = Color(100, 100, 150, 255),
	model = "models/player/eli.mdl",
	description = [[You transport players around the city.]],
	weapons = {},
	command = "busdriver",
	max = 2,
	salary = 500,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Services"
})

/*---------------------------------------------------------------------------
Define which team joining players spawn into and what team you change to if demoted
---------------------------------------------------------------------------*/
GAMEMODE.DefaultTeam = TEAM_CITIZEN


/*---------------------------------------------------------------------------
Define which teams belong to civil protection
Civil protection can set warrants, make people wanted and do some other police related things
---------------------------------------------------------------------------*/
GAMEMODE.CivilProtection = {
	[TEAM_POLICE] = true,
	[TEAM_CHIEF] = true,
	[TEAM_MAYOR] = true,
	[TEAM_SWAT] = true,
	[TEAM_SWATCHEIF] = true,
}

DarkRP.createGroupChat(TEAM_MOB, TEAM_GANG, TEAM_CRIPS, TEAM_CRIPSLEADER, TEAM_BLOODZ, TEAM_BLOODZLEADER)

/*---------------------------------------------------------------------------
Jobs that are hitmen (enables the hitman menu)
---------------------------------------------------------------------------*/
DarkRP.addHitmanTeam(TEAM_DEATH)
