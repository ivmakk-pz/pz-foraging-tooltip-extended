# Foraging Tooltip Extended - Project Zomboid Mod

## Project Overview

This is a Project Zomboid mod called "Foraging Tooltip Extended" that enhances the foraging tooltip with detailed modifier breakdowns and customizable display options. It provides comprehensive information about search radius calculations, view distances, and all factors affecting foraging effectiveness.

## Project Structure

This workspace follows the standard Project Zomboid mod structure:

### Main Development Directory
- **`Contents/mods/ForagingTooltipExtended/`** - Main code folder where all development work happens
  - Contains all mod files, scripts, and resources
  - This is where you implement features, fixes, and enhancements for your mod

### Vanilla Game Reference Directory
- **`PZ_files/`** - Original Project Zomboid files from Build 42.12.3 (**READ-ONLY**)
  - **DO NOT MODIFY** - Reference only for understanding vanilla implementations

### Preferred Modular Structure Reference
- **`Mods_Refs/QuickForageIconDiscard/`** - Reference mod showcasing preferred modular structure and project hierarchy (**READ-ONLY**)
  - **DO NOT MODIFY** - This is the developer's latest mod demonstrating the preferred modular architecture
  - Use this as the primary reference for project structure, code organization, and architectural patterns
  - Follow the modular design patterns, file organization, and naming conventions used in this mod
  - This represents the current best practices and preferred development approach
  
#### Class Hierarchy
```
ISUIElement (base UI: positioning, anchoring, events)
  └─ ISPanel (adds: backgrounds, borders, dragging)
      ├─ ISCollapsableWindow (adds: title bar, close/pin/resize)
      │   └─ ISSearchWindow (foraging search mode UI)
      ├─ ISButton (clickable buttons)
      ├─ ISToolTip (text tooltips)
      ├─ ISToolTipInv (item tooltips using Java)
      ├─ ISToolTipItemSlot (crafting tooltips)
      ├─ ISRichTextPanel (formatted text)
      ├─ ISInventoryPane (inventory display)
      ├─ ISResizeWidget (resize handles)
      └─ ISBaseIcon (world icons base)
          ├─ ISForageIcon (plants, mushrooms, etc.)
          ├─ ISStashIcon (hidden loot)
          └─ ISWorldItemIconTrack (world items)

Java: UIElement → ObjectTooltip (native item tooltips)
```

#### Foraging Core Files (9 files):
- `forageSystem.lua` - Item definitions, spawn logic, loot tables, calculations
- `ISSearchManager.lua` - Icon lifecycle, zones, visibility, search mode state
- `ISForageAction.lua` - Timed action for picking up items
- `ISBaseIcon.lua` - Base class: rendering, buttons, vision, modifiers
- `ISForageIcon.lua` - Forageable items with identification logic
- `ISStashIcon.lua` - Hidden stash icons
- `ISWorldItemIconTrack.lua` - World item position tracking
- `ISSearchWindow.lua` - Search mode UI panel with category focus
- `ISZoneDisplay.lua` - Zone info display (weather, time, celestial) **[YOUR MOD PATCHES THIS]**

#### UI Framework Files (13 files):
- `ISUIElement.lua` - Base: position, anchors, mouse events, children
- `ISPanel.lua` - Adds: background rendering, dragging
- `ISCollapsableWindow.lua` - Window: title bar, close, pin, resize
- `ISButton.lua` - Clickable button widget
- `ISToolTip.lua` - Generic text tooltips
- `ISToolTipInv.lua` - Inventory item tooltips (uses Java ObjectTooltip)
- `ISToolTipItemSlot.lua` - Crafting component tooltips
- `ISRichTextPanel.lua` - Rich text with formatting/scrolling
- `ISInventoryPane.lua` - Inventory pane functionality
- `ISResizeWidget.lua` - Corner resize handle widget
- `ISMouseDrag.lua` - Mouse dragging utilities
- `ISInventoryPaneContextMenu.lua` - Context menus, CraftTooltip pooling

#### Java Bridge Files (4 files in `java/`):
- `UIElement.java` - Base Java UI with rendering, events, clipping
- `ObjectTooltip.java` - Native item tooltip with layout system
- `ISToolTipWrapper.java` - Java→Lua tooltip creation bridge
- `ISPanelWrapper.java` - Base Java→Lua panel wrapper

#### Your Mod's Touch Points

**Tooltip Extension patches:**
1. `ISZoneDisplay:getVisionTooltipText()` - Extends vision tooltip with detailed modifiers, formula breakdown, view distances, and food detection bonus
2. `ISZoneDisplay:render()` - Adds persistent search radius display before the eye icon (FTE_SearchRadiusDisplay module)

