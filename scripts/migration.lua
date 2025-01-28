---@meta
--------------------------------------------------------------------------------
-- stack combinator migration
--------------------------------------------------------------------------------
assert(script)

local util = require('util')

local Position = require('stdlib.area.position')
local Is = require('stdlib.utils.is')
local table = require('stdlib.utils.table')

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

---------------------------------------------------------------------------

local control_behavior_template = {
    arithmetic_conditions = {
        second_constant = 0,
        operation = '*',
    }
}

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

--- Replace old staco with new Stack Combinator Redux
---@param blueprint_entity BlueprintEntity
---@return BlueprintEntity?
local function create_entity(blueprint_entity)
    local new_entity = util.copy(blueprint_entity)
    new_entity.control_behavior = util.copy(control_behavior_template)
    new_entity.name = const.migration.migrations[blueprint_entity.name]
    new_entity.tags = create_tags(blueprint_entity)
    return new_entity
end

---------------------------------------------------------------------------


local BlueprintMigrator = {
    is_cc_processor = table.array_to_dictionary {
        'compaktcircuit-processor',
        'compaktcircuit-processor_1x1',
        'compaktcircuit-processor_with_tags',
        'compaktcircuit_1x1',
    }
}

---------------------------------------------------------------------------

---@param blueprint_entity BlueprintEntity
---@return BlueprintEntity?
function BlueprintMigrator:migrateBlueprintEntity(blueprint_entity)
    if not const.migration.migrations[blueprint_entity.name] then return nil end

    return create_entity(blueprint_entity)
end

---@param processor_entity BlueprintEntity
---@return boolean changed
function BlueprintMigrator:processCompaktCircuitProcessor(processor_entity)
    local dirty = false
    local inventory = game.create_inventory(1)
    local item_stack = inventory[1]

    if not processor_entity.tags.blueprint then return false end

    if item_stack.import_stack(processor_entity.tags.blueprint) == 0 and item_stack.is_blueprint then
        if self:executeMigration(item_stack) then
            local tags = util.copy(processor_entity.tags)
            tags.blueprint = item_stack.export_stack()
            processor_entity.tags = tags
            dirty = true
        end
    end

    inventory.destroy()
    return dirty
end

---@param blueprint_entities (BlueprintEntity[])?
---@return boolean modified
function BlueprintMigrator:migrateBlueprintEntities(blueprint_entities)
    local dirty = false

    if not blueprint_entities then return dirty end

    for i = 1, #blueprint_entities, 1 do
        local blueprint_entity = blueprint_entities[i]

        if self.is_cc_processor[blueprint_entity.name] then
            dirty = self:processCompaktCircuitProcessor(blueprint_entity) or dirty
        elseif const.migration.migrations[blueprint_entity.name] then
            local new_entity = self:migrateBlueprintEntity(blueprint_entity)
            if new_entity then
                blueprint_entities[i] = new_entity
                dirty = true
            end
        end
    end

    return dirty
end

---@param migration_object (LuaItemStack|LuaRecord)?
---@return boolean
function BlueprintMigrator:executeMigration(migration_object)
    if not (migration_object and migration_object.valid) then return false end

    local blueprint_entities = util.copy(migration_object.get_blueprint_entities())
    if (self:migrateBlueprintEntities(blueprint_entities)) then
        migration_object.set_blueprint_entities(blueprint_entities)
        return true
    end

    return false
end

---@param inventory LuaInventory?
function BlueprintMigrator:processInventory(inventory)
    if not (inventory and inventory.valid) then return end
    for i = 1, #inventory, 1 do
        if inventory[i] then
            if inventory[i].is_blueprint then
                self:executeMigration(inventory[i])
            elseif inventory[i].is_blueprint_book then
                local nested_inventory = inventory[i].get_inventory(defines.inventory.item_main)
                self:processInventory(nested_inventory)
            end
        end
    end
end

---@param record LuaRecord
function BlueprintMigrator:processRecord(record)
    if not (record.valid and record.valid_for_write) then return end

    if record.type == 'blueprint' then
        self:executeMigration(record)
    elseif record.type == 'blueprint-book' then
        for _, nested_record in pairs(record.contents) do
            self:processRecord(nested_record)
        end
    end
end

---------------------------------------------------------------------------

function Migration:migrateBlueprints()
    -- migrate game blueprints
    for _, record in pairs(game.blueprints) do
        BlueprintMigrator:processRecord(record)
    end

    -- migrate blueprints players have in their inventory
    for _, player in pairs(game.players) do
        local inventory = player.get_main_inventory()
        BlueprintMigrator:processInventory(inventory)
    end
end

return Migration
