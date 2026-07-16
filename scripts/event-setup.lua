--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local Position = require('stdlib.area.position')
local Ticker = require('framework.ticker')

local Matchers = require('framework.matchers')

local migration = require('scripts.migration')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- entity create / delete
--------------------------------------------------------------------------------

---@param event EventData.on_built_entity | EventData.on_robot_built_entity | EventData.on_space_platform_built_entity | EventData.script_raised_revive | EventData.script_raised_built
local function on_entity_created(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end

    ---@type Tags?
    local tags = event.tags
    ---@type integer?
    local player_index = event.player_index

    ---@type stack_combinator.Config?
    local config = nil

    -- see if a ghost (with tags) from a blueprint is replaced
    local entity_ghost = Framework.Ghost:findGhostForEntity(entity)
    if entity_ghost then
        tags = tags or entity_ghost.tags
        player_index = player_index or entity_ghost.player_index
    end

    if tags then
        config = This.StackCombinator:deserializeConfiguration(tags)
    end

    This.StackCombinator:create(entity, player_index, config)
end

---@param event EventData.on_player_mined_entity | EventData.on_robot_mined_entity | EventData.on_space_platform_mined_entity | EventData.script_raised_destroy
local function on_entity_deleted(event)
    local entity = event and event.entity
    if not (entity and entity.valid) then return end

    if This.StackCombinator:destroy(entity.unit_number) then
        Framework.gui_manager:destroyGuiByEntityId(entity.unit_number)
    end
end

--------------------------------------------------------------------------------
-- Entity cloning
--------------------------------------------------------------------------------

---@param event EventData.on_entity_cloned
local function on_entity_cloned(event)
    if not (event and event.source and event.source.valid and event.destination and event.destination.valid) then return end

    local src_data = This.StackCombinator:getEntity(event.source.unit_number)
    if not src_data then return end

    for _, cloned_entity in pairs(event.destination.surface.find_entities_filtered {
        area = Position(event.destination.position):expand_to_area(0.5),
        name = const.internal_entity_names,
    }) do
        cloned_entity.destroy()
    end

    This.StackCombinator:create(event.destination, nil, src_data.config)
end

---@param event EventData.on_entity_cloned
local function on_internal_entity_cloned(event)
    if not (event.source and event.source.valid and event.destination and event.destination.valid) then return end

    -- delete the destination entity, it is not needed as the internal structure of the
    -- Stack combinator is recreated when the main entity is cloned
    event.destination.destroy()
end

--------------------------------------------------------------------------------
-- Entity settings pasting
--------------------------------------------------------------------------------

---@param event EventData.on_entity_settings_pasted
local function on_entity_settings_pasted(event)
    if not (event and event.source and event.source.valid and event.destination and event.destination.valid) then return end

    if event.source.force ~= event.destination.force then return end

    local src_entity = This.StackCombinator:getEntity(event.source.unit_number)
    local dst_entity = This.StackCombinator:getEntity(event.destination.unit_number)

    if not (src_entity and dst_entity) then return end

    This.StackCombinator:reconfigure(dst_entity, src_entity.config)
end

--------------------------------------------------------------------------------
-- Configuration changes startup)
--------------------------------------------------------------------------------

local function on_configuration_changed()
    This:init()

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
-- serialization for Blueprinting and Tombstones
--------------------------------------------------------------------------------

---@param entity LuaEntity
---@return table<string, any>?
local function serialize_config(entity)
    if not (entity and entity.valid) then return end

    return This.StackCombinator:serializeConfiguration(entity)
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

---@param context ff2.ticker.TickerContext
---@param values ff2.ticker.TickerContext
local function ticker_unit_of_work(context, values)
    local staco_index = context.index
    local staco_entity = values.index
    if staco_entity.main and staco_entity.main.valid then
        This.StackCombinator:tick(staco_entity)
    else
        This.StackCombinator:destroy(staco_index)
    end
end

local function on_tick()
    local ticker_info = Ticker.getTicker(const.stack_combinator_name)

    local staco_storage = This.storage()
    if staco_storage.count == 0 then return end

    local interval = Framework.settings:runtime_setting(const.settings_names.update_interval) or 6

    local entities_per_tick = math.max(1, math.ceil(staco_storage.count / interval)) -- at least one

    local context = ticker_info.context or {}

    local iterator = Ticker.createWorkIterator {
        context = context,
        field_name = 'index',
        iterable = staco_storage.entities,
    }

    while entities_per_tick > 0 do
        iterator.process(ticker_unit_of_work)

        entities_per_tick = entities_per_tick - 1
    end

    ticker_info.context = context
    ticker_info.last_tick = game.tick
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local function register_events()
    local match_all_main_entities = Matchers:matchEventEntityName {
        const.stack_combinator_name,
        const.stack_combinator_name_packed,
    }

    local match_main_entity = Matchers:matchEventEntityName(const.stack_combinator_name)
    local match_internal_entities = Matchers:matchEventEntityName(const.internal_entity_names)

    -- entity create / delete
    Event.register(Matchers.CREATION_EVENTS, on_entity_created, match_all_main_entities)
    Event.register(Matchers.DELETION_EVENTS, on_entity_deleted, match_all_main_entities)

    -- manage ghost building (robot building)
    Framework.Ghost:registerForName {
        names = const.stack_combinator_name
    }

    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)

    -- manage blueprinting and copy/paste
    Framework.blueprint:registerCallbackForNames(const.stack_combinator_name, serialize_config)

    -- manage tombstones for undo/redo and dead entities
    Framework.Tombstone:registerCallback(const.stack_combinator_name, {
        create_tombstone = serialize_config,
        apply_tombstone = Framework.Ghost.mapTombstoneToGhostTags,
    })

    -- Entity cloning
    Event.register(defines.events.on_entity_cloned, on_entity_cloned, match_main_entity)
    Event.register(defines.events.on_entity_cloned, on_internal_entity_cloned, match_internal_entities)

    -- Entity settings pasting
    Event.register(defines.events.on_entity_settings_pasted, on_entity_settings_pasted, match_main_entity)

    -- Ticker
    Event.on_nth_tick(1, on_tick)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This:init()
    register_events()
end

local function on_load()
    register_events()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)
