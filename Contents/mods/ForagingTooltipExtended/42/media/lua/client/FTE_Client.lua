local DEBUG_MODE = false

local FTE_ModOptions = require "FTE_ModOptions"
local FTE_Utils = require "FTE_Utils"

-- ===================================================================================================== --
-- VISION CALCULATION CONSTANTS AND CACHE
-- ===================================================================================================== --

local VIEW_DISTANCE_REFERENCE_SIZES = {
    small = 0.1,
    medium = 1.0,
    large = 10.0
}

local iconCache = {}

-- ===================================================================================================== --
-- VISION DISTANCE CALCULATION FUNCTIONS
-- ===================================================================================================== --

---Create or retrieve cached ISBaseIcon instance for vision calculation
---@param character IsoGameCharacter The player character
---@param itemSize number The synthetic item size (e.g., 0.1, 1.0, 10.0)
---@param square IsoGridSquare|nil The square to use for calculation (defaults to character's current square)
---@param searchManager ISSearchManager The search manager to use (required for real calculation)
---@return ISBaseIcon realIcon The cached or newly created icon instance
local function createRealIconForVisionCalculation(character, itemSize, square, searchManager)
    local cacheKey = "size_" .. tostring(itemSize);
    
    if iconCache[cacheKey] then
        return iconCache[cacheKey];
    end
    
    local targetSquare = square or character:getCurrentSquare();
    local itemType = "Base.Stone2";
    
    local iconData = {
        id = itemType .. "_vision_calc_" .. tostring(itemSize),
        x = 0,
        y = 0,
        z = 0,
		itemType = itemType,
        itemSize = itemSize,
    };
    
    local icon = ISBaseIcon:new(searchManager, iconData);
    
    icon.itemDef = {
        type = itemType,
        minCount = 1,
        maxCount = 1,
        spawnFuncs = nil
    };
    
    icon.itemObj = instanceItem("Base.Stone2");
    icon.square = targetSquare;
    
    icon:setIsSeen(false);
    icon:setIsNoticed(false);
    icon:setAlpha(1.0);
    
    icon:initGridSquare();
    icon:initItem();
    
    iconCache[cacheKey] = icon;
    
    return icon;
end

---Get view distance for a specific item size using cached icons and vanilla calculation
---@param character IsoGameCharacter The player character
---@param itemSize number The item size to calculate view distance for
---@param searchManager ISSearchManager The search manager to use for vision calculation
---@return number viewDistance The calculated view distance in tiles
local function getItemViewDistance(character, itemSize, searchManager)
    local currentSquare = character:getCurrentSquare();
    local itemIcon = createRealIconForVisionCalculation(character, itemSize, currentSquare, searchManager);
    
    itemIcon:updateModifiers();
    local viewDistance = itemIcon:doVisionCheck();

    return viewDistance;
end

---Get view distances for all reference item sizes (small, medium, large)
---@param character IsoGameCharacter The player character
---@param searchManager ISSearchManager The search manager to use for vision calculation
---@return table viewDistances
local function getAllViewDistances(character, searchManager)
    return {
        small = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.small, searchManager),
        medium = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.medium, searchManager),
        large = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.large, searchManager)
    };
