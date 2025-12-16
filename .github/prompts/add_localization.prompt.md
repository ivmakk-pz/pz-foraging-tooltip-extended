---
agent: agent
---

# Add Localization for [Language]

Please add localization support for **[specify language, e.g., German/French/Spanish]** to the Foraging Tooltip Extended mod.

## Task Details

Create translation files for the specified language by translating all text from the English reference files while maintaining the exact variable structure and FTE naming convention.

## Required Files to Create
1. `IG_UI_{LANGUAGE}.txt` - In-game UI elements and tooltips
2. `UI_{LANGUAGE}.txt` - Mod settings and menu interface

## Reference Files
Use these English files as the translation source:
- `Contents/mods/ForagingTooltipExtended/42.13/media/lua/shared/Translate/EN/IG_UI_EN.txt` (Build 42.13+ version)
- `Contents/mods/ForagingTooltipExtended/42.13/media/lua/shared/Translate/EN/UI_EN.txt` (Build 42.13+ version)

Note: Translation files should be added to BOTH version folders:
- `Contents/mods/ForagingTooltipExtended/42.13/media/lua/shared/Translate/{LANGUAGE}/` (Build 42.13+)
- `Contents/mods/ForagingTooltipExtended/42.12/media/lua/shared/Translate/{LANGUAGE}/` (Build 42.12.x)

## Expected Output
Complete, culturally appropriate translations that:
- Maintain all variable names exactly as in English files
- Follow Project Zomboid localization standards
- Preserve technical formatting and tags
- Use proper encoding for the target language

The translation should be ready for immediate use in the mod without requiring code changes.