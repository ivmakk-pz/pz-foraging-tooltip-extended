---
applyTo: '**/*.lua'
---
- Use `\%` syntax for percentage symbols in tooltips.
-- Note: Linters may highlight `\%` as an error, but this syntax renders properly in the game UI.

## Function Documentation Guidelines:
- Use LuaLS/EmmyLua type annotations for all functions (---@param, ---@return, ---@type).
- Include descriptive comments explaining what each function does.
- If accurate types cannot be determined, use `unknown` as the type and notify about it.
- Document parameters with their purpose and expected values.
- Example:
```lua
---Calculates the vision bonus multiplier for foraging
---@param player IsoPlayer The player character
---@param modifiers table The search modifiers table
---@return number visionBonus The calculated vision bonus multiplier
local function calculateVisionBonus(player, modifiers)
```

## Mod Options Guidelines:
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