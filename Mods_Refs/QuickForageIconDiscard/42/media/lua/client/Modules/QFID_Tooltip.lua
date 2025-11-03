-- QFID_Tooltip - Tooltip Module
-- Displays item name tooltip on hover over forage icons

require "Foraging/ISForageIcon"
require "ISUI/ISToolTip"

local QFID_Utils = require("QFID_Utils")
local QFID_ModOptions = require("QFID_ModOptions")
local QFID_ModuleBase = require("Core/QFID_ModuleBase")

-- ===================================================================================================== --
-- MODULE SETUP USING QFID_ModuleBase PATTERN
-- ===================================================================================================== --

local QFID_Tooltip = QFID_ModuleBase:derive("QFID_Tooltip")
local instance = QFID_Tooltip:new()

-- ===================================================================================================== --
-- TYPE DEFINITIONS
-- ===================================================================================================== --

---@class ISForageIconWithTooltip : ISForageIcon
---@field tooltip ISToolTip|nil

-- ===================================================================================================== --
-- HELPER FUNCTIONS
-- ===================================================================================================== --

---Create and configure compact tooltip for forage icon
---@param icon ISForageIconWithTooltip
---@param displayName string
---@return ISToolTip
local function createCompactTooltip(icon, displayName)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    ---@cast tooltip ISToolTip
    tooltip:addToUIManager()
    tooltip:setOwner(icon)
    
    -- Reduce margins on description panel for more compact display (defaults: 20/10/10/10)
    tooltip.descriptionPanel.marginLeft = 5
    tooltip.descriptionPanel.marginRight = 5
    tooltip.descriptionPanel.marginTop = 5
    tooltip.descriptionPanel.marginBottom = 5
    
    -- Use setDescription for smaller font (UIFont.Small instead of UIFont.Medium)
    tooltip:setDescription(displayName)
    tooltip:setVisible(true)
    
    return tooltip
end

-- ===================================================================================================== --
-- ISFORAGEICON OVERRIDE FUNCTIONS
-- ===================================================================================================== --

---Show tooltip with item name on mouse hover
---@param self ISForageIconWithTooltip
---@param dx number
---@param dy number
local function ISForageIcon_onMouseMove(self, dx, dy)
    -- Check if tooltips are enabled
    if not QFID_ModOptions.getShowTooltip() then
        -- Call original handler and exit early
        local originalHandler = instance:getOriginal("onMouseMove", ISForageIcon)
        if originalHandler then
            return originalHandler(self, dx, dy)
        end
        return
    end
    
    -- Only show tooltip if icon is visible and identified
    if self:getIsSeen() and self:getAlpha() > 0 and self.identified then
        -- Get display name first
        local displayName
        if self.itemList and not self.itemList:isEmpty() and self.itemList:get(0) then
            displayName = self.itemList:get(0):getDisplayName()
        elseif self.itemObj then
            displayName = self.itemObj:getDisplayName()
        end
        
        -- Create tooltip if we have something to display
        if displayName and not self.tooltip then
            self.tooltip = createCompactTooltip(self, displayName)
        end
    end
    
    -- Call original handler
    local originalHandler = instance:getOriginal("onMouseMove", ISForageIcon)
    if originalHandler then
        return originalHandler(self, dx, dy)
    end
end

---Hide tooltip when mouse leaves icon
---@param self ISForageIconWithTooltip
---@param dx number
---@param dy number
local function ISForageIcon_onMouseMoveOutside(self, dx, dy)
    -- Always clean up tooltip when mouse leaves (regardless of option state)
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
    
    -- Call original handler
    local originalHandler = instance:getOriginal("onMouseMoveOutside", ISForageIcon)
    if originalHandler then
        return originalHandler(self, dx, dy)
    end
end

-- ===================================================================================================== --
-- MODULE SETUP LOGIC
-- ===================================================================================================== --

---Setup module with vanilla function overrides using safe QFID_ModuleBase pattern
function QFID_Tooltip:setupModule()
    if not ISForageIcon then
        QFID_Utils.logError("ISForageIcon not found - tooltip will not work!")
        return
    end
       
    -- Create stubs for mouse movement handlers (vanilla doesn't always define them)
    ISForageIcon.onMouseMove = ISForageIcon.onMouseMove or function() end
    self:overrideFunction(ISForageIcon, "onMouseMove", ISForageIcon_onMouseMove)
    
    ISForageIcon.onMouseMoveOutside = ISForageIcon.onMouseMoveOutside or function() end
    self:overrideFunction(ISForageIcon, "onMouseMoveOutside", ISForageIcon_onMouseMoveOutside)
    
    QFID_Utils.logInfo("Tooltip module initialized successfully")
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
