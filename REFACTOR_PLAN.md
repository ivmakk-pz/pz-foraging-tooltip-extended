# Refactor Plan: Monolithic to Modular Architecture

## Target Structure

```
Contents/mods/ForagingTooltipExtended/42/media/lua/client/
├── FTE_Client.lua                    # Main entry point (slim)
├── FTE_Utils.lua                     # Logging, colors, formatting
├── FTE_ModOptions.lua                # Mod options with module toggles
│
├── Core/
│   └── FTE_ModuleBase.lua            # Base class for all modules
│
└── Modules/
    ├── FTE_CoreTooltip.lua           # Core tooltip enhancements
    ├── FTE_ViewDistance.lua          # View distance estimates (optional)
    ├── FTE_SearchRadiusVisual.lua    # Visual radius display (stub)
    └── FTE_EquipmentImpact.lua       # Equipment analysis (stub)
```

## Migration Tasks

### Phase 1: Foundation
- [x] Create `Core/` directory
- [x] Create `Core/FTE_ModuleBase.lua` (adapt from QFID_ModuleBase)
  - [x] Change all `QFID` prefixes to `FTE`
  - [x] Update class name to `FTE_ModuleBase`
  - [x] Keep all lifecycle and override methods
- [x] Enhance `FTE_Utils.lua` (reference: `Mods_Refs/QuickForageIconDiscard/42/media/lua/client/QFID_Utils.lua`)
  - [x] Add `MOD_VERSION` constant
  - [x] Add `logInfo()`, `logWarning()`, `logError()`, `logDebug()` functions
  - [x] Add `setDebugMode()` function
  - [x] Keep existing color and formatting functions

### Phase 2: Extract Core Tooltip
- [x] Create `Modules/` directory
- [x] Create `Modules/FTE_CoreTooltip.lua`
  - [x] Move tooltip generation logic from `FTE_Client.lua`
  - [x] Move vision calculation functions
  - [x] Move tooltip building functions
  - [x] Wrap in module pattern using `FTE_ModuleBase`
  - [x] Override `ISZoneDisplay:getVisionTooltipText()`
  - [x] Export module interface (initialise, destroy, isActive, getInstance)

### Phase 3: Extract View Distance
- [x] Create `Modules/FTE_ViewDistance.lua`
  - [x] Move view distance calculation code
  - [x] Move `createRealIconForVisionCalculation()`
  - [x] Move `getItemViewDistance()`
  - [x] Move `getAllViewDistances()`
  - [x] Move `VIEW_DISTANCE_REFERENCE_SIZES`
  - [x] Move `iconCache`
  - [x] Wrap in module pattern
  - [x] Export API for core tooltip to use
  - [x] Mark as optional/experimental

### Phase 4: Create New Feature Stubs
- [ ] Create `Modules/FTE_SearchRadiusVisual.lua` (empty skeleton)
  - [ ] Add module base structure
  - [ ] Add placeholder `setupModule()` function
  - [ ] Add TODO comments for future implementation
- [ ] Create `Modules/FTE_EquipmentImpact.lua` (empty skeleton)
  - [ ] Add module base structure
  - [ ] Add placeholder `setupModule()` function
  - [ ] Add TODO comments for future implementation

### Phase 5: Refactor Client Entry Point
- [ ] Update `FTE_Client.lua`
  - [ ] Remove all tooltip generation code
  - [ ] Remove all vision calculation code
  - [ ] Add module requires
  - [ ] Create slim `init()` function that initializes all modules
  - [ ] Keep event hooks (OnGameStart, OnCreateUI)
  - [ ] Remove `DEBUG_MODE` (move to FTE_Utils)

### Phase 6: Update Mod Options
- [ ] Update `FTE_ModOptions.lua`
  - [ ] Add per-module enable/disable toggles
  - [ ] Add toggle for View Distance module
  - [ ] Add toggle for Search Radius Visual (future)
  - [ ] Add toggle for Equipment Impact (future)
  - [ ] Keep existing tooltip display options

### Phase 7: Testing & Validation
- [ ] Test core tooltip functionality
- [ ] Test view distance calculations (if enabled)
- [ ] Test module auto-disable on crash
- [ ] Test module toggle options
- [ ] Verify fallback to vanilla on failure
- [ ] Check debug mode logging

### Phase 8: Documentation
- [ ] Update `.github/copilot-instructions.md` with new structure
- [ ] Document module development pattern
- [ ] Document how to add new modules
- [ ] Update README.md if needed

## Code Mapping

### Current → Target

| Current Location | Target Location | Notes |
|------------------|-----------------|-------|
| `FTE_Client.lua` (lines 1-90) | `Modules/FTE_ViewDistance.lua` | Icon cache, vision calculations |
| `FTE_Client.lua` (lines 95-370) | `Modules/FTE_CoreTooltip.lua` | Tooltip building logic |
| `FTE_Client.lua` (lines 385-413) | `Modules/FTE_CoreTooltip.lua` | ISZoneDisplay override |
| `FTE_Client.lua` (DEBUG_MODE) | `FTE_Utils.lua` | Move to utils |
| `FTE_Utils.lua` | `FTE_Utils.lua` | Add logging functions |
| N/A | `Core/FTE_ModuleBase.lua` | New base class |
| N/A | `Modules/FTE_SearchRadiusVisual.lua` | Future feature |
| N/A | `Modules/FTE_EquipmentImpact.lua` | Future feature |

## Module Dependencies

```
FTE_Client.lua
├─→ FTE_Utils.lua
├─→ FTE_ModOptions.lua
└─→ Modules/
    ├─→ FTE_CoreTooltip.lua
    │   ├─→ FTE_ModuleBase.lua
    │   ├─→ FTE_Utils.lua
    │   ├─→ FTE_ModOptions.lua
    │   └─→ FTE_ViewDistance.lua (optional)
    │
    ├─→ FTE_ViewDistance.lua
    │   ├─→ FTE_ModuleBase.lua
    │   └─→ FTE_Utils.lua
    │
    ├─→ FTE_SearchRadiusVisual.lua
    │   ├─→ FTE_ModuleBase.lua
    │   └─→ FTE_Utils.lua
    │
    └─→ FTE_EquipmentImpact.lua
        ├─→ FTE_ModuleBase.lua
        └─→ FTE_Utils.lua
```

## Rollback Plan

- Keep backup of original `FTE_Client.lua`
- Tag current version before refactor: `git tag pre-modular-refactor`
- Test each phase independently
- Can revert to monolithic if critical issues found

## Success Criteria

- [ ] All existing functionality works identically
- [ ] Core tooltip never breaks due to optional module failures
- [ ] Modules can be toggled on/off independently
- [ ] View Distance module can be fully disabled
- [ ] New feature stubs ready for development
- [ ] Code is more maintainable and organized
- [ ] No performance degradation
