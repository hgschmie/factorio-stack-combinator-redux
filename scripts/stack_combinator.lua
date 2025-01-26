---@meta
------------------------------------------------------------------------
-- Stack Combinator code
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Is = require('stdlib.utils.is')

local const = require('lib.constants')

---@class stack_combinator.StaCo
local StaCo = {
    ---@type table<stack_combinator.operations, fun(self: stack_combinator.StaCo, value: number, stack: number): number>
    compute_ops = {
        [const.defines.operations.multiply] = function(self, value, stack)
            return value * stack
        end,
        [const.defines.operations.divide_ceil] = function(self, value, stack)
            return value >= 0 and math.ceil(value / stack) or math.floor(value / stack)
        end,
        [const.defines.operations.divide_floor] = function(self, value, stack)
            return value >= 0 and math.floor(value / stack) or math.ceil(value / stack)
        end,
        [const.defines.operations.round] = function(self, value, stack)
            return (math.abs(value) % stack > math.ceil(stack / 2))
                and self.compute_ops[const.defines.operations.ceil](self, value, stack)
                or self.compute_ops[const.defines.operations.floor](self, value, stack)
        end,
        [const.defines.operations.ceil] = function(self, value, stack)
            return self.compute_ops[const.defines.operations.divide_ceil](self, value, stack) * stack
        end,
        [const.defines.operations.floor] = function(self, value, stack)
            return self.compute_ops[const.defines.operations.divide_floor](self, value, stack) * stack
        end,
    },
}

------------------------------------------------------------------------
-- init
------------------------------------------------------------------------

function StaCo:init()
    ---@type stack_combinator.Storage
    storage.entity_storage = storage.entity_storage or {
        VERSION = const.CURRENT_VERSION,
        count = 0,
        entities = {},
        open_guis = {},
    }
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

--- Returns the registered total count
---@return integer count The total count of entities
function StaCo:entityCount()
    return storage.entity_storage.count
end

--- Returns data for all entities.
---@return table<integer, stack_combinator.Data> entities
function StaCo:entities()
    return storage.entity_storage.entities
end

--- Returns data for a given entity.
---@param entity_id integer main unit number (== entity id)
---@return stack_combinator.Data? entity
function StaCo:getEntity(entity_id)
    return storage.entity_storage.entities[entity_id]
end

--- Registers and entity.
---@param entity_id integer The unit_number of the primary
---@param entity_data stack_combinator.Data
function StaCo:registerEntity(entity_id, entity_data)
    assert(storage.entity_storage.entities[entity_id] == nil)
    assert(Is.Valid(entity_data.main) and entity_data.main.unit_number == entity_id)

    storage.entity_storage.entities[entity_id] = entity_data
    storage.entity_storage.count = storage.entity_storage.count + 1
end

--- Removes an entity.
---@param entity_id integer The unit_number of the primary
---@return stack_combinator.Data? entity_data
function StaCo:removeEntity(entity_id)
    local result = storage.entity_storage.entities[entity_id]
    if result then
        storage.entity_storage.entities[entity_id] = nil
        storage.entity_storage.count = storage.entity_storage.count - 1

        if storage.entity_storage.count < 0 then
            storage.entity_storage.count = table_size(storage.entity_storage.entities)
            Framework.logger:logf('Entity count got negative (bug), size is now: %d', storage.entity_storage.count)
        end
    end

    return result
end

------------------------------------------------------------------------
-- helper code
------------------------------------------------------------------------

--- Creates a default configuration with some fields overridden by
--- an optional parent.
---
---@param parent_config stack_combinator.Config?
---@param player_index number?
---@return stack_combinator.Config
function StaCo:createConfig(parent_config, player_index)
    ---@type stack_combinator.Config
    local default_config = {
        op = const.defines.operations.multiply,
        empty_unpowered = player_index and Framework.settings:player_setting(const.settings_names.empty_unpowered, player_index) or false,
        non_item_signals = player_index and tonumber(Framework.settings:player_setting(const.settings_names.non_item_signals, player_index)) or
            const.defines.non_item_signal_type.drop,
        merge_inputs = false,
        use_wagon_stacks = false,
        process_fluids = false,
        network_settings = {
            [defines.wire_connector_id.circuit_red] = {
                enable = true,
                invert = false,
            },
            [defines.wire_connector_id.circuit_green] = {
                enable = true,
                invert = false,
            },
        }
    }

    return util.merge { default_config, parent_config }
