-- FTE_ViewDistance.lua - View distance calculation module (optional/experimental)
-- Provides real-time view distance estimates for different item sizes

local FTE_ModuleBase = require("Core/FTE_ModuleBase")
local FTE_Utils = require("FTE_Utils")

-- ===================================================================================================== --
-- MODULE CLASS DEFINITION
-- ===================================================================================================== --

---@class FTE_ViewDistance : FTE_ModuleBase
local FTE_ViewDistance = FTE_ModuleBase:derive("FTE_ViewDistance")

-- Singleton instance (created immediately at module load)
local instance = FTE_ViewDistance:new()
---@cast instance FTE_ViewDistance

-- ===================================================================================================== --
-- VIEW DISTANCE CONSTANTS AND CACHE
-- ===================================================================================================== --

---Reference item sizes for view distance calculations
---@type table<string, number>
local VIEW_DISTANCE_REFERENCE_SIZES = {
    small = 0.1,    -- Small items (e.g., berries, insects)
    medium = 1.0,   -- Medium items (e.g., mushrooms, stones)
    large = 10.0    -- Large items (e.g., wood, large plants)
}

---Cache for ISBaseIcon instances used in vision calculations
---Prevents recreating icons on every calculation
---@type table<string, ISBaseIcon>
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
    local cacheKey = "size_" .. tostring(itemSize)
    
    if iconCache[cacheKey] then
        return iconCache[cacheKey]
    end
    
    local targetSquare = square or character:getCurrentSquare()
    local itemType = "Base.Stone2"
    
    local iconData = {
        id = itemType .. "_vision_calc_" .. tostring(itemSize),
        x = 0,
        y = 0,
        z = 0,
        itemType = itemType,
        itemSize = itemSize,
    }
    
    local icon = ISBaseIcon:new(searchManager, iconData)
    
    icon.itemDef = {
        type = itemType,
        minCount = 1,
        maxCount = 1,
        spawnFuncs = nil
    }
    
    icon.itemObj = instanceItem("Base.Stone2")
    icon.square = targetSquare
    
    icon:setIsSeen(false)
    icon:setIsNoticed(false)
    icon:setAlpha(1.0)
    
    icon:initGridSquare()
    icon:initItem()
    
    iconCache[cacheKey] = icon
    
    return icon
end

---Get view distance for a specific item size using cached icons and vanilla calculation
---@param character IsoGameCharacter The player character
---@param itemSize number The item size to calculate view distance for
---@param searchManager ISSearchManager The search manager to use for vision calculation
---@return number viewDistance The calculated view distance in tiles
local function getItemViewDistance(character, itemSize, searchManager)
    local currentSquare = character:getCurrentSquare()
    local itemIcon = createRealIconForVisionCalculation(character, itemSize, currentSquare, searchManager)
    
    itemIcon:updateModifiers()
    local viewDistance = itemIcon:doVisionCheck()

    return viewDistance
end

---Get view distances for all reference item sizes (small, medium, large)
---@param character IsoGameCharacter The player character
---@param searchManager ISSearchManager The search manager to use for vision calculation
---@return table viewDistances Table with keys: small, medium, large
local function getAllViewDistances(character, searchManager)
    return {
        small = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.small, searchManager),
        medium = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.medium, searchManager),
        large = getItemViewDistance(character, VIEW_DISTANCE_REFERENCE_SIZES.large, searchManager)
    }
end

-- ===================================================================================================== --
-- MODULE SETUP METHOD
-- ===================================================================================================== --

---Setup the view distance module
function FTE_ViewDistance:setupModule()
    FTE_Utils.logInfo("FTE_ViewDistance: View distance calculation module initialized")
    -- This module is passive - it provides API functions that other modules can call
    -- No event hooks or overrides needed
end

-- ===================================================================================================== --
-- PUBLIC API
-- ===================================================================================================== --

---Get reference item sizes used for calculations
---@return table VIEW_DISTANCE_REFERENCE_SIZES
function FTE_ViewDistance:getReferenceSizes()
    return VIEW_DISTANCE_REFERENCE_SIZES
end

---Get view distance for a specific item size
---@param character IsoGameCharacter
---@param itemSize number
---@param searchManager ISSearchManager
---@return number viewDistance
function FTE_ViewDistance:getViewDistanceForSize(character, itemSize, searchManager)
    if not self:isActive() then
        FTE_Utils.logWarning("FTE_ViewDistance: Module is not active, returning 0")
        return 0
    end
    
    local ok, result = pcall(getItemViewDistance, character, itemSize, searchManager)
    if ok then
        return result
    else
        FTE_Utils.logError("FTE_ViewDistance: Error calculating view distance: " .. tostring(result))
        return 0
    end
end

---Get all view distances (small, medium, large)
---@param character IsoGameCharacter
---@param searchManager ISSearchManager
---@return table viewDistances
function FTE_ViewDistance:getAllViewDistances(character, searchManager)
    if not self:isActive() then
        FTE_Utils.logWarning("FTE_ViewDistance: Module is not active, returning zeros")
        return { small = 0, medium = 0, large = 0 }
    end
    
    local ok, result = pcall(getAllViewDistances, character, searchManager)
    if ok then
        return result
    else
        FTE_Utils.logError("FTE_ViewDistance: Error calculating all view distances: " .. tostring(result))
        return { small = 0, medium = 0, large = 0 }
    end
end

---Clear the icon cache (useful for cleanup or resetting)
function FTE_ViewDistance:clearCache()
    iconCache = {}
    FTE_Utils.logDebug("FTE_ViewDistance: Icon cache cleared")
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
    getReferenceSizes = function() return instance:getReferenceSizes() end,
    getViewDistanceForSize = function(character, itemSize, searchManager)
        return instance:getViewDistanceForSize(character, itemSize, searchManager)
    end,
    getAllViewDistances = function(character, searchManager)
        return instance:getAllViewDistances(character, searchManager)
    end,
    clearCache = function() return instance:clearCache() end
}
