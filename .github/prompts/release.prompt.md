# Release Automation Prompt

## Instructions
This prompt automates the release process for your mod. Execute these steps in order:

## Step 1: Determine Release Version
- **If on a release branch** (e.g., `release/1.2.1`): Extract version from branch name
- **If on main/master branch**: Determine next version based on changes (patch/minor/major)
- **Version Format**: Use semantic versioning (e.g., 1.2.1)

## Step 2: Verify and Update Changelog
1. **Check CHANGELOG.md**:
   - Ensure `## [Unreleased]` section exists with pending changes
   - If no unreleased changes exist, review recent commits and add appropriate entries
   - Move unreleased changes to new version section with today's date

2. **Update workshop_updates.txt**:
   - Add corresponding plain text version entry for Steam Workshop
   - Ensure formatting matches the plain text changelog format (no markdown)
   - Use format: `v[VERSION] - YYYY-MM-DD`

3. **Update common/ChangeLog.txt**:
   - Add new version entry at the BOTTOM (oldest first for file order, displays newest first in-game)
   - Use format: `[ v[VERSION] - YYYY-MM-DD ]`
   - Include same content as CHANGELOG.md but without markdown formatting
   - End entry with `[ ------ ]` separator

## Step 3: Update Version References
Update version in these files:

1. **mod.info files** (BOTH version folders):
   - `Contents/mods/ForagingTooltipExtended/42.13/mod.info` (Build 42.13+)
   - `Contents/mods/ForagingTooltipExtended/42.12/mod.info` (Build 42.12.x)
   - Update `modversion=` field in both files to keep versions consistent

2. **README.md**: Update version badge `![Mod Version](https://img.shields.io/badge/Version-<VERSION>-blue)`

3. **FTE_Utils.lua** (Build 42.13+ only):
   - `Contents/mods/ForagingTooltipExtended/42.13/media/lua/client/FTE_Utils.lua`
   - Update `FTE_Utils.MOD_VERSION` constant
   - Note: 42.12 folder has its own FTE_Utils.lua at v2.0.0 (do not modify unless backporting)

## Step 4: Validation
- Verify all files have consistent version numbers
- Ensure changelog entries are properly formatted
- Check that workshop_updates.txt matches CHANGELOG.md content for the new version

## Step 5: Current State Analysis
Before making changes, analyze:
- Current version in mod.info
- Latest version in CHANGELOG.md
- Any unreleased changes
- Git branch context (if available)

## Expected Outcome
After execution:
- All version references are consistent
- CHANGELOG.md has proper version entry with today's date
- workshop_updates.txt has corresponding plain text entry
- Unreleased section is empty or removed
- Ready for Steam Workshop upload

---

**Execute this release process now for the current state of the repository.**