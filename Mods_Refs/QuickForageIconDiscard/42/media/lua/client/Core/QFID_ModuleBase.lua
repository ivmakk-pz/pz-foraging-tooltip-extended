require "ISBaseObject"

local QFID_Utils = require("QFID_Utils")

-- ===================================================================================================== --
-- QFID MODULE BASE CLASS (stable pattern matching vanilla expectations)
-- ===================================================================================================== --

---@class QFID_ModuleBase : ISBaseObject
---@field moduleName string
---@field isActiveFlag boolean
---@field __initializing boolean
---@field __destroying boolean
---@field crashCount number
---@field isBlacklisted boolean
---@field eventHandlers table<string, boolean>   -- key: event|handler_ptr
---@field vanillaOverrides table<string, { target: table, original: function }>
local QFID_ModuleBase = ISBaseObject:derive("QFID_ModuleBase")

-- ===================================================================================================== --
-- MODULE DERIVATION SYSTEM
-- ===================================================================================================== --

---Create a new module class derived from QFID_ModuleBase
---@param className string The name of the derived module class (e.g., "QFID_QuickDiscard")
---@return table derivedClass The new module class
function QFID_ModuleBase:derive(className)
    local derivedClass = ISBaseObject.derive(self, className)
    
    ---Create new instance of the derived module
    ---@return QFID_ModuleBase instance New module instance
    function derivedClass:new()
        local o = ISBaseObject.new(self) --[[@as QFID_ModuleBase]]
        
        o.moduleName       = className
        o.isActiveFlag     = false
        
        o.__initializing   = false
        o.__destroying     = false
        
        o.crashCount       = 0
        o.isBlacklisted    = false
        
        o.eventHandlers    = {}
        o.vanillaOverrides = {}
        
        return o
    end
    
    return derivedClass
end

-- ===================================================================================================== --
-- INTERNAL KEY GENERATION HELPERS
-- ===================================================================================================== --

---Generate unique key for vanilla function overrides
---@param target table The target object containing the function to override
---@param fname string The function name being overridden
---@return string key Unique key in format "table:0x123456::functionName"
local function _ovKey(target, fname)
    return tostring(target) .. "::" .. fname
end

---Generate unique key for event handler deduplication
---@param eventName string The name of the event being registered
---@param fn function The handler function being registered
---@return string key Unique key in format "EventName::function:0x123456"
local function _ehKey(eventName, fn)
    return eventName .. "::" .. tostring(fn)
end

-- ===================================================================================================== --
-- MODULE LIFECYCLE METHODS
-- ===================================================================================================== --

---Initialise module with auto-disable safenet
---@param setupLogic fun(self:QFID_ModuleBase)
---@return boolean success
function QFID_ModuleBase:initialise(setupLogic)
    if self.isBlacklisted then
        QFID_Utils.logWarning("[AUTO-DISABLE] " .. self.moduleName .. " is blacklisted - skipping initialization")
        return false
    end
    
    if self.isActiveFlag then return true end
    if self.__initializing then
        QFID_Utils.logWarning(self.moduleName .. " initialise() re-entered - ignored")
        return false
    end
    if type(setupLogic) ~= "function" then
        QFID_Utils.logError(self.moduleName .. " initialise() aborted - setupLogic not function")
        return false
    end

    self.__initializing = true
    self.isActiveFlag   = true
    local ok, err = pcall(setupLogic, self)
    if not ok then
        self.crashCount = self.crashCount + 1
        self.isBlacklisted = true
        self.isActiveFlag = false
        self.__initializing = false
        
        QFID_Utils.logError("[AUTO-DISABLE] " .. self.moduleName .. " initialise() failed and has been permanently disabled: " .. tostring(err))
        
        return false
    end
    self.__initializing = false
    return true
end

