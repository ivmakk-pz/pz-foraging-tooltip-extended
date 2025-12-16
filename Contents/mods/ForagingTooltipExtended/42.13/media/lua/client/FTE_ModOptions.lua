-- Foraging Tooltip Extended Mod Options

local FTE_Utils = require("FTE_Utils")

-- Storage array for all of our options
local FTE_Config = {
    showPersistentRadius = nil,
    tooltipValueAlignment = nil,
}

-- Configuration function to set up mod options
local function FTE_ModOptionsConfig()
    -- Create the options object with unique ID
    local options = PZAPI.ModOptions:create("ForagingTooltipExtended", getText("UI_options_FTE_title"))

    -- Add checkbox option to show persistent radius display
    FTE_Config.showPersistentRadius = options:addTickBox(
        "showPersistentRadius", 
        getText("UI_options_FTE_showPersistentRadius"), 
        true, 
        getText("UI_options_FTE_showPersistentRadius_tooltip")
    )
    
    -- Add dropdown option for tooltip value alignment
    FTE_Config.tooltipValueAlignment = options:addComboBox(
        "tooltipValueAlignment",
        getText("UI_options_FTE_tooltipValueAlignment")
    )
    FTE_Config.tooltipValueAlignment:addItem(getText("UI_options_FTE_tooltipValueAlignment_rightAligned"), true)  -- Default
    FTE_Config.tooltipValueAlignment:addItem(getText("UI_options_FTE_tooltipValueAlignment_leftAligned"), false)
end

-- ===================================================================================================== --
-- OPTION ACCESS FUNCTIONS
-- ===================================================================================================== --

local FTE_ModOptions = {}

-- Get whether to show persistent radius display
function FTE_ModOptions.shouldShowPersistentRadius()
    if FTE_Config.showPersistentRadius then
        return FTE_Config.showPersistentRadius:getValue()
    else
        return true  -- Default enabled when not initialized
    end
end

-- Get tooltip value alignment ("left" or "right")
function FTE_ModOptions.getTooltipValueAlignment()
    if FTE_Config.tooltipValueAlignment then
        return FTE_Config.tooltipValueAlignment:getValue() == 1 and FTE_Utils.Alignment.RIGHT or FTE_Utils.Alignment.LEFT  -- 1 = Right Aligned, 2 = Left Aligned
    else
        return FTE_Utils.Alignment.RIGHT  -- Default to right-aligned when not initialized
    end
end

-- Get a specific option by its field name
function FTE_ModOptions.getOption(optionName)
    if FTE_Config[optionName] then
        ---@diagnostic disable-next-line: undefined-field
        return FTE_Config[optionName]:getValue()
    end
    return nil
end

-- ===================================================================================================== --
-- MOD OPTIONS INITIALIZATION
-- ===================================================================================================== --

---Initialize mod options when UI is ready
function FTE_ModOptions.initialize()
    if not PZAPI or not PZAPI.ModOptions then
        FTE_Utils.logWarning("ModOptions API not available, using default values")
        return
    end
    
    FTE_Utils.logInfo("Initializing mod options...")
    
    FTE_ModOptionsConfig()
    
    FTE_Utils.logInfo("Mod options initialized successfully")
end

return FTE_ModOptions