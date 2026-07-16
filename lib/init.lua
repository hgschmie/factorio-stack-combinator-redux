----------------------------------------------------------------------------------------------------
--- Global definitions included in all phases
----------------------------------------------------------------------------------------------------

-- mod code
local this = require('lib.this')

-- Framework core
local framework = require('framework.init')

if this.settings then
    framework.settings:add_defaults(framework.settings)
end

framework:init(this.framework_init)

return function()
    return this, framework
end
