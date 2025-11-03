# Feature Plan: Vision-Affecting Items Display in Tooltip

## Overview
Add a new optional module to display clothing/items that affect search radius as **level 2 items under the existing "Clothing" penalty line** in the foraging tooltip, showing each item with its icon and vision modifier value.

### Tooltip Placement
```
E. State Penalties: 0.93
├─ Exhaustion: 0.93
├─ Panic: 1.00
├─ Body Damage: 1.00
└─ Movement: 1.00

F. Clothing Effect: 0.75              ← NEW SECTION
├─ [Icon] Gas Mask: 0.50              ← Level 1 item (use "-" prefix)
├─ [Icon] Sunglasses: 0.98            ← Level 1 item (use "-" prefix)
└─ [Icon] Riot Helmet: 0.75           ← Level 1 item (use "-" prefix)
```

**Key Design Decisions**: 
1. **Clothing is separate F section** to allow clean level 1 item display
2. Items appear as level 1 entries directly under "F. Clothing Effect" using **"-"** prefix
3. Only shown when clothing penalty < 1.00 (vision-affecting items are worn)

---

## Technical Feasibility Analysis

### Available Technologies

#### 1. **ISRichTextPanel** (Rich Text Rendering)
- **Location**: `PZ_files/ISRichTextPanel.lua`
- **Capabilities**:
  - Inline image embedding: `<IMAGE:textureName>`
  - Color formatting: `<RGB:r,g,b>`, `<PUSHRGB>`, `<POPRGB>`
  - Text formatting: `<H1>`, `<H2>`, `<TEXT>`, `<LINE>`, `<BR>`
  - Alignment: `<CENTRE>`, `<LEFT>`, `<RIGHT>`
  - Dynamic width/height calculation
  - Built-in progress bars and layouts
- **Use Case**: Perfect for embedding item icons with text descriptions

#### 2. **InventoryItem Java Class**
- **Location**: `PZ_files/java/InventoryItem.java`
- **Key Methods**:
  ```java
  item:getTexture()           // Main texture
  item:getIcon()              // Icon texture  
  item:getDisplayName()       // Localized name
  item:getFullType()          // Module.ItemName
  ```
- **Use Case**: Access item icons and names for display

#### 3. **Existing Clothing Penalty System**
- **Location**: `PZ_files/forageSystem.lua` (lines 2057-2071)
- **Function**: `forageSystem.getClothingPenalty(_character)`
- **Data Source**: `forageSystem.clothingPenalties` table
- **Implementation**:
  ```lua
  local wornItems = character:getWornItems()
  for wornItem in iterList(wornItems) do
      local location = wornItem:getLocation()
      local penalty = forageSystem.clothingPenalties[location] or 0
  end
  ```
- **Penalty Values**:
  - FullSuitHead/FullHat: 75% penalty
  - MaskFull/SCBA: 50% penalty
  - MaskEyes/Mask: 20% penalty
  - Eyes/LeftEye/RightEye: 2.5% penalty

---

## Implementation Plan

### Phase 1: Data Collection Module
**File**: `FTE_VisionAffectingItems.lua` (new module)

#### Task 1.1: Create Base Module Structure
- [x] Create new module class extending `FTE_ModuleBase`
- [x] Add module registration in `FTE_Client.lua`
- [x] Follow existing module patterns (FTE_CoreTooltip, FTE_ViewDistance)

#### Task 1.2: Implement Worn Items Detection
- [x] Create function `getVisionAffectingItems(character)`
  - Get all worn items: `character:getWornItems()`
  - Filter items with clothing location penalties
  - Return table with: `{item, location, penaltyPercent, multiplier}`

#### Task 1.3: Add Sorting Logic
- [x] Sort items by penalty severity (highest first)
- [x] Optionally group by item type (headwear, eyewear, etc.)
- [x] Handle edge cases (no items, all items zero penalty)

**Example Data Structure**:
```lua
{
    {
        item = <InventoryItem>,
        location = "MaskFull",
        penaltyPercent = 50,
        multiplier = 0.50,  -- calculated from penalty
        iconTexture = <Texture>,
        displayName = "Gas Mask"
    }
}
```

---

### Phase 2: Rich Text Tooltip Builder
**File**: `FTE_VisionAffectingItems.lua` (continued)

