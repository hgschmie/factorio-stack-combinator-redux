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
        -- Remote interface name
        remote_name = Constants.stack_combinator_name,
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

Constants.internal_entity_names = {
    Constants.stack_combinator_output_name,
}

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
    'migrate_stacos',
}

Constants.settings_names = {}
Constants.settings = {}

for _, key in pairs(Constants.settings_keys) do
    Constants.settings_names[key] = key
    Constants.settings[key] = Constants:with_prefix(key)
end

------------------------------------------------------------------------
-- data helper
------------------------------------------------------------------------

Constants.ac_sprites = {
    'plus_symbol_sprites',
    'minus_symbol_sprites',
    'multiply_symbol_sprites',
    'divide_symbol_sprites',
    'modulo_symbol_sprites',
    'power_symbol_sprites',
    'left_shift_symbol_sprites',
    'right_shift_symbol_sprites',
    'and_symbol_sprites',
    'or_symbol_sprites',
    'xor_symbol_sprites',
}

------------------------------------------------------------------------
-- migration
------------------------------------------------------------------------

Constants.migration = {
    name = 'stack-combinator',
    packed_name = 'stack-combinator-packed',
    output_name = 'stack-combinator-output',
    output_packed_name = 'stack-combinator-output-packed',
}

Constants.migration.migrations = {
    ['stack-combinator'] = Constants.stack_combinator_name,
    ['stack-combinator-packed'] = Constants.stack_combinator_name_packed,
}

Constants.migration.known_entities = {
    Constants.migration.name,
    Constants.migration.packed_name,
    Constants.migration.output_name,
    Constants.migration.output_packed_name,
}

Constants.migration.migrations_names = table.keys(Constants.migration.migrations)
Constants.migration.known_entities_map = table.array_to_dictionary(Constants.migration.known_entities, true)


------------------------------------------------------------------------
return Constants
