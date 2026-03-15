- Added one-slot gang leaders for Crips and Bloodz, wired into gangster agenda/group chat/demote handling and bank robbery permissions.
- Added leader-only higher-priced pistol/SMG shipments so gang leaders can arm crews without flattening the broader dealer economy.
- Kept remembered Bloodz/Cripz/scavenger model paths as preferred options with safe fallbacks because the exact assets are not present in the current extracted server files.
- Restored a Terrorist job with a delayed suicide bomb unlock, a 10 minute commitment window before switching away, a 15 minute rejoin cooldown, and bank robbery permission like the old backup bank script indicated.
# Garry's Mod Migration Notes

Date: 2026-03-14

## Completed first-wave imports

- Imported legacy DarkRP customization files from `F:\Windows.old.000\Users\vetle\Documents\darkrpmodification-master\lua\darkrp_customthings` into `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_customthings`.
- Imported legacy DarkRP config files from `F:\Windows.old.000\Users\vetle\Documents\darkrpmodification-master\lua\darkrp_config` into `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_config`.
- Staged custom ULX commands from `F:\Users\v3gga\Documents\addons codewhire\custom-ulx-commands\CustomCommands` into `serverfiles\garrysmod\addons\custom-ulx-commands`.
- Backed up the original `darkrpmodification` template files to `serverfiles\garrysmod\migration_backups\2026-03-14_phase1` before overwriting them.
- Imported additional recovered safe jobs into `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_customthings\recovered_jobs.lua`.
- Staged legacy dependency addons for M9K, keypad cracking, and lockpicking into `serverfiles\garrysmod\addons`.
- Staged the legacy bank robbery addon into `serverfiles\garrysmod\addons\bankrob` and adapted its allowed/government team names to the current job setup.
- Preserved recovered custom E2 files and optional admin/media addons under `migration_sources` without auto-enabling them.
- Preserved additional `roxis stuff` E2 notes under `migration_sources\e2_custom`.
- Hardened DarkRP police role helpers so missing client job tables do not spam F1/chat command condition errors.
- Removed external telemetry code from `serverfiles\garrysmod\addons\bankrob\lua\autorun\bank_load.lua`.
- Disabled local `wire` and `wire-extras` filesystem addons by moving them to `serverfiles\garrysmod\migration_backups\2026-03-14_disabled_local_addons` so workshop Wiremod can load without local duplication.
- Disabled the legacy custom vehicle registrations in `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_customthings\vehicles.lua` after DarkRP crashed on unknown vehicle names like `Hummer`; left only stock Jeep/Airboat until the old custom vehicle base is recovered.
- Persisted the owner ULX assignment in `serverfiles\garrysmod\data\ulib\users.txt` after granting `STEAM_0:0:45125356` superadmin from the server console.
- Added local compatibility stubs at `serverfiles\garrysmod\lua\autorun\cssnag.lua` and `serverfiles\garrysmod\lua\weapons\weapons\shared.lua` to satisfy broken workshop include paths without changing addon behavior.
- Restored custom `Crips` and `Bloodz` gang jobs in `addons\darkrpmodification\lua\darkrp_customthings\jobs.lua` using verified `models/player/slow/...` workshop model paths from the old config, and wired them into the gangster agenda, gangster group chat, demote group, and bank robbery allowed-team list.
- Restored the archived DarkRP-oriented Expression2 helpers as `addons\wiremod-extras\lua\entities\gmod_wire_expression2\core\custom\legacy_darkrp.lua`, bringing back `entity:isShipmentName()` and `entity:getPrinted()` without patching Wiremod core files.
- Activated additional safe utility jobs directly in the live jobs file: `Casino Manager`, `Cinema Director`, and `Bus Driver`, and added matching F4 categories for `Gangsters`, `Services`, and `Printers`.
- Restored the gemstone printer ladder with live entity classes and F4 entries for `Amethyst Printer`, `Emerald Printer`, `Ruby Printer`, and `Sapphire Printer`.
- Added a new standalone addon at `serverfiles\garrysmod\addons\oldgold_progression` that restores the old level and XP backbone in a safer form: MySQLite persistence, level-gated jobs and entities, a simple progression HUD, and XP rewards for NPC kills plus underdog player kills.
- Wired the temporary gemstone printers into progression with explicit level requirements so they now act as a real ladder instead of flat placeholders.
- Rebuilt the recovered `Ammo Machine - by v3gga` as live DarkRP entities `ammo_machine_nxp` and `smg_extra`, keeping the all-ammo payout loop, touch-based SMG upgrade, and damage/overheat/explosion behavior while cleaning up the code structure.
- Restored another slice of the 2013 job roster into the live `jobs.lua`: `Assasin of death`, `Ninja`, `Private Security Service`, `Mechanic`, and `Banker`, and aligned several existing jobs back toward the old server loadouts and models, including `Master Thief`, `S.W.A.T Medic`, `S.W.A.T`, `Pet`, `Superior Arms Dealer`, `Drug Dealer`, `Admin on Duty`, and `SuperAdmin on Duty`.
- Restored more of the old server economy identity by setting `jailtimer = 175`, `runspeedcp = 260`, and bringing back more verified weapon shipments, including the old `mini gun` shipment for the Black Market Dealer.
- Rebuilt the printer foundation in `custom_moneyprinter` so tier overrides now actually work: printers store money internally, expose their tier name and stored cash in 3D2D, and support a new clean upgrade set (`printer_amount`, `printer_armor`, `printer_cooler`, `printer_silencer`, `printer_timer`) instead of importing the unsafe old upgradeable printer addon.
- Replaced the temporary gemstone ladder in F4 with a rebuilt toke-era printer ladder: `Bronze`, `Donator`, `Silver`, `Gold`, `Emerald`, `Ruby`, `Diamond`, and `Unobtainium`, each backed by live `custom_moneyprinter` tier entities instead of the missing old `toke_printer` addon.
- Staged more of the old must-have addon set directly into the live server before the first restart: `wyozimedia_base`, `wyozimedia_darkrp`, `playable_piano_104548572`, `money_detector_110639547`, `fix seats`, `sit anywhere`, and `antipropkill`.
- Re-enabled the old `Piano` and `TV` purchases in the live F4 entity list now that their backing addons exist in `serverfiles\garrysmod\addons`.
- Rebuilt `Pirate Box` as a safe live utility entity instead of copying the broken old file: it now packs one owned `custom_moneyprinter` into storage and redeploys it later with stored money and upgrades intact.
- Added `Money Detector` back into the live F4 utility list because the staged addon already provides `gmod_wire_moneydetector`.
- Restored the live `server.cfg` identity to the recovered old server name and FastDL URL: `Toke Gaming@DarkRP 2.5|[e2][WireMod - M9K - 16+Jobs] Custom [FastDL]` with `sv_downloadurl` set to `http://zyru-dl.gmod.eu:85/fastdl/27080_180/garrysmod`.
- Restored the old ULib rank skeleton by adding `the boss`, `donator`, and `v3gga` groups, and moved `STEAM_0:0:45125356` onto `the boss` so the owner boots into the recovered top-tier role instead of plain `superadmin`.
- Added a new standalone client addon at `serverfiles\garrysmod\addons\modernrp_ui` that starts the UI rebuild properly: it suppresses the fragmented stock DarkRP HUD pieces, replaces them with a unified bottom status/action bar, restyles live F4 controls into one cleaner visual system, and folds the old progression/media overlays into the same theme instead of leaving them as separate legacy widgets.

