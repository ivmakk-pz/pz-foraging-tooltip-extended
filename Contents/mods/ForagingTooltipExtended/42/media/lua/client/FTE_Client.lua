-- FTE_Client.lua - Main entry point for Foraging Tooltip Extended
-- Initializes all modules and manages mod lifecycle

local FTE_Utils = require "FTE_Utils"
local FTE_ModOptions = require "FTE_ModOptions"
local FTE_ViewDistance = require "Modules/FTE_ViewDistance"
local FTE_CoreTooltip = require "Modules/FTE_CoreTooltip"
local FTE_SearchRadiusDisplay = require "Modules/FTE_SearchRadiusDisplay"

-- ===================================================================================================== --
-- INITIALIZATION
-- ===================================================================================================== --

local ForagingTooltipExtended = {}

function ForagingTooltipExtended.init()
    FTE_Utils.logInfo("Foraging Tooltip Extended v" .. FTE_Utils.MOD_VERSION .. " - Initializing...")
    
    -- Initialize ViewDistance module first (it's used by CoreTooltip)
    FTE_ViewDistance.initialise()
    
    -- Initialize CoreTooltip module
    FTE_CoreTooltip.initialise()
    
    -- Initialize SearchRadiusDisplay module
    FTE_SearchRadiusDisplay.initialise()
    
    FTE_Utils.logInfo("Client initialization complete")
end

-- Initialize mod options when UI is ready with protection
function ForagingTooltipExtended.initModOptions()
    local ok, err = pcall(function()
        FTE_ModOptions.initialize()
    end)
    
    if not ok then
        FTE_Utils.logError("[CLIENT-PROTECTION] ModOptions initialization failed: " .. tostring(err))
        FTE_Utils.logInfo("[FALLBACK] ModOptions disabled - using default values")
    end
end

-- ===================================================================================================== --
-- EVENT HOOKS
-- ===================================================================================================== --

Events.OnGameStart.Add(ForagingTooltipExtended.init)
Events.OnCreateUI.Add(ForagingTooltipExtended.initModOptions)

return ForagingTooltipExtended