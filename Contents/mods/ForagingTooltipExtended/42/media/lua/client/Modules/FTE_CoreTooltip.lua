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

local function formatFormulaValue(_letter, _value, _isAtMinRadius, _isAtMaxRadius)
	if _isAtMinRadius or _isAtMaxRadius then
		return Colors.grey .. _letter .. Colors.white;
	else
		return FTE_Utils.getRGBForValue(_value) .. _letter .. Colors.white;
	end
end

local function buildFormulaString(_formulaData, _isAtMinRadius, _isAtMaxRadius)
	local parts = {};
	for i = 1, #_formulaData do
		local data = _formulaData[i];
		table.insert(parts, formatFormulaValue(data.letter, data.value, _isAtMinRadius, _isAtMaxRadius));
		if i < #_formulaData then
			table.insert(parts, " <SPACE> * <SPACE> ");
		end
	end
	return " " .. Colors.white .. "- Formula: <SPACE>" .. table.concat(parts) .. " <LINE> ";
end

---Builds the min/max radius section for the tooltip
---@param _visionRadius number
---@param _searchManager table
---@return string
local function buildMinMaxText(_visionRadius, _searchManager)
	local minRadius = _searchManager.minRadius;
	local maxRadius = _searchManager.maxRadiusCap
	local minColor = Colors.grey;
	local maxColor = Colors.grey;

	if math.abs(_visionRadius - minRadius) < 0.01 then
		minColor = Colors.bad;
	end
	if math.abs(_visionRadius - maxRadius) < 0.01 then
		maxColor = Colors.good;
	end

	local parts = {
		" ", Colors.white, "- Min: <SPACE> ", minColor, FTE_Utils.formatNumber(minRadius), " <LINE> ",
		" ", Colors.white, "- Max: <SPACE> ", maxColor, FTE_Utils.formatNumber(maxRadius), " <LINE> "
	}
	
	return table.concat(parts);
end

