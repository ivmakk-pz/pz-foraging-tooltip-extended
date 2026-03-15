# Foraging Tooltip Extended - Changelog for b42.13.1 through b42.15.2

## Overview

This document tracks relevant Project Zomboid game changes from **Build 42.13.1** through **Build 42.15.2** that affect foraging mechanics, the foraging API, or this mod's functionality.

> For changes introduced in Build 42.13.0 (the initial MP release), see [CHANGELOG_b42.12_to_b42.13.md](./CHANGELOG_b42.12_to_b42.13.md).

---

## Build 42.13.1 — December 18, 2025

**Source:** https://theindiestone.com/forums/index.php?/topic/89477-42131-unstable-hotfix-released/

### 🐛 Foraging Bug Fixes

- **Fixed foraging zones not being created**
  - Critical regression fix: foraging zones were silently failing to initialize, preventing items from being found at all
  - Root cause was introduced in 42.13.0 during the zone system reorganization (`forageZones.lua`)

- **Fixed Foraging XP gain being abnormally high**
  - The new distance-based XP bonus formula introduced in 42.13.0 had an over-tuned multiplier
  - This caused XP numbers to be much larger than intended; corrected in this patch

### 💡 Impact on Foraging Tooltip Extended

- No API or Lua changes — mod compatibility is unaffected
- Players on 42.13.0 experiencing missing foraging items or inflated XP should update to 42.13.1

---

## Build 42.13.2 — January 19, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/90923-42132-unstable-hotfix-released/

### 🔄 Changes Overview

No foraging system or mod-relevant API changes in this release. Fixes were focused on MP stability, animal pathfinding, animation glitches, and packaging/fluid bugs.

### 💡 Impact on Foraging Tooltip Extended

- No changes required — full compatibility maintained

---

## Build 42.14.0 — February 16, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/91647-42140-unstable-released/

### ⚖️ Foraging-Adjacent Balance Changes

- **New loot distribution roomdefs added**
  - `agriworker`, `campworker`, and `hunterstorage` room definitions added to item distribution tables
  - These rooms affect what forageable and nature-themed items can be found in the world, including outdoors kit, nature tools, and wildlife-related gear

- **Fixed Poisonous mushrooms becoming ordinary after being picked** *(MP fix)*
  - Mushrooms gained via foraging were losing their poisonous state after being picked in multiplayer sessions
  - This affected any items in the mushroom foraging category

### 💡 Impact on Foraging Tooltip Extended

- No API or tooltip system changes
- Mod remains compatible with 42.14.0 without any updates required
- The new roomdefs may increase variety in items found nearby foraging zones (no display changes needed)

---

## Build 42.14.1 — February 18, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/91799-42141-unstable-hotfix-released/

### 🔄 Changes Overview

SP and MP hotfix only — vehicle, hearing trait, and weapon sync fixes. No foraging-related changes.

### 💡 Impact on Foraging Tooltip Extended

- No changes required — full compatibility maintained

---

## Build 42.15.0 — March 9, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/92435-42150-unstable-released/

### 🔧 Critical Fix for This Mod

- **Fixed some Prescription Glasses not removing the foraging search radius penalty**
  - Prescription Glasses worn by the character were failing to apply their `clothingPenalties` entry in `forageSystem`, causing the visual penalty to be missing from the search radius calculation
  - This directly affected the `FTE_VisionAffectingItems` module, which reads `forageSystem.clothingPenalties` and displays per-item radius penalties with icons
  - **After this fix:** glasses correctly contribute to the penalty list shown by this mod, and the displayed search radius breakdown now accurately reflects in-game behavior

### 🎮 Game Mode Rebalancing

- **Five game mode presets overhauled** — Apocalypse, Outbreak, Extinction, Rising, and Custom Sandbox
  - Apocalypse removes Zombie Respawn and adjusts loot levels (affects item density while foraging)
  - New modes change sandbox parameters that influence foraging context (loot abundance, animal growth rates, etc.)
  - No changes to the foraging formula or `ISSearchManager` APIs

### 📦 Foraging-Adjacent Fixes

- **Fixed Fishing Net with Chum producing too much fish**
  - Fishing/gathering system yielded excessive results when Chum bait was used; corrected

- **Fixed Lemongrass & Ginger Root not reducing Food Sickness**
  - Both are forageable wild plants; their food effect was broken and now works correctly

