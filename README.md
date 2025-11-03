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

### Core Files
- **FTE_Client.lua**: Main client-side logic that hooks into the foraging tooltip system
- **FTE_ModOptions.lua**: Handles mod configuration options and user preferences
- **Translate files**: Localization strings for UI elements

### Key Functions
- `getVisionTooltipTextB429Extended()`: Main function that generates enhanced tooltip content
- Color system using game's `getGoodHighlitedColor()` and `getBadHighlitedColor()`
- Modifier calculation based on vanilla `ISSearchManager` methods

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
- Hooks into vanilla foraging tooltip rendering
- Uses existing game color schemes for consistency
- Minimal impact on game performance
- Should be compatible with most other mods unless they modify the same tooltip hooks

### Code Style
- _WIP_

## Mod Options Configuration

Options are stored in mod data and accessed via `FTE_ModOptions` module:

- `shouldShowFormula()`: Toggle formula display
- `shouldShowMinMaxValues()`: Toggle min/max radius values
- `shouldShowVisionBonusDetails()`: Toggle vision bonus breakdown
- `shouldShowZeroPenalties()`: Toggle zero-value penalty display
- `shouldShowZeroTraitBonuses()`: Toggle zero-value trait bonus display

## Known Issues & Limitations

- Tooltip may conflict with other mods that modify the same foraging tooltip
- Color rendering depends on game's color scheme settings
- Performance impact minimal but scales with tooltip complexity

## Contributing

### Code Style Guidelines
- Follow existing naming conventions
- Add comments for complex calculations
- Test changes thoroughly before committing
- Update CHANGELOG.md for any user-facing changes

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