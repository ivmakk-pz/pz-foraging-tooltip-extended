---
name: pz-mod-localization
description: >
  Use this skill when adding or updating translations/localizations for a PZ mod.
  Activates when the user says "add localization", "translate", "add language",
  "add German/French/Spanish/etc translation", or asks about PZ translation files.
---

# Localizing Foraging Tooltip Extended

Follow the central `pz-modding` skill (`references/localization.md`) for the JSON/TXT formats, the translation rules, and the full language-code/encoding table. This file records only this mod's project-specific facts.

## FTE facts

- **Format & layout:** single version folder, JSON only: `Contents/mods/ForagingTooltipExtended/42/media/lua/shared/Translate/<LANG>/UI.json` and `IG_UI.json` (no language suffix in filename or keys).
- **Source of truth:** only `EN/` exists today. Translate its quoted values; keep keys byte-for-byte identical. The JSON files carry a `$schema` line - leave it in place.
- **Key prefixes:** settings `UI_options_FTE_<optionName>` (with `_tooltip` suffix on tooltip strings), in-game `IGUI_FTE_...`. Preserve `%1`/`%2` placeholders and `<BR>`/`<LINE>`/`<RGB>` tags exactly.
- **Special encodings** (everything else UTF-8): KO = UTF-16, CS = Cp1250, CA = ISO-8859-15, AR = Cp1252.