end

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
	local parts = {
		" ", Colors.white, "E. ", getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), 
		": <SPACE> ", FTE_Utils.getRGBForValue(_otherPenalties), FTE_Utils.formatNumber(_otherPenalties), " <LINE> "
	}
	
	local penaltyItems = {
		{modifier = _modifiers.clothingPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Clothing"},
		{modifier = _modifiers.exhaustionPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"},
		{modifier = _modifiers.panicPenalty, textKey = "IGUI_StatsAndBody_Panic"},
		{modifier = _modifiers.bodyPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"},
		{modifier = _modifiers.movementPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Movement"}
	}
	
	for i = 1, #penaltyItems do
		local item = penaltyItems[i];
		if _shouldShowZeroPenalties or math.abs(item.modifier - 1) >= 0.01 then
			table.insert(parts, FTE_Utils.getToolTipTextSubValue(getText(item.textKey), item.modifier, "", "- "));
		end
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
	
	-- Check if we should show this section when bonus is 0
	if hungerBonus <= 1 and not FTE_ModOptions.shouldShowZeroFoodDetection() then
		return ""
	end
    
	local result = " " .. Colors.white .. getText("IGUI_FTE_Food_Detection_Header") .. " (" .. getText("IGUI_StatsAndBody_Hunger") .. ")" .. " <LINE> "
	
	if hungerBonus > 1 then
		local bonusPercent = (hungerBonus - 1.0) * 100
		result = result .. " " .. Colors.white .. "- " .. getText("IGUI_FTE_Food_Detection_Bonus") .. 
				": <SPACE> " .. Colors.good .. "+" .. FTE_Utils.formatNumber(bonusPercent) .. "% <LINE> "
	else
		result = result .. " " .. Colors.white .. "- " .. getText("IGUI_FTE_Food_Detection_Bonus") .. 
				": <SPACE> " .. Colors.grey .. "0% <LINE> "
	end
    
    return result
end

---Generate view distance section showing how far the character can see different item sizes
---@param character IsoGameCharacter
---@param searchManager ISSearchManager
---@return string
local function addViewDistanceSection(character, searchManager)
    local viewDistances = getAllViewDistances(character, searchManager)
    
    local parts = {
        " ", Colors.white, getText("IGUI_FTE_View_Distance_Header"), " <LINE> ",
        " ", Colors.white, "- ", getText("IGUI_FTE_View_Distance_Small"), ": <SPACE> ", 
        Colors.good, FTE_Utils.formatNumber(viewDistances.small), " <LINE> ",
        " ", Colors.white, "- ", getText("IGUI_FTE_View_Distance_Medium"), ": <SPACE> ", 
        Colors.good, FTE_Utils.formatNumber(viewDistances.medium), " <LINE> ",
        " ", Colors.white, "- ", getText("IGUI_FTE_View_Distance_Large"), ": <SPACE> ", 
        Colors.good, FTE_Utils.formatNumber(viewDistances.large), " <LINE> "
    }
    
    return table.concat(parts)
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
-- MAIN TOOLTIP GENERATION FUNCTION
-- ===================================================================================================== --

---@param zoneDisplay ISZoneDisplay
---@return string
local function getVisionTooltipTextB429Extended(zoneDisplay)
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
	if FTE_ModOptions.shouldShowZeroPenalties() then
        table.insert(parts, buildPenaltiesText(modifiers, otherPenalties, true));
        table.insert(parts, " <LINE> ");
	end

	-- Add view distance section if enabled
	if FTE_ModOptions.shouldShowViewDistance() then
		table.insert(parts, addViewDistanceSection(zoneDisplay.character, searchManager));
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
-- MAIN FUNCTION OVERRIDE
-- ===================================================================================================== --

-- Override the main function
local originalGetVisionTooltipText = ISZoneDisplay.getVisionTooltipText
local hasExtendedTooltipFailed = false -- Track if extended tooltip has failed

function ISZoneDisplay:getVisionTooltipText()
    if DEBUG_MODE then
        -- DEBUG MODE: Use extended tooltip directly without fallback (fail fast)
        return getVisionTooltipTextB429Extended(self)
    else
        -- PRODUCTION MODE: Use original if extended version has failed before
        if hasExtendedTooltipFailed then
            return originalGetVisionTooltipText(self)
        end
        
        -- Try extended tooltip, but switch to original permanently on any failure
        local success, result = pcall(function()
            return getVisionTooltipTextB429Extended(self)
        end)
        
        if success and result and result ~= "" then
            return result
        else
			print("[FTE] Extended tooltip failed, switching to original permanently. Error: " .. tostring(result))
            hasExtendedTooltipFailed = true
            return originalGetVisionTooltipText(self)
        end
    end
end