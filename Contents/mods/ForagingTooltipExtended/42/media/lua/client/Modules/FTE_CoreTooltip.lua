-- FTE_CoreTooltip.lua - Core tooltip enhancement module
-- Provides detailed modifier breakdown, formula display, and food detection info

local FTE_ModuleBase = require("Core/FTE_ModuleBase")
local FTE_Utils = require("FTE_Utils")
local FTE_ModOptions = require("FTE_ModOptions")
local FTE_VisionAffectingItems = require("Modules/FTE_VisionAffectingItems")

-- ===================================================================================================== --
-- MODULE CLASS DEFINITION
-- ===================================================================================================== --

---@class FTE_CoreTooltip : FTE_ModuleBase
local FTE_CoreTooltip = FTE_ModuleBase:derive("FTE_CoreTooltip")

-- Singleton instance (created immediately at module load)
local instance = FTE_CoreTooltip:new()
---@cast instance FTE_CoreTooltip

-- Store reference to modified panel and original value for cleanup
local modifiedTipPanel = nil
local originalMaxLineWidth = nil



-- ===================================================================================================== --
-- TOOLTIP BUILDING HELPER FUNCTIONS
-- ===================================================================================================== --

local Colors = FTE_Utils.Colors

---@param character IsoGameCharacter
---@return number
local function getHungerBonus(character)
	local hungerLevel = character:getStats():getHunger();
	local hungerBonus = 1 + ((forageSystem.hungerBonusMax * hungerLevel) / 100);
	return hungerBonus;
end

-- ===================================================================================================== --
-- ISZONDISPLAY OVERRIDE FUNCTION
-- ===================================================================================================== --

