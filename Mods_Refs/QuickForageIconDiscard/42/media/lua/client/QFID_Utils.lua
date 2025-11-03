-- QFID_Utils.lua
-- Utility Functions - Logging only

local QFID_Utils = {}

-- Mod version - Update this during release process
QFID_Utils.MOD_VERSION = "1.1.0"

-- Mouse button constants
QFID_Utils.BUTTON_NONE = -1  -- Special value indicating no button assigned

local DEBUG_MODE = false

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
    local logLine = "[QFID] " .. level .. " " .. safeMessage
    print(logLine)
end

---Log info message
---@param message string
function QFID_Utils.logInfo(message)
    logMessage(message, "INFO")
end

---Log warning message
---@param message string
function QFID_Utils.logWarning(message)
    logMessage(message, "WARN")
end

---Log error message
---@param message string
function QFID_Utils.logError(message)
    logMessage(message, "ERROR")
end

---Log debug message
---@param message string
function QFID_Utils.logDebug(message)
    logMessage(message, "DEBUG")
end

---Set debug mode
---@param enabled boolean
function QFID_Utils.setDebugMode(enabled)
    DEBUG_MODE = enabled
end

return QFID_Utils