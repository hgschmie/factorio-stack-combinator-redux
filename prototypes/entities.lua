---@meta
------------------------------------------------------------------------
-- entities
------------------------------------------------------------------------

local util = require('util')

local collision_mask_util = require('collision-mask-util')

local sprites = require('stdlib.data.modules.sprites')

local const = require('lib.constants')

-- Main entity

local function update_sprite(sprite, filename, x, y)
    sprite.filename = const:png(filename)
    sprite.x = x or 0
    sprite.y = y or 0
end

local main_entity = util.copy(data.raw['arithmetic-combinator']['arithmetic-combinator']) --[[@as data.ArithmeticCombinatorPrototype ]]

local selector = data.raw['selector-combinator']['selector-combinator'] --[[@as data.SelectorCombinatorPrototype ]]

-- reskin as a selector combinator
for _, field in pairs { 'sprites', 'activity_led_sprites', 'activity_led_light_offsets', 'screen_light_offsets' } do
    main_entity[field] = util.copy(selector[field])
end

-- sprites need to match the selector skin
local sprite_h = util.copy(selector.max_symbol_sprites.north)
update_sprite(sprite_h, 'entity/stack-combinator-display')

local sprite_v = util.copy(selector.max_symbol_sprites.east)
update_sprite(sprite_v, 'entity/stack-combinator-display')

local full_sprite = { east = sprite_v, west = sprite_v, north = sprite_h, south = sprite_h }

-- PrototypeBase
main_entity.name = const.stack_combinator_name

-- ArithmeticCombinatorPrototype
main_entity.plus_symbol_sprites = full_sprite
main_entity.minus_symbol_sprites = full_sprite
main_entity.multiply_symbol_sprites = full_sprite
main_entity.divide_symbol_sprites = full_sprite

-- EntityPrototype
main_entity.icon = const:png('icons/stack-combinator')
main_entity.minable.result = const.stack_combinator_name

data:extend { main_entity }

---@type data.ConstantCombinatorPrototype
local output_entity = {
    -- PrototypeBase
    type = 'constant-combinator',
    name = const.stack_combinator_output_name,
    hidden = true,
    hidden_in_factoriopedia = true,

    -- ConstantCombinatorPrototype
    sprites = util.empty_sprite(),
    activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
    circuit_wire_connection_points = sprites.empty_connection_points(4),
    circuit_wire_max_distance = default_circuit_wire_max_distance,
    draw_copper_wires = false,
    draw_circuit_wires = false,

    -- EntityWithHealthPrototype
    max_health = 1,

    -- EntityPrototype
    collision_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    collision_mask = collision_mask_util.new_mask(),
    selection_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
    flags = {
        'placeable-off-grid',
        'not-repairable',
        'not-on-map',
        'not-deconstructable',
        'not-blueprintable',
        'hide-alt-info',
        'not-flammable',
        'not-upgradable',
        'not-in-kill-statistics',
        'not-in-made-in',
    },
    minable = nil,
    selection_priority = 1,
    allow_copy_paste = false,
    selectable_in_game = false,
}

data:extend { output_entity }