end

---@param main LuaEntity
---@return LuaEntity
local function create_output(main)
    -- create output constant combinator
    local output = main.surface.create_entity {
        name = const.stack_combinator_output_name,
        position = main.position,
        quality = main.quality,
        force = main.force,
    }
    assert(output)

    output.destructible = false
    output.operable = true
    local main_wire_connectors = main.get_wire_connectors(true)
    local output_wire_connectors = output.get_wire_connectors(true)

    main_wire_connectors[defines.wire_connector_id.combinator_output_red].connect_to(output_wire_connectors[defines.wire_connector_id.circuit_red], false,
        defines.wire_origin.script)
    main_wire_connectors[defines.wire_connector_id.combinator_output_green].connect_to(output_wire_connectors[defines.wire_connector_id.circuit_green], false,
        defines.wire_origin.script)

    return output
end

------------------------------------------------------------------------
-- create / delete
------------------------------------------------------------------------

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param player_index integer
---@param tags Tags?
---@return stack_combinator.Data?
function StaCo:create(main, player_index, tags)
    if not Is.Valid(main) then return nil end

    local entity_id = main.unit_number --[[@as integer]]

    -- if tags were passed in and they contain a config, use that.
    local config = self:createConfig(tags and tags['sc_config'] --[[@as stack_combinator.Config]], player_index)
    config.status = main.status

    ---@type stack_combinator.Data
    local entity_data = {
        main = main,
        output = create_output(main),
        tick = -1,
        config = config,
    }

    self:registerEntity(entity_id, entity_data)

    self:reconfigure(entity_data)

    return entity_data
end

--- Destroys an entity.
---@param entity_id integer? main unit number (== entity id)
function StaCo:destroy(entity_id)
    if not entity_id then return end
    assert(entity_id)

    local entity_data = self:removeEntity(entity_id)
    if not entity_data then return end

    entity_data.main = nil

    if Is.Valid(entity_data.output) then entity_data.output.destroy() end
    entity_data.output = nil
end

------------------------------------------------------------------------
-- main function code
------------------------------------------------------------------------

local MAX = 2 ^ 31 - 1
local MIN = -2 ^ 31

---@param entity_data stack_combinator.Data
---@param filters table<string, LogisticFilter>
local function set_filters(entity_data, filters)
    local max_count = 1000 -- max number of signals in one section

    local section_filters = {}

    for _, filter in pairs(filters) do
        -- clamp to 32 bit values ?
        filter.min = (filter.min > MAX) and MAX or filter.min
        filter.min = (filter.min < MIN) and MIN or filter.min

        table.insert(section_filters, filter)

        max_count = max_count - 1
        if max_count == 0 then break end
    end

    local output = entity_data.output.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    assert(output)
    assert(output.sections_count == 1)
    local section = output.sections[1]
    assert(section.type == defines.logistic_section_type.manual)

    section.filters = section_filters
end

---@param signal SignalID|SignalFilter
---@return string key
local function create_key(signal)
    local type = signal.type or 'item'
    local quality = signal.quality or 'normal'
    local key = ('%s-%s-%s'):format(type, signal.name, quality)
    return key
end

---@param signal Signal
---@return LogisticFilter
local function signal_to_logistic_filter(signal)
    ---@type LogisticFilter
    local filter = {
        value = {
            type = signal.signal.type or 'item',
            name = signal.signal.name,
            quality = signal.signal.quality or 'normal',
        },
        min = signal.count,
    }

    return filter
end

---@class stack_combinator.WagonStack
---@field cargo number
---@field fluid number
local empty_wagon_stack = {
    cargo = 1,
    fluid = 1,
}

