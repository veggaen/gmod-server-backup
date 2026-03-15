# Recovered E2 And Admin Sources

Date: 2026-03-14

## Custom E2-related files recovered

Preserved under `migration_sources\e2_custom`:

- `migration_sources\e2_custom\tokerpexspression.lua`
- `migration_sources\e2_custom\entity.lua`
- `migration_sources\e2_custom\roxis_e2_function.txt`
- `migration_sources\e2_custom\roxis_e2_function_printer.txt`

### What they appear to be

- `tokerpexspression.lua` is a small custom Expression2 helper with functions for shipment contents, shipment amount, and money amount.
- `entity.lua` is a larger custom or older Expression2 entity extension source recovered from `roxis stuff`. It should be treated as reference material until Wiremod integration is reviewed carefully.
- The two `roxis` text files contain additional E2 helper snippets, including printer state access and a damage-trigger hook pattern.

## Expression2 files that were not treated as custom extensions

These were found but appear to be stock saved chips or stock Wire content:

- `F:\Windows.old.000\Users\vetle\Documents\expression2\_autosave_.txt`
- `F:\Windows.old.000\Users\vetle\Documents\expression2\_helloworld_.txt`
- `F:\Windows.old.000\Users\vetle\Documents\expression2\_shutdown_.txt`
- `F:\Windows.old.000\Users\vetle\Documents\expression2\_tabs_.txt`
- old `wire-master` source trees under `F:\Windows.old.000\Users\vetle\Documents\gmod editing\addons`

## Optional admin and gameplay addon sources preserved

Preserved under `migration_sources\admin_optional`:

- `ULX_Warn`
- `zones`
- `wyozimedia_base`
- `wyozimedia_darkrp`

## Why these were not auto-enabled

- They are likely useful, but they add extra systems beyond the current dependency recovery goal.
- `wyozimedia_darkrp` depends on the base media addon and should be enabled together with its DarkRP jobs and entities.
- `zones` and `ULX_Warn` should be tested in isolation after the base server boots cleanly.