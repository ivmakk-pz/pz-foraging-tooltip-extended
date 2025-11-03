# Foraging Tooltip Extended

![Mod Version](https://img.shields.io/badge/Version-1.1.2-blue)
[![Steam Workshop](https://img.shields.io/badge/Steam%20Workshop-View-blue)](https://steamcommunity.com/sharedfiles/filedetails/?id=3507997225)

A Project Zomboid mod that enhances the foraging tooltip with detailed modifier breakdowns and customizable display options.

## Project Structure

See more on https://pzwiki.net/wiki/Mod_structure

This project follows the Project Zomboid Build 42 mod structure for Steam Workshop publishing:

### Published to Steam Workshop (Contents/ folder only):
```
Contents/
└── mods/
    └── ForagingTooltipExtended/
        ├── common/                     # Mandatory (even if empty)
        │   └── media/                  # Large shared assets go here
        └── 42/                         # Version-specific folder
            ├── mod.info                # Mod metadata
            ├── icon.png                # Mod icon
            ├── poster.png              # Mod poster
            └── media/
                └── lua/
                    ├── client/
                    │   ├── FTE_Client.lua      # Main tooltip logic
                    │   └── FTE_ModOptions.lua  # Mod options handling
                    ├── server/             # Server-side scripts (empty)
                    └── shared/
                        └── Translate/
                            └── EN/
                                ├── IG_UI_EN.txt
                                └── UI_EN.txt
```

### Required for Steam Workshop Upload (not downloaded by users):
```
├── workshop.txt               # Steam Workshop metadata (auto-generated)
├── preview.png                # 256x256 Steam Workshop preview image
```

**Note**: The `Contents/` folder becomes the downloadable mod content for players. The `workshop.txt` and `preview.png` are required for uploading via the game's workshop interface but are not included in what users download when they subscribe to the mod.

### Git Repository Only (development files):
```
ForagingTooltipExtended/        # Root folder
├── Contents/                   # (Published content above)
├── README.md                  # This file
├── CHANGELOG.md               # Version history
├── LICENSE                    # License file
├── workshop_description.bbcode   # Workshop description text
├── workshop_assets/           # Development assets
└── instructions/              # Development documentation
```

## Technical Overview

### Modular Architecture (v1.2.0+)

The mod uses a modular architecture pattern with clear separation of concerns:

```
Contents/mods/ForagingTooltipExtended/42/media/lua/client/
├── FTE_Client.lua                    # Main entry point (orchestrator)
├── FTE_Utils.lua                     # Shared utilities (logging, colors, formatting)
├── FTE_ModOptions.lua                # Configuration management
│
├── Core/
│   └── FTE_ModuleBase.lua            # Base class for all feature modules
│
└── Modules/
    ├── FTE_CoreTooltip.lua           # Core tooltip enhancements
    ├── FTE_ViewDistance.lua          # View distance calculations (optional)
    ├── FTE_SearchRadiusDisplay.lua   # Persistent radius display next to eye icon
    ├── FTE_SearchRadiusVisual.lua    # Visual radius display (future)
    └── FTE_EquipmentImpact.lua       # Equipment analysis (future)
```

**Key Benefits:**
- **Fault Isolation**: Module failures don't crash the entire mod
- **Modularity**: Features can be toggled independently
- **Maintainability**: Clear code organization and separation
- **Extensibility**: Easy to add new features as modules

### Core Files
- **FTE_Client.lua**: Slim entry point that initializes modules and manages lifecycle
- **FTE_Utils.lua**: Shared utilities (logging with color formatting, helper functions)
- **FTE_ModOptions.lua**: Handles mod configuration options and user preferences
- **Core/FTE_ModuleBase.lua**: Base class providing lifecycle hooks and error handling for all modules
- **Modules/FTE_CoreTooltip.lua**: Main tooltip enhancement logic (hooks into vanilla foraging system)
- **Modules/FTE_ViewDistance.lua**: Optional view distance calculation system
- **Modules/FTE_SearchRadiusDisplay.lua**: Displays current search radius before the eye icon in ISZoneDisplay panel
- **Translate files**: Localization strings for UI elements

### Key Functions & Patterns
- **Module Pattern**: All features extend `FTE_ModuleBase` with consistent lifecycle (initialize, destroy, isActive)
- **Safe Overrides**: Game function overrides wrapped in error handlers with fallback to vanilla
- **Color System**: Uses game's `getGoodHighlitedColor()` and `getBadHighlitedColor()` for consistency
- **Modifier Calculation**: Based on vanilla `ISSearchManager` methods for accuracy

## Development Setup

### Prerequisites
- Project Zomboid Build 42.9+
- Text editor with Lua syntax support (recommended [Visual Studio Code](https://pzwiki.net/wiki/Visual_Studio_Code))
- Access to Project Zomboid [modding documentation](https://pzwiki.net/wiki/Modding)

### Building
No build process required. Lua files are interpreted directly by the game.

### Testing
1. Enable [Debug Mode](https://pzwiki.net/wiki/Debug_mode) (e.g. add `-debug` in Steam in game's properties)
2. Copy mod to `%USERPROFILE%\Zomboid\mods\`
3. Test foraging tooltip functionality
4. Verify mod options work correctly

#### Debugging Lua Changes

You can test modifications to Lua files without restarting the game by using the debug console (`F11` by default). Find the mod's files by name (e.g., `FTE_Client.lua`) and reload them directly from the UI menu. This allows for faster iteration during development and testing.

## Technical Notes

### Compatibility Considerations
- Modular architecture isolates failures to individual modules
- Hooks into vanilla foraging tooltip rendering with safe overrides
- Uses existing game color schemes for consistency
- Minimal impact on game performance
- Should be compatible with most other mods unless they modify the same tooltip hooks
- Core functionality remains stable even if optional modules fail

### Module System
Each feature module:
- Extends `FTE_ModuleBase` for consistent behavior
- Can be enabled/disabled independently via mod options
- Fails gracefully without breaking other features
- Logs lifecycle events for debugging
- Provides clean public API for inter-module communication

### Code Style
- _WIP_

## Mod Options Configuration

Options are stored in mod data and accessed via `FTE_ModOptions` module:

- `shouldShowFormula()`: Toggle formula display
- `shouldShowMinMaxValues()`: Toggle min/max radius values
- `shouldShowVisionBonusDetails()`: Toggle vision bonus breakdown
- `shouldShowZeroPenalties()`: Toggle zero-value penalty display
- `shouldShowZeroTraitBonuses()`: Toggle zero-value trait bonus display
- `shouldShowViewDistance()`: Toggle view distance estimates for items
- `shouldShowPersistentRadius()`: Toggle persistent radius display before eye icon

## Known Issues & Limitations

- Tooltip may conflict with other mods that modify the same foraging tooltip
- Color rendering depends on game's color scheme settings
- Performance impact minimal but scales with tooltip complexity

## Contributing

### Architecture Guidelines
- **Follow Module Pattern**: New features should be implemented as modules extending `FTE_ModuleBase`
- **Place in Modules/**: All feature modules go in `Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/`
- **Use FTE_Utils**: Leverage shared utilities for logging and formatting
- **Export Interface**: Always export `initialise`, `destroy`, `isActive`, `getInstance` functions
- **Handle Errors**: Use pcall() for risky operations; fail gracefully

### Code Style Guidelines
- Follow existing naming conventions (`FTE_` prefix for all classes/modules)
- Add LuaLS/EmmyLua type annotations for functions
- Use section separators for large files (`-- === SECTION NAME === --`)
- Keep comments concise - focus on "why" not "what"
- Test changes thoroughly before committing
- Update CHANGELOG.md for any user-facing changes

### Adding a New Module
1. Create `Modules/FTE_YourFeature.lua` extending `FTE_ModuleBase`
2. Implement `setupModule()` and any lifecycle hooks needed
3. Export module interface (initialise, destroy, isActive, getInstance)
4. Add initialization to `FTE_Client.lua`
5. Add mod option toggle in `FTE_ModOptions.lua` (if applicable)
6. Test with module enabled/disabled
7. Document the module's purpose and API

### Submitting Changes
1. Test mod functionality in-game
2. Verify compatibility with base game
3. Update version in mod.info if needed
4. Document changes in CHANGELOG.md

## Release Process

1. Update version in `mod.info`
2. Update CHANGELOG.md with release notes
3. Test final build
4. Upload to Steam Workshop
5. Tag release in repository

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## Support & Issues

### Reporting Bugs
When reporting issues, please include:
- Project Zomboid version
- Mod version
- Steps to reproduce
- Any error messages from console
- List of other active mods

### Debug Information
Enable debug mode in mod options to get additional console output for troubleshooting.

## License

This mod is released under the terms specified in [LICENSE](LICENSE).

## Maintainer

**ivmakk** - Primary developer and maintainer