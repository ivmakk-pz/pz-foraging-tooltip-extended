---
applyTo: '**/*.lua'
---

## Project Structure

This workspace contains multiple directory structures with different purposes:

### Main Development Directory
- **`Contents/mods/ForagingTooltipExtended/`** - Our main code folder where all development work happens
  - Contains your mod files and all new features, modifications, and implementations

### Modular Architecture (as of v1.2.0)

The mod follows a modular architecture pattern with clear separation of concerns:

```
Contents/mods/ForagingTooltipExtended/42/media/lua/client/
├── FTE_Client.lua                    # Main entry point (slim orchestrator)
├── FTE_Utils.lua                     # Logging, colors, formatting utilities
├── FTE_ModOptions.lua                # Mod options configuration
│
├── Core/
│   └── FTE_ModuleBase.lua            # Base class for all feature modules
│
└── Modules/
    ├── FTE_CoreTooltip.lua           # Core tooltip enhancements (mandatory)
    ├── FTE_ViewDistance.lua          # View distance calculations (optional)
    ├── FTE_SearchRadiusVisual.lua    # Visual radius display (future)
    └── FTE_EquipmentImpact.lua       # Equipment analysis (future)
```

**Key Components:**
- **FTE_Client.lua**: Minimal entry point that initializes all modules and manages lifecycle
- **FTE_Utils.lua**: Shared utilities (logging, colors, formatting) used across all modules
- **FTE_ModOptions.lua**: Configuration management with per-module toggle support
- **Core/FTE_ModuleBase.lua**: Base class providing lifecycle hooks, error handling, and state management
- **Modules/**: Feature modules that extend ModuleBase and implement specific functionality

**Module Pattern:**
All feature modules follow this pattern:
1. Extend `FTE_ModuleBase`
2. Implement `setupModule()` for initialization
3. Use lifecycle hooks (onPreStart, onStart, onPostStart)
4. Export interface: `initialise()`, `destroy()`, `isActive()`, `getInstance()`
5. Handle errors gracefully with fallback to disabled state

**Benefits:**
- **Modularity**: Features can be enabled/disabled independently
- **Fault Isolation**: Module crashes don't break core functionality
- **Maintainability**: Clear code organization and separation of concerns
- **Extensibility**: Easy to add new feature modules following the pattern

### Other Directories
- **`workshop_assets/`** - Steam Workshop assets and metadata
- **Root files** - Mod documentation and configuration (README.md, CHANGELOG.md, etc.)

When developing features, always work in the `Contents/mods/ForagingTooltipExtended/` directory. New features should be implemented as modules in the `Modules/` folder extending `FTE_ModuleBase`.

## Function Documentation Guidelines:
- Use LuaLS/EmmyLua type annotations for all functions (---@param, ---@return, ---@type).
- **Avoid verbose/redundant comments** - if the purpose is obvious from function/variable names, don't repeat it.
- **Don't duplicate information** between function description and @return annotation.
- **Common parameters** (character, searchManager, etc.) don't need explanations each time they're used.
- **Variable names should be self-explanatory** - avoid obvious descriptions like "The player character" for `player`.
- **Keep annotations minimal but accurate** - focus on types rather than redundant descriptions.
- If accurate types cannot be determined, use `unknown` as the type and notify about it.

## Type Annotations for Vanilla Class Extensions:
When hooking vanilla classes and adding custom fields, use proper type extensions instead of diagnostic suppressions:

### Correct Approach (Type Extension):
```lua
-- Define extended type with custom fields
---@class ISForageIconWithTooltip : ISForageIcon
---@field tooltip ISToolTip|nil

-- Use extended type in function signatures
---@param self ISForageIconWithTooltip
local function ISForageIcon_onMouseMove(self, dx, dy)
    if not self.tooltip then
        self.tooltip = ISToolTip:new()  -- No linter errors
    end
end
```

### Wrong Approach (Diagnostic Suppression):
```lua
-- AVOID: This pattern hides type information
---@param self ISForageIcon
local function ISForageIcon_onMouseMove(self, dx, dy)
    ---@diagnostic disable-next-line: inject-field
    if not self.tooltip then
        ---@diagnostic disable-next-line: inject-field
        self.tooltip = ISToolTip:new()
    end
end
```

### Type Casting for Return Values:
When vanilla constructors return base types but you need specific type methods:
```lua
local tooltip = ISToolTip:new()  -- Returns ISBaseObject
tooltip:initialise()
---@cast tooltip ISToolTip  -- Cast to specific type
tooltip:setDescription("text")  -- Now linter knows this method exists
```

**Benefits:**
- Cleaner code without suppression comments
- Proper type checking and IntelliSense
- Self-documenting type extensions
- Easier to maintain and understand

### Good Example (Concise):
```lua
---Calculates vision bonus multiplier for foraging
---@param player IsoPlayer
---@param modifiers table
---@return number
local function calculateVisionBonus(player, modifiers)
```

### Bad Example (Verbose/Redundant):
```lua
---Get view distance for a specific item size using cached icons and vanilla calculation
---@param character IsoGameCharacter The player character
---@param itemSize number The item size to calculate view distance for
---@param searchManager ISSearchManager The search manager to use for vision calculation
---@return number viewDistance The calculated view distance in tiles
local function getViewDistance(character, itemSize, searchManager)
```

## Inline Commenting Guidelines:
- **Avoid obvious comments** - if the code is self-explanatory, don't comment it.
- **Comment complex logic** - explain non-trivial algorithms, calculations, or business rules.
- **Use comments to separate code blocks** in large functions for better readability.
- **Focus on "why" not "what"** - explain the reasoning behind code, not what it literally does.

### Good Examples:
```lua
-- Cache miss - calculate new view distance
local viewDistance = calculateDistance(player, itemSize)

-- Apply night vision penalty (reduced visibility in darkness)
if isNight then
    viewDistance = viewDistance * 0.7
end

-- === TOOLTIP GENERATION === --
local tooltipParts = {}
-- ... tooltip building code ...
```

### Bad Examples (Avoid):
```lua
-- Get the player
local player = getPlayer()

-- Set variable to true
local isVisible = true

-- Loop through items
for i = 1, #items do
    -- Get item at index i
    local item = items[i]
end
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

## Testing Guidelines:
- **No Automated Tests**: Avoid creating unit tests or automated test suites for this mod.
- **In-Game Testing Preferred**: All functionality should be tested directly in Project Zomboid.
- **Testing Instructions**: When implementing features, provide clear step-by-step instructions for manual testing in-game.
- **Test Scenarios**: Include specific scenarios to test (items to use, actions to perform, expected results).
- **Edge Cases**: Document edge cases that should be manually verified during gameplay.

### Testing Instruction Format:
When implementing a feature, include testing steps like:
```
## Testing Steps:
1. Spawn items: [list specific items needed]
2. Action: [describe what to do]
3. Expected: [what should happen]
4. Edge cases: [specific scenarios to verify]
```

## Module Development Guidelines

### Creating a New Feature Module

When adding new features, follow the established module pattern:

1. **Create Module File**: Place in `Modules/FTE_YourFeature.lua`
2. **Extend Base Class**: Inherit from `FTE_ModuleBase`
3. **Implement Required Methods**:
   - `setupModule()`: Initialize your feature
   - Optionally override lifecycle hooks: `onPreStart()`, `onStart()`, `onPostStart()`
4. **Export Interface**: Return `initialise`, `destroy`, `isActive`, `getInstance` functions
5. **Register in Client**: Add module initialization to `FTE_Client.lua`
6. **Add Mod Option**: Create toggle in `FTE_ModOptions.lua` if needed

### Module Template

```lua
-- Modules/FTE_YourFeature.lua
local FTE_ModuleBase = require "Core/FTE_ModuleBase"
local FTE_Utils = require "FTE_Utils"

local YourFeature = FTE_ModuleBase:derive("FTE_YourFeature")

function YourFeature:setupModule()
    FTE_Utils.logInfo("[YourFeature] Setting up...")
    
    -- Your initialization code here
    
    FTE_Utils.logInfo("[YourFeature] Setup complete")
end

-- Optional: Override lifecycle hooks if needed
function YourFeature:onStart()
    -- Called during initialization
end

-- Module instance
local instance = YourFeature:new()

-- Export module interface
return {
    initialise = function() return instance:initialise() end,
    destroy = function() instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end
}
```

### Module Best Practices

- **Fail Gracefully**: Use pcall() for risky operations; module crashes shouldn't break core functionality
- **Log State Changes**: Use FTE_Utils logging functions to track module lifecycle
- **Check Dependencies**: Verify required modules are active before using them
- **Respect Mod Options**: Check if module is enabled before executing logic
- **Document Public API**: Clearly define what other modules can call
- **Handle Edge Cases**: Consider what happens when game objects are nil or invalid

### Module Integration Checklist

- [ ] Module extends `FTE_ModuleBase`
- [ ] `setupModule()` implemented
- [ ] Module exports interface (initialise, destroy, isActive, getInstance)
- [ ] Added to `FTE_Client.lua` initialization sequence
- [ ] Mod option toggle created (if applicable)
- [ ] Dependencies documented
- [ ] Error handling implemented
- [ ] Logging added for key operations
- [ ] Tested in-game with module enabled/disabled