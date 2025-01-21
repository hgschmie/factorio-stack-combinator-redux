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
---@field enabled boolean
---@field status defines.entity_status?

---@class stack_combinator.Data
---@field main LuaEntity
---@field output LuaEntity
---@field config stack_combinator.Config
