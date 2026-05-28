# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Foraging Tooltip Extended is a client-side Project Zomboid Build 42 mod. It rewrites the vanilla foraging "Vision Effectiveness" tooltip to break down every modifier affecting search radius, and optionally shows the current radius next to the eye icon during search mode. Pure Lua 5.1 (PZ's embedded runtime) — there is no build, compile, or test step. Files are interpreted directly by the game.

## Versioning and the two release folders

The mod ships multiple version-specific folders under `Contents/mods/ForagingTooltipExtended/`; the game loads the one matching the player's build (see the `versionMin`/`versionMax` in each `mod.info`).

- `42/` — Build 42.12 through 42.14. Translations are legacy Lua `.txt` (`UI_EN.txt`, `IG_UI_EN.txt`).
- `42.15/` — Build 42.15+. This is the **active development target**. Translations are JSON (`UI.json`, `IG_UI.json`) per the 42.15 localization change.

The Lua code in both folders is otherwise the same. When changing behavior, decide whether the fix applies to one build line or both, and mirror it into each folder that needs it. Translation edits must respect each folder's format (`.txt` vs `.json`).

The mod version lives in **two** places that must stay in sync on every release: `modversion=` in each `mod.info`, and `FTE_Utils.MOD_VERSION` in `FTE_Utils.lua`.

## Architecture

`FTE_Client.lua` is a slim orchestrator: on `OnGameStart` it calls `initialise()` on each module; on `OnCreateUI` it sets up mod options. Everything else is a feature module.

All modules extend `FTE_ModuleBase` (`Core/FTE_ModuleBase.lua`), which is the heart of the mod's stability model. Use its methods rather than touching the game directly:

- `module:initialise(setupLogic)` — runs setup inside `pcall`; on failure the module is permanently blacklisted and disabled, isolating the crash.
- `module:overrideFunction(target, name, newFn)` — patches a vanilla function with an auto-restoring wrapper. If the override ever throws at runtime, it restores the original, blacklists the module, and falls back to vanilla for that call. Idempotent per (target, name).
- `module:registerEvent(name, handler)` — wraps the handler in `pcall` and tracks it for clean removal in `destroy()`.

A module file derives the class, creates a single instance, and exports `{ initialise, destroy, isActive, getInstance }`. Live modules:

- `Modules/FTE_CoreTooltip.lua` — the main feature; rebuilds the foraging vision tooltip (patches `ISZoneDisplay:getVisionTooltipText`). Mandatory.
- `Modules/FTE_SearchRadiusDisplay.lua` — persistent radius readout next to the eye icon (patches `ISZoneDisplay:render`). Toggleable.
- `Modules/FTE_VisionAffectingItems.lua` — worn-item vision penalties shown in the tooltip.

`FTE_Utils.lua` holds shared state and helpers: `MOD_VERSION`, the color schema (`Colors`, built from the game's good/bad highlight colors), logging (`logInfo/logWarning/logError/logDebug`, gated by a `DEBUG_MODE` flag), number/percent formatting, and the cached `tooltipLayout` metrics (font scaling, value column X position, tree-connector texture selection). Tooltip text is assembled with PZ rich-text markup (`<RGB>`, `<SETX>`, `<LINE>`, `<IMAGE>`) using helpers like `getToolTipTextRadius` and `getToolTipTextWithTreeImage`.

`FTE_ModOptions.lua` defines the in-game options (via `PZAPI.ModOptions`): persistent-radius toggle and tooltip value alignment (right/left).

Radius math mirrors vanilla `ISSearchManager` (`getOverlayRadius`, `updateModifiers`, `minRadius`/`maxRadius`/`maxRadiusCap`, `perkLevel`) so the breakdown matches what the game actually computes — do not invent independent formulas.

## Conventions

- Prefix everything (`FTE_`) — file names, module classes, option keys — to avoid clashes with the game and other mods.
- LuaLS/EmmyLua annotations (`---@param`, `---@return`, `---@class`) on functions; keep them terse and type-focused, not prose. For vanilla classes you add fields to, declare an extended `---@class X : VanillaClass` instead of `---@diagnostic disable` suppressions.
- Section large files with `-- ===== SECTION NAME ===== --` banners.
- Reach for `pcall`/`or`-fallbacks only where data can genuinely be missing (mod options, optional item properties). Guaranteed game singletons (`getPlayer()`, `forageSystem`, `ScriptManager.instance`) should fail fast, not be defensively guarded.
- Use `table.concat` for tooltip building / loops; plain `..` for short 2–4 part strings.
- No emojis in code, comments, or docs.

## Looking up vanilla behavior

The mod patches vanilla foraging UI (`ISZoneDisplay`) and builds rich-text tooltips, so you often need to read vanilla source. Use the global context repo the pz-modding skill points at: `C:\games\pz-modding-llm-context` — decompiled Java (`decompiled/zombie/`) and game Lua (`game/media/lua/`, e.g. `client/ISUI/ISRichTextPanel.lua`, the foraging files under `client/`). The mod template at `C:\games\pz-mod-template-ivmakk` is the reference for shared structure and conventions. (Earlier the repo vendored local `PZ_files/` and `Mods_Refs/` copies for this; they were removed in favor of the context and template repos.)

## Changelogs and release

Two changelogs are maintained: `CHANGELOG.md` (repo) and `Contents/mods/ForagingTooltipExtended/common/ChangeLog.txt` (the in-game format, oldest-first, blocks delimited by `[ ------ ]`). Update user-facing changes in both. The Steam Workshop description lives in `workshop_description.bbcode` / `workshop.txt` and uses Steam BBCode, not Markdown.

## Skills (task workflows)

Detailed workflows live as Claude skills in `.claude/skills/` — these are the source of truth, synced from the `pz-mod-template-ivmakk` template repo:

- `pz-modding` — general PZ mod development, game API lookups, code conventions, changelog system.
- `pz-mod-release` — version bump + three-changelog update + tag/merge workflow.
- `pz-mod-localization` — adding translations (JSON for 42.15+, Lua `.txt` for 42.14 and earlier).
- `pz-mod-multi-version` — managing the per-build version folders and `versionMin`/`versionMax`.
- `pz-mod-upgrade` — upgrading the mod to a newer game build (changelog analysis, API verification, phased plan).
- `pz-rich-text-markup` — project-specific: the `<RGB>`/`<LINE>`/`<IMAGE>`/`<SETX>` tooltip markup this mod builds its strings with.

The legacy `.github/copilot-instructions.md`, `.github/instructions/`, and `.github/prompts/` are the older Copilot-format equivalents, kept for teammates still using Copilot. Several were written against an earlier layout (they reference a `42.13/` folder and a since-removed `FTE_ViewDistance` module) — prefer the skills and the actual files in `Contents/` over those docs where they disagree.

## Testing

In-game only — no automated tests, and do not create test files or testing-guide documents. The maintainer tests manually in Project Zomboid; Lua changes can be hot-reloaded from the debug console (F11) without restarting.