---Override ISZoneDisplay:getVisionTooltipText to provide enhanced tooltip with detailed modifier breakdown
---@param zoneDisplay ISZoneDisplay
---@return string
local function ISZoneDisplay_getVisionTooltipText(zoneDisplay)
    -- Reinitialize tooltip layout to detect font changes (lightweight, only when tooltip shows)
    FTE_Utils.initializeTooltipLayout()
    
    -- Configure tooltip panel to prevent soft wrapping (only once)
    if zoneDisplay.tipPanel and modifiedTipPanel == nil then
        -- Store reference to panel and original value for cleanup
        modifiedTipPanel = zoneDisplay.tipPanel
        originalMaxLineWidth = zoneDisplay.tipPanel.maxLineWidth
        
        -- Set large value to prevent soft wrapping
        zoneDisplay.tipPanel.maxLineWidth = 10000
    end
    
    -- Get alignment preference from mod options
    local useRightAlign = FTE_ModOptions.isTooltipValueRightAligned()
    
    -- Use table-based concatenation for better performance
    local parts = {}

    ---@type ISSearchManager
    local searchManager = zoneDisplay.manager;
	local visionRadius	= searchManager:getOverlayRadius();
	local modifiers		= searchManager.modifiers;

	-- Calculate detailed radius breakdown based on getOverlayRadiusB429
	searchManager:updateModifiers();
	local traitBonus = modifiers.traitBonus;
	local professionBonus = modifiers.professionBonus;
	local minRadius = zoneDisplay.manager.minRadius + professionBonus + traitBonus;
	local maxRadius = zoneDisplay.manager.maxRadius + professionBonus + traitBonus;
	local levelRadius = (maxRadius - minRadius) * (zoneDisplay.manager.perkLevel / 10);
	local baseRadius = minRadius + levelRadius;

	-- Reorganize variables for new layout
	local visionBonus = math.max(modifiers.aimBonus, modifiers.sneakBonus);
	local darknessMultiplier = modifiers.lightPenalty;
	local weatherPenalty = modifiers.weatherPenalty;
	local clothingPenalty = modifiers.clothingPenalty;
	local exhaustionPenalty = modifiers.exhaustionPenalty;
	local panicPenalty = modifiers.panicPenalty;
	local bodyPenalty = modifiers.bodyPenalty;
	local movementPenalty = modifiers.movementPenalty;
	
	-- Check if current radius equals minimum or maximum radius
	local isAtMinRadius = math.abs(visionRadius - searchManager.minRadius) < 0.01;
	local isAtMaxRadius = math.abs(visionRadius - searchManager.maxRadiusCap) < 0.01;
	
	-- Add main radius text
	table.insert(parts, FTE_Utils.getToolTipTextRadius(getText("IGUI_SearchMode_Vision_Effect_Radius"), visionRadius, isAtMinRadius, isAtMaxRadius, useRightAlign));
	
	-- Get value X position for alignment (responsive to font size)
	local valueXPosition = useRightAlign and FTE_Utils.tooltipLayout.valueXPosition or nil
	
	-- Collect all base modifiers for display (excluding clothing - it will be replaced by individual items)
	local modifierItems = {
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits"), value = baseRadius, showAlways = true, forceWhite = true},
		{text = getText("IGUI_SearchMode_Vision_Effect_Weather"), value = weatherPenalty},
		{text = getText("IGUI_SearchMode_Vision_Effect_Darkness"), value = darknessMultiplier},
		{text = modifiers.aimBonus >= modifiers.sneakBonus and getText("IGUI_SearchMode_Vision_Effect_Aiming") or getText("IGUI_SearchMode_Vision_Effect_Crouching"), value = visionBonus},
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"), value = exhaustionPenalty},
		{text = getText("IGUI_StatsAndBody_Panic"), value = panicPenalty},
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"), value = bodyPenalty},
		{text = getText("IGUI_SearchMode_Vision_Effect_Movement"), value = movementPenalty}
	}
	
	-- Get vision-affecting worn items
	local wornItems = FTE_VisionAffectingItems.getWornItemsForTooltip(zoneDisplay.character, clothingPenalty)
	
	-- Filter base modifiers: show always-visible items and items with impact
	local displayItems = {}
	for i = 1, #modifierItems do
		local item = modifierItems[i]
		if item.showAlways or math.abs(item.value - 1) >= 0.01 then
			table.insert(displayItems, item)
		end
	end
	
	-- Add vision-affecting worn items to display list
	for i = 1, #wornItems do
		table.insert(displayItems, wornItems[i])
	end
	
	-- Add all modifier items with proper tree connectors
	for i = 1, #displayItems do
		local item = displayItems[i]
		local isLast = (i == #displayItems)
		
		-- Handle forceWhite flag for values that should always be white
		local valueToDisplay = item.value
		if item.forceWhite then
			-- Pre-format the value as white instead of using auto-coloring
			valueToDisplay = Colors.white .. FTE_Utils.formatNumber(item.value)
		end
		
		table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(
			item.text,
			valueToDisplay,
			isLast,
			valueXPosition,
			useRightAlign
		))
	end
	
	table.insert(parts, " <LINE> ");

    -- Add trait/profession bonuses section
    local totalBonus = modifiers.professionBonus + modifiers.traitBonus
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Trait_Profession_Bonuses"));
    table.insert(parts, " <LINE> ");
    
    -- Add food detection bonus first (if applicable)
    local hungerBonus = getHungerBonus(zoneDisplay.character)
    local hasFoodDetection = hungerBonus > 1.01
    if hasFoodDetection then
        local foodDetectionValue = hungerBonus - 1.0
        local formattedFoodBonus = Colors.good .. FTE_Utils.formatPercentShort(foodDetectionValue) .. "%"
        table.insert(parts, Colors.white)
        table.insert(parts, getText("IGUI_FTE_Food_Detection_Header") .. " (" .. getText("IGUI_StatsAndBody_Hunger") .. ")")
        if useRightAlign and valueXPosition then
            table.insert(parts, " <SETX:")
            table.insert(parts, tostring(valueXPosition))
            table.insert(parts, "> ")
        else
            table.insert(parts, ": <SPACE> ")
        end
        table.insert(parts, formattedFoodBonus)
        table.insert(parts, " <LINE> ")
    end
    
    -- Format total bonus with proper color and sign (1 decimal place)
    local bonusColor = FTE_Utils.getRGBForTooltip(totalBonus > 0, totalBonus == 0)
    local formattedTotalBonus = bonusColor .. string.format("%+.1f", totalBonus)
    
    table.insert(parts, Colors.white)
    table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Bonus_Radius"))
    if useRightAlign and valueXPosition then
        table.insert(parts, " <SETX:")
        table.insert(parts, tostring(valueXPosition))
        table.insert(parts, "> ")
    else
        table.insert(parts, ": <SPACE> ")
    end
    table.insert(parts, formattedTotalBonus)
    table.insert(parts, " <LINE> ")
	
	-- Collect character effect items for sorting
	local characterItems = {};
	
	-- Add weather and darkness effects
	table.insert(characterItems, {text = getText("IGUI_SearchMode_Vision_Effect_Weather"), value = forageSystem.getWeatherEffectReduction(zoneDisplay.character) - 1, isBonus = false});
	table.insert(characterItems, {text = getText("IGUI_SearchMode_Vision_Effect_Darkness"), value = forageSystem.getDarknessEffectReduction(zoneDisplay.character) - 1, isBonus = false});
	
	-- Add category bonuses to character items
	for _, catDef in pairs(forageSystem.catDefs) do
		if catDef and catDef.name then
			local catVisionEffect = forageSystem.getCategoryBonus(zoneDisplay.character, catDef) - 1;
			local categoryText = getTextOrNull("IGUI_SearchMode_Categories_"..catDef.name);
			if categoryText then
				table.insert(characterItems, {text = categoryText, value = catVisionEffect, isBonus = true})
			end;
		end
	end
	
	-- Sort character items (non-zero first, then zero)
	FTE_Utils.sortTooltipItems(characterItems)

    -- Filter items that should be displayed and add them to text
	local displayBonusItems = {}
	for i = 1, #characterItems do
		local item = characterItems[i]
		if not item.isBonus or item.value ~= 0 then
			table.insert(displayBonusItems, item)
		end
	end
	
	-- Add filtered items without tree connectors
	for i = 1, #displayBonusItems do
		local item = displayBonusItems[i]
		
		-- Format percentage value with proper color (using short format)
		local valueColor = item.isBonus and FTE_Utils.getRGBForTooltip(item.value > 0, item.value == 0) 
		                                  or FTE_Utils.getRGBForTooltip(item.value < 0, item.value == 0)
		local formattedValue = valueColor .. FTE_Utils.formatPercentShort(item.value) .. "%"
		
		table.insert(parts, Colors.white)
		table.insert(parts, item.text)
		if useRightAlign and valueXPosition then
			table.insert(parts, " <SETX:")
			table.insert(parts, tostring(valueXPosition))
			table.insert(parts, "> ")
		else
			table.insert(parts, ": <SPACE> ")
		end
		table.insert(parts, formattedValue)
		table.insert(parts, " <LINE> ")
	end

	return table.concat(parts);