## Recovered identity targets to keep anchoring future iterations

- Server identity recovered from old backups: `Toke Gaming@DarkRP 2.5|[e2][WireMod - M9K - 16+Jobs] Custom [FastDL]` on `rp_downtown_v4c_v2`, with FastDL at `http://zyru-dl.gmod.eu:85/fastdl/27080_180/garrysmod`.
- Confirmed current live config already matches part of the old identity in `darkrp_config/settings.lua`: starting money `3500`, base salary `50`, respawn `1`, 3D voice enabled, and realistic fall damage enabled.
- Essential recovered addon set to preserve or replace cleanly: Ammo Machine, Pirate Box, upgradeable printers, AntiPropKill, Chess, Fix Seats, Money Detector, Sit Anywhere, slow_snp_pack_4, Wyozi Media Base, Wyozi Media DarkRP.
- Recovered job identity to restore in modernized form includes: Thief, Master Thief, Assassin of Death, Ninja, Civil Protection, S.W.A.T Medic, S.W.A.T, Private Security, Secret Agent, Pet, King Hobo, Black Market Dealer, Superior Arms Dealer, Mechanic, Drug Dealer, Banker, Admin on Duty, SuperAdmin on Duty.
- Recovered entity identity to preserve in modernized form includes: Gunz Lab, Piano, Ammo Machine, TV/Wyozi screen, tiered printers, and later a rebuilt Pirate Box.
- Recovered shipment identity to preserve: large M9K-heavy weapon and drug shipment catalogue from the old DarkRP config.
- Pirate Box source from `MUST HAVE THEESE/pirate_box` is incomplete and broken; it should be rebuilt from concept, not copied directly.

