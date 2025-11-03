-- FTE_SearchRadiusDisplay.lua - Persistent search radius display module
-- Displays current search radius next to the eye icon in ISZoneDisplay

local FTE_ModuleBase = require("Core/FTE_ModuleBase")
local FTE_Utils = require("FTE_Utils")
local FTE_ModOptions = require("FTE_ModOptions")

-- ===================================================================================================== --
-- MODULE CLASS DEFINITION
-- ===================================================================================================== --

---@class FTE_SearchRadiusDisplay : FTE_ModuleBase
---@field _cachedRadius number|nil Last known radius value
---@field _cachedText string|nil Pre-formatted text string
---@field _cachedColor table|nil RGB color table {r, g, b}
local FTE_SearchRadiusDisplay = FTE_ModuleBase:derive("FTE_SearchRadiusDisplay")

-- Singleton instance (created immediately at module load)
local instance = FTE_SearchRadiusDisplay:new()
---@cast instance FTE_SearchRadiusDisplay

-- ===================================================================================================== --
-- INTERNAL STATE AND CONSTANTS
-- ===================================================================================================== --

---Internal state for caching to optimize performance
instance._cachedRadius = nil       -- Last known radius value
instance._cachedText = nil         -- Pre-formatted text string
instance._cachedColor = nil        -- RGB color table {r, g, b}

---Cached font metrics (initialized once, unchanged during runtime)
local CACHED_FONT = UIFont.Small
local CACHED_TEXT_HEIGHT = getTextManager():getFontHeight(CACHED_FONT)

---Threshold for detecting min/max radius (tolerance for floating point comparison)
local RADIUS_THRESHOLD = 0.01

---UI spacing constant (distance between text and eye icon)
local UI_BORDER_SPACING = 6

---Background padding constants for text display
local BG_PADDING_X = 3  -- Horizontal padding around text
local BG_PADDING_Y = -2  -- Vertical padding around text (0 for tight fit)
local BG_ALPHA = 0.7    -- Background opacity (70%)

-- ===================================================================================================== --
-- COLOR HELPER FUNCTIONS
-- ===================================================================================================== --

---Get color based on radius state (min/max/normal)
---@param visionRadius number Current search radius
---@param minRadius number Minimum radius cap
---@param maxRadius number Maximum radius cap
---@return number r Red component (0-1)
---@return number g Green component (0-1)
---@return number b Blue component (0-1)
local function getRadiusColor(visionRadius, minRadius, maxRadius)
    local isAtMinRadius = math.abs(visionRadius - minRadius) < RADIUS_THRESHOLD
    local isAtMaxRadius = math.abs(visionRadius - maxRadius) < RADIUS_THRESHOLD
    
    if isAtMinRadius then
        -- Red for minimum radius (bad)
        local BHC = getCore():getBadHighlitedColor()
        return BHC:getR(), BHC:getG(), BHC:getB()
    elseif isAtMaxRadius then
        -- Green for maximum radius (good)
        local GHC = getCore():getGoodHighlitedColor()
        return GHC:getR(), GHC:getG(), GHC:getB()
    else
        -- White for normal range
        return 1, 1, 1
    end
end

-- ===================================================================================================== --
-- RADIUS TEXT RENDERING
-- ===================================================================================================== --

