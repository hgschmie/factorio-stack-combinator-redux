---@meta
----------------------------------------------------------------------------------------------------
-- class definitions
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- scripts/stack_combinator.lua
----------------------------------------------------------------------------------------------------

---@class stack_combinator.Storage
---@field VERSION integer
---@field count integer
---@field entities table<number, stack_combinator.Data>
---@field open_guis table<integer, stack_combinator.Data>

---@class stack_combinator.Config
---@field status defines.entity_status?
---@field op stack_combinator.operations
---@field empty_unpowered boolean
---@field merge_inputs boolean
---@field non_item_signals stack_combinator.non_item_signal_type
---@field use_wagon_stacks boolean
---@field process_fluids boolean
---@field network_settings table<defines.wire_connector_id, stack_combinator.NetworkSettings>

---@class stack_combinator.NetworkSettings
---@field invert boolean
---@field enable boolean

---@class stack_combinator.Data
---@field main LuaEntity
---@field output LuaEntity
---@field tick integer
---@field config stack_combinator.Config
