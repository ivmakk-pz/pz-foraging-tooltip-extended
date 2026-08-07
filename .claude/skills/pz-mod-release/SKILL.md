---
name: pz-mod-release
description: >
  Use this skill when releasing a PZ mod version: preparing changelogs, bumping versions,
  or finalizing a release. Activates when the user says "release", "prepare release",
  "bump version", "post release", "finalize release", "tag release", or asks to
  update version numbers across mod files.
---

# Releasing Foraging Tooltip Extended

Follow the generic release procedure in the central `pz-modding` skill (`references/releasing.md`) for the two-phase flow (prepare on a `release/X.Y.Z` branch -> finalize with merge + tag), the exact changelog block formats, and the `workshop.txt` publish gate. This file records only this mod's project-specific facts.

## FTE facts

- **Layout:** single version folder, `Contents/mods/ForagingTooltipExtended/42/` (`versionMin=42.15`, no `versionMax`), plus `common/`.
- **Version references (all must match `X.Y.Z`):**
  - `Contents/mods/ForagingTooltipExtended/42/mod.info` -> `modversion=`
  - `Contents/mods/ForagingTooltipExtended/42/media/lua/client/FTE_Utils.lua` -> `FTE_Utils.MOD_VERSION`
  - `README.md` -> version badge (`Version-X.Y.Z-blue`)
- **Three changelogs:** `CHANGELOG.md` (newest-first), `workshop_assets/workshop_updates.txt` (plain text, newest-first), `Contents/mods/ForagingTooltipExtended/common/ChangeLog.txt` (in-game alert, oldest-first, append at BOTTOM).
- **Tag convention:** NO `v` prefix - tags are bare `X.Y.Z` (e.g. `2.2.1`). Confirm with `git tag --sort=-version:refname`.
- **mod id:** `Ivmakk_ForagingTooltipExtended`.