---@param signals Signal[]
---@return stack_combinator.WagonStack
local function compute_wagon_stacks(signals)
    local cargo = 0
    local fluid = 0
    for _, signal in pairs(signals) do
        local prototype = prototypes.entity[signal.signal.name]
        if Is.Valid(prototype) then
            local cargo_stacks = (prototype.type == 'cargo-wagon') and prototype.get_inventory_size(defines.inventory.cargo_wagon)
            if (cargo_stacks) then
                cargo_stacks = cargo_stacks * signal.count
                cargo = cargo + cargo_stacks
            end

            local fluid_stack = prototype.type == 'fluid-wagon' and prototype.fluid_capacity
            if (fluid_stack) then
                fluid_stack = fluid_stack * signal.count
                fluid = fluid + fluid_stack
            end
        end
    end

    return {
        cargo = cargo > 0 and cargo or 1,
        fluid = fluid > 0 and fluid or 1,
    }
end

--- Convert circuit network signal values to their stack sizes
---@param signals (Signal[])?
---@param filters table<string, LogisticFilter>
---@param config stack_combinator.Config
---@param connection_id defines.wire_connector_id?
function StaCo:compute(signals, filters, config, connection_id)
    if not signals then return end

    local wagon_stacks = config.use_wagon_stacks and compute_wagon_stacks(signals) or empty_wagon_stack
    local invert = connection_id and config.network_settings[connection_id].invert or false

    for _, signal in pairs(signals) do
        local filter = signal_to_logistic_filter(signal)
        local name = filter.value.name
        local value = filter.min
        local type = filter.value.type

        assert(name)
        assert(value)

        -- always process items or when non-item signals are not dropped
        local process = (type == 'item') or (config.non_item_signals ~= const.defines.non_item_signal_type.drop)

        -- if wagon_stacks is active, skip cargo-wagon and fluid-wagon
        if config.use_wagon_stacks and prototypes.entity[name] then
            local entity_type = prototypes.entity[name].type
            process = process and not (entity_type == 'cargo-wagon' or entity_type == 'fluid-wagon')
        end

        if (process) then
            local match_item = type == 'item'
            local match_fluid = config.use_wagon_stacks and config.process_fluids and type == 'fluid'

            local prototype = prototypes.item[name]
            local multiplier
            if match_item or match_fluid then
                multiplier = invert and -1 or 1
            else
                multiplier = (config.non_item_signals == const.defines.non_item_signal_type.invert) and -1 or 1
            end

            local stack = match_item and (prototype.stack_size * (config.use_wagon_stacks and wagon_stacks.cargo or 1)) or 1
            stack = match_fluid and wagon_stacks.fluid or stack

            local result = multiplier * This.StackCombinator.compute_ops[config.op](self, value, stack)

            if result ~= 0 then
                local key = create_key(filter.value)

                if (filters[key]) then
                    filters[key].min = filters[key].min + result
                else
                    filters[key] = filter
                    filters[key].min = result
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- reconfiguration / ticker
------------------------------------------------------------------------

---@param entity_data stack_combinator.Data
function StaCo:reconfigure(entity_data)
    entity_data.tick = game.tick

    if not entity_data.main.valid then return end
    local config = entity_data.config

    ---@type table<string, LogisticFilter>
    local filters = {}

    if config.status ~= defines.entity_status.no_power then
        ---@type Signal[]
        local signals = {}

        for _, connection_id in pairs { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green } do
            local network_settings = config.network_settings[connection_id]
            local network_signals = network_settings.enable and entity_data.main.get_signals(connection_id)

            if network_signals then
                if config.merge_inputs then
                    for _, signal in pairs(network_signals) do
                        local key = create_key(signal.signal)
                        local value = util.copy(signal)
                        value.count = value.count * (network_settings.invert and -1 or 1)

                        if signals[key] then
                            signals[key].count = signals[key].count + value.count
                        else
                            signals[key] = value
                        end
                    end
                else
                    -- not merged, compute separately
                    self:compute(network_signals, filters, config, connection_id)
                end
            end
        end

        if config.merge_inputs then
            self:compute(signals, filters, config)
        end
    elseif not config.empty_unpowered then
        return
    end

    set_filters(entity_data, filters)
end

---@param entity_data stack_combinator.Data
---@return boolean
function StaCo:tick(entity_data)
    if not entity_data.main.valid then
        entity_data.config.status = defines.entity_status.marked_for_deconstruction
        return false
    else
        entity_data.config.status = entity_data.main.status
        self:reconfigure(entity_data)
    end

    return true
end

return StaCo
