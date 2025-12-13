# Migration Plan: v2.0.0 → v2.1.0 (Build 42.13 Support)

## Overview
Update Foraging Tooltip Extended for compatibility with Project Zomboid Build 42.13.0

**Status:** In Progress  
**Branch:** release/2.1.0  
**Target Release Date:** TBD

---

## Tasks

### 1. Update Reference Files
- [x] Update `PZ_files/ISZoneDisplay.lua` to b42.13 version
- [x] Update `PZ_files/forageSystem.lua` to b42.13 version
- [x] Add new b42.13 files to `PZ_files/`:
  - [x] `forageClient.lua`
  - [x] `forageCategories.lua`
  - [x] `forageDefinitions.lua`
  - [x] `forageSkills.lua`
  - [x] `forageZones.lua`
  - [x] `ISWorldItemIcon.lua`
  - [x] `ISAnimalTracksFinder.lua`
  - [x] `ISAnimalTracksMenu.lua`
  - [x] `scavenges.lua`

### 2. Verify Patch Compatibility
- [x] Compare old vs new `ISZoneDisplay.lua` structure
- [x] Check if `getVisionTooltipText()` function signature changed
- [x] Verify `ISSearchManager` API compatibility
- [x] Test `forageSystem` data access (modifiers, radius calculations)
- [x] Ensure no breaking changes in patched functions

**Verification Results:**
- `ISZoneDisplay:getVisionTooltipText()` - No changes, signature identical
- `ISZoneDisplay:render()` - Function doesn't exist in vanilla (we override from ISUIElement)
- `ISSearchManager:getOverlayRadius()` - No changes
- `ISSearchManager:updateModifiers()` - No changes, modifiers structure identical
- `forageSystem` API - All functions present and unchanged:
  - `hungerBonusMax`, `getWeatherEffectReduction()`, `getDarknessEffectReduction()`, `getCategoryBonus()`
- **Conclusion:** No code changes required, all patches compatible with b42.13

### 3. Code Updates
- [ ] Update mod version to `2.1.0` in `mod.info`
- [ ] Update `versionMin=42.13` in `mod.info`
- [ ] Update tags to `Build 42.13` if needed
- [ ] Review and update error handling in `FTE_CoreTooltip.lua`
- [ ] Review and update error handling in `FTE_SearchRadiusDisplay.lua`
- [ ] Add game version detection to `FTE_Utils.lua` (optional)

### 4. Testing (In-Game)
- [ ] Enable DEBUG_MODE in `FTE_Utils.lua`
- [ ] Launch game with b42.13
- [ ] Check console for Lua errors
- [ ] Test Core Functionality:
  - [ ] Tooltip displays in search mode
  - [ ] Search radius calculations correct
  - [ ] Modifier breakdown shows all values
  - [ ] Formula display works (if enabled)
  - [ ] Min/Max radius indicators function
  - [ ] View distance estimates accurate
  - [ ] Food detection bonus displays
  - [ ] Trait/profession bonuses sorted correctly
- [ ] Test with different scenarios:
  - [ ] Various weather conditions
  - [ ] Day/night cycles
  - [ ] Different exhaustion levels
  - [ ] Different clothing items
  - [ ] With/without traits
- [ ] Test mod options:
  - [ ] All toggles work
  - [ ] Settings save/load correctly
  - [ ] Font size scaling correct

### 5. Documentation
- [x] Create b42.13 compatibility instructions
- [ ] Update `CHANGELOG.md` with v2.1.0 changes
- [ ] Update `README.md` if needed
- [ ] Update `workshop_description.bbcode`
- [ ] Add migration notes to `workshop_updates.txt`

### 6. Release Preparation
- [ ] Disable DEBUG_MODE
- [ ] Final in-game testing
- [ ] Git commit all changes
- [ ] Tag release as `v2.1.0`
- [ ] Merge `release/2.1.0` → `master`
- [ ] Upload to Steam Workshop
- [ ] Announce update

---

## Known Issues to Address

None identified yet (testing phase)

---

## Notes

- Build 42.13 reorganized foraging system into modular files
- XP system changed (distance-based), but doesn't affect our tooltip display
- Our mod patches only `ISZoneDisplay.lua` (still in client/)
- No registry system needed (we don't add custom identifiers)
- Client-side only mod (no multiplayer concerns)

---

## References

- `.github/instructions/b42.13_compatibility.instructions.md`
- `docs/42.13.0-20250113.md`
- `docs/CHANGELOG_b42.12_to_b42.13.md`
- `docs/migration_guide_to_b42.13.md`
