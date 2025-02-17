------------------------------------------------------------------------
-- entities
------------------------------------------------------------------------

local util = require('util')

local collision_mask_util = require('collision-mask-util')

local sprites = require('stdlib.data.modules.sprites')

local data_util = require('framework.prototypes.data-util')

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
for _, field in pairs(const.ac_sprites) do
    main_entity[field] = full_sprite
end

-- EntityPrototype
main_entity.icon = const:png('icons/stack-combinator')
main_entity.minable.result = const.stack_combinator_name

data:extend { main_entity }

local output_entity = data_util.copy_entity_prototype(data.raw['constant-combinator']['constant-combinator'], const.stack_combinator_output_name, true) --[[@as data.ConstantCombinatorPrototype ]]

data:extend { output_entity }
