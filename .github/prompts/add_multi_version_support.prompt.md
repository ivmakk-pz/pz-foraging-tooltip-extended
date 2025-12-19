---
agent: agent
description: This prompt is used to add multi-version support to a Project Zomboid mod, enabling it to support multiple game builds (e.g., stable 42.12.x and unstable 42.13+) simultaneously.
---

# Add Multi-Version Support to Project Zomboid Mod

Please implement multi-version support for this Project Zomboid mod to support multiple game builds simultaneously (e.g., stable 42.12.x and unstable 42.13+).

## Context

Project Zomboid uses version-specific folders to automatically load the appropriate mod version based on the player's game build. This allows a single workshop item to serve players on different game versions.

## Task: Implement Multi-Version Structure

### Step 1: Analyze Current Structure

First, determine the current mod structure:
- Identify existing version folder (e.g., `42/`, `42.13/`, or other)
- Note the current mod version from `mod.info`
- Understand which game build is currently supported

### Step 2: Create Version Folders

Create the multi-version folder structure:

```
Contents/mods/{ModName}/
├── 42.13/                    # Latest development version (Build 42.13+)
│   ├── mod.info
│   ├── media/
│   │   └── lua/
│   │       ├── client/
│   │       ├── server/
│   │       └── shared/
│   └── [other assets]
│
├── 42.12/                    # Stable/legacy version (Build 42.12.x)
│   ├── mod.info
│   ├── media/
│   │   └── lua/
│   │       ├── client/
│   │       ├── server/
│   │       └── shared/
│   └── [other assets]
│
└── common/                   # Shared assets (required, can be empty)
```

**Critical Rules:**
- **Folder names must be exact version numbers**: `42.13`, `42.12` (NOT `42` or `42.x`)
- **Both version folders are required** for proper game detection
- **common/ folder is mandatory** even if empty

### Step 3: Populate Version Folders

**For 42.13/ folder (active development):**
- If migrating from existing `42/` folder: Move all files from `42/` to `42.13/`
- If creating new: Copy current mod files to `42.13/`
- This will be your active development folder

**For 42.12/ folder (stable version):**
- Copy files from `42.13/` to create initial stable snapshot
- Or use a specific stable version tag/commit if available
- This folder should remain read-only except for critical fixes

**For common/ folder:**
- Create the folder (can be empty)
- Optionally add shared assets that work across all versions

### Step 4: Configure mod.info Files

**CRITICAL: Both mod.info files must have IDENTICAL `modversion` and `id` values**

**42.13/mod.info** (for Build 42.13+):
```ini
name=Your Mod Name
id=Author_ModID
poster=poster.png
icon=icon.png
author=yourname
description=Your mod description
tags=Build 42
modversion=X.Y.Z          # Same version as 42.12
incompatible=            # If applicable
versionMin=42.13         # Minimum: 42.13
# NO versionMax - supports all future 42.13.x versions
```

**42.12/mod.info** (for Build 42.12.x):
```ini
name=Your Mod Name
id=Author_ModID
poster=poster.png
icon=icon.png
author=yourname
description=Your mod description
tags=Build 42
modversion=X.Y.Z          # Same version as 42.13
incompatible=            # If applicable
versionMin=42.12.0       # Minimum: 42.12.0
versionMax=42.12.99      # Maximum: 42.12.99 (locks to 42.12.x)
```

**Key Differences:**
- 42.13: `versionMin=42.13`, NO `versionMax`
- 42.12: `versionMin=42.12.0`, `versionMax=42.12.99`

### Step 5: Update Version Constants (if applicable)

If your mod has Lua version constants, update them in BOTH folders:

**42.13/media/lua/client/YourMod_Utils.lua:**
```lua
YourMod.MOD_VERSION = "X.Y.Z"  -- Keep synchronized
```

**42.12/media/lua/client/YourMod_Utils.lua:**
```lua
YourMod.MOD_VERSION = "X.Y.Z"  -- Same value as 42.13
```

### Step 6: Update Documentation

Update these files to reflect multi-version support:

1. **README.md**: Add note about multi-version support
   ```markdown
   ## Compatibility
   This mod supports multiple game versions:
   - Build 42.13+ (unstable/beta)
   - Build 42.12.x (stable)
   
   The game automatically loads the appropriate version.
   ```

