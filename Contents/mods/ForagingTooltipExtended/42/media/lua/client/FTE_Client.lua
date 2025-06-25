local GHC = getCore():getGoodHighlitedColor()
local BHC = getCore():getBadHighlitedColor()

-- Import mod options
local FTE_ModOptions = require "FTE_ModOptions"

-- Unified color schema for tooltips
local Colors = {
	white = " <RGB:1,1,1> ",
	grey = " <RGB:0.75,0.75,0.75> ",
	good = " <RGB:"..GHC:getR()..","..GHC:getG()..","..GHC:getB().."> ",
	bad = " <RGB:"..BHC:getR()..","..BHC:getG()..","..BHC:getB().."> "
}

-- Helper function to format numbers with 2 decimal places
local function formatNumber(value)
	return string.format("%.2f", value);
end

local function getRGBForTooltip(_isGreen, _isZero)
	if _isZero then return Colors.grey; end;
	if _isGreen then return Colors.good; end;
	return Colors.bad;
end

-- Updated function to get color for value-based tooltips (multipliers, etc.)
local function getRGBForValue(_value)
	if math.abs(_value - 1) < 0.01 then
		return Colors.grey; -- Neutral (1.0)
	elseif _value < 1 then
		return Colors.bad; -- Penalty (red)
	else
		return Colors.good; -- Bonus (green)
	end
end

local function formatPercent(_float)
	if _float == 0 then
		return "0";
	end
	return string.format("%+.2f", _float * 100);
end

local function getToolTipText(_text, _value, _isBonus)
	-- Show 0 values in grey color instead of hiding them
	local text = _text .. ": <SPACE> ";
	local isZero = (_value == 0);
	if _isBonus then
		return " " .. Colors.white .. text .. getRGBForTooltip(_value > 0, isZero) .. formatPercent(_value) .. " % <LINE> ";
	else
		return " " .. Colors.white .. text .. getRGBForTooltip(_value < 0, isZero) .. formatPercent(_value) .. " % <LINE> ";
	end;
end

local function getToolTipTextRadius(_text, _value, _isAtMinRadius, _isAtMaxRadius)
	-- Use red for radius when at minimum, green for positive values
	local color;
	local extraText = "";
	
	if _isAtMinRadius then
		color = Colors.bad; -- Red when at minimum radius
		extraText = color .. " <SPACE> (min)" .. Colors.white;
	elseif _isAtMaxRadius then
		color = Colors.good; -- Green when at maximum radius
		extraText = color .. " <SPACE> (max)" .. Colors.white;
	else
		color = Colors.good; -- Green for positive radius
	end
	
	return " " .. Colors.white .. _text .. ": <SPACE> " .. color .. formatNumber(_value) .. extraText .. " <LINE> ";
end

local function getToolTipTextSubValue(_text, _value, _suffix, _prefix)
	local prefix = _prefix or "- ";
	local suffix = _suffix or "";
	
	-- Use the new color function for consistent game color scheme
	local color = getRGBForValue(_value);
	
	return " " .. Colors.white .. prefix .. _text .. ": <SPACE> " .. color .. formatNumber(_value) .. suffix .. " <LINE> ";
end

-- Helper function to format formula values with colored letters
local function formatFormulaValue(_letter, _value, _isAtMinRadius, _isAtMaxRadius)
	if _isAtMinRadius or _isAtMaxRadius then
		return Colors.grey .. _letter .. Colors.white; -- All grey when at minimum or maximum radius
	else
		return getRGBForValue(_value) .. _letter .. Colors.white;
	end
end

-- Helper function to build complete formula string from array of letter-value pairs
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

-- Helper function to sort tooltip items (non-zero first in original order, then zero values)
local function sortTooltipItems(items)
    -- Add original index to preserve order
    for i = 1, #items do
        local item = items[i];
        item.originalIndex = i
    end
    
    table.sort(items, function(a, b)
        -- If one is zero and the other is not, non-zero comes first
        if a.value == 0 and b.value ~= 0 then
            return false
        elseif a.value ~= 0 and b.value == 0 then
            return true        end
        -- If both are zero or both are non-zero, maintain original order
        return a.originalIndex < b.originalIndex
    end)
end

