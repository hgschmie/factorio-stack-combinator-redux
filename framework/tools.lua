---@meta
--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

local util = require('util')

local Is = require('stdlib.utils.is')
local table = require('stdlib.utils.table')


---@class FrameworkTools
---@field STATUS_TABLE table<defines.entity_status, string>
---@field STATUS_SPRITES table<defines.entity_status, string>
---@field STATUS_NAMES table<defines.entity_status, string>
---@field STATUS_LEDS table<string, string>
local Tools = {
    STATUS_LEDS = {},
    STATUS_TABLE = {},
    STATUS_NAMES = {},
    STATUS_SPRITES = {},

    copy = util.copy -- allow `tools.copy`
}

--------------------------------------------------------------------------------
-- entity_status led and caption
--------------------------------------------------------------------------------

Tools.STATUS_LEDS = {
    RED = 'utility/status_not_working',
    GREEN = 'utility/status_working',
    YELLOW = 'utility/status_yellow',
}

Tools.STATUS_TABLE = {
    [defines.entity_status.working] = 'GREEN',
    [defines.entity_status.normal] = 'GREEN',
    [defines.entity_status.no_power] = 'RED',
    [defines.entity_status.low_power] = 'YELLOW',
    [defines.entity_status.disabled_by_control_behavior] = 'RED',
    [defines.entity_status.disabled_by_script] = 'RED',
    [defines.entity_status.marked_for_deconstruction] = 'RED',
    [defines.entity_status.disabled] = 'RED',
}

for name, idx in pairs(defines.entity_status) do
    Tools.STATUS_NAMES[idx] = 'entity-status.' .. string.gsub(name, '_', '-')
end

for status, led in pairs(Tools.STATUS_TABLE) do
    Tools.STATUS_SPRITES[status] = Tools.STATUS_LEDS[led]
end

return Tools
