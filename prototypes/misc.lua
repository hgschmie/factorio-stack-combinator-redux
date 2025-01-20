---@meta
------------------------------------------------------------------------
-- misc stuff
------------------------------------------------------------------------

local util = require('util')
local table = require('stdlib.utils.table')

local const = require('lib.constants')

---@type data.RecipePrototype
local recipe = {
    type = 'recipe',
    name = const.stack_combinator_name,
    enabled = false,
    ingredients = {
        { type = 'item', name = 'copper-cable',       amount = 5 },
        { type = 'item', name = 'electronic-circuit', amount = 5 },
    },
    results = {
        { type = 'item', name = const.stack_combinator_name, amount = 1 },
    },
}

data:extend { recipe }

assert(data.raw['technology']['circuit-network'])
table.insert(data.raw['technology']['circuit-network'].effects, { type = 'unlock-recipe', recipe = const.stack_combinator_name })

---@type data.ItemPrototype
local item = util.copy(data.raw.item['selector-combinator'])
item.name = const.stack_combinator_name
item.icon = const:png('icons/stack-combinator')
item.place_result = const.stack_combinator_name
item.order = const.order

data:extend { item }

local function update_sprite(sprite, filename, x, y)
    sprite.filename = const:png(filename)
    sprite.x = x or 0
    sprite.y = y or 0
end

local entity = util.copy(data.raw['arithmetic-combinator']['arithmetic-combinator']) --[[@as data.ArithmeticCombinatorPrototype ]]

local selector = data.raw['selector-combinator']['selector-combinator'] --[[@as data.SelectorCombinatorPrototype ]]

-- reskin as a selector combinator

for _, field in pairs({ 'sprites', 'activity_led_sprites', 'activity_led_light_offsets', 'screen_light_offsets' }) do
    entity[field] = util.copy(selector[field])
end

-- sprites need to match the selector skin
local sprite_h = util.copy(selector.max_symbol_sprites.north)
update_sprite(sprite_h, 'entity/stack-combinator-display')

local sprite_v = util.copy(selector.max_symbol_sprites.east)
update_sprite(sprite_v, 'entity/stack-combinator-display')

local full_sprite = { east = sprite_v, west = sprite_v, north = sprite_h, south = sprite_h }

-- PrototypeBase
entity.name = const.stack_combinator_name

-- ArithmeticCombinatorPrototype
entity.plus_symbol_sprites = full_sprite
entity.minus_symbol_sprites = full_sprite
entity.multiply_symbol_sprites = full_sprite
entity.divide_symbol_sprites = full_sprite

-- EntityPrototype
entity.icon = const:png('icons/stack-combinator')
entity.minable.result = entity.name

data:extend { entity }
