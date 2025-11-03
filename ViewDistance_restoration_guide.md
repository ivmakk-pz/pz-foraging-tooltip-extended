# ViewDistance Feature Restoration Guide

## Overview
This guide explains how to restore the Items View Distance feature that was removed in commit 7395469.

## Restoration Method

Simply revert the removal commit:

```bash
# Revert the removal commit (creates a new commit that restores the feature)
git revert 7395469
```

Or cherry-pick the state before removal:

```bash
# Cherry-pick the commit right before removal
git cherry-pick 29ba859
```

## Reference Commits
- **Removal Commit**: `7395469` - Remove Items View Distance feature
- **Last Working State**: `29ba859` - Save current changes before ViewDistance removal
- **Original Implementation**: `b501b01` - Added: Implement ViewDistance module

## What Gets Restored

All code, options, translations, and documentation related to the Items View Distance feature will be restored, including:

1. `FTE_ViewDistance.lua` module
2. Client integration in `FTE_Client.lua`
3. Mod option in `FTE_ModOptions.lua`
4. Tooltip integration in `FTE_CoreTooltip.lua`
5. All translation entries (UI_EN.txt, IG_UI_EN.txt)
6. Workshop description updates

## Verification

After restoration, verify everything is back:

```bash
git status
git log --oneline -3
```

