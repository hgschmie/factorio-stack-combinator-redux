require('lib.init')

local const = require('lib.constants')

local framework_settings = {
    {
        -- Debug mode (framework dependency)
        type = "bool-setting",
        name = Framework.PREFIX .. 'debug-mode',
        order = "z",
        setting_type = "runtime-global",
        default_value = false,
    },
}

local player_settings = {
    {
        name = const.settings.empty_unpowered,
        setting_type = "runtime-per-user",
        type = "bool-setting",
        default_value = false,
        order = 'aa',
    },
    {
        name = const.settings.non_item_signals,
        setting_type = "runtime-per-user",
        type = "string-setting",
        default_value = tostring(const.defines.non_item_signal_type.drop),
        allowed_values = {
            tostring(const.defines.non_item_signal_type.pass),
            tostring(const.defines.non_item_signal_type.invert),
            tostring(const.defines.non_item_signal_type.drop),
        },
        order = 'ab',
    },
}

local runtime_settings = {
    {
        type = "int-setting",
        name = const.settings.update_interval,
        order = "aa",
        setting_type = "runtime-global",
        default_value = 6,
        minimum_value = 1,
        maximum_value = 216000, -- 1h
    },
}

local startup_settings = {
    {
        type = 'bool-setting',
        name = const.settings.migrate_stacos,
        order = 'aa',
        setting_type = 'startup',
        default_value = false,
    },
}

data:extend(framework_settings)
data:extend(player_settings)
data:extend(runtime_settings)
data:extend(startup_settings)

--------------------------------------------------------------------------------

Framework.post_settings_stage()
