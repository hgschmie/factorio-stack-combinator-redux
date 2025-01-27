--------------------------------------------------------------------------------
-- Even Pickier Dollies (https://mods.factorio.com/mod/even-pickier-dollies) support
--------------------------------------------------------------------------------

local Is = require('stdlib.utils.is')

local const = require('lib.constants')

local PickerDolliesSupport = {}

---@class epd.Event: EventData
---@field player_index uint                 Player index
---@field moved_entity LuaEntity            The entity that was moved. See 'transporter mode' note below
---@field start_pos MapPosition             The start position from which the entity was moved
---@field start_direction defines.direction The start direction of the entity (since 2.5.0)
---@field start_unit_number integer?        The original unit number of the entity (since 2.5.0)

--------------------------------------------------------------------------------

---@param event epd.Event
local function picker_dollies_moved(event)
    local moved_entity = event.moved_entity
    if not Is.Valid(moved_entity) then return end
    if not const.main_entity_names_map[moved_entity.name] then return end

    This.StackCombinator:move(moved_entity, event.start_pos)
end

--------------------------------------------------------------------------------

PickerDolliesSupport.runtime = function()
    assert(script)

    local Event = require('stdlib.event.event')

    local picker_dollies_init = function()
        if not remote.interfaces['PickerDollies'] then return end

        if remote.interfaces['PickerDollies']['dolly_moved_entity_id'] then
            Event.on_event(remote.call('PickerDollies', 'dolly_moved_entity_id'), picker_dollies_moved)
        end

        if remote.interfaces['PickerDollies']['add_oblong_name'] then
            remote.call('PickerDollies', 'add_oblong_name', const.stack_combinator_name)
        end
    end

    Event.on_init(picker_dollies_init)
    Event.on_load(picker_dollies_init)
end

return PickerDolliesSupport
