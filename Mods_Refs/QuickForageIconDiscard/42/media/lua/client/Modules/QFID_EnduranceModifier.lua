-- QFID_EnduranceModifier - Endurance Modifier Module
-- Reduces endurance penalty for discard actions based on configurable multiplier

require "Foraging/forageSystem"
require "Foraging/ISForageAction"

local QFID_Utils = require("QFID_Utils")
local QFID_ModOptions = require("QFID_ModOptions")
local QFID_ModuleBase = require("Core/QFID_ModuleBase")

-- ===================================================================================================== --
-- MODULE SETUP USING QFID_ModuleBase PATTERN
-- ===================================================================================================== --

local QFID_EnduranceModifier = QFID_ModuleBase:derive("QFID_EnduranceModifier")
local instance = QFID_EnduranceModifier:new()

-- ===================================================================================================== --
-- HELPER FUNCTIONS
-- ===================================================================================================== --

-- Track current action context to detect discard state
local currentAction = nil

---Store reference to current action being executed
---@param action ISForageAction
local function setCurrentAction(action)
    currentAction = action
end

---Clear current action reference
local function clearCurrentAction()
    currentAction = nil
end

---Check if current action is a discard action
---@return boolean
local function isCurrentActionDiscard()
    return (currentAction and currentAction.discardItems == true) or false
end

-- ===================================================================================================== --
-- ISFORAGEACTION OVERRIDE FUNCTIONS
-- ===================================================================================================== --

---Override forage() to track action context
---@param self ISForageAction
local function ISForageAction_forage(self)
    -- Set current action context so penalty functions can check it
    setCurrentAction(self)
    
    -- Call original forage (which calls penalty functions)
    local originalForage = instance:getOriginal("forage", ISForageAction)
    if originalForage then
        originalForage(self)
    end
    
    -- Clear action context after execution
    clearCurrentAction()
end

-- ===================================================================================================== --
-- FORAGESYSTEM OVERRIDE FUNCTIONS
-- ===================================================================================================== --

---Modified endurance penalty that applies multiplier for discard actions
---@param _character IsoPlayer
---@param _amount number|nil
---@return number enduranceLevel
local function forageSystem_doEndurancePenalty(_character, _amount)
    local modifier = QFID_ModOptions.getDiscardEnduranceModifier()
    
    -- Fast path: Use vanilla behavior if not a discard OR modifier is 1.0 (100%)
    if not isCurrentActionDiscard() or modifier == 1.0 then
        local originalPenalty = instance:getOriginal("doEndurancePenalty", forageSystem)
        if originalPenalty then
            return originalPenalty(_character, _amount)
        end
    end
    
    -- Apply modified penalty for discard
    local baseAmount = forageSystem.endurancePenalty * modifier
    local enduranceLevel = _character:getStats():getEndurance()
    enduranceLevel = enduranceLevel - baseAmount
    _character:getStats():setEndurance(enduranceLevel)
    
    return enduranceLevel
end

-- ===================================================================================================== --
-- MODULE SETUP LOGIC
-- ===================================================================================================== --

---Setup module with vanilla function overrides using safe QFID_ModuleBase pattern
function QFID_EnduranceModifier:setupModule()
    if not forageSystem then
        QFID_Utils.logError("forageSystem not found - endurance modifier will not work!")
        return
    end
    
    if not forageSystem.doEndurancePenalty then
        QFID_Utils.logError("forageSystem.doEndurancePenalty not found - endurance modifier will not work!")
        return
    end
    
    if not ISForageAction then
        QFID_Utils.logError("ISForageAction not found - endurance modifier will not work!")
        return
    end
    
    -- Override the forage action to track action context
    self:overrideFunction(ISForageAction, "forage", ISForageAction_forage)
    
    -- Override endurance penalty to apply modifier based on action context
    self:overrideFunction(forageSystem, "doEndurancePenalty", forageSystem_doEndurancePenalty)
    
    QFID_Utils.logInfo("Endurance modifier module initialized successfully")
end

-- ===================================================================================================== --
-- MODULE EXPORT
-- ===================================================================================================== --

return {
    initialise = function() return instance:initialise(function(self) self:setupModule() end) end,
    destroy = function() return instance:destroy() end,
    isActive = function() return instance:isActive() end,
    getInstance = function() return instance end
}
