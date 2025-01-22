---@meta
------------------------------------------------------------------------
-- event registration
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local tools = require('framework.tools')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function onEntityCreated(event)
    local entity = event and event.entity

    local player_index = event.player_index
    local tags = event.tags

    local entity_ghost = Framework.ghost_manager:findMatchingGhost(entity)
    if entity_ghost then
        player_index = player_index or entity_ghost.player_index
        tags = tags or entity_ghost.tags
    end

    -- register entity for destruction
    script.register_on_object_destroyed(entity)

    This.StackCombinator:create(entity, player_index, tags)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_space_platform_mined_entity | EventData.on_entity_died | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event and event.entity

    local unit_number = entity.unit_number

    This.StackCombinator:destroy(unit_number)
end

--------------------------------------------------------------------------------
-- Configuration changes (runtime and startup)
--------------------------------------------------------------------------------

local function onConfigurationChanged()
    This.StackCombinator:init()

    -- enable if circuit network is researched.
    for _, force in pairs(game.forces) do
        if force.recipes[const.stack_combinator_name] and force.technologies['circuit-network'] then
            force.recipes[const.stack_combinator_name].enabled = force.technologies['circuit-network'].researched
        end
    end
end

--------------------------------------------------------------------------------
-- Ticker
--------------------------------------------------------------------------------

---@param event EventData.on_tick
local function onTick(event)
    local interval = Framework.settings:runtime_setting(const.settings_names.update_interval) or 6
    local entities = This.StackCombinator:entities()
    local process_count = math.ceil(table_size(entities) / interval)
    local index = storage.last_tick_entity

    if table_size(entities) == 0 then
        index = nil
    else
        local destroy_list = {}
        local entity_data
        repeat
            index, entity_data = next(entities, index)
            if entity_data and (entity_data.main and entity_data.main.valid) then
                if (event.tick - entity_data.tick) >= interval then
                    if This.StackCombinator:tick(entity_data) then
                        process_count = process_count - 1
                    end
                end
            else
                table.insert(destroy_list, index)
            end
        until process_count == 0 or not index

        if table_size(destroy_list) then
            for _, unit_id in pairs(destroy_list) do
                This.StackCombinator:destroy(unit_id)

                -- if the last index was destroyed, reset the scan loop index
                if unit_id == index then
                    index = nil
                end
            end
        end
    end

    storage.last_tick_entity = index
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local entity_filter = tools.create_event_entity_matcher('name', const.main_entity_names)

local function register_events()
    -- entity create / delete
    tools.event_register(tools.CREATION_EVENTS, onEntityCreated, entity_filter)
    tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, entity_filter)

    -- Configuration changes (runtime and startup)
    Event.on_configuration_changed(onConfigurationChanged)
    Event.register(defines.events.on_runtime_mod_setting_changed, onConfigurationChanged)

    -- Ticker
    Event.register(defines.events.on_tick, onTick)
end

local function on_init()
    This.StackCombinator:init()
    register_events()
end

local function on_load()
    register_events()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)
