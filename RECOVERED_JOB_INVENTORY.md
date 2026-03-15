# Recovered Job Inventory

Date: 2026-03-14

## Main legacy job source already imported

- `F:\Windows.old.000\Users\vetle\Documents\darkrpmodification-master\lua\darkrp_customthings\jobs.lua`

This is the broadest recovered custom job file found on the old drive. It includes these jobs already staged into the live server:

- Thief
- Master Thief
- S.W.A.T Medic
- S.W.A.T
- Secret Agent
- Pet
- King Hobo
- Black Market Dealer
- Superior Arms Dealer
- Drug Dealer
- Admin on Duty
- SuperAdmin on Duty

## Additional legacy job variants found

- `F:\Windows.old.000\Users\vetle\Documents\darkrpmodification-master\jobs.lua`
- `F:\Windows.old.000\Users\vetle\Documents\fast dl\zyru2.gmod.eu_27080\addons\darkrpmodification-master\lua\darkrp_customthings\jobs.lua`
- `F:\Windows.old.000\Users\vetle\Documents\gmad\keypad\addons\darkrpmodification-master\lua\darkrp_customthings\jobs.lua`
- `F:\Windows.old.000\Users\vetle\Documents\gmod editing\addons\darkrpmodification-master\lua\darkrp_customthings\jobs.lua`
- `F:\Windows.old.000\Users\vetle\Documents\gmod editing\darkrpmodification-master\lua\darkrp_customthings\jobs.lua`

Most of these are partial or older copies. The `gmod editing` variants are clearly older and narrower than the imported version.

## Extra jobs recovered from edited DarkRP core files

Source families found:

- `F:\Windows.old.000\Users\vetle\Documents\gmod editing\DarkRP\gamemode\config\jobrelated.lua`
- `F:\Windows.old.000\Users\vetle\Documents\gmod editing\exp things\DarkRP\gamemode\config\jobrelated.lua`
- `F:\Windows.old.000\Users\vetle\Documents\gmad\New folder\DarkRP\gamemode\config\jobrelated.lua`
- `F:\Windows.old.000\Users\vetle\Documents\roxis stuff\darkrp\gamemode\shared.lua`

Recovered custom jobs from those sources:

- Casino Manager
- Cinema Director
- Bus Driver
- CSI: Crime Scene Investigation
- DJ
- Cinema Owner

## Imported now

The following recovered jobs were imported into the live server as safe standalone jobs in `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_customthings\recovered_jobs.lua`:

- Casino Manager
- Cinema Director
- Bus Driver

## Deferred for dependency review

- DJ
- Cinema Owner
Reason: these came from the Wyozi media addon and should be enabled together with the media entities and base addon.

- CSI: Crime Scene Investigation
Reason: the old version depends on legacy weapon classes that are not currently verified in the live server.

- Older duplicate Admin on Duty, SWAT, Black Market, and thief variants
Reason: broader or cleaner versions are already present in the main imported `jobs.lua`.