# Foraging Tooltip Extended - Changelog for b42.13

## Project Zomboid b42.13 - Foraging System Changes

This document outlines the relevant changes in Project Zomboid build 42.13 that affect foraging mechanics and this mod's functionality.

### 🎯 Core Foraging Mechanics Changes

#### XP System Overhaul
- **XP bonuses for finding items further apart** (capped at 20 squares)
  - Distance bonus is calculated when an item begins to be revealed
  - XP bonuses for difficult finds still apply
  - Diminishing returns for low level items continue to apply

- **XP removed from pickup action**
  - Only finding items now grants XP, not picking them up
  - This encourages exploration rather than just collecting visible items

#### Search Mode Improvements
- **Discard Item option removed** from foraging interface
- **Force Find logic updated**
  - Now checks to place a new item when maximum 2D distance travelled without a find increases
  - Better ensures players don't go too long without discoveries

- **Affinity checks updated**
  - Minimum radius added to foraging affinity checks
  - Only triggers affinity find once per chunk
  - Distance XP snapshot occurs when marker arrow appears
  - Added reset for `lastSpottedX/Y` when player toggles search mode

### 📦 New Files Added to Game (b42.13)

The foraging system was reorganized with several new files:

**Client-side:**
- `forageClient.lua` - Client-side foraging logic
- `ISAnimalTracksFinder.lua` - Animal tracking finder system
- `ISAnimalTracksMenu.lua` - Animal tracks context menu
- `ISWorldItemIcon.lua` - Base class for world item icons

**Shared:**
- `forageCategories.lua` - Foraging category definitions
- `forageDefinitions.lua` - Detailed item definitions
- `forageSkills.lua` - Foraging skill mechanics
- `forageZones.lua` - Zone-based foraging configurations
- `scavenges.lua` - Scavenging system definitions

### 🔄 Modified Files

**Core System:**
- `forageSystem.lua` - Major updates to XP calculation, distance tracking, force find logic

**UI Components:**
- `ISForageAction.lua` - Updated action handling
- `ISBaseIcon.lua` - Base icon functionality updates
- `ISForageIcon.lua` - Foraging icon display logic
- `ISSearchManager.lua` - Search mode state management
- `ISSearchWindow.lua` - Search window UI updates
- `ISStashIcon.lua` - Stash icon rendering
- `ISWorldItemIconTrack.lua` - World item icon tracking
- `ISZoneDisplay.lua` - Zone visualization updates

### 🐾 New Feature: Animal Tracking

Build 42.13 introduces animal tracking to the foraging system:
- New UI for tracking animal movements
- Integration with foraging search mode
- Animal tracks can be found while foraging

### ⚖️ Balance Changes

#### Foraging Traits & Skills
- **Former Scout trait** now grants:
  - 1 skill level in Fishing
  - Survivalist recipes: MakeFishingRod, FixFishingRod, MakeChum

#### Wild Plants
- **Hops** added to WildPlants loot table
  - Spawn with random seed amounts (1-10) 75% of the time when collected

### 🎮 UI/UX Improvements

- Print-media and stash-map icons on in-game map reduced in size when zooming out
- Labels now display when mousing over brochure and flier icons on the map
- Map items now show green checkmark icon for players who have read them

### 💡 Impact on Foraging Tooltip Extended

**High Priority Updates:**
- Update tooltip display logic to reflect new XP calculation system
- Consider showing distance-based XP bonuses in tooltips
- Update to handle new file structure (categories, definitions, zones)

**Medium Priority:**
- Support for animal tracking displays if relevant
- Update any hardcoded references to removed "discard" functionality
- Verify compatibility with new Force Find logic

**Low Priority:**
- Adapt to icon size changes on map zoom
- Support for new wild plant additions (Hops)

### 📝 Technical Notes

**API Changes:**
- Foraging system now uses modular file structure
- `lastSpottedX/Y` tracking added for distance calculations
- Affinity system expanded with minimum radius checks
- Chunk-based affinity triggers implemented

**Deprecations:**
- "Discard Item" option removed from foraging
- XP on pickup action removed

---

**Last Updated:** December 13, 2025
**Source:** Project Zomboid Build 42.13 Release Notes (January 13, 2025)
**Mod Compatibility:** Requires update to support new foraging mechanics
