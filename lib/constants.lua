---@meta
------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

local table = require('stdlib.utils.table')

------------------------------------------------------------------------
-- globals
------------------------------------------------------------------------

---@class stack_combinator.Constants
local Constants = {
    -- the current version that is the result of the latest migration
    CURRENT_VERSION = 1,

    prefix = 'hps__sc-',
    name = 'stack-combinator-redux',
    root = '__stack-combinator-redux__',
    order = 'c[combinators]-cs[stack-combinator-redux]',
    config_tag_name = 'sc_config',
}

Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('gui.') .. id
end

------------------------------------------------------------------------
-- constants and names
------------------------------------------------------------------------

-- Base name
Constants.stack_combinator_name = Constants:with_prefix(Constants.name)

Constants.stack_combinator_output_name = Constants.stack_combinator_name .. '-o'

-- Compactcircuits support
Constants.stack_combinator_name_packed = Constants:with_prefix(Constants.name .. '-packed')

Constants.main_entity_names = {
    Constants.stack_combinator_name, Constants.stack_combinator_name_packed,
}

Constants.internal_entity_names = {
    Constants.stack_combinator_output_name,
}

Constants.main_entity_names_map = table.array_to_dictionary(Constants.main_entity_names, true)
Constants.internal_entity_names_map = table.array_to_dictionary(Constants.internal_entity_names, true)

------------------------------------------------------------------------
-- constants and names
------------------------------------------------------------------------

Constants.defines = {
    ---@enum stack_combinator.non_item_signal_type
    non_item_signal_type = {
        pass = 1,
        invert = 2,
        drop = 3,
    },

    ---@enum stack_combinator.operations
    operations = {
        multiply = 1,
        divide_ceil = 2,
        divide_floor = 3,
        round = 4,
        ceil = 5,
        floor = 6,
    }
}

Constants.settings_keys = {
    'empty_unpowered',
    'non_item_signals',
    'update_interval',
}

Constants.settings_names = {}
Constants.settings = {}

for _, key in pairs(Constants.settings_keys) do
    Constants.settings_names[key] = key
    Constants.settings[key] = Constants:with_prefix(key)
end

------------------------------------------------------------------------
return Constants
