---@meta
------------------------------------------------------------------------
-- event registration
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')

local function register_events()
end

local function on_init()
    register_events()
end

local function on_load()
    register_events()
end

Event.on_init(on_init)
Event.on_load(on_load)
