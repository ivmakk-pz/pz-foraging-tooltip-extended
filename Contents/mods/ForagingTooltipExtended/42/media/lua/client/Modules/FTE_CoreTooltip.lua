-- FTE_CoreTooltip.lua - Core tooltip enhancement module
-- Provides detailed modifier breakdown, formula display, and food detection info

local FTE_ModuleBase = require("Core/FTE_ModuleBase")
local FTE_Utils = require("FTE_Utils")
local FTE_ModOptions = require("FTE_ModOptions")

-- ===================================================================================================== --
-- MODULE CLASS DEFINITION
-- ===================================================================================================== --

---@class FTE_CoreTooltip : FTE_ModuleBase
local FTE_CoreTooltip = FTE_ModuleBase:derive("FTE_CoreTooltip")

-- Singleton instance (created immediately at module load)
local instance = FTE_CoreTooltip:new()
---@cast instance FTE_CoreTooltip



-- ===================================================================================================== --
-- TOOLTIP BUILDING HELPER FUNCTIONS
-- ===================================================================================================== --

local Colors = FTE_Utils.Colors

---Builds the penalties section for the tooltip
---@param _modifiers table
---@param _otherPenalties number
---@return string
local function buildPenaltiesText(_modifiers, _otherPenalties)
	-- Removed clothing from this section - it now has its own F section
	local penaltyItems = {
		{modifier = _modifiers.exhaustionPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"},
		{modifier = _modifiers.panicPenalty, textKey = "IGUI_StatsAndBody_Panic"},
		{modifier = _modifiers.bodyPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"},
		{modifier = _modifiers.movementPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Movement"}
	}
	
	-- Collect sub-items that should be displayed (only show items with impact)
	local subItems = {}
	for i = 1, #penaltyItems do
		local item = penaltyItems[i];
		if math.abs(item.modifier - 1) >= 0.01 then
			table.insert(subItems, {text = getText(item.textKey), value = item.modifier})
		end
	end
	
	-- Only build section if there are sub-items to display
	if #subItems == 0 then
		return ""
	end
	
	-- Build header
	local parts = {
		FTE_Utils.getToolTipHeaderWithAlignment("E. " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), _otherPenalties)
	}
	
	-- Use global fixed alignment position
	local valueXPosition = FTE_Utils.TOOLTIP_VALUE_X_POSITION
	
	-- Add sub-items with tree connectors
	for i = 1, #subItems do
		local item = subItems[i]
		local isLast = (i == #subItems)
		table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(item.text, item.value, isLast, valueXPosition))
	end
	
	return table.concat(parts);
end

---Builds the clothing effect section with vision-affecting items
---@param _modifiers table
---@param _character IsoPlayer The player character
---@return string
local function buildClothingEffectText(_modifiers, _character)
	-- Only show section if clothing has an effect
	if math.abs(_modifiers.clothingPenalty - 1) < 0.01 then
		return ""
	end
	
	local parts = {
		FTE_Utils.getToolTipHeaderWithAlignment("F. " .. getText("IGUI_SearchMode_Vision_Effect_Clothing"), _modifiers.clothingPenalty)
	}
	
	-- Add vision-affecting items if clothing penalty < 1.0
	if _modifiers.clothingPenalty < 1.0 then
		-- Check if VisionAffectingItems module is available and enabled
		local FTE_VisionAffectingItems = nil
		local status, module = pcall(require, "Modules/FTE_VisionAffectingItems")
		if status and module and module.isActive and module.isActive() then
			FTE_VisionAffectingItems = module
		end
		
		-- Build items list with simple defaults (no mod options needed)
		if FTE_VisionAffectingItems and _character then
			local options = {
				showZeroPenalty = false,  -- Only show items with actual penalties
				sortMode = "severity"     -- Sort by penalty severity (highest first)
			}
			local itemsText = FTE_VisionAffectingItems.buildItemsList(_character, options)
			if itemsText then
				table.insert(parts, itemsText)
			end
		end
	end
	
	return table.concat(parts)
end

---@param character IsoGameCharacter
---@return number
local function getHungerBonus(character)
	local hungerLevel = character:getStats():getHunger();
	local hungerBonus = 1 + ((forageSystem.hungerBonusMax * hungerLevel) / 100);
	return hungerBonus;
end

---Builds the A-F modifiers section with conditional display
---@param _modifierDefs table Array of modifier definitions with letter, value, textKey, showAlways
---@param _valueXPosition number X position for value alignment
---@return string
local function buildModifiersSection(_modifierDefs, _valueXPosition)
	-- Filter and build display list (skip items with no impact unless showAlways)
	local modifierItems = {}
	for i = 1, #_modifierDefs do
		local def = _modifierDefs[i]
		if def.showAlways or math.abs(def.value - 1) >= 0.01 then
			table.insert(modifierItems, {
				label = "[" .. def.letter .. "] " .. getText(def.textKey),
				value = def.value
			})
		end
	end
	
	-- Render all filtered items with proper isLast detection
	local parts = {}
	for i = 1, #modifierItems do
		local item = modifierItems[i]
		local isLast = (i == #modifierItems)
		table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(item.label, item.value, isLast, _valueXPosition))
	end
	
	return table.concat(parts)
end

-- ===================================================================================================== --
-- ISZONDISPLAY OVERRIDE FUNCTION
-- ===================================================================================================== --

---Override ISZoneDisplay:getVisionTooltipText to provide enhanced tooltip with detailed modifier breakdown
---@param zoneDisplay ISZoneDisplay
---@return string
local function ISZoneDisplay_getVisionTooltipText(zoneDisplay)
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
	local baseRadius = minRadius + levelRadius;	-- Reorganize variables for new layout
	local visionBonus = math.max(modifiers.aimBonus, modifiers.sneakBonus);
	local darknessMultiplier = modifiers.lightPenalty;
	local weatherPenalty = modifiers.weatherPenalty;
	local otherPenalties = modifiers.panicPenalty * modifiers.bodyPenalty * modifiers.exhaustionPenalty * modifiers.movementPenalty;
	local clothingPenalty = modifiers.clothingPenalty;
	-- Check if current radius equals minimum or maximum radius
	local isAtMinRadius = math.abs(visionRadius - searchManager.minRadius) < 0.01;
	local isAtMaxRadius = math.abs(visionRadius - searchManager.maxRadiusCap) < 0.01;
	
	-- Add main radius text
	table.insert(parts, FTE_Utils.getToolTipTextRadius(getText("IGUI_SearchMode_Vision_Effect_Radius"), visionRadius, isAtMinRadius, isAtMaxRadius));
	
	-- Use global fixed alignment position for all values
	local valueXPosition = FTE_Utils.TOOLTIP_VALUE_X_POSITION
	
	-- Define A-F modifiers data structure
	local modifierDefs = {
		{letter = "A", value = baseRadius, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits", showAlways = true},
		{letter = "B", value = weatherPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Weather"},
		{letter = "C", value = darknessMultiplier, textKey = "IGUI_SearchMode_Vision_Effect_Darkness"},
		{letter = "D", value = visionBonus, textKey = modifiers.aimBonus >= modifiers.sneakBonus and "IGUI_SearchMode_Vision_Effect_Aiming" or "IGUI_SearchMode_Vision_Effect_Crouching"},
		{letter = "E", value = otherPenalties, textKey = "IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"},
		{letter = "F", value = clothingPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Clothing"}
	}
	
	-- Build and add A-F modifiers section
	table.insert(parts, buildModifiersSection(modifierDefs, valueXPosition))
	table.insert(parts, " <LINE> ");

    -- E. State Penalties detailed breakdown
	if math.abs(otherPenalties - 1) >= 0.01 then
        local penaltiesSection = buildPenaltiesText(modifiers, otherPenalties);
        if penaltiesSection and penaltiesSection ~= "" then
            table.insert(parts, penaltiesSection);
            table.insert(parts, " <LINE> ");
        end
	end

	-- F. Clothing Effect with vision-affecting items
	local clothingSection = buildClothingEffectText(modifiers, zoneDisplay.character)
	if clothingSection and clothingSection ~= "" then
		table.insert(parts, clothingSection);
		table.insert(parts, " <LINE> ");
	end

    -- Add trait/profession bonuses section
    local totalBonus = modifiers.professionBonus + modifiers.traitBonus
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Trait_Profession_Bonuses"));
    table.insert(parts, " <LINE> ");
    
    -- Use global fixed alignment position
    local valueXPosition = FTE_Utils.TOOLTIP_VALUE_X_POSITION
    
    -- Add food detection bonus first (if applicable)
    local hungerBonus = getHungerBonus(zoneDisplay.character)
    local hasFoodDetection = hungerBonus > 1.01
    if hasFoodDetection then
        local foodDetectionValue = hungerBonus - 1.0
        local formattedFoodBonus = Colors.good .. FTE_Utils.formatPercentShort(foodDetectionValue) .. "%"
        table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(
            getText("IGUI_FTE_Food_Detection_Header") .. " (" .. getText("IGUI_StatsAndBody_Hunger") .. ")",
            formattedFoodBonus,
            false,  -- not last (more items follow)
            valueXPosition
        ))
    end
    
    -- Format total bonus with proper color and sign (1 decimal place)
    local bonusColor = FTE_Utils.getRGBForTooltip(totalBonus > 0, totalBonus == 0)
    local formattedTotalBonus = bonusColor .. string.format("%+.1f", totalBonus)
    
    table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(
        getText("IGUI_SearchMode_Vision_Effect_Bonus_Radius"),
        formattedTotalBonus,
        false,  -- not last (more items follow)
        valueXPosition
    ))
	
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

    -- Filter items that should be displayed and add them to text with tree structure
	local displayItems = {}
	for i = 1, #characterItems do
		local item = characterItems[i]
		if not item.isBonus or item.value ~= 0 then
			table.insert(displayItems, item)
		end
	end
	
	-- Add filtered items with proper isLast detection
	for i = 1, #displayItems do
		local item = displayItems[i]
		local isLast = (i == #displayItems)  -- Now correctly detects last displayed item
		
		-- Format percentage value with proper color (using short format)
		local valueColor = item.isBonus and FTE_Utils.getRGBForTooltip(item.value > 0, item.value == 0) 
		                                  or FTE_Utils.getRGBForTooltip(item.value < 0, item.value == 0)
		local formattedValue = valueColor .. FTE_Utils.formatPercentShort(item.value) .. "%"
		
		table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(
			item.text,
			formattedValue,
			isLast,
			valueXPosition
		))
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

-- ===================================================================================================== --
-- MODULE API EXPORTS
-- ===================================================================================================== --

return {
    initialise = function() return instance:initialise(function(self) self:setupModule() end) end,
    destroy = function() return instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end
}