### Other Directories
- **`.github/instructions/`** - Development guidelines and modding instructions
  - Contains project-specific development patterns and best practices
  - Reference these for consistent development workflow
- **`.github/prompts/`** - Reusable AI prompts for common tasks
  - Contains templates for common development tasks
- **`workshop_assets/`** - Steam Workshop assets and metadata
  - Thumbnails, preview images, and workshop description
- **Root files** - Mod documentation and configuration (README.md, CHANGELOG.md, LICENSE, etc.)

When developing features, always work in the `Contents/mods/ForagingTooltipExtended/` directory and reference vanilla files in `PZ_files/` as needed.

## Technologies and Framework

- **Primary Language**: Lua 5.1 (Project Zomboid's Lua environment)
- **Target Platform**: Project Zomboid (Steam Workshop mod)
- **Mod Framework**: Project Zomboid's mod system
- **File Structure**: Standard PZ mod structure with `media/lua/` directories
- **Build Version**: Build 42.9+ (tested up to Build 42.12)
- **Mod Options**: PZAPI.ModOptions for in-game configuration

## Key Development Principles

- **Code Quality**: Write clean, maintainable, and well-documented code
- **Compatibility-First Approach**: Ensure changes maintain compatibility with vanilla game and other popular mods
- **Minimal Footprint**: Keep the mod lightweight and focused on core functionality
- **Safe Patching**: Use safe function overriding with pcall error handling and fallback to original implementation
- **Error Resilience**: Implement proper error handling and graceful degradation (debug mode vs production mode)
- **Read-Only References**: Never modify files in reference directories - they should remain unchanged
- **Naming Conventions**: Use consistent prefixing (e.g., `FTE_`) for all mod files and functions to avoid conflicts
- **Performance Consideration**: Optimize code for performance, use table concatenation for string building
- **Modular Design**: Separate concerns (Client logic, ModOptions, Utils) for maintainability

## Testing Guidelines

- **No Automated Tests**: Avoid creating unit tests or automated test suites for this mod
- **No Testing Files**: Do NOT create separate testing files, testing guides, or testing instruction documents
- **In-Game Testing Only**: All functionality should be tested directly in Project Zomboid by the developer
- **Manual Testing Preferred**: The developer will manually test all features in-game
- **Implementation Only**: Focus on implementing features correctly rather than documenting how to test them

## Implementation Guidelines

- **Questions vs Implementation**: If the user asks a question about architecture, patterns, or "how to" - provide guidance and explanation in chat only
- **Explicit Implementation Requests**: Only create/modify files when the user explicitly asks for implementation (e.g., "implement this", "create a file", "modify this code")
- **No Unsolicited Files**: Do NOT create example files, sample implementations, or demonstration code unless specifically requested
- **Chat-First Approach**: For questions about design patterns, architecture advice, or technical guidance - respond with detailed explanations in chat
- **No Emojis in Documents**: Do NOT use emojis in any documentation files, markdown files, or code comments. Use plain text symbols and clear descriptive language instead

## Current Implementation Structure

```
Contents/mods/ForagingTooltipExtended/42/media/
├── lua/
│   ├── client/
│   │   ├── FTE_Client.lua                    # Main entry point (orchestrator)
│   │   ├── FTE_ModOptions.lua                # Mod options configuration
│   │   ├── FTE_Utils.lua                     # Shared utilities (colors, formatting, helpers)
│   │   ├── Core/
│   │   │   └── FTE_ModuleBase.lua            # Base class for all feature modules
│   │   └── Modules/
│   │       ├── FTE_CoreTooltip.lua           # Core tooltip enhancements (mandatory)
│   │       ├── FTE_ViewDistance.lua          # View distance calculations (optional)
│   │       └── FTE_SearchRadiusDisplay.lua   # Persistent radius display (optional)
│   └── shared/Translate/
│       └── EN/
│           ├── IG_UI_EN.txt                  # In-game UI translations
│           └── UI_EN.txt                     # Mod options translations
└── ui/
    └── TooltipStructureItems/
        ├── middle_connector.png              # Tree connector for list items (16x16px)
        └── last_connector.png                # Tree connector for last item (16x16px)
```

### UI Assets

- **Tree Connector Images**: Custom images for tooltip list structure visualization
  - Size: 16x16 pixels (optimized for clean display)
  - Auto-scales based on font size selected in game options (calculated from UIFont.NewSmall line height)
  - Used in A-F modifier section to create visual hierarchy

## Testing Guidelines

- **No Automated Tests**: Avoid creating unit tests or automated test suites for this mod
- **No Testing Files**: Do NOT create separate testing files, testing guides, or testing instruction documents
- **In-Game Testing Only**: All functionality should be tested directly in Project Zomboid by the developer
- **Manual Testing Preferred**: The developer will manually test all features in-game
- **Implementation Only**: Focus on implementing features correctly rather than documenting how to test them

## Implementation Guidelines

- **Questions vs Implementation**: If the user asks a question about architecture, patterns, or "how to" - provide guidance and explanation in chat only
- **Explicit Implementation Requests**: Only create/modify files when the user explicitly asks for implementation (e.g., "implement this", "create a file", "modify this code")
- **No Unsolicited Files**: Do NOT create example files, sample implementations, or demonstration code unless specifically requested
- **Chat-First Approach**: For questions about design patterns, architecture advice, or technical guidance - respond with detailed explanations in chat
- **No Emojis in Documents**: Do NOT use emojis in any documentation files, markdown files, or code comments. Use plain text symbols and clear descriptive language instead

### Code Implementation Focus
When implementing a feature (only when explicitly requested), focus solely on:
1. Clean, working code implementation
2. Proper error handling and logging (DEBUG_MODE flag support)
3. Following existing mod patterns and conventions (FTE_ prefix)
4. Maintaining compatibility with vanilla game and other mods
5. Using consistent naming conventions with FTE prefix
6. Performance optimization (table concatenation, caching)

**DO NOT CREATE**: Testing guides, testing files, test scenarios, testing instructions, example files, or demonstration code unless explicitly requested.

## Localization Support

- Follow the localization instructions in `.github/instructions/localization.instructions.md`
- Support multiple languages when applicable
- Keep text keys organized and consistently named
- Use the `Translate/` directory structure for language files
- Current supported language: English (EN)
- Translation files: `IGUI_FTE_EN.txt` (in-game UI), `UI_FTE_EN.txt` (mod options)

## Steam Workshop Integration

- Update `workshop_description.bbcode` with proper formatting following `.github/instructions/steam_syntax.instructions.md`
- Maintain `CHANGELOG.md` for version history using `.github/instructions/changelog.instructions.md`
- Keep workshop assets in `workshop_assets/` directory
- Follow Steam Workshop guidelines and best practices
- Workshop ID: 3507997225
- Mod ID: Ivmakk_ForagingTooltipExtended

## Development Workflow

1. **Planning**: Review existing instructions and prompts in `.github/` directory
2. **Implementation**: Work in `Contents/mods/ForagingTooltipExtended/` following established patterns
3. **Documentation**: Update relevant documentation files (README.md, CHANGELOG.md, etc.)
4. **Localization**: Add or update translation files if text changes are made
5. **Testing**: Test in-game manually with DEBUG_MODE flag for detailed error tracking
6. **Release**: Use `.github/prompts/release.prompt.md` workflow for publishing updates

## Common Tasks Reference

- **Adding Localization**: See `.github/prompts/add_localization.prompt.md`
- **Release Process**: See `.github/prompts/release.prompt.md`
- **Mod Options**: See `.github/instructions/mod_options.instructions.md`
- **Mod Info Updates**: See `.github/instructions/mod.info.instructions.md`
- **Changelog Format**: See `.github/instructions/changelog.instructions.md`
- **Steam BBCode**: See `.github/instructions/steam_syntax.instructions.md`

## Key Features Overview

- **Detailed Modifier Breakdown**: Shows exact effects of weather, darkness, exhaustion, and other modifiers
- **Formula Display**: Optional formula view (A * B * C * D * E) with color-coded values
- **Min/Max Indicators**: Highlights when radius reaches minimum or maximum caps
- **View Distance Estimates**: Shows detection ranges for small/medium/large items
- **Persistent Radius Display**: Shows current search radius before the eye icon (always visible during search mode)
- **Food Detection Bonus**: Displays hunger-based food detection multiplier
- **Vision Bonus Details**: Breaks down aiming and crouching bonuses
- **State Penalties**: Details clothing, exhaustion, panic, body damage, movement penalties
- **Trait/Profession Bonuses**: Shows all category-specific bonuses with sorting (non-zero first)
- **Customizable Display**: Multiple mod options to toggle sections and zero-value visibility
- **Error Resilience**: Production mode with fallback to vanilla tooltip on failure
- **Modular Architecture**: Fault-isolated feature modules for stability and maintainability
