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
