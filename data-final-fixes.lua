------------------------------------------------------------------------
-- data phase 3
------------------------------------------------------------------------

require('lib.init')

local const = require('lib.constants')
local tools = require('framework.tools')

if Framework.settings:startup_setting('migrate_stacos') then
    if not data.raw['arithmetic-combinator'][const.migration.name] then
        local migration = tools.copy(data.raw['arithmetic-combinator'][const.stack_combinator_name])
        migration.name = const.migration.name
        data:extend { migration }
    end
end


Framework.post_data_final_fixes_stage()
