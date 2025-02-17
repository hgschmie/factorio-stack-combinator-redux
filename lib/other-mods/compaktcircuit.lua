--------------------------------------------------------------------------------
-- CompactCircuit (https://mods.factorio.com/mod/compaktcircuit) support
--------------------------------------------------------------------------------

local const = require('lib.constants')
local Is = require('stdlib.utils.is')

local CompaktCircuitSupport = {}

--------------------------------------------------------------------------------

---@param entity LuaEntity
local function ccs_get_info(entity)
    if not Is.Valid(entity) then return end

    local entity_data = This.StackCombinator:getEntity(entity.unit_number)
    if not entity_data then return end

    return {
        [const.config_tag_name] = entity_data.config
    }
end

---@class stack_combinator.CompactCircuitInfo
---@field name string
---@field index number
---@field position MapPosition
---@field direction defines.direction
---@field sc_config stack_combinator.Config

---@param info stack_combinator.CompactCircuitInfo
---@param surface LuaSurface
---@param position MapPosition
---@param force LuaForce
local function ccs_create_packed_entity(info, surface, position, force)
    local packed_main = surface.create_entity {
        name = const.stack_combinator_name_packed,
        position = position,
        direction = info.direction,
        force = force,
        raise_built = false,
    }

    assert(packed_main)

    local entity_data = This.StackCombinator:create(packed_main, nil, info[const.config_tag_name])
    assert(entity_data)

    return packed_main
end

---@param info stack_combinator.CompactCircuitInfo
---@param surface LuaSurface
---@param force LuaForce
local function ccs_create_entity(info, surface, force)
    local main = surface.create_entity {
        name = const.stack_combinator_name,
        position = info.position,
        direction = info.direction,
        force = force,
        raise_built = false,
    }

    assert(main)

    local entity_data = This.StackCombinator:create(main, nil, info[const.config_tag_name])
    assert(entity_data)

    return main
end

--------------------------------------------------------------------------------

local function ccs_init()
    if not Framework.remote_api then return end
    if not remote.interfaces['compaktcircuit'] then return end

    if remote.interfaces['compaktcircuit']['add_combinator'] then
        Framework.remote_api.get_info = ccs_get_info
        Framework.remote_api.create_packed_entity = ccs_create_packed_entity
        Framework.remote_api.create_entity = ccs_create_entity

        remote.call('compaktcircuit', 'add_combinator', {
            name = const.stack_combinator_name,
            packed_names = { const.stack_combinator_name_packed },
            interface_name = const.stack_combinator_name,
        })
    end
end

--------------------------------------------------------------------------------

function CompaktCircuitSupport.data()
    assert(data.raw)

    local data_util = require('framework.prototypes.data-util')

    local main_entity_packed = data_util.copy_entity_prototype(data.raw['arithmetic-combinator'][const.stack_combinator_name],
        const.stack_combinator_name_packed, true) --[[@as data.ArithmeticCombinatorPrototype ]]

    -- ArithmeticCombinatorPrototype
    for _, field in pairs(const.ac_sprites) do
        main_entity_packed[field] = util.empty_sprite()
    end

    main_entity_packed.hidden = true
    main_entity_packed.hidden_in_factoriopedia = true

    data:extend { main_entity_packed }
end

--------------------------------------------------------------------------------

function CompaktCircuitSupport.data_final_fixes()
    assert(data.raw)

    local data_util = require('framework.prototypes.data-util')

    if not Framework.settings:startup_setting(const.settings_names.migrate_stacos) then return end

    if not data.raw['arithmetic-combinator'][const.migration.packed_name] then
        local migration = data_util.copy_entity_prototype(data.raw['arithmetic-combinator'][const.stack_combinator_name_packed],
            const.migration.packed_name, true) --[[@as data.ArithmeticCombinatorPrototype ]]

        data:extend { migration }
    end
end

function CompaktCircuitSupport.runtime()
    assert(script)

    local Event = require('stdlib.event.event')

    Event.on_init(ccs_init)
    Event.on_load(ccs_init)
end

return CompaktCircuitSupport