2. **CHANGELOG.md**: Add entry for multi-version support
   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD
   ### Added
   - Multi-version support: added back support for Build 42.12.3 (and future 42.12.x versions) with separate support for Build 42.13+ builds
   ```

3. **Update workshop description** to mention multi-version support

### Step 7: Update .github Files

**IMPORTANT:** Update all references in .github folder to reflect the new multi-version structure:

1. **Update .github/instructions/*.instructions.md files**:
   - Find all references to `Contents/mods/{ModName}/42/`
   - Replace with `Contents/mods/{ModName}/42.13/`
   - Ensure documentation accurately reflects the 42.12 and 42.13 folder structure
   - Update any diagrams, examples, or file paths that mention version folders

2. **Update .github/prompts/*.prompt.md files**:
   - Update `add_localization.prompt.md` to reference both version folders
   - Update `release.prompt.md` to include steps for updating both mod.info files
   - Update any other prompts that reference mod folder structure
   - Change all `42/` paths to `42.13/` where applicable

3. **Search and verify**:
   - Use grep/search to find any remaining references to old folder structure
   - Verify all paths point to correct version folders (42.13 or 42.12)
   - Ensure no stale references to generic `42/` folder remain

**Example changes needed:**
- `Contents/mods/{ModName}/42/media/lua/` → `Contents/mods/{ModName}/42.13/media/lua/`
- File structure diagrams showing `42/` → Update to show `42.13/` and `42.12/`
- Release instructions mentioning one mod.info → Update to mention both mod.info files

### Step 8: Clean Up Old Structure

If migrating from single-version:
- Delete old version folder (e.g., `42/`) after moving files to `42.13/`
- Verify no references to old folder paths remain

### Step 8: Clean Up Old Structure

If migrating from single-version:
- Delete old version folder (e.g., `42/`) after moving files to `42.13/`
- Verify no references to old folder paths remain

### Step 9: Validation Checklist

Verify the implementation:
- [ ] Folder structure matches required layout (42.13/, 42.12/, common/)
- [ ] Folder names use exact version numbers (not generic `42`)
- [ ] Both mod.info files exist with correct settings
- [ ] Both mod.info files have IDENTICAL `modversion`
- [ ] Both mod.info files have IDENTICAL `id`
- [ ] 42.13/mod.info has `versionMin=42.13` and NO `versionMax`
- [ ] 42.12/mod.info has `versionMin=42.12.0` and `versionMax=42.12.99`
- [ ] common/ folder exists (even if empty)
- [ ] All mod files are present in both version folders
- [ ] Version constants (if any) are synchronized
- [ ] Documentation updated to mention multi-version support
- [ ] All .github/instructions/*.instructions.md files updated with correct paths
- [ ] All .github/prompts/*.prompt.md files updated with correct paths
- [ ] No references to old `42/` folder remain in documentation

## Expected Result

After implementation:
- Mod supports both Build 42.12.x and 42.13+ from single workshop item
- Game automatically loads correct version folder based on player's build
- Players on 42.12.x use stable version from 42.12/ folder
- Players on 42.13+ use latest version from 42.13/ folder
- Both versions show same mod version number to avoid confusion

## Future Maintenance

**For releases:**
- Update `modversion` in BOTH mod.info files (keep synchronized)
- Update version constants in BOTH folders (keep synchronized)
- Develop new features in 42.13/ folder only
- Only modify 42.12/ for critical backported fixes

**For testing:**
- Test on Build 42.13+ (should load from 42.13/ folder)
- Test on Build 42.12.x (should load from 42.12/ folder)
- Verify correct folder is loaded in each case

## Common Pitfalls to Avoid

1. **Wrong folder names**: Using `42` instead of `42.13` - game won't detect properly
2. **Mismatched modversion**: Different versions in each mod.info causes confusion
3. **Missing common/ folder**: Mod may fail to load
4. **Wrong version ranges**: Incorrect versionMin/versionMax causes wrong folder to load
5. **Forgetting to update both mod.info**: Only updating one version during releases

## Additional Notes

- This is a ONE-TIME migration task
- After implementation, maintain both folders during releases
- 42.13/ is active development, 42.12/ is stable/legacy
- Workshop upload includes entire Contents/mods/ structure with all version folders

---

**Execute this migration now to add multi-version support to the mod.**
