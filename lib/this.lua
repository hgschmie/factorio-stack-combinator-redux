---@meta
----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class stack_combinator.Mod
---@field other_mods table<string, string>
This = {
    other_mods = {
        ['even-pickier-dollies'] = 'picker_dollies',
    },
}

Framework.settings:add_defaults(require('lib.settings'))

if script then
end

return This
