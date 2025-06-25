-- Foraging Tooltip Extended Mod Options
-- Storage array for all of our options
local FTE_Config = {
    showZeroPenalties = nil,
    showZeroTraitBonuses = nil,
    showMinMaxValues = nil,
    showFormula = nil,
    showVisionBonusDetails = nil,
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

    -- Add checkbox option to show 0 values in trait/profession bonuses
    FTE_Config.showZeroTraitBonuses = options:addTickBox(
        "showZeroTraitBonuses", 
        getText("UI_options_FTE_showZeroTraitBonuses"), 
        false, 
        getText("UI_options_FTE_showZeroTraitBonuses_tooltip")
    )
end

-- Initialize the mod options
FTE_ModOptionsConfig()

-- Getter functions for easier access to option values
local FTE_ModOptions = {}

-- Get whether to show zero values in trait/profession bonuses
function FTE_ModOptions.shouldShowZeroTraitBonuses()
    return FTE_Config.showZeroTraitBonuses and FTE_Config.showZeroTraitBonuses:getValue() or false
end

-- Get whether to show zero values in state penalties sub items
function FTE_ModOptions.shouldShowZeroPenalties()
    return FTE_Config.showZeroPenalties and FTE_Config.showZeroPenalties:getValue() or false
end

-- Get whether to show min and max values in tooltip
function FTE_ModOptions.shouldShowMinMaxValues()
    return FTE_Config.showMinMaxValues and FTE_Config.showMinMaxValues:getValue() or false
end

-- Get whether to show formula in tooltip
function FTE_ModOptions.shouldShowFormula()
    return FTE_Config.showFormula and FTE_Config.showFormula:getValue() or false
end

-- Get whether to show vision bonus details even when modifier = 1
function FTE_ModOptions.shouldShowVisionBonusDetails()
    return FTE_Config.showVisionBonusDetails and FTE_Config.showVisionBonusDetails:getValue() or false
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

-- Export the utility functions
return FTE_ModOptions