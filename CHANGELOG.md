# Changelog

## [2.2.2] - 2026-08-07
### Changed
- Dropped Build 42.12-42.14 support; consolidated to a single 42.15+ version folder

## [2.2.1] - 2026-03-15
### Changed
- Updated for Build 42.14 compatibility: increased versionMax

## [2.2.0] - 2026-03-15
### Changed
- Updated for Build 42.15 compatibility: translation files converted from Lua .txt format to .json

## [2.1.1] - 2025-12-16
### Added
- Multi-version support: added back support for Build 42.12.3 (and future 42.12.x versions) with separate support for Build 42.13+ builds

## [2.1.0] - 2025-12-13
### Changed
- Updated for Build 42.13 compatibility

## [2.0.0] - 2025-11-12
### Added
- Vision-affecting worn items display with icons and individual penalties
- Persistent search radius display next to eye icon (toggleable)
- Tooltip layout options: right-aligned (default) or left-aligned values

### Changed
- Complete modular architecture refactor with fault-isolated modules
- Fully reworked tooltip layout with cleaner visual hierarchy
- Simplified mod options from 6 to 2
- Zero-value bonuses now automatically hidden

### Removed
- "Show Min/Max Values" mod option (min/max indicators already shown via color-highlighting in radius display)
- "Show Items View Distance" mod option and feature (view distance estimates for small/medium/large items)
- "Show Zero Trait Bonuses" mod option (zero-value trait/profession bonuses now always hidden for cleaner display)
- "Show Zero Food Detection Bonus" mod option (food detection section now always hidden when hunger bonus is zero)

### Fixed
- Food Detection section now properly hides when bonus is zero and option is disabled

## [1.1.2] - 2025-06-28
### Changed
- "Show Items View Distance" option is now disabled by default (search radius is more impactful for foraging)

### Fixed
- State Penalties section now appears when penalties are non-neutral, not just when "Show Zero Penalties" option is enabled
- "Show Zero Penalties" option now properly filters individual penalty items instead of hiding the entire section
- Food Detection bonus no longer incorrectly shows green color for zero/negligible values

## [1.1.1] - 2025-06-27
### Changed
- Renamed Mod Option from "Show View Distance Estimate" to "Show Items View Distance"
  
## [1.1.0] - 2025-06-27
### Added
- Functionality to display estimated view distances for small, medium, and large items
- Food search bonus based on Hunger level

### Changed
- Refactored growing codebase and extracted Utilities file

### Fixed
- Unused mod option "Show Zero Penalties" (previously, "Show Zero Trait Bonuses" was incorrectly used instead)
- Minor typos in localizations (EN)

## [1.0.1] - 2025-06-25
### Changed
- Improved mod options menu to reflect the order of items on tooltip.
- Prepared materials for Steam (images, icon, etc.).

## [1.0.0] - 2025-06-24
### Added
- Initial mod published to Steam.