-- Helper function to generate min/max values text
local function buildMinMaxText(_visionRadius, _searchManager)
	local text = "";
	local minRadius = _searchManager.minRadius;
	local maxRadius = _searchManager.maxRadiusCap
	local minColor = Colors.grey;
	local maxColor = Colors.grey;

	-- Color min radius red if current radius equals min, max radius green if current equals max
	if math.abs(_visionRadius - minRadius) < 0.01 then
		minColor = Colors.bad; -- Red for hitting minimum
	end
	if math.abs(_visionRadius - maxRadius) < 0.01 then
		maxColor = Colors.good; -- Green for hitting maximum
	end

	text = text .. " " .. Colors.white .. "- Min: <SPACE> " .. minColor .. formatNumber(minRadius) .. " <LINE> ";
	text = text .. " " .. Colors.white .. "- Max: <SPACE> " .. maxColor .. formatNumber(maxRadius) .. " <LINE> ";
	
	return text;
end

-- Helper function to generate penalties tooltip section
local function buildPenaltiesText(_modifiers, _otherPenalties)
	local text = "";
	
	-- E. State Penalties detailed breakdown
	text = text .. " " .. Colors.white .. "E. " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties") .. ": <SPACE> " .. getRGBForValue(_otherPenalties) .. formatNumber(_otherPenalties) .. " <LINE> ";	
	-- Get option for showing zero penalties
	local shouldShowZeroPenalties = FTE_ModOptions.shouldShowZeroPenalties()
	
	-- Define penalty items with their modifier and text key
	local penaltyItems = {
		{modifier = _modifiers.clothingPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Clothing"},
		{modifier = _modifiers.exhaustionPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"},
		{modifier = _modifiers.panicPenalty, textKey = "IGUI_StatsAndBody_Panic"},
		{modifier = _modifiers.bodyPenalty, textKey = "IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"},
		{modifier = _modifiers.movementPenalty, textKey = "IGUI_SearchMode_Vision_Effect_Movement"}
	}
	
	-- Show each penalty sub-item conditionally
	for i = 1, #penaltyItems do
		local item = penaltyItems[i];
		if shouldShowZeroPenalties or math.abs(item.modifier - 1) >= 0.01 then
			text = text .. getToolTipTextSubValue(getText(item.textKey), item.modifier, "", "- ");
		end
	end
	
	return text;
end

---@param zoneDisplay ISZoneDisplay
---@return string
local function getVisionTooltipTextB429Extended(zoneDisplay)
	local text = "";

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
	                      modifiers.clothingPenalty * modifiers.movementPenalty;	-- Track which vision bonus is active
	-- Check if current radius equals minimum or maximum radius
	local isAtMinRadius = math.abs(visionRadius - searchManager.minRadius) < 0.01;
	local isAtMaxRadius = math.abs(visionRadius - searchManager.maxRadiusCap) < 0.01;
	text = text .. getToolTipTextRadius(getText("IGUI_SearchMode_Vision_Effect_Radius"), visionRadius, isAtMinRadius, isAtMaxRadius);
    
    -- Formula string
	if FTE_ModOptions.shouldShowFormula() then
        local formulaData = {
            {letter = "A", value = baseRadius},
            {letter = "B", value = weatherPenalty},
            {letter = "C", value = darknessMultiplier},
            {letter = "D", value = visionBonus},
            {letter = "E", value = otherPenalties}
        };

		text = text .. buildFormulaString(formulaData, isAtMinRadius, isAtMaxRadius);
	end
	
	-- Min/Max
	if FTE_ModOptions.shouldShowMinMaxValues() then
		text = text .. buildMinMaxText(visionRadius, searchManager);
	end

    text = text .. " <LINE> ";
    text = text .. " " .. Colors.white .. getText("IGUI_FTE_SearchMode_Vision_Effect_Search_Radius_Modifiers") .. " <LINE> ";
	text = text .. getToolTipTextSubValue("[A] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits"), baseRadius, "", "- ");
	text = text .. getToolTipTextSubValue("[B] " .. getText("IGUI_SearchMode_Vision_Effect_Weather"), weatherPenalty, "", "- ");
	text = text .. getToolTipTextSubValue("[C] " .. getText("IGUI_SearchMode_Vision_Effect_Darkness"), darknessMultiplier, "", "- ");
	text = text .. getToolTipTextSubValue("[D] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus"), visionBonus, "", "- ");
	text = text .. getToolTipTextSubValue("[E] " .. getText("IGUI_FTE_SearchMode_Vision_Effect_State_Penalties"), otherPenalties, "", "- ");
	text = text .. " <LINE> ";
    
    -- D. Best Vision Bonus detailed breakdown
	local shouldShowVisionBonusDetails = FTE_ModOptions.shouldShowVisionBonusDetails()
	if shouldShowVisionBonusDetails or math.abs(visionBonus - 1) >= 0.01 then
        text = text .. " " .. Colors.white .. "D. " .. getText("IGUI_FTE_SearchMode_Vision_Effect_Best_Vision_Bonus") .. ": <SPACE> " .. getRGBForValue(visionBonus) .. formatNumber(visionBonus) .. " <LINE> ";
		text = text .. getToolTipTextSubValue(getText("IGUI_SearchMode_Vision_Effect_Aiming"), modifiers.aimBonus, "", "- ");
		text = text .. getToolTipTextSubValue(getText("IGUI_SearchMode_Vision_Effect_Crouching"), modifiers.sneakBonus, "", "- ");
        text = text .. " <LINE> ";
	end

    -- E. State Penalties detailed breakdown - use helper function
	local shouldShowZeroTraitBonuses = FTE_ModOptions.shouldShowZeroTraitBonuses()
	if shouldShowZeroTraitBonuses then
        text = text .. buildPenaltiesText(modifiers, otherPenalties);
        text = text .. " <LINE> ";
	end

    local totalBonus = modifiers.professionBonus + modifiers.traitBonus
    text = text .. Colors.white .. getText("IGUI_SearchMode_Vision_Effect_Trait_Profession_Bonuses") .. " <LINE> ";
    text = text .. Colors.white .. getText("IGUI_SearchMode_Vision_Effect_Bonus_Radius") .. ": <SPACE> " .. getRGBForTooltip(totalBonus > 0) .. string.format("%+.2f", totalBonus) .. " <LINE> ";
	
	-- Collect character effect items for sorting
	local characterItems = {    
		{text = getText("IGUI_SearchMode_Vision_Effect_Weather"), value = forageSystem.getWeatherEffectReduction(zoneDisplay.character) - 1, isBonus = false},
		{text = getText("IGUI_SearchMode_Vision_Effect_Darkness"), value = forageSystem.getDarknessEffectReduction(zoneDisplay.character) - 1, isBonus = false}
	}
	
	-- Add category bonuses to character items
	for _, catDef in pairs(forageSystem.catDefs) do
		local catVisionEffect = forageSystem.getCategoryBonus(zoneDisplay.character, catDef) - 1;
		local categoryText = getTextOrNull("IGUI_SearchMode_Categories_"..catDef.name);
		if categoryText then
			table.insert(characterItems, {text = categoryText, value = catVisionEffect, isBonus = true})
		end;
	end;
	
	-- Sort character items (non-zero first, then zero)
	sortTooltipItems(characterItems)

    -- Add sorted character items to text
	for i = 1, #characterItems do
		local item = characterItems[i];		-- Show zero bonuses if the option is enabled or if it's not a bonus category or if value is non-zero
		if shouldShowZeroTraitBonuses or not item.isBonus or item.value ~= 0 then
			text = text .. getToolTipText(item.text, item.value, item.isBonus)
		end
	end
	
	return text;
end

-- Override the main function
local originalGetVisionTooltipText = ISZoneDisplay.getVisionTooltipText

-- Circuit breaker: disable extended tooltip after first error
local extendedTooltipDisabled = false

function ISZoneDisplay:getVisionTooltipText()
    -- If extended tooltip has failed before, skip it entirely
    if extendedTooltipDisabled then
        return originalGetVisionTooltipText(self)
    end
    
    -- Try to generate extended tooltip, fall back to original on error
    local success, result = pcall(function()
        return getVisionTooltipTextB429Extended(self)
    end)
    
    if success then
        return result
    else
        -- Disable extended tooltip for the rest of the session
        extendedTooltipDisabled = true
        
        -- Log the error for debugging
        print("[FTE] Error generating extended tooltip: " .. tostring(result))
        print("[FTE] Extended tooltip disabled for this session. Falling back to original tooltip.")
        
        -- Fall back to original tooltip
        return originalGetVisionTooltipText(self)
    end
end