# Dependency Audit

Date: 2026-03-14

## Current finding

The imported DarkRP jobs and shipments reference several legacy addon families that are not currently visible under `serverfiles\garrysmod\addons`.

## Referenced by imported content

Job and shipment references currently include:

- `m9k_*` weapon classes such as `m9k_deagle`, `m9k_m4a1`, `m9k_spas12`, `m9k_knife`
- `lock_pick`
- `pro_lockpick_update`
- `keypad_cracker`
- `keypad_cracker_fast`
- `keypad_cracker_admin`
- `weaponchecker`
- `weapon_medkit`
- `door_ram`
- `arrest_stick`
- `unarrest_stick`

## What appears present already

DarkRP itself still exposes backward-compatible registration functions for old custom content:

- `AddExtraTeam = DarkRP.createJob`
- `AddCustomShipment = DarkRP.createShipment`
- `AddCustomVehicle = DarkRP.createVehicle`
- `AddEntity = DarkRP.createEntity`

This means the main compatibility risk is not the registration API. The risk is missing or outdated addon content behind the weapon and tool class names.

## Newly staged from the old drive

The following legacy dependency addons were copied into the live server addon tree:

- `serverfiles\garrysmod\addons\m9k small arms`
- `serverfiles\garrysmod\addons\freakys_m9k_darkrp_weapon_pack_177539840`
- `serverfiles\garrysmod\addons\Keypad`
- `serverfiles\garrysmod\addons\lockpick things`
- `serverfiles\garrysmod\addons\keypad_cracker_fast`

Confirmed recovered class coverage now includes:

- `keypad_cracker_admin` from `serverfiles\garrysmod\addons\Keypad\lua\weapons\keypad_cracker_admin.lua`
- `m9k_spas12` from the staged Freaky pack materials and weapon addon content
- `m9k_honeybadger` from the staged M9K small arms addon content

`weapon_medkit` was already present under `serverfiles\garrysmod\lua\weapons\weapon_medkit.lua`.

## Recommended next step

1. Boot the server once the workshop install finishes and capture startup errors.
2. Confirm whether the staged legacy addons actually mount cleanly and expose the expected weapon classes at runtime.
3. If classes are still missing, either install maintained replacements or prune the affected jobs and shipments.