end

-- ===================================================================================================== --
-- MODULE SETUP METHOD
-- ===================================================================================================== --

---Setup the core tooltip module
function FTE_CoreTooltip:setupModule()
    FTE_Utils.logInfo("FTE_CoreTooltip: Setting up core tooltip enhancement module")

    self:overrideFunction(ISZoneDisplay, "getVisionTooltipText", ISZoneDisplay_getVisionTooltipText)
    
    FTE_Utils.logInfo("FTE_CoreTooltip: Core tooltip enhancement module setup complete")
end

---Override destroy to restore property modifications before base cleanup
function FTE_CoreTooltip:destroy()
    -- Restore maxLineWidth property if we modified it
    if modifiedTipPanel ~= nil and originalMaxLineWidth ~= nil then
        modifiedTipPanel.maxLineWidth = originalMaxLineWidth
        FTE_Utils.logInfo("FTE_CoreTooltip: Restored tipPanel.maxLineWidth to " .. tostring(originalMaxLineWidth))
        modifiedTipPanel = nil
        originalMaxLineWidth = nil
    end
    
    -- Call base destroy to restore function overrides and cleanup events
    FTE_ModuleBase.destroy(self)
end

-- ===================================================================================================== --
-- MODULE API EXPORTS
-- ===================================================================================================== --

return {
    initialise = function() return instance:initialise(function(self) self:setupModule() end) end,
    destroy = function() return instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end
}
