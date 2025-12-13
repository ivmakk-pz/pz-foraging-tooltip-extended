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

-- ===================================================================================================== --
-- TOOLTIP BUILDING HELPER FUNCTIONS
-- ===================================================================================================== --

local Colors = FTE_Utils.Colors

---Get hunger-based food detection bonus
---@param character IsoGameCharacter
---@return number
local function getHungerBonus(character)
	local hungerLevel = character:getStats():get(CharacterStat.HUNGER);
	local hungerBonus = 1 + ((forageSystem.hungerBonusMax * hungerLevel) / 100);
	return hungerBonus;
end

---Add aligned label and value to parts table (eliminates repeated alignment logic)
---@param parts table Array to append formatted text to
---@param label string The label text (will be colored white)
---@param value string The value text (pre-formatted with color)
---@param valueXPos number|nil X position for right alignment (nil for left alignment)
---@param alignment string Alignment constant from FTE_Utils.Alignment ("left" or "right")
local function addAlignedValue(parts, label, value, valueXPos, alignment)
	table.insert(parts, Colors.white)
	table.insert(parts, label)
	if alignment == FTE_Utils.Alignment.RIGHT and valueXPos then
		table.insert(parts, " <SETX:")
		table.insert(parts, tostring(valueXPos))
		table.insert(parts, "> ")
	else
		table.insert(parts, ": <SPACE> ")
	end
	table.insert(parts, value)
	table.insert(parts, " <LINE> ")
end

---Collect radius data and modifiers from zone display
---@param zoneDisplay ISZoneDisplay
---@return table {visionRadius, modifiers, baseRadius, minRadius, maxRadius, isAtMinRadius, isAtMaxRadius}
local function collectRadiusData(zoneDisplay)
	local searchManager = zoneDisplay.manager
	local visionRadius = searchManager:getOverlayRadius()
	local modifiers = searchManager.modifiers
	
	-- Calculate detailed radius breakdown
	searchManager:updateModifiers()
	local traitBonus = modifiers.traitBonus
	local professionBonus = modifiers.professionBonus
	local minRadius = searchManager.minRadius + professionBonus + traitBonus
	local maxRadius = searchManager.maxRadius + professionBonus + traitBonus
	local levelRadius = (maxRadius - minRadius) * (searchManager.perkLevel / 10)
	local baseRadius = minRadius + levelRadius
	
	-- Check if at min/max caps
	local isAtMinRadius = math.abs(visionRadius - searchManager.minRadius) < 0.01
	local isAtMaxRadius = math.abs(visionRadius - searchManager.maxRadiusCap) < 0.01
	
	return {
		visionRadius = visionRadius,
		modifiers = modifiers,
		baseRadius = baseRadius,
		minRadius = minRadius,
		maxRadius = maxRadius,
		isAtMinRadius = isAtMinRadius,
		isAtMaxRadius = isAtMaxRadius
	}
end

---Collect base modifier items for display
---@param modifiers table Modifier data from search manager
---@param baseRadius number Calculated base radius value
---@return table Array of {text, value, showAlways, forceWhite}
local function collectBaseModifiers(modifiers, baseRadius)
	local visionBonus = math.max(modifiers.aimBonus, modifiers.sneakBonus)
	
	return {
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Base_Skill_Traits"), value = baseRadius, showAlways = true, forceWhite = true},
		{text = getText("IGUI_SearchMode_Vision_Effect_Weather"), value = modifiers.weatherPenalty},
		{text = getText("IGUI_SearchMode_Vision_Effect_Darkness"), value = modifiers.lightPenalty},
		{text = modifiers.aimBonus >= modifiers.sneakBonus and getText("IGUI_SearchMode_Vision_Effect_Aiming") or getText("IGUI_SearchMode_Vision_Effect_Crouching"), value = visionBonus},
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Exhaustion"), value = modifiers.exhaustionPenalty},
		{text = getText("IGUI_StatsAndBody_Panic"), value = modifiers.panicPenalty},
		{text = getText("IGUI_FTE_SearchMode_Vision_Effect_Body_Damage"), value = modifiers.bodyPenalty},
		{text = getText("IGUI_SearchMode_Vision_Effect_Movement"), value = modifiers.movementPenalty}
	}
