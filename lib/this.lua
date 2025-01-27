---@meta
----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class stack_combinator.Mod
---@field other_mods table<string, string>
---@field StackCombinator stack_combinator.StaCo
This = {
    other_mods = {
        ['even-pickier-dollies'] = 'picker_dollies',
        compaktcircuit = 'compaktcircuit',
    },
}

Framework.settings:add_defaults(require('lib.settings'))

if script then
    This.StackCombinator = require('scripts.stack_combinator')
    This.Gui = require('scripts.gui')
end

return This
