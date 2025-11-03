---
applyTo: '**/common/ChangeLog.txt'
---

# Changelog Alert System Guide

## Purpose
- Use `ChangeLog.txt` in the `common/` folder for in-game changelog alerts
- This format is used by mods that display changelog notifications directly in the game UI
- The file is read by alert systems to show players what's new when they load the game
- Located in `common/` folder to support Build 42+ (older builds used `media/`)

## File Location
**Required Path**: `Contents/mods/CleanUIExtension/common/ChangeLog.txt`

## Format Requirements

### Entry Structure
Each changelog entry follows this format:
```
[ DATE - VERSION ]
Added:
- Feature 1
- Feature 2
Fixed:
- Bug fix 1
[ ------ ]
```

### Format Rules
1. **Date Header**: Wrap version and date in square brackets `[ v[VERSION] - YYYY-MM-DD ]`
   - Version format: `v[VERSION]` (e.g., `v1.2.0`)
   - Date format: `YYYY-MM-DD` (e.g., `2025-10-05`)
   - For multiple updates same day: `[ v1.2.0 #2 - 2025-10-05 ]`

2. **Content Sections** (use same structure as CHANGELOG.md):
   - Use section headers: `Added:`, `Changed:`, `Deprecated:`, `Removed:`, `Fixed:`, `Security:`
   - Only include sections that have content
   - Each section followed by bullet points
   - Use hyphens (`-`) for bullet points
   - Keep descriptions clear and user-friendly

3. **Entry Separator**: End each entry with `[ ------ ]` on its own line

4. **Order**: **Oldest entries at the TOP, newest at the BOTTOM** (chronological order)
   - This is the OPPOSITE of CHANGELOG.md (which has newest first)
   - The alert system displays entries in reverse, so oldest-first results in newest-first display
   - When adding a new version, append it to the BOTTOM of the file

### Optional: Alert Configuration
Add custom buttons/links at the top of the file:
```
[ ALERT_CONFIG ]
link1 = Button Text = URL,
link2 = Another Button = URL,
[ ------ ]
```

**URL Requirements**:
- Steam Community links: Direct URLs allowed
- External links: Must use Steam's link filter: `https://steamcommunity.com/linkfilter/?u=YOUR_URL`
- Well-known sites (GitHub, Steam, etc.) are automatically styled with logos

## Content Guidelines
1. **User-Facing Only**: Focus on changes players will notice
2. **Clear Language**: Avoid technical jargon when possible
3. **Structured Sections**: Use `Added:`, `Changed:`, `Fixed:`, etc. to match CHANGELOG.md structure
4. **Concise**: Keep entries brief but informative
5. **Date Format**: Always use YYYY-MM-DD format (ISO 8601) for consistency

## Synchronization with Other Changelogs
- **CHANGELOG.md**: Main project changelog in standard Keep a Changelog format
- **workshop_updates.txt**: Plain text version for Steam Workshop descriptions
- **ChangeLog.txt**: In-game alert system format (this file)

All three should contain the same information, just formatted differently for their respective purposes.

## Example Entry
```
[ v1.2.0 - 2025-10-05 ]
Added:
- SmarterStorage mod compatibility (context menu, custom container colors)
- B42.11 compatibility bridge for improved mod interoperability (parent hierarchy handling)
- Mod version logging on initialization
Fixed:
- Context menu errors when right-clicking Proximity Inventory mod icon
[ ------ ]
```

## Release Workflow
When releasing a new version:
1. Update CHANGELOG.md with new version (add at top, newest first)
2. Update workshop_updates.txt with plain text version (add at top, newest first)
3. Update ChangeLog.txt with in-game alert format (add at BOTTOM, oldest first)
4. Ensure all three files contain the same core information
5. ChangeLog.txt must be in `Contents/mods/CleanUIExtension/common/`