end

---Collect bonus data (trait/profession and food detection)
---@param character IsoGameCharacter
---@param modifiers table Modifier data from search manager
---@return table {totalBonus, hungerBonus, hasFoodDetection}
local function collectBonusData(character, modifiers)
	local totalBonus = modifiers.professionBonus + modifiers.traitBonus
	local hungerBonus = getHungerBonus(character)
	local hasFoodDetection = hungerBonus > 1.01
	
	return {
		totalBonus = totalBonus,
		hungerBonus = hungerBonus,
		hasFoodDetection = hasFoodDetection
	}
end

---Collect and sort character effect items (weather, darkness, category bonuses)
---@param character IsoGameCharacter
---@return table Sorted array of {text, value, isBonus}
local function collectCharacterEffects(character)
	local characterItems = {}
	
	-- Add weather and darkness effects
	table.insert(characterItems, {
		text = getText("IGUI_SearchMode_Vision_Effect_Weather"),
		value = forageSystem.getWeatherEffectReduction(character) - 1,
		isBonus = false
	})
	table.insert(characterItems, {
		text = getText("IGUI_SearchMode_Vision_Effect_Darkness"),
		value = forageSystem.getDarknessEffectReduction(character) - 1,
		isBonus = false
	})
	
	-- Add category bonuses
	for _, catDef in pairs(forageSystem.catDefs) do
		if catDef and catDef.name then
			local catVisionEffect = forageSystem.getCategoryBonus(character, catDef) - 1
			local categoryText = getTextOrNull("IGUI_SearchMode_Categories_"..catDef.name)
			if categoryText then
				table.insert(characterItems, {
					text = categoryText,
					value = catVisionEffect,
					isBonus = true
				})
			end
		end
	end
	
	-- Sort (non-zero first, then zero)
	FTE_Utils.sortTooltipItems(characterItems)
	
	return characterItems
end

---Format main radius section with min/max indicators
---@param radiusData table Data from collectRadiusData()
---@param alignment string Alignment constant ("left" or "right")
---@return string Formatted text parts
local function formatMainRadiusSection(radiusData, alignment)
	return FTE_Utils.getToolTipTextRadius(
		getText("IGUI_SearchMode_Vision_Effect_Radius"),
		radiusData.visionRadius,
		radiusData.isAtMinRadius,
		radiusData.isAtMaxRadius,
		alignment
	)
end

