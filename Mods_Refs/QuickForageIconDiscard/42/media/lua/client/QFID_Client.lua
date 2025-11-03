-- Quick Forage Icon Discard Main Client File
-- Author: ivmakk
-- Version: 1.0.0

local QFID_Utils = require "QFID_Utils"
local QFID_ModOptions = require "QFID_ModOptions"
local QFID_QuickDiscard = require "Modules/QFID_QuickDiscard"
local QFID_Tooltip = require "Modules/QFID_Tooltip"
local QFID_EnduranceModifier = require "Modules/QFID_EnduranceModifier"

local QuickForageIconDiscard = {}

function QuickForageIconDiscard.init()
    QFID_Utils.logInfo("Quick Forage Icon Discard v" .. QFID_Utils.MOD_VERSION .. " - Initializing...")
    
    QFID_QuickDiscard.initialise()
    QFID_Tooltip.initialise()
    QFID_EnduranceModifier.initialise()
    
    QFID_Utils.logInfo("Client initialization complete")
end

-- Initialize mod options when UI is ready with protection
function QuickForageIconDiscard.initModOptions()
    local ok, err = pcall(function()
        QFID_ModOptions.initialize()
    end)
    
    if not ok then
        QFID_Utils.logError("[CLIENT-PROTECTION] ModOptions initialization failed: " .. tostring(err))
        QFID_Utils.logInfo("[FALLBACK] ModOptions disabled - using hardcoded default values")
    end
end

-- Hook into game events
Events.OnGameStart.Add(QuickForageIconDiscard.init)
Events.OnCreateUI.Add(QuickForageIconDiscard.initModOptions)

return QuickForageIconDiscard
