-- QFID_QuickDiscard - Quick Discard Module
-- Implements quick discard on RMB and context menu on middle mouse button

require "Foraging/ISForageIcon"

local QFID_Utils = require("QFID_Utils")
local QFID_ModOptions = require("QFID_ModOptions")
local QFID_ModuleBase = require("Core/QFID_ModuleBase")

-- ===================================================================================================== --
-- MODULE SETUP USING QFID_ModuleBase PATTERN
-- ===================================================================================================== --

local QFID_QuickDiscard = QFID_ModuleBase:derive("QFID_QuickDiscard")
local instance = QFID_QuickDiscard:new()

-- ===================================================================================================== --
-- ISFORAGEICON OVERRIDE FUNCTIONS
-- ===================================================================================================== --

---Handle right mouse button based on configuration
---Priority: If both options use same button, discard takes priority
---@param self ISForageIcon
---@param x number
---@param y number
---@return boolean
local function ISForageIcon_onRightMouseDown(self, x, y)
    -- Check if icon is visible and interactable
    if self:getIsSeen() and self:getAlpha() > 0 then
        local discardButton = QFID_ModOptions.getDiscardButton()
        local contextMenuButton = QFID_ModOptions.getContextMenuButton()
        
        -- Priority: Discard takes priority if both use RMB
        if discardButton == Mouse.RMB then
            self:onClickDiscard(x, y, nil)
            return true
        -- RMB is context menu button (only if not also discard button)
        elseif contextMenuButton == Mouse.RMB then
            self:doContextMenu()
            return true
        end
    end
    
    -- Call original if RMB not used by this mod
    local originalHandler = instance:getOriginal("onRightMouseDown", ISForageIcon)
    if originalHandler then
        return originalHandler(self, x, y)
    end
    
    return false
end

---Suppress default context menu on RMB Up if RMB is used by this mod
---@param self ISForageIcon
---@return boolean
local function ISForageIcon_onRightMouseUp(self)
    local discardButton = QFID_ModOptions.getDiscardButton()
    local contextMenuButton = QFID_ModOptions.getContextMenuButton()
    
    -- Suppress default context menu if RMB is used for discard or context menu
    if discardButton == Mouse.RMB or contextMenuButton == Mouse.RMB then
        return false
    end
    
    -- Call original if RMB not used by this mod
    local originalHandler = instance:getOriginal("onRightMouseUp", ISForageIcon)
    if originalHandler then
        return originalHandler(self)
    end
    
    return false
end

---Handle extra mouse buttons (MMB, MB4, MB5) based on configuration
---Priority: If both options use same button, discard takes priority
---@param self ISForageIcon
---@param btn number Mouse button code (2=MMB, 3=MB4, 4=MB5)
---@return boolean
local function ISForageIcon_onMouseButtonDown(self, btn)
    if self:getIsSeen() and self:getAlpha() > 0 then
        local buttonCode = Mouse.BTN_OFFSET + btn
        local discardButton = QFID_ModOptions.getDiscardButton()
        local contextMenuButton = QFID_ModOptions.getContextMenuButton()

        -- Priority: Discard takes priority if both use same button
        if discardButton ~= QFID_Utils.BUTTON_NONE and buttonCode == discardButton then
            self:onClickDiscard(0, 0, nil)
        -- Check if this button is context menu button (only if not also discard button)
        elseif buttonCode == contextMenuButton then
            self:doContextMenu()
        end
    end
    
    -- Call original handler for unassigned buttons
    local originalHandler = instance:getOriginal("onMouseButtonDown", ISForageIcon)
    if originalHandler then
        return originalHandler(self, btn)
    end
    
    return false
end

---Initialise to enable extra mouse events
---@param self ISForageIcon
local function ISForageIcon_initialise(self)
    -- Call original initialise first
    local originalInitialise = instance:getOriginal("initialise", ISForageIcon)
    if originalInitialise then
        originalInitialise(self)
    end
    
    -- Enable extra mouse events to receive onMouseButtonDown calls
    if self.setWantExtraMouseEvents then
        self:setWantExtraMouseEvents(true)
    else
        QFID_Utils.logWarning("setWantExtraMouseEvents not available on ISForageIcon")
    end
end

-- ===================================================================================================== --
-- MODULE SETUP LOGIC
-- ===================================================================================================== --

---Setup module with vanilla function overrides using safe QFID_ModuleBase pattern
function QFID_QuickDiscard:setupModule()
    -- Override initialise to enable extra mouse events
    self:overrideFunction(ISForageIcon, "initialise", ISForageIcon_initialise)
    
    -- Override Right Mouse Button handlers
    self:overrideFunction(ISForageIcon, "onRightMouseDown", ISForageIcon_onRightMouseDown)
    self:overrideFunction(ISForageIcon, "onRightMouseUp", ISForageIcon_onRightMouseUp)
    
    -- Create stub for onMouseButtonDown (vanilla doesn't define it, but we need it for overrideFunction to succeed)
    ISForageIcon.onMouseButtonDown = ISForageIcon.onMouseButtonDown or function() return false end
    self:overrideFunction(ISForageIcon, "onMouseButtonDown", ISForageIcon_onMouseButtonDown)
    
    QFID_Utils.logInfo("Quick Discard module initialized successfully")
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
