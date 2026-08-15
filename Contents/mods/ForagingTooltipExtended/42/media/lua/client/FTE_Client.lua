-- FTE_Client.lua - Main entry point for Foraging Tooltip Extended
-- Initializes all modules and manages mod lifecycle

local FTE_Utils = require "FTE_Utils"
local FTE_ModOptions = require "FTE_ModOptions"
local FTE_CoreTooltip = require "Modules/FTE_CoreTooltip"
local FTE_SearchRadiusDisplay = require "Modules/FTE_SearchRadiusDisplay"
local FTE_VisionAffectingItems = require "Modules/FTE_VisionAffectingItems"

-- ===================================================================================================== --
-- INITIALIZATION
-- ===================================================================================================== --

local ForagingTooltipExtended = {}

function ForagingTooltipExtended.init()
    FTE_Utils.logInfo("Foraging Tooltip Extended v" .. FTE_Utils.MOD_VERSION .. " - Initializing...")
    
    -- Initialize CoreTooltip module
    FTE_CoreTooltip.initialise()
    
    -- Initialize SearchRadiusDisplay module
    FTE_SearchRadiusDisplay.initialise()
    
    -- Initialize VisionAffectingItems module
    FTE_VisionAffectingItems.initialise()
    
    FTE_Utils.logInfo("Client initialization complete")
end

-- Register mod options at game boot (before the first main-menu options screen builds).
-- Registering late (e.g. OnCreateUI, which only fires in-world) leaves the options
-- unregistered at the title screen, where a title-screen save of another options mod
-- parks FTE's ini lines without a newline and a vanilla save() bug concatenates them,
-- corrupting the saved values. Booting early keeps them in Data and always written cleanly.
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
Events.OnGameBoot.Add(ForagingTooltipExtended.initModOptions)

return ForagingTooltipExtended