# Workshop Audit 2026-03-14

## Summary

- Parsed 177 workshop entries from `serverfiles/garrysmod/cfg/srcds_addons.txt`.
- 38 entries were backed by modern `.gma` archives and could be extracted into normal addon folders.
- 139 entries are older `legacy.bin` workshop cache items and were not convertible with the available command-line tools.
- Extracted workshop addons were placed in `serverfiles/garrysmod/addons/workshop_<id>_<name>` folders.
- Clear duplicate workshop copies were moved out of the live addon path into `serverfiles/garrysmod/addons_disabled_workshop_dupes` so existing custom/tweaked addon folders remain authoritative.

## Disabled Workshop Duplicates

These workshop folders were moved out of `serverfiles/garrysmod/addons` and into `serverfiles/garrysmod/addons_disabled_workshop_dupes`:

- `workshop_557962238_ulib`
- `workshop_557962280_ulx`
- `workshop_160250458_wiremod`
- `workshop_2306283801_gmodstore_vliss_scoreboard_v1_resources`
- `workshop_1976452711_rp_downtown_tits_v2_new_workshop_upload`
- `workshop_108424005_keypad_tool_and_cracker_with_wire_support`

These were disabled because they overlap real live addon folders:

- `ulib`
- `ulx`
- `wiremod`
- `vliss_scoreboard`
- `rp_downtown_tits_v2`
- `Keypad`

## Disabled After Verification

The following workshop folder was additionally verified as a real duplicate and then disabled:

- `workshop_108424005_keypad_tool_and_cracker_with_wire_support`
  - overlaps `Keypad`
  - verified shared files include:
    - `lua/entities/keypad/cl_init.lua`
    - `lua/entities/keypad/init.lua`
    - `lua/entities/keypad/sh_init.lua`
    - `lua/entities/keypad_wire/cl_init.lua`
    - `lua/entities/keypad_wire/init.lua`
    - `lua/entities/keypad_wire/sh_init.lua`
    - `lua/weapons/keypad_cracker.lua`
    - `lua/weapons/gmod_tool/stools/keypad_willox.lua`
    - `lua/weapons/gmod_tool/stools/keypad_willox_wire.lua`

## Checked Candidates That Are Probably Safe

These pairs were checked and did not show direct file overlap in the inspected comparisons:

- `workshop_108176967_the_sit_anywhere_script` vs `sit anywhere`
- `workshop_112606459_tdmcars_base_pack` vs `tdmcars_-_emergency_vehicles_pack`
- `workshop_2125384232_skeypad_content` vs `xlogs_content`
- `workshop_546392647_media_player` vs `wyozimedia_base`

These still may be related dependencies, but they did not look like direct duplicate payloads.

## Verified Extracted Addons Mentioned During Audit

- `workshop_112806637_gmod_legs_3`
- `workshop_2973512530_vmanip_door_interaction_animation`
- `workshop_3370631899_pathfinder_swep_become_a_nextbot`
- `workshop_3451239016_support_hands_for_m9k`
- `workshop_349050451_chuck_s_weaponry_2_0`
- `workshop_358608166_extra_chuck_s_weaponry_2_0`

## Legacy Workshop Extraction Status

- Alternate extractor found:
  - `D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\GMad Extractor\GMad.exe`
- Command-line test against a sample legacy cache file did not produce any extracted output:
  - sample input: `serverfiles/steam_cache/content/4000/104477476/560956219610273760_legacy.bin`
  - test output folder remained empty

Current conclusion:

- The available `gmad.exe` tool can extract `.gma` workshop caches.
- The available `GMad Extractor` binary did not prove usable from the CLI for legacy `.bin` caches in this environment.
- The remaining 139 `legacy.bin` workshop items should still be treated as workshop-mounted content unless a working legacy extractor is found.

## Log Findings

`serverfiles/logs/workshop_log.txt` confirms successful workshop downloads for many items, including items checked during this audit:

- `108424005`
- `112806637`
- `160250458`
- `557962238`
- `557962280`
- `1976452711`

No `Processing addon ... Mounted!` or `Mounted!` lines were found in the current text logs that were searched.

## Recommended Next Action

Boot the server once and verify that the non-workshop folders are the ones loading for `ulib`, `ulx`, `wiremod`, `Keypad`, `vliss_scoreboard`, and `rp_downtown_tits_v2`.