#### Task 2.1: Implement Icon + Text Formatter
- [x] Create function `buildItemsList(character)`
- [x] Return formatted string for level 2 items
- [x] Use proper indentation: **"--"** prefix (spaces don't render in rich text)
- [x] Format: `"-- <IMAGE:icon> ItemName: X.XXx <LINE> "`
  ```lua
  local parts = {}
  for _, data in ipairs(itemsData) do
      local line = "--"  -- Level 2 indentation (double dash)
      line = line .. " <IMAGE:" .. data.iconTexture:getName() .. "> "
      line = line .. data.displayName .. ": "
      line = line .. getColorForPenalty(data.penaltyPercent)
      line = line .. string.format("%.2fx", data.multiplier)
      line = line .. " <LINE> "
      table.insert(parts, line)
  end
  return table.concat(parts)
  ```
  
**Important**: Use `"--"` not `"  - "` because leading spaces are stripped in rich text rendering

#### Task 2.2: Add Color Coding Logic
- [x] Implement `getColorForPenalty(penaltyPercent)`
  - Red (bad): Penalty > 0% (negative effect on vision)
  - Green (good): Penalty <= 0% (positive effect on vision, if any exist)
- [x] Use FTE_Utils existing color constants (good/bad)

#### Task 2.3: Handle Zero/Minimal Penalties
- [x] Filter out items with no effect (< 0.01% penalty)
- [x] Only show items that actually affect vision
- [x] Support showZeroPenalty option for debugging/testing if needed

---

### Phase 3: Integration with Tooltip System
**File**: `FTE_CoreTooltip.lua` (modifications)

#### Task 3.1: Add Hook Point in Penalties Section
- [x] Modify `buildPenaltiesText()` to reorder penalty items
- [x] **Move clothing to last position** in the penalty list
- [x] Insert level 2 items immediately after "Clothing: X.XX" line
- [x] Use **"--"** prefix for level 2 indentation (not spaces)
- [x] Call new module's `buildItemsList()` function
- [x] Only show items when clothing penalty < 1.00

**Implementation Steps**:
1. Reorder `penaltyItems` array in `buildPenaltiesText()`:
   ```lua
   local penaltyItems = {
       {modifier = _modifiers.exhaustionPenalty, textKey = "..."},
       {modifier = _modifiers.panicPenalty, textKey = "..."},
       {modifier = _modifiers.bodyPenalty, textKey = "..."},
       {modifier = _modifiers.movementPenalty, textKey = "..."},
       {modifier = _modifiers.clothingPenalty, textKey = "..."}, -- LAST
   }
   ```

2. Add item expansion after clothing line:
   ```lua
   -- After adding clothing to subItems:
   if modifiers.clothingPenalty < 1.0 then
       local itemsText = FTE_VisionAffectingItems.buildItemsList(character)
       if itemsText then
           table.insert(subItems, itemsText)
       end
   end
   ```

**Note**: Use `"--"` for level 2, not `"  - "` (spaces are stripped)

#### Task 3.2: Add Mod Options
**File**: `FTE_ModOptions.lua`
- [x] ~~Add toggle: "Show Vision-Affecting Items" (default: OFF)~~ **REMOVED - Feature always enabled**
- [x] ~~Add toggle: "Show Items with Zero Penalty" (default: OFF)~~ **REMOVED - Hardcoded to false**
- [x] ~~Add option: "Sort Order" (Severity/Name/Type)~~ **REMOVED - Hardcoded to "severity"**
- [x] ~~Add localization keys to translation files~~ **REMOVED - Not needed**

**Decision**: Removed all mod options to keep the feature simple and non-overwhelming. The feature now:
- Always shows when clothing penalty < 1.0 (vision-affecting items are worn)
- Only shows items with actual penalties (showZeroPenalty = false)
- Always sorts by severity (highest penalty first)
- No user configuration needed

#### Task 3.3: Performance Optimization
- [ ] Cache item icons on first access
- [ ] Only recalculate when worn items change
- [ ] Add debug logging for troubleshooting

---

### Phase 4: Edge Cases & Polish

#### Task 4.1: Handle Special Cases
- [ ] No items worn → Skip section entirely
- [ ] All items have zero penalty → Show message or skip
- [ ] Multiple items same location → Combine penalties correctly
- [ ] Modded items with custom locations → Graceful fallback

#### Task 4.2: Icon Size & Layout
- [ ] Ensure icons scale properly (16x16 or 32x32)
- [ ] Test with long item names (wrap if needed)
- [ ] Verify alignment with existing tooltip sections

#### Task 4.3: Error Handling
- [ ] Add pcall protection around item access
- [ ] Fallback to text-only if icon missing
- [ ] Log errors in DEBUG_MODE only

---

### Phase 5: Testing & Documentation

#### Task 5.1: In-Game Testing Scenarios
- Wear full hazmat suit (high penalty)
- Wear sunglasses only (low penalty)
- Wear combination of items
- Test with modded clothing items
- Verify performance with many worn items

#### Task 5.2: Update Documentation
- [ ] Update README.md with feature description
- [ ] Add screenshots showing new tooltip section
- [ ] Document mod options in user guide
- [ ] Update CHANGELOG.md for release

---

## Technical Challenges & Solutions

### Challenge 1: ISRichTextPanel vs Plain Text Tooltip
**Problem**: Current tooltip uses concatenated strings, not ISRichTextPanel  
**Solution**: 
- Use inline `<IMAGE:>` tags in string concatenation
- ISZoneDisplay already supports rich text rendering
- No need to create separate ISRichTextPanel instance

### Challenge 2: Accessing Item Icons
**Problem**: Need Texture object from InventoryItem  
**Solution**:
```lua
local item = wornItem:getItem()
local icon = item:getIcon()  -- Returns Texture object
local iconName = icon:getName()  -- Use in <IMAGE:iconName>
```

### Challenge 3: Texture Name Format
**Problem**: Icon names may need path/format conversion  
**Solution**:
- Test with vanilla items first
- Add path normalization function if needed
- Fallback to item type name if texture unavailable

### Challenge 4: Performance Impact
**Problem**: Tooltip rendered every frame in search mode  
**Solution**:
- Cache results until worn items change
- Add dirty flag: recalculate only on clothing change
- Benchmark with 10+ worn items

---

## Module Architecture

```
FTE_VisionAffectingItems (new module)
├── Data Collection
│   ├── getVisionAffectingItems(character) → itemsData[]
│   ├── calculateItemPenalty(wornItem) → penaltyData
│   └── sortItems(itemsData, sortMode) → sortedData
│
├── Text Building
│   ├── buildItemsList(character) → richTextString (level 2 format)
│   ├── formatItemEntry(itemData) → richTextLine
│   └── getColorForPenalty(percent) → rgbString
│
└── Integration
    ├── shouldShowItems(clothingPenalty) → boolean
    ├── getModOptions() → options
    └── clearCache() → void
```

**Integration Point**: Hooks into `buildPenaltiesText()` immediately after the Clothing penalty line

---

## Mod Options Schema

```lua
FTE_ModOptions = {
    showVisionItems = {
        name = "Show Vision-Affecting Items",
        tooltip = "Display clothing that affects search radius",
        default = false,
        type = "boolean"
    },
    showZeroPenaltyItems = {
        name = "Show Items with Zero Penalty",
        tooltip = "Include worn items that don't affect vision",
        default = false,
        type = "boolean"
    },
    visionItemsSortOrder = {
        name = "Sort Vision Items By",
        tooltip = "How to order items in the list",
        default = 1,
        type = "enum",
        values = {"Severity", "Name", "Type"}
    }
}
```

---

## Localization Keys Required

```
EN/IG_UI_EN.txt:
- IGUI_FTE_VisionItems_Header = "Vision-Affecting Items:"
- IGUI_FTE_VisionItems_None = "No vision-affecting items worn"
- IGUI_FTE_VisionItems_Penalty = "Penalty"
- IGUI_FTE_VisionItems_Multiplier = "Multiplier"

EN/UI_EN.txt:
- UI_FTE_ModOptions_ShowVisionItems = "Show Vision-Affecting Items"
- UI_FTE_ModOptions_ShowVisionItems_Tooltip = "Display clothing that affects search radius with icons"
- UI_FTE_ModOptions_ShowZeroPenaltyItems = "Show Items with Zero Penalty"
- UI_FTE_ModOptions_ShowZeroPenaltyItems_Tooltip = "Include all worn items, even those without vision penalty"
- UI_FTE_ModOptions_VisionItemsSortOrder = "Sort Vision Items By"
- UI_FTE_ModOptions_SortOrder_Severity = "Penalty Severity"
- UI_FTE_ModOptions_SortOrder_Name = "Item Name"
- UI_FTE_ModOptions_SortOrder_Type = "Item Type"
```

---

## Example Output (Rich Text Format)

```
E. State Penalties: 0.93
- Exhaustion: 0.93
- Panic: 1.00
- Body Damage: 1.00
- Movement: 1.00
- Clothing: 0.75                    ← Last in list
-- [GasMask Icon] Gas Mask: 0.50x   ← Level 2 (double dash)
-- [Helmet Icon] Riot Helmet: 0.75x ← Level 2 (double dash)
```

**Notes**: 
- Clothing is positioned **last** in E. State Penalties to allow expansion
- Level 2 items use **"--"** prefix (spaces don't render in rich text)
- Items only appear when clothing penalty < 1.00 (vision-affecting items are worn)

---

## Timeline Estimate

- **Phase 1** (Data Collection): 2-3 hours
- **Phase 2** (Rich Text Builder): 3-4 hours
- **Phase 3** (Integration): 2-3 hours
- **Phase 4** (Edge Cases): 2-3 hours
- **Phase 5** (Testing/Docs): 2-3 hours

**Total**: 11-16 hours of development time

---

## Success Criteria

- [ ] Items displayed with correct icons
- [ ] Penalties accurately reflect game calculations
- [ ] Color coding matches penalty severity
- [ ] Mod options work as expected
- [ ] No performance degradation
- [ ] Works with vanilla and modded items
- [ ] Graceful handling of edge cases
- [ ] Proper localization support

---

## Future Enhancements (Out of Scope)

1. **Interactive Icons**: Click to see item details
2. **Comparison Mode**: Show before/after penalties
3. **Item Suggestions**: Recommend better alternatives
4. **Historical Tracking**: Log penalty changes over time
5. **Export to File**: Save item analysis to text file

---

## References

- **ISRichTextPanel Documentation**: `PZ_files/ISRichTextPanel.lua`
- **InventoryItem API**: `PZ_files/java/InventoryItem.java`
- **Clothing Penalty System**: `PZ_files/forageSystem.lua:2057-2071`
- **Existing Module Patterns**: `Contents/mods/ForagingTooltipExtended/42/media/lua/client/Modules/`
- **Mod Options Framework**: `FTE_ModOptions.lua`

---

**Document Version**: 1.0  
**Created**: 2025-11-03  
**Status**: Planning Phase
