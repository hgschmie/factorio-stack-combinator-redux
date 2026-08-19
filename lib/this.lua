----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

local const = require('lib.constants')

---@class stack_combinator.Mod
---@field other_mods table<string, string>
---@field settings ff2.ModSettings
---@field StackCombinator stack_combinator.StaCo
---@field Gui stack_combinator.Gui
---@field DescGui stack_combinator.DescGui
local This = {
    other_mods = {
        ['even-pickier-dollies'] = 'picker_dollies',
        compaktcircuit = 'compaktcircuit',
        ['compaktcircuit-factorio21'] = 'compaktcircuit',
    },
    settings = require('lib.settings'),
}

if script then
    This.StackCombinator = require('scripts.stack_combinator')
    This.Gui = require('scripts.gui')
    This.DescGui = require('scripts.desc-gui')
end

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function This.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = const.prefix,
        -- prefix for log messages
        log_prefix = const.log_prefix,
        -- name is a human readable name
        name = const.name,
        -- The filesystem root.
        root = const.root,
        -- Remote interface name
        exported_api_name = const.stack_combinator_name,
    }
end

function This:init()
    ---@type stack_combinator.Storage
    storage.entity_storage = storage.entity_storage or {
        count = 0,
        entities = {},
    }
end

---@return stack_combinator.Storage
function This.storage()
    return assert(storage.entity_storage)
end

return This
