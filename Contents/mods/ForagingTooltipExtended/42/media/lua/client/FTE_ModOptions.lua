-- Foraging Tooltip Extended Mod Options

local FTE_Utils = require("FTE_Utils")

-- Storage array for all of our options
local FTE_Config = {
    showZeroPenalties = nil,
    showZeroTraitBonuses = nil,
    showMinMaxValues = nil,
    showFormula = nil,
    showVisionBonusDetails = nil,
    showViewDistance = nil,
    showZeroFoodDetection = nil,
}

-- Configuration function to set up mod options
local function FTE_ModOptionsConfig()
    -- Create the options object with unique ID
    local options = PZAPI.ModOptions:create("ForagingTooltipExtended", getText("UI_options_FTE_title"))
    
    -- Add checkbox option to show formula in tooltip
    FTE_Config.showFormula = options:addTickBox(
        "showFormula", 
        getText("UI_options_FTE_showFormula"), 
        true, 
        getText("UI_options_FTE_showFormula_tooltip")
    )
    
    -- Add checkbox option to show min and max values in tooltip
    FTE_Config.showMinMaxValues = options:addTickBox(
        "showMinMaxValues", 
        getText("UI_options_FTE_showMinMaxValues"), 
        false, 
        getText("UI_options_FTE_showMinMaxValues_tooltip")
    )
    
    -- Add checkbox option to show vision bonus details even when modifier = 1
    FTE_Config.showVisionBonusDetails = options:addTickBox(
        "showVisionBonusDetails", 
        getText("UI_options_FTE_showVisionBonusDetails"), 
        false, 
        getText("UI_options_FTE_showVisionBonusDetails_tooltip")
    )
    
    -- Add checkbox option to show 0 values in state penalties sub items
    FTE_Config.showZeroPenalties = options:addTickBox(
        "showZeroPenalties", 
        getText("UI_options_FTE_showZeroPenalties"), 
        true, 
        getText("UI_options_FTE_showZeroPenalties_tooltip")
    )

    -- Add checkbox option to show view distance in tooltip
    FTE_Config.showViewDistance = options:addTickBox(
        "showViewDistance", 
        getText("UI_options_FTE_showViewDistance"), 
        false, 
        getText("UI_options_FTE_showViewDistance_tooltip")
    )
    
    -- Add checkbox option to show zero value for food detection
    FTE_Config.showZeroFoodDetection = options:addTickBox(
        "showZeroFoodDetection", 
        getText("UI_options_FTE_showZeroFoodDetection"), 
        false, 
        getText("UI_options_FTE_showZeroFoodDetection_tooltip")
    )

    -- Add checkbox option to show 0 values in trait/profession bonuses
    FTE_Config.showZeroTraitBonuses = options:addTickBox(
        "showZeroTraitBonuses", 
        getText("UI_options_FTE_showZeroTraitBonuses"), 
        false, 
        getText("UI_options_FTE_showZeroTraitBonuses_tooltip")
    )
end

-- ===================================================================================================== --
-- OPTION ACCESS FUNCTIONS
-- ===================================================================================================== --

local FTE_ModOptions = {}

-- Get whether to show zero values in trait/profession bonuses
function FTE_ModOptions.shouldShowZeroTraitBonuses()
    if FTE_Config.showZeroTraitBonuses then
        return FTE_Config.showZeroTraitBonuses:getValue()
    else
        return false  -- Default disabled when not initialized
    end
end

-- Get whether to show zero values in state penalties sub items
function FTE_ModOptions.shouldShowZeroPenalties()
    if FTE_Config.showZeroPenalties then
        return FTE_Config.showZeroPenalties:getValue()
    else
        return true  -- Default enabled when not initialized
    end
end

-- Get whether to show min and max values in tooltip
function FTE_ModOptions.shouldShowMinMaxValues()
    if FTE_Config.showMinMaxValues then
        return FTE_Config.showMinMaxValues:getValue()
    else
        return false  -- Default disabled when not initialized
    end
end

-- Get whether to show formula in tooltip
function FTE_ModOptions.shouldShowFormula()
    if FTE_Config.showFormula then
        return FTE_Config.showFormula:getValue()
    else
        return true  -- Default enabled when not initialized
    end
end

-- Get whether to show vision bonus details even when modifier = 1
function FTE_ModOptions.shouldShowVisionBonusDetails()
    if FTE_Config.showVisionBonusDetails then
        return FTE_Config.showVisionBonusDetails:getValue()
    else
        return false  -- Default disabled when not initialized
    end
end

-- Get whether to show view distance in tooltip
function FTE_ModOptions.shouldShowViewDistance()
    if FTE_Config.showViewDistance then
        return FTE_Config.showViewDistance:getValue()
    else
        return false  -- Default disabled when not initialized
    end
end

-- Get whether to show zero value for food detection
function FTE_ModOptions.shouldShowZeroFoodDetection()
    if FTE_Config.showZeroFoodDetection then
        return FTE_Config.showZeroFoodDetection:getValue()
    else
        return false  -- Default disabled when not initialized
    end
end

-- Get the raw config object (for advanced usage)
function FTE_ModOptions.getConfig()
    return FTE_Config
end

-- Get a specific option by its field name
function FTE_ModOptions.getOption(optionName)
    if FTE_Config[optionName] then
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