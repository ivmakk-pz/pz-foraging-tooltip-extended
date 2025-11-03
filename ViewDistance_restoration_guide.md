# ViewDistance Feature Restoration Guide

## Overview
This guide explains how to restore the Items View Distance feature that was removed.

## Files to Restore

### 1. Module File
- **Location**: `Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/FTE_ViewDistance.lua`
- **Commit**: b501b01
- **Description**: Core module for view distance calculations

### 2. Client Integration
- **File**: `Contents/mods/ForagingTooltipExtended/42/media/lua/client/FTE_Client.lua`
- **Changes**:
  - Add require: `local FTE_ViewDistance = require "Modules/FTE_ViewDistance"`
  - Add initialization: `FTE_ViewDistance.initialise()`

### 3. Mod Options
- **File**: `Contents/mods/ForagingTooltipExtended/42/media/lua/client/FTE_ModOptions.lua`
- **Changes**:
  - Add config field: `showViewDistance = nil`
  - Add option tickbox for showViewDistance
  - Add function: `shouldShowViewDistance()`

### 4. CoreTooltip Integration
- **File**: `Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/FTE_CoreTooltip.lua`
- **Changes**:
  - Add require: `local FTE_ViewDistance = require("Modules/FTE_ViewDistance")`
  - Add function: `addViewDistanceSection(character, searchManager)`
  - Add conditional call in tooltip generation with option check

### 5. Translations
- **File**: `Contents/mods/ForagingTooltipExtended/42/media/lua/shared/Translate/EN/UI_EN.txt`
- **Add**:
  - `UI_options_FTE_showViewDistance`
  - `UI_options_FTE_showViewDistance_tooltip`

- **File**: `Contents/mods/ForagingTooltipExtended/42/media/lua/shared/Translate/EN/IG_UI_EN.txt`
- **Add**:
  - `IGUI_FTE_View_Distance_Header`
  - `IGUI_FTE_View_Distance_Small`
  - `IGUI_FTE_View_Distance_Medium`
  - `IGUI_FTE_View_Distance_Large`

### 6. Documentation
- **File**: `workshop_description.bbcode`
- **Restore**: Items View Distance mentions in features and options

## Restoration Commands

```bash
# 1. Restore the module file from git history
git show b501b01:Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/FTE_ViewDistance.lua > Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/FTE_ViewDistance.lua

# 2. Use the generated patch file
git apply 0001-Added-Implement-ViewDistance-module-for-real-time-vi.patch
```

## Manual Integration Steps

1. Restore FTE_ViewDistance.lua module file
2. Update FTE_Client.lua to require and initialize the module
3. Update FTE_ModOptions.lua to add the option
4. Update FTE_CoreTooltip.lua to use the module
5. Add translation entries
6. Update workshop description

## Reference Commit
- ViewDistance Implementation: b501b01

