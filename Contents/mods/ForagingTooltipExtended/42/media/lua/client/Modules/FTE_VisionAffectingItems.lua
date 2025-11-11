-- FTE_VisionAffectingItems.lua - Vision-Affecting Items Data Module
-- Provides data about clothing/items that affect search radius

local FTE_ModuleBase = require("Core/FTE_ModuleBase")
local FTE_Utils = require("FTE_Utils")
local FTE_ModOptions = require("FTE_ModOptions")

require "Foraging/forageSystem"

-- ===================================================================================================== --
-- MODULE CLASS DEFINITION
-- ===================================================================================================== --

---@class FTE_VisionAffectingItems : FTE_ModuleBase
local FTE_VisionAffectingItems = FTE_ModuleBase:derive("FTE_VisionAffectingItems")

-- Singleton instance (created immediately at module load)
local instance = FTE_VisionAffectingItems:new()
---@cast instance FTE_VisionAffectingItems

-- ===================================================================================================== --
-- CONSTANTS & CONFIGURATION
-- ===================================================================================================== --

-- Items must have a penalty to be shown (no zero-effect items by default)
local MIN_PENALTY_THRESHOLD = 0.01  -- 0.01% minimum penalty to display

-- ===================================================================================================== --
-- DATA COLLECTION FUNCTIONS
-- ===================================================================================================== --

---Calculate item penalty data from worn item
---@param wornItem WornItem The worn item wrapper object
---@return table|nil itemData Table with item info or nil if no penalty
local function calculateItemPenalty(wornItem)
    if not wornItem then return nil end
    
    local location = wornItem:getLocation()
    if not location then return nil end
    
    -- Use vanilla forageSystem.clothingPenalties table (with safety check)
    if not forageSystem or not forageSystem.clothingPenalties then return nil end
    local penaltyPercent = forageSystem.clothingPenalties[location]
    if not penaltyPercent then return nil end
    
    -- Get the actual inventory item from the wrapper
    -- wornItem is a WornItem wrapper, need to get the actual InventoryItem
    local item = wornItem:getItem()
    if not item then return nil end
    
    -- Calculate multiplier from penalty percentage
    -- Formula: 1 - (penalty / 100)
    local multiplier = 1 - (penaltyPercent / 100)
    
    -- Get item display information
    local displayName = item:getDisplayName() or item:getName() or "Unknown Item"
    
    -- Get icon - use getIcon() which returns Texture object
    local iconTexture = item:getIcon()
    local iconName = nil
    if iconTexture then
        iconName = iconTexture:getName()
    end
    
    return {
        item = item,
        location = location,
        penaltyPercent = penaltyPercent,
        multiplier = multiplier,
        iconTexture = iconTexture,
        iconName = iconName,
        displayName = displayName,
    }
end

---Sort items by penalty severity (highest first)
---@param itemsData table Array of item penalty data
---@param sortMode string|nil Sort mode: "severity" (default), "name", "type"
---@return table sortedData Sorted array of item penalty data
local function sortItems(itemsData, sortMode)
    if not itemsData or #itemsData == 0 then return itemsData end
    
    sortMode = sortMode or "severity"
    
    local sortedData = {}
    for i = 1, #itemsData do
        sortedData[i] = itemsData[i]
    end
    
    if sortMode == "severity" then
        -- Sort by penalty percentage (highest first)
        table.sort(sortedData, function(a, b)
            return a.penaltyPercent > b.penaltyPercent
        end)
    elseif sortMode == "name" then
        -- Sort alphabetically by display name
        table.sort(sortedData, function(a, b)
            return a.displayName < b.displayName
        end)
    elseif sortMode == "type" then
        -- Sort by location type, then by penalty
        table.sort(sortedData, function(a, b)
            if a.location == b.location then
                return a.penaltyPercent > b.penaltyPercent
            end
            return a.location < b.location
        end)
    end
    
    return sortedData
end

---Get all vision-affecting items worn by character
---@param character IsoPlayer The player character
---@param showZeroPenalty boolean|nil If true, include items with zero/minimal penalty
---@return table itemsData Array of item penalty data tables
local function getVisionAffectingItems(character, showZeroPenalty)
    if not character then return {} end
    
    local itemsData = {}
    local wornItems = character:getWornItems()
    if not wornItems then return itemsData end
    
    -- Iterate through worn items using Java ArrayList methods
    for i = 0, wornItems:size() - 1 do
        local wornItem = wornItems:get(i)
        if wornItem then
            local itemData = calculateItemPenalty(wornItem)
            if itemData then
                -- Filter out zero/minimal penalties unless showZeroPenalty is true
                if showZeroPenalty or itemData.penaltyPercent >= MIN_PENALTY_THRESHOLD then
                    table.insert(itemsData, itemData)
                end
            end
        end
    end
    
    return itemsData
end

-- ===================================================================================================== --
-- COLOR CODING FUNCTIONS
-- ===================================================================================================== --

---Get color code for penalty/bonus effect
---@param penaltyPercent number The penalty percentage (0-100)
---@return string rgbColor RGB color code (red for penalty, green for bonus)
local function getColorForPenalty(penaltyPercent)
    if penaltyPercent > 0 then
        return FTE_Utils.Colors.bad   -- Red for penalty (negative effect)
    else
        return FTE_Utils.Colors.good  -- Green for bonus (positive effect, if any exist)
    end
end

