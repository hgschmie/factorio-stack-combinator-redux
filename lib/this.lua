----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

local const = require('lib.constants')

---@class stack_combinator.Mod
---@field other_mods table<string, string>
---@field settings ff2.ModSettings
---@field StackCombinator stack_combinator.StaCo
---@field Gui stack_combinator.Gui
local This = {
    other_mods = {
        ['even-pickier-dollies'] = 'picker_dollies',
        compaktcircuit = 'compaktcircuit',
    },
    settings = require('lib.settings')
}

if script then
    This.StackCombinator = require('scripts.stack_combinator')
    This.Gui = require('scripts.gui')
end

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function This.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = const.prefix,
        -- name is a human readable name
        name = const.name,
        -- The filesystem root.
        root = const.root,
        -- Remote interface name
        exported_api_name = const.stack_combinator_name,
    }
end

return This
