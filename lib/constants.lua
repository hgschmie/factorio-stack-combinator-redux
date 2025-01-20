---@meta
------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

------------------------------------------------------------------------
-- globals
------------------------------------------------------------------------

local Constants = {
    -- the current version that is the result of the latest migration
    CURRENT_VERSION = 1,

    prefix = 'hps__sc-',
    name = 'stack-combinator-redux',
    root = '__stack-combinator-redux__',
    order = 'c[combinators]-r[stack-combinator-redux]',
}

Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('gui.') .. id
end

------------------------------------------------------------------------
-- constants and names
------------------------------------------------------------------------

-- Base name
Constants.stack_combinator_name = Constants:with_prefix(Constants.name)

-- Compactcircuits support
Constants.stack_combinator_name_packed = Constants:with_prefix(Constants.name .. '-packed')

Constants.main_entity_names = {
    Constants.stack_combinator_name, Constants.stack_combinator_name_packed,
}

------------------------------------------------------------------------
return Constants