## Deferred on purpose

- Level/XP system from `F:\Windows.old.000\Users\vetle\Documents\LevelExperience`.
- Wiremod, Wire Extras, AdvDupe2, and Expression2 migration decisions.
- Optional gameplay addons such as drug, media, robbery, and dealer systems.
- Addon-dependent recovered jobs such as DJ, Cinema Owner, and CSI.

## Important compatibility notes

- The imported `jobs.lua` has been partially normalized to `DarkRP.createJob`, but it still relies on custom `level = ...` fields and old addon dependencies.
- The imported jobs and shipments reference older weapons, models, and addons that may not exist in the current install.
- Drug shipments from the old server are still intentionally deferred because the live server does not currently contain the required `durgz_*` entity classes.
- Some other old high-tier shipments are also still deferred until their live entity classes are confirmed, especially non-M9K custom pack items like `weapon_real_spas` and old grenade variants.
- `ulx` and `ulib` were already present on the live server, so only the custom ULX commands were added in this pass.
- Mixed old job sources were audited, and safe extra jobs were recovered from older edited-core DarkRP copies.
- A dependency audit was added to track unresolved M9K, lockpick, and keypad-related requirements.
- A recovered source inventory was added for custom E2 files and optional admin/media addons.
- The first real boot log identified and confirmed a DarkRP startup blocker caused by the stock Hobo job conflicting with the custom King Hobo command; this was fixed by disabling the default Hobo job.
- A later clean boot on `rp_downtown_tits_v25` confirmed the DarkRP vehicle crash and mayor/chief chat-condition spam were resolved, the player could receive paydays and weapons normally, and `bankvault_setpos` successfully saved the bank vault position.

## Recommended next implementation step

1. Restart once more so the saved bank vault position is picked up by the live bank robbery entity.
2. Re-check whether the local compatibility stubs suppress the `cssnag.lua` and `weapons/weapons/shared.lua` warnings on the next boot.
3. Decide whether to disable or replace noisy workshop addons that still produce harmless client errors, especially Franchi Spas 12 and M9K Specialties.
4. Restart and confirm the restored `Crips` and `Bloodz` jobs appear in F4 under `Gangsters` and that the mob boss agenda/group chat now includes them.
5. Normalize or prune the remaining legacy shipments and vehicle definitions after runtime dependency coverage is known.
6. Decide whether to enable optional admin/media addons from `migration_sources\admin_optional`.
7. Replace the temporary gemstone printers with a rebuilt printer system that keeps the remembered upgrade path but does not import the unsafe legacy printer code.