---Clean up module resources and restore vanilla functions
function QFID_ModuleBase:destroy()
    if not self.isActiveFlag then return end
    if self.__destroying then
        QFID_Utils.logWarning(self.moduleName .. " destroy() re-entered - ignored")
        return
    end
    self.__destroying = true

    -- Remove events (reverse order for safer cleanup)
    for key,_ in pairs(self.eventHandlers) do
        local i = key:find("::", 1, true)
        local eventName = key:sub(1, i-1)
        local handlerPtr = key:sub(i+2)
        pcall(function() Events[eventName].Remove(loadstring("return "..handlerPtr)() or handlerPtr) end)
    end
    self.eventHandlers = {}

    -- Restore vanilla functions (cleanup in reverse order)
    for k, data in pairs(self.vanillaOverrides) do
        pcall(function() data.target[k:match("::(.+)$")] = data.original end)
    end
    self.vanillaOverrides = {}

    self.isActiveFlag = false
    self.__destroying = false
end

---Check if module is currently active (not blacklisted)
---@return boolean
function QFID_ModuleBase:isActive()
    return self.isActiveFlag and not self.isBlacklisted
end

---Check if module is blacklisted due to failures
---@return boolean
function QFID_ModuleBase:getBlacklistStatus()
    return self.isBlacklisted or false
end

---Get crash count for debugging/monitoring
---@return number
function QFID_ModuleBase:getCrashCount()
    return self.crashCount or 0
end

-- ===================================================================================================== --
-- EVENT AND OVERRIDE MANAGEMENT METHODS  
-- ===================================================================================================== --

---Register event handler with deduplication and error wrapping
---@param eventName string
---@param handler function
---@return boolean success
function QFID_ModuleBase:registerEvent(eventName, handler)
    if type(handler) ~= "function" then return false end
    local key = _ehKey(eventName, handler)
    if self.eventHandlers[key] then return true end

    local function safeHandler(...)
        local ok, res = pcall(handler, ...)
        if not ok then
            QFID_Utils.logError(self.moduleName .. " event '"..eventName.."' failed: "..tostring(res))
        end
        return res
    end

    local ok, err = pcall(function() Events[eventName].Add(safeHandler) end)
    if ok then
        -- Store wrapper pointer for reliable removal
        self.eventHandlers[_ehKey(eventName, safeHandler)] = true
        return true
    else
        QFID_Utils.logError(self.moduleName .. " failed to register "..eventName..": "..tostring(err))
        return false
    end
end

---Override vanilla function with idempotent wrapping and enhanced auto-restore on crash
---@param targetObject table
---@param functionName string  
---@param newFunction function
---@return boolean success
function QFID_ModuleBase:overrideFunction(targetObject, functionName, newFunction)
    -- Skip if module is blacklisted
    if self.isBlacklisted then
        QFID_Utils.logWarning("[AUTO-DISABLE] " .. self.moduleName .. " is blacklisted - skipping function override for " .. functionName)
        return false
    end
    
    if not targetObject or type(targetObject[functionName]) ~= "function" or type(newFunction) ~= "function" then
        return false
    end
    local key = _ovKey(targetObject, functionName)
    if self.vanillaOverrides[key] then
        -- Already patched by this module - idempotent behavior
        return true
    end

    local original = targetObject[functionName]
    self.vanillaOverrides[key] = { target = targetObject, original = original }

    local wrapper
    wrapper = function(...)
        local ok, result = pcall(newFunction, ...)
        if ok then return result end
        
        -- Enhanced auto-restore with blacklisting on crash
        self.crashCount = self.crashCount + 1
        self.isBlacklisted = true
        self.isActiveFlag = false
        
        -- Enhanced logging for runtime crashes
        QFID_Utils.logError("[AUTO-DISABLE] " .. self.moduleName .. " override '" .. functionName .. "' crashed and module has been permanently disabled: " .. tostring(result))
        
        -- Auto-restore vanilla on crash and fall back for this call
        targetObject[functionName] = original
        self.vanillaOverrides[key] = nil
        return original(...)
    end

    targetObject[functionName] = wrapper
    return true
end

---Get stored original override
---@param functionName string
---@param targetObject table|nil
---@return function|nil
function QFID_ModuleBase:getOriginal(functionName, targetObject)
    if targetObject then
        local ov = self.vanillaOverrides[_ovKey(targetObject, functionName)]
        return ov and ov.original or nil
    end
    -- fallback: search any stored by name (kept for convenience)
    for k, ov in pairs(self.vanillaOverrides) do
        if k:match("::(.+)$") == functionName then return ov.original end
    end
    return nil
end

return QFID_ModuleBase