---Format base modifiers section with tree connectors
---@param baseModifiers table Array of modifier items
---@param wornItems table Array of worn item effects
---@param valueXPos number|nil X position for alignment
---@param alignment string Alignment constant ("left" or "right")
---@return string Formatted text string
local function formatBaseModifiersSection(baseModifiers, wornItems, valueXPos, alignment)
	local parts = {}
	
	-- Filter base modifiers: show always-visible items and items with impact
	local displayItems = {}
	for i = 1, #baseModifiers do
		local item = baseModifiers[i]
		if item.showAlways or math.abs(item.value - 1) >= 0.01 then
			table.insert(displayItems, item)
		end
	end
	
	-- Add worn items to display list
	for i = 1, #wornItems do
		table.insert(displayItems, wornItems[i])
	end
	
	-- Add all items with tree connectors
	for i = 1, #displayItems do
		local item = displayItems[i]
		local isLast = (i == #displayItems)
		
		-- Handle forceWhite flag for values that should always be white
		local valueToDisplay = item.value
		if item.forceWhite then
			valueToDisplay = Colors.white .. FTE_Utils.formatNumber(item.value)
		end
		
		table.insert(parts, FTE_Utils.getToolTipTextWithTreeImage(
			item.text,
			valueToDisplay,
			isLast,
			valueXPos,
			alignment
		))
	end
	
	table.insert(parts, " <LINE> ")
	
	return table.concat(parts)
end

---Format trait/profession bonus section with food detection
---@param bonusData table Data from collectBonusData()
---@param valueXPos number|nil X position for alignment
---@param alignment string Alignment constant ("left" or "right")
---@return string Formatted text string
local function formatBonusSection(bonusData, valueXPos, alignment)
	local parts = {}
	
	-- Section header
	table.insert(parts, Colors.white)
	table.insert(parts, getText("IGUI_SearchMode_Vision_Effect_Trait_Profession_Bonuses"))
	table.insert(parts, " <LINE> ")
	
	-- Food detection bonus (if applicable)
	if bonusData.hasFoodDetection then
		local foodDetectionValue = bonusData.hungerBonus - 1.0
		local formattedFoodBonus = Colors.good .. FTE_Utils.formatPercentShort(foodDetectionValue) .. "%"
		addAlignedValue(
			parts,
			getText("IGUI_FTE_Food_Detection_Header") .. " (" .. getText("IGUI_StatsAndBody_Hunger") .. ")",
			formattedFoodBonus,
			valueXPos,
			alignment
		)
	end
	
	-- Total bonus radius
	local bonusColor = FTE_Utils.getRGBForTooltip(bonusData.totalBonus > 0, bonusData.totalBonus == 0)
	local formattedTotalBonus = bonusColor .. string.format("%+.1f", bonusData.totalBonus)
	addAlignedValue(
		parts,
		getText("IGUI_SearchMode_Vision_Effect_Bonus_Radius"),
		formattedTotalBonus,
		valueXPos,
		alignment
	)
	
	return table.concat(parts)
end

---Format character effects section (weather, darkness, categories)
---@param characterEffects table Array from collectCharacterEffects()
---@param valueXPos number|nil X position for alignment
---@param alignment string Alignment constant ("left" or "right")
---@return string Formatted text string
local function formatCharacterEffectsSection(characterEffects, valueXPos, alignment)
	local parts = {}
	
	-- Filter items that should be displayed
	local displayItems = {}
	for i = 1, #characterEffects do
		local item = characterEffects[i]
		if not item.isBonus or item.value ~= 0 then
			table.insert(displayItems, item)
		end
	end
	
	-- Add filtered items
	for i = 1, #displayItems do
		local item = displayItems[i]
		
		-- Format percentage value with proper color
		local valueColor = item.isBonus and FTE_Utils.getRGBForTooltip(item.value > 0, item.value == 0)
		                                  or FTE_Utils.getRGBForTooltip(item.value < 0, item.value == 0)
		local formattedValue = valueColor .. FTE_Utils.formatPercentShort(item.value) .. "%"
		
		addAlignedValue(parts, item.text, formattedValue, valueXPos, alignment)
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
	-- Initialize tooltip layout to detect font changes
	FTE_Utils.initializeTooltipLayout()
	
	-- Get alignment preference
	local alignment = FTE_ModOptions.getTooltipValueAlignment()
	local valueXPos = alignment == FTE_Utils.Alignment.RIGHT and FTE_Utils.tooltipLayout.valueXPosition or nil
	
	-- Collect all data
	local radiusData = collectRadiusData(zoneDisplay)
	local baseModifiers = collectBaseModifiers(radiusData.modifiers, radiusData.baseRadius)
	local wornItems = FTE_VisionAffectingItems.getWornItemsForTooltip(
		zoneDisplay.character,
		radiusData.modifiers.clothingPenalty
	)
	local bonusData = collectBonusData(zoneDisplay.character, radiusData.modifiers)
	local characterEffects = collectCharacterEffects(zoneDisplay.character)
	
	-- Build tooltip sections
	local parts = {}
	table.insert(parts, formatMainRadiusSection(radiusData, alignment))
	table.insert(parts, formatBaseModifiersSection(baseModifiers, wornItems, valueXPos, alignment))
	table.insert(parts, formatBonusSection(bonusData, valueXPos, alignment))
	table.insert(parts, formatCharacterEffectsSection(characterEffects, valueXPos, alignment))
	
	return table.concat(parts)
end

-- ===================================================================================================== --
-- MODULE SETUP METHOD
-- ===================================================================================================== --

---Setup the core tooltip module
function FTE_CoreTooltip:setupModule()
    self:overrideFunction(ISZoneDisplay, "getVisionTooltipText", ISZoneDisplay_getVisionTooltipText)
    
    FTE_Utils.logInfo("FTE_CoreTooltip initialized")
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
