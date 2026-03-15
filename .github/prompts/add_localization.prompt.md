---
agent: agent
---

# Add Localization for [Language]

Please add localization support for **[specify language, e.g., German/French/Spanish]** to the Foraging Tooltip Extended mod.

## Task Details

Create translation files for the specified language by translating all text from the English reference files while maintaining the exact variable structure and FTE naming convention.

## Required Files to Create

### Build 42.15+ (`42.15` folder) — JSON format
As of Build 42.15.0, translation files are plain `.json` files. The language code is NOT part of the filename — it is inferred from the parent folder name.

1. `IG_UI.json` - In-game UI elements and tooltips
2. `UI.json` - Mod settings and menu interface

Each `UI.json` file must include a `$schema` entry for validation. No schema is available for `IG_UI.json`:

```json
// IG_UI.json — no $schema (schema not published for this type)
{
    "IGUI_FTE_...\": \"...\"
}

// UI.json
{
    "$schema": "https://raw.githubusercontent.com/SirDoggyJvla/pz-translation-data/refs/heads/main/PZ_Translation_Schemas/UI.schema.json",
    "UI_options_FTE_...": "..."
}
```

### Build 42.12 (`42.12` folder) — Lua table format
The old `.txt` Lua-table format is still used for the 42.12 version folder.

1. `IG_UI_{LANGUAGE}.txt` - In-game UI elements and tooltips
2. `UI_{LANGUAGE}.txt` - Mod settings and menu interface

## Reference Files
Use these English files as the translation source:
- `Contents/mods/ForagingTooltipExtended/42.15/media/lua/shared/Translate/EN/IG_UI.json` (Build 42.15+ version)
- `Contents/mods/ForagingTooltipExtended/42.15/media/lua/shared/Translate/EN/UI.json` (Build 42.15+ version)
- `Contents/mods/ForagingTooltipExtended/42.12/media/lua/shared/Translate/EN/IG_UI_EN.txt` (Build 42.12 version)
- `Contents/mods/ForagingTooltipExtended/42.12/media/lua/shared/Translate/EN/UI_EN.txt` (Build 42.12 version)

## Target Folders
Translation files should be added to BOTH version folders:
- `Contents/mods/ForagingTooltipExtended/42.15/media/lua/shared/Translate/{LANGUAGE}/` — `IG_UI.json` + `UI.json`
- `Contents/mods/ForagingTooltipExtended/42.12/media/lua/shared/Translate/{LANGUAGE}/` — `IG_UI_{LANGUAGE}.txt` + `UI_{LANGUAGE}.txt`

## Encoding
All languages use **UTF-8** encoding in Build 42.15.0+. The 42.12 folder may require language-specific encodings (see `localization.instructions.md`).

## Expected Output
Complete, culturally appropriate translations that:
- Maintain all variable names exactly as in English files
- Follow Project Zomboid localization standards (Build 42.15 wiki)
- Preserve technical formatting and tags
- Use UTF-8 encoding

The translation should be ready for immediate use in the mod without requiring code changes.