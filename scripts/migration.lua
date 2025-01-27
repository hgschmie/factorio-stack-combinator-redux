---@meta
--------------------------------------------------------------------------------
-- stack combinator migration
--------------------------------------------------------------------------------
assert(script)

local util = require('util')

local Position = require('stdlib.area.position')
local Is = require('stdlib.utils.is')

local const = require('lib.constants')

if not Framework.settings:startup_setting('migrate_stacos') then return nil end

---@class stack_combinator.Migration
---@field stats table<string, number>
local Migration = {
    stats = {},
}

for old, new in pairs(const.migration.migrations) do
    assert(prototypes.entity[old])
    assert(prototypes.entity[new])
end

---@param src LuaEntity
---@param dst LuaEntity
local function copy_wire_connections(src, dst)
    for wire_connector_id, wire_connector in pairs(src.get_wire_connectors(true)) do
        local dst_connector = dst.get_wire_connector(wire_connector_id, true)
        for _, connection in pairs(wire_connector.connections) do
            if connection.origin == defines.wire_origin.player then
                dst_connector.connect_to(connection.target, false, connection.origin)
            end
        end
    end
end

local staco_op_map = {
    ['*'] = const.defines.operations.multiply,
    ['+'] = const.defines.operations.divide_ceil,
    ['/'] = const.defines.operations.divide_floor,
    ['AND'] = const.defines.operations.round,
    ['OR'] = const.defines.operations.ceil,
    ['XOR'] = const.defines.operations.floor,
}

local staco_signal_map = {
    ['signal-black'] = { false, false },
    ['signal-red'] = { true, false },
    ['signal-green'] = { false, true },
    ['signal-yellow'] = { true, true },
}

---@param staco LuaEntity
---@return stack_combinator.Config?
local function create_config_from_staco(staco)
    local config = This.StackCombinator:createConfig()

    local control = staco.get_or_create_control_behavior() --[[@as LuaArithmeticCombinatorControlBehavior]]
    assert(control)

    local parameters = control.parameters

    local invert = staco_signal_map[parameters.first_signal.name]
    if invert then
        config.network_settings[defines.wire_connector_id.circuit_red].invert = invert[1]
        config.network_settings[defines.wire_connector_id.circuit_green].invert = invert[2]
    end

    config.merge_inputs = bit32.band(parameters.second_constant, 1) == 1
    config.use_wagon_stacks = bit32.band(parameters.second_constant, 2) == 2
    config.process_fluids = true

    config.op = staco_op_map[parameters.operation]

    return config
end

---@param blueprint_entity BlueprintEntity
---@return Tags?
local function create_tags(blueprint_entity)
    local config = This.StackCombinator:createConfig()
    local control = blueprint_entity.control_behavior
    assert(control)

    local parameters = control.arithmetic_conditions
    assert(parameters)

    local invert = parameters.first_signal and staco_signal_map[parameters.first_signal.name] or false
    if invert then
        config.network_settings[defines.wire_connector_id.circuit_red].invert = invert[1]
        config.network_settings[defines.wire_connector_id.circuit_green].invert = invert[2]
    end

    config.merge_inputs = bit32.band(parameters.second_constant, 1) == 1
    config.use_wagon_stacks = bit32.band(parameters.second_constant, 2) == 2
    config.process_fluids = true

    config.op = staco_op_map[parameters.operation]

    return {
        ['const.config_tag_name'] = config
    }
end

---@param surface LuaSurface
---@param staco LuaEntity
local function migrate_staco(surface, staco)
    if not Is.Valid(staco) then return end
    local entities_to_delete = surface.find_entities(Position(staco.position):expand_to_area(0.5))

    local entity_config = {
        name = const.migration.migrations[staco.name],
        position = staco.position,
        direction = staco.direction,
        quality = staco.quality,
        force = staco.force,
    }

    local config = create_config_from_staco(staco)

    -- create new main entity in the same spot
    local main = surface.create_entity(entity_config)

    assert(main)

    copy_wire_connections(staco, main)

    local entity_data = This.StackCombinator:create(main, nil, config)

    Migration.stats[staco.name] = (Migration.stats[staco.name] or 0) + 1

    for _, entity_to_delete in pairs(entities_to_delete) do
        if const.migration.known_entities_map[entity_to_delete.name] then
            entity_to_delete.destroy()
        end
    end
end

function Migration:migrateStacos()
    for _, surface in pairs(game.surfaces) do
        self.stats = {}

        local stacos = surface.find_entities_filtered {
            name = const.migration.migrations_names,
        }

        for _, staco in pairs(stacos) do
            migrate_staco(surface, staco)
        end

        local stats = ''
        local total = 0
        for name, count in pairs(self.stats) do
            stats = stats .. ('%s: %s'):format(name, count)
            total = total + count
            if next(self.stats, name) then
                stats = stats .. ', '
            end
        end
        if total > 0 then
            game.print { const:locale('migration'), total, surface.name, stats }
        end
    end
end

---@param blueprint LuaRecord
local function migrate_blueprint(blueprint)
    if blueprint.type == 'blueprint-book' then
        for _, nested_blueprint in pairs(blueprint.contents) do
            migrate_blueprint(nested_blueprint)
        end
        return
    end

    if blueprint.type ~= 'blueprint' then return end

    for _, default_icon in pairs(blueprint.default_icons) do
        if (default_icon.signal.type == nil or default_icon.signal.type == 'item') and const.migration.migrations[default_icon.signal.name] then
            default_icon.signal.name = const.migration.migrations[default_icon.signal.name]
        end
    end

    local dirty = false

    local blueprint_entities = blueprint.get_blueprint_entities()
    if not blueprint_entities then return end

    for i = 1, blueprint.get_blueprint_entity_count() do
        local blueprint_entity = blueprint_entities[i]

        if const.migration.migrations[blueprint_entity.name] then
            local new_entity = util.copy(blueprint_entity)
            new_entity.name = const.migration.migrations[blueprint_entity.name]
            new_entity.tags = create_tags(blueprint_entity)
            blueprint_entities[i] = new_entity
            dirty = true
        end
    end

    if dirty then
        blueprint.set_blueprint_entities(blueprint_entities)
    end
end

function Migration:migrateBlueprints()
    for _, blueprint in pairs(game.blueprints) do
        migrate_blueprint(blueprint)
    end
end

return Migration
