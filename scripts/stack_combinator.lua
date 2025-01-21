---@meta
------------------------------------------------------------------------
-- Stack Combinator code
------------------------------------------------------------------------
assert(script)

local util = require('util')

local Is = require('stdlib.utils.is')

local const = require('lib.constants')

---@class stack_combinator.StaCo
local StaCo = {}

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

---@type stack_combinator.Config
local default_config = {
    enabled = true,
}

--- Creates a default configuration with some fields overridden by
--- an optional parent.
---
---@param parent_config stack_combinator.Config?
---@return stack_combinator.Config
local function create_config(parent_config)
    return util.merge { default_config, parent_config }
end


---@param main LuaEntity
---@param config stack_combinator.Config
---@return LuaEntity
local function create_output(main, config)
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

    main_wire_connectors[defines.wire_connector_id.combinator_output_red].connect_to(output_wire_connectors[defines.wire_connector_id.circuit_red], false, defines.wire_origin.script)
    main_wire_connectors[defines.wire_connector_id.combinator_output_green].connect_to(output_wire_connectors[defines.wire_connector_id.circuit_green], false, defines.wire_origin.script)

    return output
end

------------------------------------------------------------------------
-- create / delete
------------------------------------------------------------------------

--- Creates a new entity from the main entity, registers with the mod
--- and configures it.
---@param main LuaEntity
---@param tags Tags?
---@return stack_combinator.Data?
function StaCo:create(main, tags)
    if not Is.Valid(main) then return nil end

    local entity_id = main.unit_number --[[@as integer]]

    -- if tags were passed in and they contain a config, use that.
    local config = create_config(tags and tags['sc_config'] --[[@as stack_combinator.Config]])
    config.status = main.status

    ---@type stack_combinator.Data
    local entity_data = {
        main = main,
        output = create_output(main, config),
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

function StaCo:reconfigure(entity_data)
end

return StaCo
