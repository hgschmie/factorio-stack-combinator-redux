------------------------------------------------------------------------
-- global startup settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type table<FrameworkSettings.name, FrameworkSettingsGroup>
local Settings = {
    runtime = {
        [const.settings_names.update_interval] = { key = const.settings.update_interval, value = 6 },
    },
    startup = {
        [const.settings_names.migrate_stacos] =  { key = const.settings.migrate_stacos, value = false },
    },
    player = {
        [const.settings_names.empty_unpowered] = { key = const.settings.empty_unpowered, value = false },
        [const.settings_names.non_item_signals] = { key = const.settings.non_item_signals, value = const.defines.non_item_signal_type.drop },
    }
}

return Settings
