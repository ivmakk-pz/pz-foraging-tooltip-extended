-- FTE_Utils.lua - Utility functions and constants for Foraging Tooltip Extended
-- Contains color definitions, formatting functions, and other shared utilities

local FTE_Utils = {}

-- ===================================================================================================== --
-- CONSTANTS
-- ===================================================================================================== --

-- Mod version - Update this during release process
FTE_Utils.MOD_VERSION = "1.1.2"

local PRECISION_THRESHOLD = 0.01
local PERCENTAGE_MULTIPLIER = 100

-- Debug mode flag
local DEBUG_MODE = false

-- Tree connector image paths and size
FTE_Utils.TREE_CONNECTOR_MIDDLE = "media/ui/TooltipStructureItems/middle_connector.png"
FTE_Utils.TREE_CONNECTOR_LAST = "media/ui/TooltipStructureItems/last_connector.png"

-- Image padding constant (matches ISRichTextPanel's IMAGE_PAD value)
FTE_Utils.IMAGE_PAD = 5  -- Padding on each side of images in ISRichTextPanel

-- Global alignment position for tooltip values (fixed right-aligned position)
-- Calculated to accommodate max possible value width like "+100.00%" or "10.50"
FTE_Utils.TOOLTIP_VALUE_X_POSITION = 180  -- Fixed X position for all tooltip values

-- Calculate tree connector dimensions based on default tooltip font line height
-- Height matches line height, width is fixed at 8px for thinner connector lines
local function getTreeConnectorDimensions()
    local defaultFont = UIFont.NewSmall
    local lineHeight = getTextManager():getFontFromEnum(defaultFont):getLineHeight()
    local height = math.max(lineHeight, 10)  -- Minimum 10px as per ISRichTextPanel
    local width = 4  -- Fixed width for thinner tree connector lines
    return width, height
end

local treeConnectorWidth, treeConnectorHeight = getTreeConnectorDimensions()
FTE_Utils.TREE_CONNECTOR_WIDTH = treeConnectorWidth    -- Width of tree connector images
FTE_Utils.TREE_CONNECTOR_HEIGHT = treeConnectorHeight  -- Height matches font line height
FTE_Utils.TREE_CONNECTOR_SIZE = treeConnectorHeight    -- Legacy constant (use WIDTH/HEIGHT instead)

-- Pre-built tree connector image tags for convenience
FTE_Utils.TREE_CONNECTOR_MIDDLE_TAG = " <IMAGE:" .. FTE_Utils.TREE_CONNECTOR_MIDDLE .. "," .. treeConnectorWidth .. "," .. treeConnectorHeight .. "> "
FTE_Utils.TREE_CONNECTOR_LAST_TAG = " <IMAGE:" .. FTE_Utils.TREE_CONNECTOR_LAST .. "," .. treeConnectorWidth .. "," .. treeConnectorHeight .. "> "

-- Get game colors once at module load
local GHC = getCore():getGoodHighlitedColor()
local BHC = getCore():getBadHighlitedColor()

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
    
    -- Ensure message is always a string
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

---Format percentage values
---@param float number
---@return string formattedPercent
function FTE_Utils.formatPercent(float)
    if float == 0 then
        return "0"
    end
    return string.format("%+.2f", float * PERCENTAGE_MULTIPLIER)
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

---Generate tooltip text for percentage-based values
---@param text string The label text
---@param value number The percentage value
---@param isBonus boolean Whether this is a bonus (true) or penalty (false)
---@return string tooltipText
function FTE_Utils.getToolTipText(text, value, isBonus)
    local textWithSpace = text .. ": <SPACE> "
    local isZero = (value == 0)
    
    if isBonus then
        return " " .. FTE_Utils.Colors.white .. textWithSpace .. 
               FTE_Utils.getRGBForTooltip(value > 0, isZero) .. 
               FTE_Utils.formatPercent(value) .. " % <LINE> "
    else
        return " " .. FTE_Utils.Colors.white .. textWithSpace .. 
               FTE_Utils.getRGBForTooltip(value < 0, isZero) .. 
               FTE_Utils.formatPercent(value) .. " % <LINE> "
    end
end

---Generate tooltip text for radius values with min/max indicators
---@param text string The label text
---@param value number The radius value
---@param isAtMinRadius boolean
---@param isAtMaxRadius boolean
---@return string tooltipText
function FTE_Utils.getToolTipTextRadius(text, value, isAtMinRadius, isAtMaxRadius)
    local color
    local extraText = ""
    
    if isAtMinRadius then
        color = FTE_Utils.Colors.bad -- Red when at minimum radius
        extraText = color .. " <SPACE> (min)" .. FTE_Utils.Colors.white
    elseif isAtMaxRadius then
        color = FTE_Utils.Colors.good -- Green when at maximum radius
        extraText = color .. " <SPACE> (max)" .. FTE_Utils.Colors.white
    else
        color = FTE_Utils.Colors.good -- Green for positive radius
    end
    
    return " " .. FTE_Utils.Colors.white .. text .. ": <SPACE> " .. 
           color .. FTE_Utils.formatNumber(value) .. extraText .. " <LINE> "
end

---Generate tooltip text for sub-values with prefixes
---@param text string The label text
---@param value number
---@param suffix string Optional suffix (default: "")
---@param prefix string Optional prefix (default: "- ")
---@return string tooltipText
function FTE_Utils.getToolTipTextSubValue(text, value, suffix, prefix)
    local actualPrefix = prefix or "- "
    local actualSuffix = suffix or ""
    
    local color = FTE_Utils.getRGBForValue(value)
    
    return " " .. FTE_Utils.Colors.white .. actualPrefix .. text .. ": <SPACE> " .. 
           color .. FTE_Utils.formatNumber(value) .. actualSuffix .. " <LINE> "
end

---Generate tooltip text with tree connector image
---@param text string The label text
---@param value number|string The value to display (number for auto-formatting, or pre-formatted string with color)
---@param isLast boolean Whether this is the last item (uses last_connector instead of middle_connector)
---@param setXPosition number|nil Optional X position for value alignment (uses <SETX> for column alignment)
---@return string tooltipText
function FTE_Utils.getToolTipTextWithTreeImage(text, value, isLast, setXPosition)
    local imageTag = isLast and FTE_Utils.TREE_CONNECTOR_LAST_TAG or FTE_Utils.TREE_CONNECTOR_MIDDLE_TAG
    
    -- Handle both numeric values and pre-formatted strings
    local formattedValue = ""
    if type(value) == "number" then
        local color = FTE_Utils.getRGBForValue(value)
        formattedValue = color .. FTE_Utils.formatNumber(value)
    else
        formattedValue = tostring(value)  -- Already formatted string with color
    end
    
    if setXPosition then
        -- Use SETX for column-aligned values (like vanilla ISCraftingUI.lua)
        return " " .. imageTag .. FTE_Utils.Colors.white .. text .. ": <SETX:" .. setXPosition .. "> " .. 
               formattedValue .. " <LINE> "
    else
        -- Default: simple space separator
        return " " .. imageTag .. FTE_Utils.Colors.white .. text .. ": <SPACE> " .. 
               formattedValue .. " <LINE> "
    end
end

---Generate tooltip header text with aligned value (for section headers like D, E, F)
---@param text string The header text (e.g., "D. Best Vision Bonus")
---@param value number The value to display
---@return string tooltipText
function FTE_Utils.getToolTipHeaderWithAlignment(text, value)
    local color = FTE_Utils.getRGBForValue(value)
    return " " .. FTE_Utils.Colors.white .. text .. ": <SETX:" .. FTE_Utils.TOOLTIP_VALUE_X_POSITION .. "> " ..
           color .. FTE_Utils.formatNumber(value) .. " <LINE> "
end

---Calculate maximum label width for a set of labels (for column alignment)
---@param labels table Array of label strings
---@param font any UIFont enum (default: UIFont.NewSmall)
---@return number maxWidth Maximum width in pixels
function FTE_Utils.calculateMaxLabelWidth(labels, font)
    font = font or UIFont.NewSmall
    local maxWidth = 0
    
    for i = 1, #labels do
        local labelWidth = getTextManager():MeasureStringX(font, labels[i])
        maxWidth = math.max(maxWidth, labelWidth)
    end
    
    return maxWidth
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
-- DEBUG FUNCTIONS
-- ===================================================================================================== --

local debugMarkers = {}
local lastDebugCoords = {}

---Draw debug circle at specified coordinates (for development purposes only)
---@param x number
---@param y number 
---@param z number
---@param radius number
---@return unknown|nil marker The created marker or nil if failed
function FTE_Utils.drawDebugCircle(x, y, z, radius)
    -- Clean up previous markers if coordinates changed
    if lastDebugCoords.x ~= x or lastDebugCoords.y ~= y or lastDebugCoords.z ~= z then
        for _, marker in pairs(debugMarkers) do
            if marker then
                marker:remove();
            end
        end
        debugMarkers = {};
        lastDebugCoords = {x = x, y = y, z = z};
    end
    
    local square = getCell():getGridSquare(x, y, z);
    if square then
        local marker = getIsoMarkers():addIsoMarker(
            "media/textures/Foraging/pinIconBlank.png",
            square,
            1, 0.5, 0, 0.35  -- Orange color (R=1, G=0.5, B=0)
        );
        if marker then
            marker:setCircleSize(radius);
            table.insert(debugMarkers, marker);
            return marker;
        end
    end
end

-- ===================================================================================================== --
-- MODULE EXPORT
-- ===================================================================================================== --

return FTE_Utils