### 🛠️ Modding System Fixes

The following fixes from the `MODS` section of 42.15.0 are relevant for this mod's deployment:

- Fixed `COMMON/VERSION` folders not being detected correctly in the mod directory — game now only requires one of the two folders (directly relevant to this mod's `common/` and `42.15/` structure)
- Fixed mod translation loading order
- Fixed mod file comparison between client and server
- Fixed `ModID` / `WorkshopID` logic
- Fixed icon/poster file path for mods on Linux
- Added translation support for `mod.info` (title, description)
- Improved error message when clients are missing a mod from the server

### ⚠️ Breaking Change: Translation File Format

Build 42.15.0 changed the translation system for all mods. The old Lua-table `.txt` format is no longer loaded — the game now expects plain `.json` files.

**Old format** (no longer loaded by the game):
```
-- UI_EN.txt
UI_FTE_EN = {
    UI_options_FTE_title = "Foraging Tooltip Extended",
    ...
}
```

**New required format:**
```json
// UI.json  (no _EN suffix in filename)
{
    "UI_options_FTE_title": "Foraging Tooltip Extended",
    ...
}
```

File rename required per translation folder:

| Old filename   | New filename |
| -------------- | ------------ |
| `UI_EN.txt`    | `UI.json`    |
| `IG_UI_EN.txt` | `IG_UI.json` |

The `_EN` suffix is dropped — the language is inferred from the parent folder name (`EN/`, `RU/`, etc.).

> **Action required:** Rename and convert both translation files in each `Translate/<LANG>/` folder inside the `42.15` version folder.

### 💡 Impact on Foraging Tooltip Extended

| Area                                                 | Status                                            |
| ---------------------------------------------------- | ------------------------------------------------- |
| `FTE_VisionAffectingItems` — glasses penalty display | Now behaves correctly after game fix              |
| `FTE_CoreTooltip` — search radius breakdown          | No changes needed                                 |
| `FTE_SearchRadiusDisplay` — radius overlay display   | No changes needed                                 |
| Mod file structure (`common/` + `42.15/`)            | Now reliably detected by game engine              |
| **Translation files** (`UI_EN.txt`, `IG_UI_EN.txt`)  | **Must be converted to `UI.json` / `IG_UI.json`** |

**The glasses penalty fix is automatic, but translation files must be manually converted.** Without conversion, all `getText()` calls return raw key strings (e.g. `UI_options_FTE_title`) instead of the translated text.

---

## Build 42.15.1 — March 10, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/92519-42151-unstable-hotfix-released/

### 🔄 Changes Overview

Single fix: game not loading when username contains non-ASCII characters. No foraging or mod-system changes.

### 💡 Impact on Foraging Tooltip Extended

- No changes required — full compatibility maintained

---

## Build 42.15.2 — March 11, 2026

**Source:** https://theindiestone.com/forums/index.php?/topic/92591-42152-unstable-hotfix-released/

### 🔄 Changes Overview

Three fixes: additional non-ASCII username loading fix, animals not moving when rope is attached, and `GlobalModDataPacket` error. No foraging or tooltip-system changes.

### 💡 Impact on Foraging Tooltip Extended

- No changes required — full compatibility maintained

---

## Summary Table

| Version | Date       | Foraging Impact                                                                                      | Mod Update Required                          |
| ------- | ---------- | ---------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| 42.13.1 | 2025-12-18 | Critical bug fix: zones and XP                                                                       | No                                           |
| 42.13.2 | 2026-01-19 | None                                                                                                 | No                                           |
| 42.14.0 | 2026-02-16 | New roomdefs, mushroom MP fix                                                                        | No                                           |
| 42.14.1 | 2026-02-18 | None                                                                                                 | No                                           |
| 42.15.0 | 2026-03-09 | **Glasses penalty bug fixed** (affects mod display accuracy), **translation format changed to JSON** | **Yes — rename & convert translation files** |
| 42.15.1 | 2026-03-10 | None                                                                                                 | No                                           |
| 42.15.2 | 2026-03-11 | None                                                                                                 | No                                           |

---

**Last Updated:** March 15, 2026
**Covers:** Project Zomboid Builds 42.13.1 through 42.15.2
**Mod Version at Time of Writing:** 2.1.1
