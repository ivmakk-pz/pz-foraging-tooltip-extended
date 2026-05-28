# Foraging Tooltip Extended — Copilot Instructions

Guidance for GitHub Copilot (and Copilot review) when working in this repository. This mirrors `CLAUDE.md` at the repo root; keep the two in sync when conventions change.

## What this is

Foraging Tooltip Extended is a client-side Project Zomboid Build 42 mod. It rewrites the vanilla foraging "Vision Effectiveness" tooltip to break down every modifier affecting search radius, and optionally shows the current radius next to the eye icon during search mode. Pure Lua 5.1 (PZ's embedded runtime) — there is no build, compile, or test step. Files are interpreted directly by the game.

## Versioning and the two release folders

The mod ships multiple version-specific folders under `Contents/mods/ForagingTooltipExtended/`; the game loads the one matching the player's build (see `versionMin`/`versionMax` in each `mod.info`).

- `42/` — Build 42.12 through 42.14. Translations are legacy Lua `.txt` (`UI_EN.txt`, `IG_UI_EN.txt`).
- `42.15/` — Build 42.15+. Active development target. Translations are JSON (`UI.json`, `IG_UI.json`).

The Lua code in both folders is otherwise the same. When changing behavior, decide whether the fix applies to one build line or both, and mirror it into each folder that needs it. Translation edits must respect each folder's format (`.txt` vs `.json`).

The mod version lives in **two** places that must stay in sync on every release: `modversion=` in each `mod.info`, and `FTE_Utils.MOD_VERSION` in `FTE_Utils.lua`.

## Architecture

`FTE_Client.lua` is a slim orchestrator: on `OnGameStart` it calls `initialise()` on each module; on `OnCreateUI` it sets up mod options. Everything else is a feature module.

All modules extend `FTE_ModuleBase` (`Core/FTE_ModuleBase.lua`), which is the mod's stability model. Use its methods rather than touching the game directly:

- `module:initialise(setupLogic)` — runs setup inside `pcall`; on failure the module is permanently blacklisted and disabled, isolating the crash.
- `module:overrideFunction(target, name, newFn)` — patches a vanilla function with an auto-restoring wrapper. If the override throws at runtime, it restores the original, blacklists the module, and falls back to vanilla for that call. Idempotent per (target, name).
- `module:registerEvent(name, handler)` — wraps the handler in `pcall` and tracks it for clean removal in `destroy()`.

A module file derives the class, creates a single instance, and exports `{ initialise, destroy, isActive, getInstance }`. Live modules:

- `Modules/FTE_CoreTooltip.lua` — the main feature; rebuilds the foraging vision tooltip (patches `ISZoneDisplay:getVisionTooltipText`). Mandatory.
- `Modules/FTE_SearchRadiusDisplay.lua` — persistent radius readout next to the eye icon (patches `ISZoneDisplay:render`). Toggleable.
- `Modules/FTE_VisionAffectingItems.lua` — worn-item vision penalties shown in the tooltip.

`FTE_Utils.lua` holds shared state and helpers: `MOD_VERSION`, the color schema (`Colors`, built from the game's good/bad highlight colors), logging (`logInfo/logWarning/logError/logDebug`, gated by a `DEBUG_MODE` flag), number/percent formatting, and the cached `tooltipLayout` metrics. Tooltip text is assembled with PZ rich-text markup (`<RGB>`, `<SETX>`, `<LINE>`, `<IMAGE>`); tags must be space-separated and RGB values are 0.0–1.0.

`FTE_ModOptions.lua` defines the in-game options via `PZAPI.ModOptions` (persistent-radius toggle, tooltip value alignment).

Radius math mirrors vanilla `ISSearchManager` (`getOverlayRadius`, `updateModifiers`, `minRadius`/`maxRadius`/`maxRadiusCap`, `perkLevel`) so the breakdown matches what the game computes — do not invent independent formulas.

## Code conventions

- Prefix everything (`FTE_`) — file names, module classes, option keys.
- LuaLS/EmmyLua annotations (`---@param`, `---@return`, `---@class`) on functions; terse and type-focused, not prose. For vanilla classes you add fields to, declare an extended `---@class X : VanillaClass` instead of `---@diagnostic disable` suppressions.
- Section large files with `-- ===== SECTION NAME ===== --` banners.
- Reach for `pcall`/`or`-fallbacks only where data can genuinely be missing (mod options, optional item properties). Guaranteed game singletons (`getPlayer()`, `forageSystem`, `ScriptManager.instance`) should fail fast, not be defensively guarded.
- `table.concat` for tooltip building / loops; plain `..` for short 2–4 part strings. Numeric `for i = 1, #t do` over `ipairs` for arrays.
- No emojis in code, comments, or docs.

## Changelogs and release

Two changelogs are maintained: `CHANGELOG.md` (repo, newest-first) and `Contents/mods/ForagingTooltipExtended/common/ChangeLog.txt` (in-game format, oldest-first, blocks delimited by `[ ------ ]`). Update user-facing changes in both. The Steam Workshop description lives in `workshop_description.bbcode` / `workshop.txt` and uses Steam BBCode, not Markdown.

## Looking up vanilla behavior

To read vanilla source the mod patches (foraging `ISZoneDisplay`, `ISRichTextPanel`, etc.), use the local context repo at `C:\games\pz-modding-llm-context` (decompiled Java under `decompiled/zombie/`, game Lua under `game/media/lua/`). Shared mod structure/conventions live in the template at `C:\games\pz-mod-template-ivmakk`. The repo no longer vendors local `PZ_files/` or `Mods_Refs/` copies.

## Testing

In-game only — no automated tests, and do not create test files or testing-guide documents. The maintainer tests manually in Project Zomboid; Lua changes can be hot-reloaded from the debug console (F11) without restarting.

## Note for Copilot

Detailed task workflows (release, localization, multi-version, build upgrade, rich-text markup) now live as Claude Code skills in `.claude/skills/`. The previous `.github/prompts/` and `.github/instructions/` subfiles were removed after migrating to those skills; this file is the single Copilot-facing instruction document.