-- ===================================================================================================== --
-- DISPLAY FORMATTING FUNCTIONS
-- ===================================================================================================== --

---Format worn items for tooltip display
---@param itemsData table Array of item penalty data
---@return table displayItems Array of formatted display items with text and value
local function formatWornItemsForDisplay(itemsData)
    local displayItems = {}
    
    -- Use cached values for performance (calculated once, used many times)
    local maxItemNameWidth = FTE_Utils.getCachedMaxItemNameWidth()
    local currentFont = FTE_Utils.getCachedTooltipFont()
    
    for i = 1, #itemsData do
        local itemData = itemsData[i]
        
        -- Build label with icon (scaled to font size, respecting aspect ratio)
        local label = ""
        if itemData.iconName and itemData.iconTexture then
            local iconWidth, iconHeight = FTE_Utils.getScaledIconDimensions(itemData.iconTexture)
            label = " <IMAGE:" .. itemData.iconName .. "," .. iconWidth .. "," .. iconHeight .. "> "
        end
        
        -- Truncate item name if too long to prevent text overlap (responsive to font size)
        local itemName = FTE_Utils.truncateText(itemData.displayName, maxItemNameWidth, currentFont)
        label = label .. itemName
        
        table.insert(displayItems, {
            text = label,
            value = itemData.multiplier,
            showAlways = false
        })
    end
    
    return displayItems
end

-- ===================================================================================================== --
-- MODULE SETUP METHOD
-- ===================================================================================================== --

---Setup the vision-affecting items module
function FTE_VisionAffectingItems:setupModule()
    FTE_Utils.logInfo("[VisionAffectingItems] Module initialized successfully")
    -- No patches needed - this module provides data functions only
end

-- ===================================================================================================== --
-- PUBLIC MODULE API
-- ===================================================================================================== --

---Get vision-affecting items for a character
---@param character IsoPlayer The player character
---@param options table|nil Optional configuration {showZeroPenalty: boolean, sortMode: string}
---@return table itemsData Sorted array of item penalty data
function FTE_VisionAffectingItems:getItems(character, options)
    if not self:isActive() then return {} end
    
    options = options or {}
    local showZeroPenalty = options.showZeroPenalty or false
    local sortMode = options.sortMode or "severity"
    
    local itemsData = getVisionAffectingItems(character, showZeroPenalty)
    return sortItems(itemsData, sortMode)
end

---Get vision-affecting worn items formatted for tooltip display
---@param character IsoPlayer The player character
---@param options table|nil Optional configuration {showZeroPenalty: boolean, sortMode: string}
---@return table displayItems Array of formatted display items with text and value
function FTE_VisionAffectingItems:getFormattedWornItems(character, options)
    if not self:isActive() then return {} end
    
    local itemsData = self:getItems(character, options)
    return formatWornItemsForDisplay(itemsData)
end

---Get vision-affecting worn items formatted for display (convenience wrapper)
---Returns empty array if clothing penalty is negligible or module is inactive
---@param character IsoPlayer The player character
---@param clothingPenalty number The clothing penalty modifier
---@return table displayItems Array of formatted display items with text and value
function FTE_VisionAffectingItems:getWornItemsForTooltip(character, clothingPenalty)
    if not self:isActive() then return {} end
    
    -- Only get items if clothing penalty is significant
    if math.abs(clothingPenalty - 1) < 0.01 then
        return {}
    end
    
    local options = {
        showZeroPenalty = false,  -- Only show items with actual penalties
        sortMode = "severity"     -- Sort by penalty severity (highest first)
    }
    return self:getFormattedWornItems(character, options)
end

---Get color for penalty value
---@param penaltyPercent number The penalty percentage
---@return string rgbColor RGB color code
function FTE_VisionAffectingItems:getColorForPenalty(penaltyPercent)
    return getColorForPenalty(penaltyPercent)
end

---Check if any vision-affecting items are worn
---@param character IsoPlayer The player character
---@return boolean hasItems True if character is wearing items that affect vision
function FTE_VisionAffectingItems:hasVisionAffectingItems(character)
    if not self:isActive() then return false end
    if not character then return false end
    
    -- Safety check for forageSystem
    if not forageSystem or not forageSystem.clothingPenalties then return false end
    
    local wornItems = character:getWornItems()
    if not wornItems then return false end
    
    -- Iterate through worn items using Java ArrayList methods
    for i = 0, wornItems:size() - 1 do
        local wornItem = wornItems:get(i)
        if wornItem then
            local location = wornItem:getLocation()
            if location and forageSystem.clothingPenalties[location] then
                return true
            end
        end
    end
    
    return false
end

-- ===================================================================================================== --
-- MODULE API EXPORTS
-- ===================================================================================================== --

return {
    initialise = function() return instance:initialise(function(self) self:setupModule() end) end,
    destroy = function() return instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end,
    
    -- Direct API exports for convenience
    getItems = function(character, options) return instance:getItems(character, options) end,
    getFormattedWornItems = function(character, options) return instance:getFormattedWornItems(character, options) end,
    getWornItemsForTooltip = function(character, clothingPenalty) return instance:getWornItemsForTooltip(character, clothingPenalty) end,
    getColorForPenalty = function(penaltyPercent) return instance:getColorForPenalty(penaltyPercent) end,
    hasVisionAffectingItems = function(character) return instance:hasVisionAffectingItems(character) end
}
