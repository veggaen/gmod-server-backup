# Modern DarkRP UI Rebuild Plan

Date: 2026-03-14

## What the old server actually used

- Old player HUD: `F:\Users\v3gga\Desktop\darkrpmodification-master\lua\darkrp_modules\SanyHUD_V1\cl_hudv1.lua`
  - This was the real custom HUD layer.
  - It hid `DarkRP_LocalPlayerHUD` and drew a custom player card with name, job, salary, wallet, health, armor, agenda, voice state, and gun license.
  - It also rendered the XP bar directly inside the HUD, so the HUD and level system were visually coupled.

- Old XP system: `F:\Users\v3gga\Desktop\darkrpmodification-master\lua\darkrp_modules\levels\*`
  - This was the Vrondakis-based level system.
  - Key files:
    - `sv_levels.lua`: player meta methods for XP and level handling.
    - `sv_data.lua`: MySQLite persistence.
    - `sv_addways.lua`: extra XP sources.
    - `cl_config.lua`: HUD toggle and color settings.
  - Verified extra XP sources from `sv_addways.lua`:
    - killing NPCs
    - killing higher-level players
    - money reward/penalty tied to PvP kills

- Old F4/menu situation:
  - `darkrp_modules\extraf4tab` exists, but it looks like the stock/example DarkRP extra-tab sample rather than a real custom menu.
  - No evidence yet of a complete old custom F4 replacement of the same quality as the HUD.

- Old lockpick/keypad UI situation:
  - The current server still uses separate lockpick and keypad-cracker weapon addons.
  - Their UI is old-style weapon-driven HUD logic, not a unified interface system.
  - This makes them good candidates for replacement in a new shared UI addon.

- Old printer UI situation:
  - The old ecosystem mixed several printer eras:
    - basic DarkRP/custom money printers
    - gemstone printers
    - Vrondakis printer ladder
    - Roxis printers
  - These were never part of one clean unified UI system.

## Current live config findings that matter for a rebuild

- `serverfiles\garrysmod\addons\darkrpmodification\lua\darkrp_config\settings.lua`
  - `GM.Config.DarkRPSkin = "DarkRP"`
  - `GM.Config.hideNonBuyable = false`
  - `GM.Config.hideTeamUnbuyable = true`
  - `GM.Config.DisabledCustomModules["hudreplacement"] = false`
  - `GM.Config.DisabledCustomModules["extraf4tab"] = false`
  - default laws, pocket blacklist, printer limits, and legal weapon defaults are still being carried by this file.

- Practical implication:
  - A modern rebuild should not rely on scattered example modules anymore.
  - It should live in one dedicated addon with clear client/server boundaries and one design system.

## Modern GMod migration constraints

- Build Derma panels once and update them through hooks/net messages; do not create Derma inside `HUDPaint`.
- Prefer modern `DarkRP.createJob`, `DarkRP.createEntity`, and related APIs over old `AddEntity`/`AddCustomShipment` style patterns.
- Scripted entities should use proper `init.lua`, `cl_init.lua`, and `shared.lua` structure so both server and client register them correctly.
- Expect old workshop-era assumptions to be wrong now:
  - model mounting is more reliable than it used to be, but missing workshop assets still need fallbacks
  - rendering and HUD hooks have had engine-side fixes, so old hacks should be re-evaluated instead of copied

## Recommendation

Do not keep layering patches on top of 10+ year old UI pieces.

Recommended direction: build a new addon that replaces the player-facing DarkRP UI as one coherent system.

## Proposed addon scope

Addon name suggestion: `modernrp_ui`

Modules:

1. Theme core
   - color tokens
   - typography/font registry
   - spacing and scaling helpers
   - panel drawing helpers

2. HUD
   - player card
   - health, armor, money, salary, level, XP
   - active weapon and ammo readout
   - wanted/arrest/lockdown state badges

3. F4 menu
   - categories with consistent visual language
   - job/entity/shipment/ammo/vehicle panels
   - dependency-aware disabled states
   - support for level and donor requirements without ugly legacy text dumps

4. Tab menu / scoreboard
   - cleaner scoreboard with rank, job, ping, level, and status indicators
   - hooks into ULX/ULib groups where available

5. Interaction overlays
   - lockpick progress UI
   - keypad crack progress UI
   - printer status and pickup UI
   - robbery/bank interaction prompts

6. Progression UI
   - reusable XP/level widgets
   - event feed for XP gain reasons
   - hooks for printers, kills, robberies, and job actions

## Recommended build order

1. Stabilize gameplay regressions first.
2. Extract old progression rules from the Vrondakis addon into a compatibility map.
3. Build a new theme + HUD foundation addon.
4. Replace F4 menu next.
5. Replace scoreboard/tab menu.
6. Replace lockpick/keypad/printer overlays.
7. Reintroduce progression visuals and XP sources on top of the new UI.

## What to reuse vs rewrite

- Reuse as reference only:
  - `SanyHUD_V1\cl_hudv1.lua`
  - `levels\sv_addways.lua`
  - `levels\sv_levels.lua`
  - old printer addentity definitions

- Rewrite from scratch:
  - HUD rendering
  - F4 menu
  - scoreboard/tab menu
  - lockpick/keypad overlays
  - printer status UI

- Migrate carefully:
  - XP rules
  - player groups/defaults
  - laws, limits, and blacklist config

## Immediate next implementation step

Build the new UI foundation addon first, starting with:

1. a shared theme system
2. a modern HUD/player card
3. a clean XP/level widget that can temporarily read existing DarkRP vars

After that, move to F4.