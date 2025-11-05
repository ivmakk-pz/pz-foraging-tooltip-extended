-- FTE_VisionAffectingItems.lua - Vision-Affecting Items Display Module
-- Displays clothing/items that affect search radius as level 2 items under the Clothing penalty line

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

-- Maximum width for item names in pixels (prevents long names from breaking layout)
local MAX_ITEM_NAME_WIDTH = 120

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
-- RICH TEXT TOOLTIP BUILDER
-- ===================================================================================================== --

---Format a single item entry for tooltip display
---@param itemData table Item penalty data (from calculateItemPenalty)
---@param isLast boolean|nil Whether this is the last item in the list (for tree connector)
---@param setXPosition number|nil X position for value alignment (uses tree connector if provided)
---@return string richTextLine Formatted rich text line for this item
local function formatItemEntry(itemData, isLast, setXPosition)
    local parts = {}
    
    -- Use tree connectors if alignment position is provided, otherwise use simple dash
    if setXPosition then
        -- Build label with icon and name
        local label = ""
        
        -- Add item icon if available with fixed square size
        if itemData.iconName and itemData.iconTexture then
            local iconSize = FTE_Utils.TREE_CONNECTOR_SIZE
            local iconTag = " <IMAGE:" .. itemData.iconName .. "," .. iconSize .. "," .. iconSize .. "> "
            label = label .. iconTag
        end
        
        -- Truncate item name if too long
        local itemName = FTE_Utils.truncateText(itemData.displayName, MAX_ITEM_NAME_WIDTH)
        label = label .. itemName
        
        -- Get colored multiplier value
        local penaltyColor = getColorForPenalty(itemData.penaltyPercent)
        local value = penaltyColor .. string.format("%.2f", itemData.multiplier)
        
        -- Use tree connector utility function with alignment
        return FTE_Utils.getToolTipTextWithTreeImage(label, value, isLast or false, setXPosition)
    else
        -- Original simple dash format (fallback)
        table.insert(parts, FTE_Utils.Colors.white)
        table.insert(parts, "-")
        
        -- Add item icon if available with fixed square size
        if itemData.iconName and itemData.iconTexture then
            local iconSize = 16
            local iconTag = " <IMAGE:" .. itemData.iconName .. "," .. iconSize .. "," .. iconSize .. "> "
            table.insert(parts, iconTag)
        end
        
        -- Truncate item name if too long
        local itemName = FTE_Utils.truncateText(itemData.displayName, MAX_ITEM_NAME_WIDTH)
        
        -- Add item display name in white
        table.insert(parts, FTE_Utils.Colors.white)
        table.insert(parts, itemName)
        table.insert(parts, ": <SPACE> ")
        
        -- Add colored multiplier value
        local penaltyColor = getColorForPenalty(itemData.penaltyPercent)
        table.insert(parts, penaltyColor)
        table.insert(parts, string.format("%.2f", itemData.multiplier))
        
        -- Add line break
        table.insert(parts, " <LINE> ")
        
        return table.concat(parts)
    end
end

---Build complete items list text for tooltip
---@param character IsoPlayer The player character
---@param options table|nil Optional configuration {showZeroPenalty: boolean, sortMode: string, useAlignment: boolean}
---@return string|nil richTextString Formatted rich text string or nil if no items
local function buildItemsList(character, options)
    if not character then return nil end
    
    -- Get sorted items data
    options = options or {}
    local showZeroPenalty = options.showZeroPenalty or false
    local sortMode = options.sortMode or "severity"
    local useAlignment = options.useAlignment ~= false  -- Default to true
    
    local itemsData = getVisionAffectingItems(character, showZeroPenalty)
    if not itemsData or #itemsData == 0 then return nil end
    
    itemsData = sortItems(itemsData, sortMode)
    
    -- Use global fixed alignment position (or calculate if alignment disabled)
    local valueXPosition = nil
    if useAlignment then
        valueXPosition = FTE_Utils.TOOLTIP_VALUE_X_POSITION
    end
    
    -- Build formatted text for all items
    local parts = {}
    for i, itemData in ipairs(itemsData) do
        local isLast = (i == #itemsData)
        local itemLine = formatItemEntry(itemData, isLast, valueXPosition)
        table.insert(parts, itemLine)
    end
    
    return table.concat(parts)
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

---Build formatted rich text list of vision-affecting items
---@param character IsoPlayer The player character
---@param options table|nil Optional configuration {showZeroPenalty: boolean, sortMode: string}
---@return string|nil richTextString Formatted rich text string or nil if no items
function FTE_VisionAffectingItems:buildItemsList(character, options)
    if not self:isActive() then return nil end
    return buildItemsList(character, options)
end

---Format a single item entry for display
---@param itemData table Item penalty data table
---@param isLast boolean|nil Whether this is the last item (for tree connector)
---@param setXPosition number|nil X position for value alignment
---@return string richTextLine Formatted rich text line
function FTE_VisionAffectingItems:formatItemEntry(itemData, isLast, setXPosition)
    return formatItemEntry(itemData, isLast, setXPosition)
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
    buildItemsList = function(character, options) return instance:buildItemsList(character, options) end,
    formatItemEntry = function(itemData, isLast, setXPosition) return instance:formatItemEntry(itemData, isLast, setXPosition) end,
    getColorForPenalty = function(penaltyPercent) return instance:getColorForPenalty(penaltyPercent) end,
    hasVisionAffectingItems = function(character) return instance:hasVisionAffectingItems(character) end
}
