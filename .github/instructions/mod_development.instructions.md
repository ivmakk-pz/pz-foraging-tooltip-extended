````instructions
---
applyTo: '**/*.lua'
---
## Function Documentation Guidelines:
- Use LuaLS/EmmyLua type annotations for all functions (---@param, ---@return, ---@type).
- Include descriptive comments explaining what each function does.
- Keep parameter and return descriptions concise - avoid verbose/redundant explanations.
- If the function name/purpose is clear, don't repeat it in parameter descriptions.
- Common parameters (character, searchManager, etc.) don't need detailed explanations each time.
- If accurate types cannot be determined, use `unknown` as the type and notify about it.
- Example:
```lua
---Calculates the vision bonus multiplier for foraging
---@param player IsoPlayer
---@param modifiers table
---@return number
local function calculateVisionBonus(player, modifiers)
```

## Mod Options Guidelines:
- **DO NOT** automatically create new mod options or localizations unless explicitly requested by the user.
- When implementing new features, focus only on the core functionality first.
- Mod options and language entries should be created as a separate step when the user specifically asks for them.
- When adding new mod options, don't add separators unless explicitly requested.
- New option text labels and tooltips must be added to the language file (`UI_EN.txt`).
- Use positive statements for option names (e.g., "Show X" instead of "Skip X" or "Hide X").
- Follow the naming convention: `UI_options_FTE_<optionName>` for labels and `UI_options_FTE_<optionName>_tooltip` for tooltips.

## Mod Options API Quick Reference:
```lua
-- Create options object
local options = PZAPI.ModOptions:create("ModID", getText("UI_options_title"))

-- Add formatting elements
options:addTitle("Section Title")              -- Large header text
options:addDescription("Description text")     -- Small description text
options:addSeparator()                        -- Horizontal line

-- Add interactive options
local checkbox = options:addTickBox("id", getText("label"), defaultValue, getText("tooltip"))
local textField = options:addTextEntry("id", getText("label"), "defaultText", getText("tooltip"))
local keybind = options:addKeyBind("id", getText("label"), Keyboard.KEY_Z, getText("tooltip"))
local slider = options:addSlider("id", getText("label"), min, max, step, defaultValue, getText("tooltip"))
local colorPicker = options:addColorPicker("id", getText("label"), r, g, b, a, getText("tooltip"))
local button = options:addButton("id", getText("label"), getText("tooltip"), callbackFunction)

-- Dropdown/ComboBox
local dropdown = options:addComboBox("id", getText("label"), getText("tooltip"))
dropdown:addItem("Option 1", false)  -- Add dropdown items
dropdown:addItem("Option 2", true)   -- true = initially selected

-- Multiple checkbox group
local multiBox = options:addMultipleTickBox("id", getText("label"), getText("tooltip"))
multiBox:addTickBox("Sub Option 1", false)   -- Use getValue(1) to get this value
multiBox:addTickBox("Sub Option 2", true)    -- Use getValue(2) to get this value

-- Get option values
local value = checkbox:getValue()     -- Returns boolean for checkbox
local text = textField:getValue()     -- Returns string for text entry
local key = keybind:getValue()        -- Returns keyboard key constant
local number = slider:getValue()      -- Returns number within min/max range
local color = colorPicker:getValue()  -- Returns table {r, g, b, a}
local selected = dropdown:getValue()  -- Returns number (1-based index) for dropdown
local sub1 = multiBox:getValue(1)     -- Returns boolean for first sub-checkbox
```

## Debugging and Error Handling Guidelines:
- **Balanced Approach**: Use defensive programming judiciously based on data certainty.
- **Core Game Singletons**: No fallbacks needed for guaranteed game objects (getPlayer(), ScriptManager.instance, etc.).
- **Optional/Unknown Data**: Use fallbacks for data that might genuinely be missing (mod configs, optional item properties, etc.).
- **Fail Fast for Guaranteed Data**: Let functions crash immediately when core game APIs are invalid.
- **Minimal pcall Usage**: Only use pcall() for the main tooltip override to fallback to original on complete failure.
- **Smart Fallback Strategy**: Use `or` fallbacks only when data absence is a valid scenario.

### Examples:

**NO Fallback Needed (Guaranteed Singletons):**
```lua
-- Core game objects - always present
local player = getPlayer();
local scriptMgr = ScriptManager.instance;
local searchMgr = forageSystem.searchManager;
local perkLevel = player:getPerkLevel(Perks.Foraging);
```

**Fallback Appropriate (Optional/Unknown Data):**
```lua
-- Item properties that might not exist
local itemWeight = item:getActualWeight() or item:getUnequippedWeight() or 1.0;
-- Mod option values that might be missing
local showFeature = modOptions:getValue("showFeature") or false;
-- Dynamic data that could be nil
local zoneData = zone and zone:getModData() or {};
```

## Debug Mode Toggle:
The mod includes a `DEBUG_MODE` toggle variable at the top of `FTE_Client.lua` for easy switching between debug and production modes:

```lua
-- DEBUG MODE TOGGLE: Set to false for production safety mode
local DEBUG_MODE = true
```

**When DEBUG_MODE = true (Development):**
- Uses fail-fast approach with direct tooltip generation
- Errors surface immediately for easier debugging
- No fallback to original tooltip on failure

**When DEBUG_MODE = false (Production):**
- Uses pcall() safety wrapper around extended tooltip
- Falls back to original vanilla tooltip on any error
- Logs errors to console but maintains game stability

# String Concatenation Guidelines

## When to Use Each Approach

### Use `..` for simple concatenations:
- Small strings (2-4 parts)
- Helper functions
- When readability matters most

```lua
-- Good: Simple, readable
return " " .. Colors.white .. _text .. ": " .. value .. " <LINE> ";
local cacheKey = "size_" .. tostring(itemSize);
```

### Use `table.concat()` for complex building:
- Many parts (5+) or loops
- Main tooltip functions
- Performance-critical paths

```lua
-- Good: Complex tooltips
local parts = {"Header: ", value, " more parts..."}
return table.concat(parts)
```

## Loop Performance

### Use numeric `for` loops for arrays:
```lua
-- Slower: iterator-based
for i, v in ipairs(t) do
    print(v)
end

-- MUCH faster: numeric indexing
for i = 1, #t do
    local v = t[i]
    print(v)
end
```

## Code Section Organization

Use visual section separators for large files:
```lua
-- ===================================================================================================== --
-- SECTION NAME (ALL CAPS, DESCRIPTIVE)
-- ===================================================================================================== --
```

**Typical sections**: Constants/Imports → Helper Functions → Main Logic → Exports/Overrides

**Alternative styles**: `-` or `/` separators, but `=` is most visible and widely adopted.
````