---@meta
------------------------------------------------------------------------
-- event registration
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local Position = require('stdlib.area.position')

local tools = require('framework.tools')

local migration = require('scripts.migration')

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

    local config = tags and tags[const.config_tag_name] --[[@as stack_combinator.Config]]

    This.StackCombinator:create(entity, player_index, config)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_space_platform_mined_entity | EventData.script_raised_destroy
local function onEntityDeleted(event)
    local entity = event and event.entity
    local unit_number = entity.unit_number

    This.StackCombinator:destroy(unit_number)
end

--------------------------------------------------------------------------------
-- Entity destruction
--------------------------------------------------------------------------------

---@param event EventData.on_object_destroyed
local function onObjectDestroyed(event)
    -- clear out references if applicable
    if not This.StackCombinator:getEntity(event.useful_id) then return end

    This.StackCombinator:destroy(event.useful_id)
end

--------------------------------------------------------------------------------
-- Blueprinting
--------------------------------------------------------------------------------

---@param entity LuaEntity
---@param idx integer
---@param blueprint LuaItemStack
---@param context table<string, any>
local function onBlueprintCallback(entity, idx, blueprint, context)
    if not entity and entity.valid then return end

    This.StackCombinator:blueprint_callback(entity, idx, blueprint, context)
end

--------------------------------------------------------------------------------
-- Entity settings pasting
--------------------------------------------------------------------------------

---@param event EventData.on_entity_settings_pasted
local function onEntitySettingsPasted(event)
    local player = Player.get(event.player_index)

    if not (player and player.valid and player.force == event.source.force and player.force == event.destination.force) then return end

    local src_entity = This.StackCombinator:getEntity(event.source.unit_number)
    local dst_entity = This.StackCombinator:getEntity(event.destination.unit_number)

    if not (src_entity and dst_entity) then return end

    This.StackCombinator:reconfigure(dst_entity, src_entity.config)
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

---@param event EventData.on_entity_cloned
local function onEntityCloned(event)
    if not (event.source and event.source.valid and event.destination and event.destination.valid) then return end

    local src_data = This.StackCombinator:getEntity(event.source.unit_number)
    if not src_data then return end

    local cloned_entities = event.destination.surface.find_entities(Position(event.destination.position):expand_to_area(0.5))
    for _, cloned_entity in pairs(cloned_entities) do
        if const.internal_entity_names_map[cloned_entity.name] then
            cloned_entity.destroy()
        end
    end

    This.StackCombinator:create(event.destination, nil, src_data.config)
end

---@param event EventData.on_entity_cloned
local function onInternalEntityCloned(event)
    if not (event.source and event.source.valid and event.destination and event.destination.valid) then return end

    -- delete the destination entity, it is not needed as the internal structure of the
    -- Stack combinator is recreated when the main entity is cloned
    event.destination.destroy()
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

    for _, entity_data in pairs(This.StackCombinator:entities()) do
        entity_data.config = This.StackCombinator:createConfig(entity_data.config)
    end

    if Framework.settings:startup_setting(const.settings_names.migrate_stacos) then
        assert(migration)
        migration:migrateStacos()
        migration:migrateBlueprints()
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

    if process_count > 0 then
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

        if table_size(destroy_list) > 0 then
            for _, unit_id in pairs(destroy_list) do
                This.StackCombinator:destroy(unit_id)

                -- if the last index was destroyed, reset the scan loop index
                if unit_id == index then index = nil end
            end
        end
    else
        index = nil
    end

    storage.last_tick_entity = index
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local entity_filter = tools.create_event_entity_matcher('name', const.main_entity_names)
local internal_entity_filter = tools.create_event_entity_matcher('name', const.internal_entity_names)

local function register_events()
    -- entity create / delete
    tools.event_register(tools.CREATION_EVENTS, onEntityCreated, entity_filter)
    tools.event_register(tools.DELETION_EVENTS, onEntityDeleted, entity_filter)

    -- Configuration changes (runtime and startup)
    Event.on_configuration_changed(onConfigurationChanged)

    -- entity destroy (can't filter on that)
    Event.register(defines.events.on_object_destroyed, onObjectDestroyed)

    -- manage blueprinting and copy/paste
    Framework.blueprint:register_callback(const.main_entity_names, onBlueprintCallback)

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, onEntityCloned, entity_filter)
    Event.register(defines.events.on_entity_cloned, onInternalEntityCloned, internal_entity_filter)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, onEntitySettingsPasted, entity_filter)

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
