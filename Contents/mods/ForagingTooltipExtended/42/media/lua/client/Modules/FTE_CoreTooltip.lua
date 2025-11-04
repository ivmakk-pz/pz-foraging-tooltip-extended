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

local function buildFormulaString(_formulaData)
	local parts = {};
	for i = 1, #_formulaData do
		local data = _formulaData[i];
		table.insert(parts, FTE_Utils.getRGBForValue(data.value) .. data.letter .. Colors.white);
		if i < #_formulaData then
			table.insert(parts, " <SPACE> * <SPACE> ");
		end
	end
	return " " .. Colors.white .. "- Formula: <SPACE>" .. table.concat(parts) .. " <LINE> ";
end

---Builds the penalties section for the tooltip
---@param _modifiers table
---@param _otherPenalties number
---@param _shouldShowZeroPenalties boolean
---@return string
local function buildPenaltiesText(_modifiers, _otherPenalties, _shouldShowZeroPenalties)
	-- Removed clothing from this section - it now has its own F section
	local penaltyItems = {
		{modifier = _modifiers.exhaustionPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"},
		{modifier = _modifiers.panicPenalty, textKey = "IGUI_StatsAndBody_Panic"},
		{modifier = _modifiers.bodyPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"},
		{modifier = _modifiers.movementPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Movement"}
	}
	
	-- Collect sub-items that should be displayed
	local subItems = {}
	local labels = {}
	for i = 1, #penaltyItems do
		local item = penaltyItems[i];
		if _shouldShowZeroPenalties or math.abs(item.modifier - 1) >= 0.01 then
			table.insert(subItems, {text = getText(item.textKey), value = item.modifier})
			table.insert(labels, getText(item.textKey) .. ":")
		end
	end
	
	-- Only build section if there are sub-items to display
	if #subItems == 0 then
		return ""
	end
	
	-- Build header
	local parts = {
		" ", Colors.white, "E. ", getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), 
		": <SPACE> ", FTE_Utils.getRGBForValue(_otherPenalties), FTE_Utils.formatNumber(_otherPenalties), " <LINE> "
	}
	
	-- Calculate max label width for aligned sub-items
	local maxLabelWidth = FTE_Utils.calculateMaxLabelWidth(labels)
	local valueXPosition = FTE_Utils.TREE_CONNECTOR_SIZE + maxLabelWidth + 20
	
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
		" ", Colors.white, "F. ", getText("IGUI_SearchMode_Vision_Effect_Clothing"),
		": <SPACE> ", FTE_Utils.getRGBForValue(_modifiers.clothingPenalty), FTE_Utils.formatNumber(_modifiers.clothingPenalty), " <LINE> "
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

---@param character IsoGameCharacter
---@return string
local function addFoodDetectionSection(character)
	local hungerBonus = getHungerBonus(character)
	
	-- Hide section if no bonus
	if hungerBonus <= 1.01 then
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
    
    -- Calculate max label width for aligned sub-items
    local labels = {
        getText("IGUI_SearchMode_Vision_Effect_Aiming") .. ":",
        getText("IGUI_SearchMode_Vision_Effect_Crouching") .. ":"
    }
    local maxLabelWidth = FTE_Utils.calculateMaxLabelWidth(labels)
    local valueXPosition = FTE_Utils.TREE_CONNECTOR_SIZE + maxLabelWidth + 20
    
    table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(getText("IGUI_SearchMode_Vision_Effect_Aiming"), _modifiers.aimBonus, false, valueXPosition))
    table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(getText("IGUI_SearchMode_Vision_Effect_Crouching"), _modifiers.sneakBonus, true, valueXPosition))
    
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
    
    -- Formula string (A * B * C * D * E * F)
	if FTE_ModOptions.shouldShowFormula() then
        local formulaData = {
            {letter = "A", value = baseRadius},
            {letter = "B", value = weatherPenalty},
            {letter = "C", value = darknessMultiplier},
            {letter = "D", value = visionBonus},
            {letter = "E", value = otherPenalties},
            {letter = "F", value = clothingPenalty}
        };

		table.insert(parts, buildFormulaString(formulaData));
	end

    -- Add modifiers section
	table.insert(parts, " <LINE> ");
    table.insert(parts, " ");
    table.insert(parts, Colors.white);
    table.insert(parts, getText("IGUI_FTE_SearchMode_Vision_Effect_Search_Radius_Modifiers"));
    table.insert(parts, " <LINE> ");
	
	-- Calculate max label width for column alignment (like vanilla ISCraftingUI.lua)
	local labels = {
		"[A] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits") .. ":",
		"[B] " .. getText("IGUI_SearchMode_Vision_Effect_Weather") .. ":",
		"[C] " .. getText("IGUI_SearchMode_Vision_Effect_Darkness") .. ":",
		"[D] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus") .. ":",
		"[E] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties") .. ":",
		"[F] " .. getText("IGUI_SearchMode_Vision_Effect_Clothing") .. ":"
	}
	local maxLabelWidth = FTE_Utils.calculateMaxLabelWidth(labels)
	local valueXPosition = FTE_Utils.TREE_CONNECTOR_SIZE + maxLabelWidth + 20  -- Tree icon + label + padding
	
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[A] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits"), baseRadius, false, valueXPosition));
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[B] " .. getText("IGUI_SearchMode_Vision_Effect_Weather"), weatherPenalty, false, valueXPosition));
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[C] " .. getText("IGUI_SearchMode_Vision_Effect_Darkness"), darknessMultiplier, false, valueXPosition));
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[D] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus"), visionBonus, false, valueXPosition));
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[E] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), otherPenalties, false, valueXPosition));
	table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage("[F] " .. getText("IGUI_SearchMode_Vision_Effect_Clothing"), clothingPenalty, true, valueXPosition));
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

	-- F. Clothing Effect with vision-affecting items
	local clothingSection = buildClothingEffectText(modifiers, zoneDisplay.character)
	if clothingSection and clothingSection ~= "" then
		table.insert(parts, clothingSection);
		table.insert(parts, " <LINE> ");
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
	for i = 1, #characterItems do
		local item = characterItems[i];
		if not item.isBonus or item.value ~= 0 then
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