---Builds the penalties section for the tooltip
---@param _modifiers table
---@param _otherPenalties number
---@param _shouldShowZeroPenalties boolean
---@return string
local function buildPenaltiesText(_modifiers, _otherPenalties, _shouldShowZeroPenalties)
	local penaltyItems = {
		{modifier = _modifiers.clothingPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Clothing"},
		{modifier = _modifiers.exhaustionPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"},
		{modifier = _modifiers.panicPenalty, textKey = "IGUI_StatsAndBody_Panic"},
		{modifier = _modifiers.bodyPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"},
		{modifier = _modifiers.movementPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Movement"}
	}
	
	-- Collect sub-items that should be displayed
	local subItems = {}
	for i = 1, #penaltyItems do
		local item = penaltyItems[i];
		if _shouldShowZeroPenalties or math.abs(item.modifier - 1) >= 0.01 then
			table.insert(subItems, FTE_Utils.getToolTipTextSubValue(getText(item.textKey), item.modifier, "", "- "));
		end
	end
	
	-- Only build section if there are sub-items to display
	if #subItems == 0 then
		return ""
	end
	
	-- Build header + sub-items
	local parts = {
		" ", Colors.white, "E. ", getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), 
		": <SPACE> ", FTE_Utils.getRGBForValue(_otherPenalties), FTE_Utils.formatNumber(_otherPenalties), " <LINE> "
	}
	
	for i = 1, #subItems do
		table.insert(parts, subItems[i])
	end
	
	return table.concat(parts);
end

---@param character IsoGameCharacter
---@return number
local function getHungerBonus(character)
	local hungerLevel = character:getStats():getHunger();
	local hungerBonus = 1 + ((forageSystem.hungerBonusMax * hungerLevel) / 100);
	return hungerBonus;
end

---@param character IsoGameCharacter
---@return string
local function addFoodDetectionSection(character)
	local hungerBonus = getHungerBonus(character)
	
	-- Hide section if no bonus and option disabled
	if hungerBonus <= 1.01 and not FTE_ModOptions.shouldShowZeroFoodDetection() then
		return ""
	end
    
	local result = " " .. Colors.white .. getText("IGUI_FTE_Food_Detection_Header") .. " (" .. getText("IGUI_StatsAndBody_Hunger") .. ")" .. " <LINE> "
	
	if hungerBonus > 1.01 then
		local bonusPercent = (hungerBonus - 1.0) * 100
		result = result .. " " .. Colors.white .. "- " .. getText("IGUI_FTE_Food_Detection_Bonus") .. 
				": <SPACE> " .. Colors.good .. "+" .. FTE_Utils.formatNumber(bonusPercent) .. "% <LINE> "
	else
		result = result .. " " .. Colors.white .. "- " .. getText("IGUI_FTE_Food_Detection_Bonus") .. 
				": <SPACE> " .. Colors.grey .. "0% <LINE> "
	end
    
    return result
end

---Builds the vision bonus details section for the tooltip
---@param _visionBonus number
---@param _modifiers table
---@return string
local function buildVisionBonusDetailsText(_visionBonus, _modifiers)
    local parts = {
        " ", Colors.white, "D. ", getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus"),
        ": <SPACE> ", FTE_Utils.getRGBForValue(_visionBonus), FTE_Utils.formatNumber(_visionBonus), " <LINE> "
    }
    
    table.insert(parts, FTE_Utils.getToolTipTextSubValue(getText("IGUI_SearchMode_Vision_Effect_Aiming"), _modifiers.aimBonus, "", "- "))
    table.insert(parts, FTE_Utils.getToolTipTextSubValue(getText("IGUI_SearchMode_Vision_Effect_Crouching"), _modifiers.sneakBonus, "", "- "))
    
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
	local otherPenalties = modifiers.panicPenalty * modifiers.bodyPenalty * modifiers.exhaustionPenalty * 
	                      modifiers.clothingPenalty * modifiers.movementPenalty;
	-- Check if current radius equals minimum or maximum radius
	local isAtMinRadius = math.abs(visionRadius - searchManager.minRadius) < 0.01;
	local isAtMaxRadius = math.abs(visionRadius - searchManager.maxRadiusCap) < 0.01;
	
	-- Add main radius text
	table.insert(parts, FTE_Utils.getToolTipTextRadius(getText("IGUI_SearchMode_Vision_Effect_Radius"), visionRadius, isAtMinRadius, isAtMaxRadius));
    
    -- Formula string
	if FTE_ModOptions.shouldShowFormula() then
        local formulaData = {
            {letter = "A", value = baseRadius},
            {letter = "B", value = weatherPenalty},
            {letter = "C", value = darknessMultiplier},
            {letter = "D", value = visionBonus},
            {letter = "E", value = otherPenalties}
        };

		table.insert(parts, buildFormulaString(formulaData, isAtMinRadius, isAtMaxRadius));
	end
	
	-- Min/Max
	if FTE_ModOptions.shouldShowMinMaxValues() then
		table.insert(parts, buildMinMaxText(visionRadius, searchManager));
	end

    -- Add modifiers section
	table.insert(parts, " <LINE> ");
    table.insert(parts, " ");
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_FTE_SearchMode_Vision_Effect_Search_Radius_Modifiers"));
    table.insert(parts, " <LINE> ");
	table.insert(parts, FTE_Utils.getToolTipTextSubValue("[A] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits"), baseRadius, "", "- "));
	table.insert(parts, FTE_Utils.getToolTipTextSubValue("[B] " .. getText("IGUI_SearchMode_Vision_Effect_Weather"), weatherPenalty, "", "- "));
	table.insert(parts, FTE_Utils.getToolTipTextSubValue("[C] " .. getText("IGUI_SearchMode_Vision_Effect_Darkness"), darknessMultiplier, "", "- "));
	table.insert(parts, FTE_Utils.getToolTipTextSubValue("[D] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus"), visionBonus, "", "- "));
	table.insert(parts, FTE_Utils.getToolTipTextSubValue("[E] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), otherPenalties, "", "- "));
	table.insert(parts, " <LINE> ");
    
    -- D. Best Vision Bonus detailed breakdown
	if FTE_ModOptions.shouldShowVisionBonusDetails() or math.abs(visionBonus - 1) >= 0.01 then
        table.insert(parts, buildVisionBonusDetailsText(visionBonus, modifiers));
		table.insert(parts, " <LINE> ")
	end

    -- E. State Penalties detailed breakdown
	if FTE_ModOptions.shouldShowZeroPenalties() or math.abs(otherPenalties - 1) >= 0.01 then
        local penaltiesSection = buildPenaltiesText(modifiers, otherPenalties, FTE_ModOptions.shouldShowZeroPenalties());
        if penaltiesSection and penaltiesSection ~= "" then
            table.insert(parts, penaltiesSection);
            table.insert(parts, " <LINE> ");
        end
	end

	-- Add food detection section
	local foodDetectionSection = addFoodDetectionSection(zoneDisplay.character)
	if foodDetectionSection and foodDetectionSection ~= "" then
		table.insert(parts, foodDetectionSection);
		table.insert(parts, " <LINE> ");
	end

    -- Add trait/profession bonuses
    local totalBonus = modifiers.professionBonus + modifiers.traitBonus
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Trait_Profession_Bonuses"));
    table.insert(parts, " <LINE> ");
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Bonus_Radius"));
    table.insert(parts, ": <SPACE> ");
    table.insert(parts, FTE_Utils.getRGBForTooltip(totalBonus > 0, totalBonus == 0));
    table.insert(parts, string.format("%+.2f", totalBonus));
    table.insert(parts, " <LINE> ");
	
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

    -- Add sorted character items to text
	local shouldShowZeroTraitBonuses = FTE_ModOptions.shouldShowZeroTraitBonuses()
	for i = 1, #characterItems do
		local item = characterItems[i];
		if shouldShowZeroTraitBonuses or not item.isBonus or item.value ~= 0 then
			table.insert(parts, FTE_Utils.getToolTipText(item.text, item.value, item.isBonus));
		end
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