---Draw the radius text to the left of the eye icon
---@param zoneDisplay ISZoneDisplay The zone display instance
local function drawRadiusText(zoneDisplay)
    -- Validate required objects exist
    if not zoneDisplay or not zoneDisplay.manager then
        return
    end
    
    local searchManager = zoneDisplay.manager
    
    -- Get current vision radius
    local visionRadius = searchManager:getOverlayRadius()
    if not visionRadius then
        return
    end
    
    -- Get min/max radius for color coding
    local minRadius = searchManager.minRadius or 0
    local maxRadius = searchManager.maxRadiusCap or 15
    
    -- Check if we need to update cached values
    local needsUpdate = (instance._cachedRadius ~= visionRadius)
    
    if needsUpdate then
        -- Update cached radius value
        instance._cachedRadius = visionRadius
        
        -- Format text
        instance._cachedText = string.format("R: %.2f", visionRadius)
        
        -- Calculate color
        local r, g, b = getRadiusColor(visionRadius, minRadius, maxRadius)
        instance._cachedColor = {r = r, g = g, b = b}
    end
    
    -- Get cached values
    local text = instance._cachedText
    local color = instance._cachedColor
    
    if not text or not color then
        return
    end
    
    -- Get eye icon position from zdImages table
    local eyeIcon = zoneDisplay.zdImages and zoneDisplay.zdImages.visionBonuses or zoneDisplay.visionBonuses
    
    if not eyeIcon then
        return
    end
    
    -- Get eye icon position and dimensions
    local eyeX = eyeIcon:getX()
    local eyeY = eyeIcon:getY()
    local eyeHeight = eyeIcon:getHeight()
    
    -- Calculate text width (text changes, so we measure each time)
    local textManager = getTextManager()
    local textWidth = textManager:MeasureStringX(CACHED_FONT, text)
    
    -- Position text to left of eye icon, vertically centered
    local textX = eyeX - textWidth - UI_BORDER_SPACING
    local textY = eyeY + (eyeHeight / 2) - (CACHED_TEXT_HEIGHT / 2)
    
    -- Draw background for better readability
    zoneDisplay:drawRect(
        textX - BG_PADDING_X,
        textY - BG_PADDING_Y,
        textWidth + (BG_PADDING_X * 2),
        CACHED_TEXT_HEIGHT + (BG_PADDING_Y * 2),
        BG_ALPHA,
        0, 0, 0  -- Black background
    )
    
    -- Draw the text on top of the background
    zoneDisplay:drawText(text, textX, textY, color.r, color.g, color.b, 1.0, CACHED_FONT)
end

-- ===================================================================================================== --
-- ISZONDISPLAY RENDER OVERRIDE
-- ===================================================================================================== --

---Override ISZoneDisplay:render() to add persistent radius display
---This ensures our text renders after child elements (zone images)
---@param self ISZoneDisplay
local function ISZoneDisplay_render(self)
    -- Call original render first (if it exists)
    local originalRender = instance:getOriginal("render", ISZoneDisplay)
    if originalRender then
        originalRender(self)
    end
    
    -- Only draw radius text if mod option is enabled and search mode is active
    local showPersistentRadius = FTE_ModOptions.getOption("showPersistentRadius")
    
    if showPersistentRadius and self.manager and self.manager.isSearchMode then
        -- Draw radius text (error protection handled by overrideFunction wrapper)
        drawRadiusText(self)
    end
end

-- ===================================================================================================== --
-- MODULE SETUP METHOD
-- ===================================================================================================== --

---Setup the search radius display module
function FTE_SearchRadiusDisplay:setupModule()
    local ISZoneDisplay = _G.ISZoneDisplay
    
    if not ISZoneDisplay then
        FTE_Utils.logError("FTE_SearchRadiusDisplay: ISZoneDisplay not found")
        error("Failed to initialize FTE_SearchRadiusDisplay - ISZoneDisplay not found")
    end
    
    -- ISZoneDisplay inherits render() from ISUIElement (empty by default)
    -- Override ISZoneDisplay:render() using module's safe override system
    local success = self:overrideFunction(ISZoneDisplay, "render", ISZoneDisplay_render)
    
    if success then
        FTE_Utils.logInfo("FTE_SearchRadiusDisplay: Module initialized successfully")
    else
        FTE_Utils.logError("FTE_SearchRadiusDisplay: Failed to patch ISZoneDisplay:render()")
        error("Failed to initialize FTE_SearchRadiusDisplay")
    end
end

-- ===================================================================================================== --
-- PUBLIC API
-- ===================================================================================================== --

---Get current cached radius value (for debugging/testing)
---@return number|nil cachedRadius
function FTE_SearchRadiusDisplay:getCachedRadius()
    return instance._cachedRadius
end

---Clear cached values (useful for testing or forcing refresh)
function FTE_SearchRadiusDisplay:clearCache()
    instance._cachedRadius = nil
    instance._cachedText = nil
    instance._cachedColor = nil
    FTE_Utils.logDebug("FTE_SearchRadiusDisplay: Cache cleared")
end

-- ===================================================================================================== --
-- MODULE API EXPORTS
-- ===================================================================================================== --

return {
    ---@diagnostic disable-next-line: undefined-field
    initialise = function() return instance:initialise(function(self) self:setupModule() end) end,
    destroy = function() return instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end,
    
    -- Direct API exports for convenience
    getCachedRadius = function() return instance:getCachedRadius() end,
    clearCache = function() return instance:clearCache() end
}
