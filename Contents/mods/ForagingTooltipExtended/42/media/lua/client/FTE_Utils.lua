-- FTE_Utils.lua - Utility functions and constants for Foraging Tooltip Extended
-- Contains color definitions, formatting functions, and other shared utilities

local FTE_Utils = {}

-- ===================================================================================================== --
-- CONSTANTS
-- ===================================================================================================== --

-- Mod version - Update this during release process
FTE_Utils.MOD_VERSION = "2.2.2"

local PRECISION_THRESHOLD = 0.01
local PERCENTAGE_MULTIPLIER = 100

-- Debug mode flag
local DEBUG_MODE = false

-- Tree connector texture size definitions (available texture sizes in pixels)
local TREE_CONNECTOR_SIZES = {16, 19, 26, 33, 38}  -- Available texture sizes

-- Font size to texture size mapping (with fallback reuse for larger fonts)
local FONT_TO_TEXTURE_MAP = {
    [16] = 16,
    [19] = 19,
    [26] = 26,
    [33] = 33,
    [38] = 38
}

-- Image padding constant (matches ISRichTextPanel's IMAGE_PAD value)
FTE_Utils.IMAGE_PAD = 5  -- Padding on each side of images in ISRichTextPanel

-- Tooltip base content width (matches ISToolTip.layoutContents base width)
-- This is the base width before font scaling is applied (from vanilla: 180 * widthScale)
FTE_Utils.TOOLTIP_BASE_CONTENT_WIDTH = 185

-- Alignment constants (enum-like)
FTE_Utils.Alignment = {
    LEFT = "left",
    RIGHT = "right"
}

-- Get game colors once at module load
local GHC = getCore():getGoodHighlitedColor()
local BHC = getCore():getBadHighlitedColor()

-- ===================================================================================================== --
-- TOOLTIP LAYOUT METRICS
-- ===================================================================================================== --
-- Tooltip layout metrics are calculated once at initialization and cached for performance
-- All values are based on current font settings and remain constant during gameplay

---@class TooltipLayout
---@field currentFont any Current tooltip font enum
---@field widthScale number Width scale factor (fontHeight / 15)
---@field contentWidth number Available content width (180 * widthScale)
---@field maxValueWidth number Width of "+100%" in current font
---@field valueXPosition number Calculated X position for value alignment
---@field maxItemNameWidth number Max width for item names (accounting for icons and tree connectors)
---@field itemIconHeight number Base icon height (equals font height)
---@field treeConnectorWidth number Tree connector image width (scaled with font)
---@field treeConnectorHeight number Tree connector image height (equals font line height)
---@field treeConnectorMiddlePath string Path to middle connector texture (font-size-specific)
---@field treeConnectorLastPath string Path to last connector texture (font-size-specific)

---Tooltip layout metrics (initialized on module load)
---@type TooltipLayout
FTE_Utils.tooltipLayout = {
    currentFont = UIFont.NewSmall,
    widthScale = 0,
    contentWidth = 0,
    maxValueWidth = 0,
    valueXPosition = 0,
    maxItemNameWidth = 0,
    itemIconHeight = 0,
    treeConnectorWidth = 0,
    treeConnectorHeight = 0,
    treeConnectorMiddlePath = "",
    treeConnectorLastPath = "",
}

---Select best tree connector texture size based on font line height
---@param lineHeight number Current font line height in pixels
---@return number textureSize Best matching texture size (fallback: 16px for unsupported sizes)
local function selectBestTextureSize(lineHeight)
    local roundedHeight = math.floor(lineHeight + 0.5)
    
    if FONT_TO_TEXTURE_MAP[roundedHeight] then
        return FONT_TO_TEXTURE_MAP[roundedHeight]
    end
    
    -- Find closest available texture size (prefer smaller to avoid excessive upscaling)
    local bestSize = TREE_CONNECTOR_SIZES[1]  -- Default to smallest (16px)
    local minDiff = math.abs(roundedHeight - bestSize)
    
    for i = 1, #TREE_CONNECTOR_SIZES do
        local size = TREE_CONNECTOR_SIZES[i]
        local diff = math.abs(roundedHeight - size)
        if diff < minDiff or (diff == minDiff and size > bestSize) then
            bestSize = size
            minDiff = diff
        end
    end
    
    -- Fallback: if no close match found or unexpected font size, use 16px texture
    if bestSize == 0 or minDiff > 20 then
        bestSize = 16
    end
    
    return bestSize
end

---Calculate tree connector dimensions and paths based on line height and texture aspect ratio
---@param font any UIFont enum
---@return number width Calculated width respecting aspect ratio
---@return number height Calculated height matching line height
---@return string middlePath Path to middle connector texture
---@return string lastPath Path to last connector texture
local function calculateTreeConnectorDimensions(font)
    local lineHeight = getTextManager():getFontFromEnum(font):getLineHeight()
    -- Apply same minimum as vanilla ISRichTextPanel
    if lineHeight < 10 then
        lineHeight = 10
    end
    
    -- Select best texture size for current font
    local textureSize = selectBestTextureSize(lineHeight)
    
    -- Build texture paths
    local middlePath = "media/ui/TooltipStructureItems/t_connector_" .. textureSize .. ".png"
    local lastPath = "media/ui/TooltipStructureItems/l_connector_" .. textureSize .. ".png"
    
    -- Load tree connector texture to get actual dimensions and aspect ratio
    local treeTexture = getTexture(middlePath)
    if treeTexture then
        local originalWidth = treeTexture:getWidth()
        local originalHeight = treeTexture:getHeight()
        
        if originalWidth > 0 and originalHeight > 0 then
            -- Calculate aspect ratio and scale width to match line height
            local aspectRatio = originalWidth / originalHeight
            local height = math.ceil(lineHeight)
            local width = math.ceil(height * aspectRatio)
            return width, height, middlePath, lastPath
        end
    end
    
    -- Fallback if texture not found or invalid
    return 4, math.ceil(lineHeight), middlePath, lastPath
end

---Initialize tooltip layout metrics based on current font settings
function FTE_Utils.initializeTooltipLayout()
    local layout = FTE_Utils.tooltipLayout
    
    local currentFont = ISToolTip.GetFont and ISToolTip.GetFont() or UIFont.NewSmall
    
    if layout.currentFont == currentFont and layout.contentWidth > 0 then
        return
    end
    
    layout.currentFont = currentFont
    
    local fontHeight = getTextManager():getFontHeight(layout.currentFont)
    layout.widthScale = fontHeight / 15  -- Same scaling factor used in ISToolTip.layoutContents
    
    -- Calculate tree connector dimensions and paths based on line height and texture aspect ratio
    layout.treeConnectorWidth, layout.treeConnectorHeight, layout.treeConnectorMiddlePath, layout.treeConnectorLastPath = 
        calculateTreeConnectorDimensions(layout.currentFont)

    layout.itemIconHeight = fontHeight
    layout.contentWidth = FTE_Utils.TOOLTIP_BASE_CONTENT_WIDTH * layout.widthScale
    layout.maxValueWidth = getTextManager():MeasureStringX(layout.currentFont, "+999%")
    
    local valueSpaceNeeded = layout.maxValueWidth + (10 * layout.widthScale)
    layout.valueXPosition = math.floor(layout.contentWidth - valueSpaceNeeded)
    
    -- Tree connector: base width (scaled) + padding (FIXED pixels, not scaled)
    local treeConnectorTotal = (layout.treeConnectorWidth * layout.widthScale) + (FTE_Utils.IMAGE_PAD * 2)
    -- Item icon: fontHeight (already in pixels) + padding (FIXED pixels, not scaled)
    local itemIconTotal = layout.itemIconHeight + (FTE_Utils.IMAGE_PAD * 2)
    layout.maxItemNameWidth = math.floor(layout.contentWidth - treeConnectorTotal - itemIconTotal - valueSpaceNeeded)
end

---Get scaled icon dimensions respecting aspect ratio
---Icons are scaled to fit within a square box (fontHeight x fontHeight)
---Aspect ratio is always preserved - icons are scaled down to fit if needed
---@param texture any Texture object from item:getIcon()
---@return number width Scaled width maintaining aspect ratio
---@return number height Scaled height maintaining aspect ratio
function FTE_Utils.getScaledIconDimensions(texture)
    local maxSize = FTE_Utils.tooltipLayout.itemIconHeight
    
    if not texture then
        return maxSize, maxSize
    end
    
    local originalWidth = texture:getWidth()
    local originalHeight = texture:getHeight()
    
    if not originalWidth or not originalHeight or originalWidth == 0 or originalHeight == 0 then
        return maxSize, maxSize
    end
    
    -- Calculate scale factor to fit within square box while maintaining aspect ratio
    local scaleWidth = maxSize / originalWidth
    local scaleHeight = maxSize / originalHeight
    local scale = math.min(scaleWidth, scaleHeight)
    
    local scaledWidth = math.floor(originalWidth * scale)
    local scaledHeight = math.floor(originalHeight * scale)
    
    return scaledWidth, scaledHeight
end

---Get tree connector image tag for tooltips
---@param isLast boolean Whether this is the last item (uses l_connector instead of t_connector)
---@return string imageTag The complete IMAGE tag with current font-scaled dimensions
function FTE_Utils.getTreeConnectorImageTag(isLast)
    local layout = FTE_Utils.tooltipLayout
    local imagePath = isLast and layout.treeConnectorLastPath or layout.treeConnectorMiddlePath
    return " <IMAGE:" .. imagePath .. "," .. layout.treeConnectorWidth .. "," .. layout.treeConnectorHeight .. "> "
end

-- ===================================================================================================== --
-- LOGGING FUNCTIONS
-- ===================================================================================================== --

---Core logging function
---@param message string
---@param level string
local function logMessage(message, level)
    if not DEBUG_MODE and level == "DEBUG" then
        return
    end
    
    local safeMessage = message
    if type(message) ~= "string" then
        safeMessage = tostring(message)
    end
    
    -- Build complete log line
    local logLine = "[FTE] " .. level .. " " .. safeMessage
    print(logLine)
end

---Log info message
---@param message string
function FTE_Utils.logInfo(message)
    logMessage(message, "INFO")
end

---Log warning message
---@param message string
function FTE_Utils.logWarning(message)
    logMessage(message, "WARN")
end

---Log error message
---@param message string
function FTE_Utils.logError(message)
    logMessage(message, "ERROR")
end

---Log debug message
---@param message string
function FTE_Utils.logDebug(message)
    logMessage(message, "DEBUG")
end

---Set debug mode
---@param enabled boolean
function FTE_Utils.setDebugMode(enabled)
    DEBUG_MODE = enabled
end

-- ===================================================================================================== --
-- COLOR DEFINITIONS
-- ===================================================================================================== --

-- Unified color schema for tooltips
FTE_Utils.Colors = {
    white = " <RGB:1,1,1> ",
    grey = " <RGB:0.75,0.75,0.75> ",
    good = " <RGB:"..GHC:getR()..","..GHC:getG()..","..GHC:getB().."> ",
    bad = " <RGB:"..BHC:getR()..","..BHC:getG()..","..BHC:getB().."> "
}

-- ===================================================================================================== --
-- FORMATTING FUNCTIONS
-- ===================================================================================================== --

---Format numbers with 2 decimal places
---@param value number
---@return string formattedNumber
function FTE_Utils.formatNumber(value)
    return string.format("%.2f", value)
end

---Format percentage values for bonus sections (shorter format)
---Shows integers without decimals (e.g., "+10%"), floats with 1 decimal (e.g., "+5.5%")
---@param float number The decimal value (e.g., 0.1 for 10%, 0.055 for 5.5%)
---@return string formattedPercent
function FTE_Utils.formatPercentShort(float)
    if float == 0 then
        return "0"
    end
    local percent = float * PERCENTAGE_MULTIPLIER
    -- Check if it's effectively an integer (within 0.01 precision)
    if math.abs(percent - math.floor(percent + 0.5)) < 0.01 then
        return string.format("%+d", math.floor(percent + 0.5))
    end
    return string.format("%+.1f", percent)
end

-- ===================================================================================================== --
-- COLOR FUNCTIONS
-- ===================================================================================================== --

---Get RGB color for tooltip based on conditions
---@param isGreen boolean Whether the value should be colored green
---@param isZero boolean Whether the value is zero (should be grey)
---@return string colorCode
function FTE_Utils.getRGBForTooltip(isGreen, isZero)
    if isZero then 
        return FTE_Utils.Colors.grey 
    end
    if isGreen then 
        return FTE_Utils.Colors.good 
    end
    return FTE_Utils.Colors.bad
end

---Get RGB color for value-based tooltips (multipliers, etc.)
---@param value number The value to determine color for
---@return string colorCode
function FTE_Utils.getRGBForValue(value)
    if math.abs(value - 1) < PRECISION_THRESHOLD then
        return FTE_Utils.Colors.grey -- Neutral (1.0)
    elseif value < 1 then
        return FTE_Utils.Colors.bad -- Penalty (red)
    else
        return FTE_Utils.Colors.good -- Bonus (green)
    end
end

-- ===================================================================================================== --
-- TOOLTIP TEXT GENERATION FUNCTIONS
-- ===================================================================================================== --

---Generate tooltip text for radius values with min/max indicators
---@param text string The label text
---@param value number The radius value
---@param isAtMinRadius boolean
---@param isAtMaxRadius boolean
---@param alignment string|nil Optional: FTE_Utils.Alignment.LEFT or FTE_Utils.Alignment.RIGHT (default: RIGHT)
---@return string tooltipText
function FTE_Utils.getToolTipTextRadius(text, value, isAtMinRadius, isAtMaxRadius, alignment)
    alignment = alignment or FTE_Utils.Alignment.RIGHT
    
    local color = FTE_Utils.Colors.white -- White for normal radius values
    local labelSuffix = ""
    
    if isAtMinRadius then
        color = FTE_Utils.Colors.bad
        labelSuffix = " <SPACE> " .. FTE_Utils.Colors.bad .. "(min)" .. FTE_Utils.Colors.white
    elseif isAtMaxRadius then
        color = FTE_Utils.Colors.good
        labelSuffix = " <SPACE> " .. FTE_Utils.Colors.good .. "(max)" .. FTE_Utils.Colors.white
    end
    
    if alignment == FTE_Utils.Alignment.RIGHT then
        local xPosition = FTE_Utils.tooltipLayout.valueXPosition
        return " " .. FTE_Utils.Colors.white .. text .. labelSuffix .. " <SETX:" .. xPosition .. "> " .. 
               color .. FTE_Utils.formatNumber(value) .. " <LINE> "
    else
        return " " .. FTE_Utils.Colors.white .. text .. labelSuffix .. ": <SPACE> " .. 
               color .. FTE_Utils.formatNumber(value) .. " <LINE> "
    end
end

---Generate tooltip text with tree connector image
---@param text string The label text
---@param value number|string The value to display (number for auto-formatting, or pre-formatted string with color)
---@param isLast boolean Whether this is the last item (uses last_connector instead of middle_connector)
---@param setXPosition number|nil Optional X position for value alignment (uses <SETX> for column alignment)
---@param alignment string|nil Optional: FTE_Utils.Alignment.LEFT or FTE_Utils.Alignment.RIGHT (default: RIGHT)
---@return string tooltipText
function FTE_Utils.getToolTipTextWithTreeImage(text, value, isLast, setXPosition, alignment)
    alignment = alignment or FTE_Utils.Alignment.RIGHT
    
    local imageTag = FTE_Utils.getTreeConnectorImageTag(isLast)
    
    -- Handle both numeric values and pre-formatted strings
    local formattedValue = ""
    if type(value) == "number" then
        local color = FTE_Utils.getRGBForValue(value)
        formattedValue = color .. FTE_Utils.formatNumber(value)
    else
        formattedValue = tostring(value)  -- Already formatted string with color
    end
    
    if setXPosition and alignment == FTE_Utils.Alignment.RIGHT then
        -- Use SETX for column-aligned values - place SETX before the colon to prevent wrapping
        return " " .. imageTag .. FTE_Utils.Colors.white .. text .. " <SETX:" .. setXPosition .. "> " .. 
               formattedValue .. " <LINE> "
    else
        -- Default: simple space separator (left-aligned)
        return " " .. imageTag .. FTE_Utils.Colors.white .. text .. ": <SPACE> " .. 
               formattedValue .. " <LINE> "
    end
end

---Truncate text to fit within maximum width, adding ellipsis if needed
---@param text string The text to truncate
---@param maxWidth number Maximum width in pixels
---@param font any UIFont enum (default: UIFont.NewSmall)
---@return string truncatedText The truncated text with ellipsis if needed
function FTE_Utils.truncateText(text, maxWidth, font)
    font = font or UIFont.NewSmall
    local textManager = getTextManager()
    
    -- Check if text fits
    local textWidth = textManager:MeasureStringX(font, text)
    if textWidth <= maxWidth then
        return text
    end
    
    -- Measure ellipsis width
    local ellipsis = ".."
    local ellipsisWidth = textManager:MeasureStringX(font, ellipsis)
    local availableWidth = maxWidth - ellipsisWidth
    
    -- Binary search for the longest substring that fits
    local left = 1
    local right = #text
    local bestFit = ""
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        local substring = string.sub(text, 1, mid)
        local substringWidth = textManager:MeasureStringX(font, substring)
        
        if substringWidth <= availableWidth then
            bestFit = substring
            left = mid + 1
        else
            right = mid - 1
        end
    end
    
    return bestFit .. ellipsis
end

-- ===================================================================================================== --
-- HELPER FUNCTIONS
-- ===================================================================================================== --

---Sort tooltip items (non-zero first in original order, then zero values)
---@param items table Array of items with value property
function FTE_Utils.sortTooltipItems(items)
    -- Add original index to preserve order
    for i = 1, #items do
        local item = items[i]
        item.originalIndex = i
    end
    
    table.sort(items, function(a, b)
        -- If one is zero and the other is not, non-zero comes first
        if a.value == 0 and b.value ~= 0 then
            return false
        elseif a.value ~= 0 and b.value == 0 then
            return true
        end
        -- If both are zero or both are non-zero, maintain original order
        return a.originalIndex < b.originalIndex
    end)
end

-- ===================================================================================================== --
-- MODULE EXPORT
-- ===================================================================================================== --

return FTE_Utils
