# Foraging Tooltip Extended

![Mod Version](https://img.shields.io/badge/Version-2.2.3-blue)

[Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3507997225)

A client-side Project Zomboid Build 42 mod that rewrites the foraging "Vision Effectiveness" tooltip to break down every modifier affecting search radius, and optionally shows the current radius next to the eye icon during search mode.

## Features

- Replaces the vanilla single-number vision tooltip with a per-modifier breakdown (perk level, light, weather, moon, vision-affecting worn items, and the min/max radius caps) that mirrors the game's own `ISSearchManager` math.
- Optional persistent radius readout next to the eye icon while searching.
- In-game options for the persistent-radius toggle and tooltip value alignment.

## Installing

Subscribe on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3507997225). For a manual install, download a release from the [Releases](https://github.com/ivmakk-pz/pz-foraging-tooltip-extended/releases) page and copy the `ForagingTooltipExtended` folder into `%USERPROFILE%\Zomboid\mods\`.

Requires Build 42.15 or newer.

## Contributing

Issues and pull requests are welcome. The mod is pure Lua 5.1 (Project Zomboid's embedded runtime) with no build step - files are interpreted directly by the game. See `CLAUDE.md` for the architecture and conventions.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Licensed under the [GNU General Public License v3.0](LICENSE). Copyright (C) 2025 ivmakk.

You're free to use, study, and modify the code. If you distribute a modified version (including reuploading to the Steam Workshop), it must stay under GPL-3.0, keep this copyright and attribution, and make its full source available. Verbatim or barely-changed reuploads that strip credit violate the license - please don't. Contributions back to this repo are welcome.
