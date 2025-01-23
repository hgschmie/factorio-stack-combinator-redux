---@meta
------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local Is = require('stdlib.utils.is')
local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local tools = require('framework.tools')

local const = require('lib.constants')

---@class stack_combinator.Gui
local Gui = {}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

---@param entity_data stack_combinator.Data
---@return framework.gui.element_definition ui
function Gui.getUi(entity_data)
    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = Gui.onWindowClosed },
        elem_mods = { auto_center = true },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                drag_target = 'gui_root',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { 'entity-name.' .. const.stack_combinator_name },
                        drag_target = 'gui_root',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'empty-widget',
                        style = 'framework_titlebar_drag_handle',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'sprite-button',
                        style = 'frame_action_button',
                        sprite = 'utility/close',
                        hovered_sprite = 'utility/close_black',
                        clicked_sprite = 'utility/close_black',
                        mouse_button_filter = { 'left' },
                        handler = { [defines.events.on_gui_click] = Gui.onWindowClosed },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'frame',
                style = 'entity_frame',
                children = {
                    {
                        type = 'flow',
                        style = 'two_module_spacing_vertical_flow',
                        direction = 'vertical',
                        children = {
                            {
                                type = 'frame',
                                direction = 'horizontal',
                                style = 'framework_subheader_frame',
                                children = {
                                    {
                                        type = 'label',
                                        style = 'subheader_caption_label',
                                        caption = { '', { 'gui-arithmetic.input' }, { 'colon' } },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'connections_input',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'combinator_input_red',
                                        visible = false,
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'combinator_input_green',
                                        visible = false,
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                    {
                                        type = 'label',
                                        style = 'subheader_caption_label',
                                        caption = { '', { 'gui-arithmetic.output' }, { 'colon' } },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'connections_output',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'combinator_output_red',
                                        visible = false,
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'combinator_output_green',
                                        visible = false,
                                    },
                                },
                            },
                            {
                                type = 'flow',
                                style = 'framework_indicator_flow',
                                children = {
                                    {
                                        type = 'sprite',
                                        name = 'lamp',
                                        style = 'framework_indicator',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'status',
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { horizontally_stretchable = true },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        caption = { const:locale('id'), entity_data.main.unit_number, },
                                    },
                                },
                            },
                            {
                                type = 'frame',
                                style = 'deep_frame_in_shallow_frame',
                                name = 'preview_frame',
                                children = {
                                    {
                                        type = 'entity-preview',
                                        name = 'preview',
                                        style = 'wide_entity_button',
                                        elem_mods = { entity = entity_data.main },
                                    },
                                },
                            },
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                style_mods = {
                                    vertical_align = 'center',
                                },
                                children = {
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { const:locale('operation-mode') },
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                    },
                                    {
                                        type = 'drop-down',
                                        style = 'circuit_condition_comparator_dropdown',
                                        name = 'operation-mode',
                                        handler = {},
                                        items = {
                                            { const:locale('operation-mode-1') },
                                            { const:locale('operation-mode-2') },
                                            { const:locale('operation-mode-3') },
                                            { const:locale('operation-mode-4') },
                                            { const:locale('operation-mode-5') },
                                            { const:locale('operation-mode-6') },
                                        },
                                        selected_index = 3,
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        caption = { const:locale('operation-mode-description-3') },
                                        style_mods = {
                                            left_padding = 8,
                                        },
                                    },
                                },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { 'description.signals' },
                            },
                            {
                                type = 'checkbox',
                                caption = { const:locale('merge-signals') },
                                tooltip = { const:locale('merge-signals-description') },
                                name = 'merge-signals',
                                handler = {},
                                state = false,
                            },
                            {
                                type = 'table',
                                column_count = 2,
                                children = {
                                    -- row 1
                                    {
                                        type = 'checkbox',
                                        caption = { 'color-capital.red' },
                                        name = 'enable-red',
                                        handler = {},
                                        state = true,
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('invert') },
                                        name = 'invert-red',
                                        handler = {},
                                        state = false,
                                    },
                                    -- row 2
                                    {
                                        type = 'checkbox',
                                        caption = { 'color-capital.green' },
                                        name = 'enable-green',
                                        handler = {},
                                        state = true,
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('invert') },
                                        name = 'invert-green',
                                        handler = {},
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'checkbox',
                                caption = { const:locale('unpowered-empty') },
                                tooltip = { const:locale('unpowered-empty-description') },
                                name = 'unpowered-empty',
                                handler = {},
                                state = false,
                            },
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { const:locale('wagon-stacks') },
                                tooltip = { const:locale('wagon-stacks-description') },
                            },
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                children = {
                                    {
                                        type = 'switch',
                                        name = 'use-wagon-stacks',
                                        right_label_caption = { 'gui-constant.on' },
                                        left_label_caption = { 'gui-constant.off' },
                                        handler = {},
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { width = 8 },
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('process-fluid') },
                                        tooltip = { const:locale('process-fluid-description') },
                                        name = 'process-fluid',
                                        handler = {},
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'label',
                                style = 'semibold_label',
                                caption = { const:locale('non-item-signals') },
                                tooltip = { const:locale('non-item-signals-description') },
                            },
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                children = {
                                    {
                                        type = 'radiobutton',
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                        caption = { const:locale('non-item-signals-1') },
                                        tooltip = { const:locale('non-item-signals-description-1') },
                                        name = 'non-item-signals-1',
                                        handler = {},
                                        state = false,
                                    },
                                    {
                                        type = 'radiobutton',
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                        caption = { const:locale('non-item-signals-2') },
                                        tooltip = { const:locale('non-item-signals-description-2') },
                                        name = 'non-item-signals-2',
                                        handler = {},
                                        state = false,
                                    },
                                    {
                                        type = 'radiobutton',
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                        caption = { const:locale('non-item-signals-3') },
                                        tooltip = { const:locale('non-item-signals-description-3') },
                                        name = 'non-item-signals-3',
                                        handler = {},
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'table',
                                column_count = 2,
                                style_mods = {
                                    horizontal_spacing = 24,
                                },
                                children = {
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { 'description.input-signals' },
                                    },
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { 'description.output-signals' },
                                    },
                                    {
                                        type = 'scroll-pane',
                                        style = 'deep_slots_scroll_pane',
                                        direction = 'vertical',
                                        name = 'input-view-pane',
                                        visible = true,
                                        vertical_scroll_policy = 'auto-and-reserve-space',
                                        horizontal_scroll_policy = 'never',
                                        style_mods = {
                                            width = 400,
                                        },
                                        children = {
                                            {
                                                type = 'table',
                                                style = 'filter_slot_table',
                                                name = 'input-signal-view',
                                                column_count = 10,
                                                style_mods = {
                                                    vertical_spacing = 4,
                                                },
                                            },
                                        },
                                    },
                                    {
                                        type = 'scroll-pane',
                                        style = 'deep_slots_scroll_pane',
                                        direction = 'vertical',
                                        name = 'output-view-pane',
                                        visible = true,
                                        vertical_scroll_policy = 'auto-and-reserve-space',
                                        horizontal_scroll_policy = 'never',
                                        style_mods = {
                                            width = 400,
                                        },
                                        children = {
                                            {
                                                type = 'table',
                                                style = 'filter_slot_table',
                                                name = 'output-signal-view',
                                                column_count = 10,
                                                style_mods = {
                                                    vertical_spacing = 4,
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    }
end

----------------------------------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------------------------------

---@param gui framework.gui
---@param entity_data stack_combinator.Data
local function update_gui(gui, entity_data)
end

---@param gui framework.gui
---@param entity_data stack_combinator.Data
local function refresh_gui(gui, entity_data)
    --     render_preview(gui, entity_data)

    for _, pin in pairs { 'input', 'output' } do
        local connections = gui:find_element('connections_' .. pin)
        connections.caption = { 'gui-control-behavior.not-connected' }
        for _, color in pairs { 'red', 'green' } do
            local pin_name = ('combinator_%s_%s'):format(pin, color)

            local wire_connector = entity_data.main.get_wire_connector(defines.wire_connector_id[pin_name], false)
            local connect = false

            local wire_connection = gui:find_element(pin_name)
            if wire_connector then
                for _, connection in pairs(wire_connector.connections) do
                    connect = connect or (connection.origin == defines.wire_origin.player)
                    if connect then break end
                end
            end
            if connect then
                connections.caption = { 'gui-control-behavior.connected-to-network' }
                wire_connection.visible = true
                wire_connection.caption = { ('gui-control-behavior.%s-network-id'):format(color), wire_connector.network_id }
            else
                wire_connection.visible = false
                wire_connection.caption = nil
            end
        end
    end
end

----------------------------------------------------------------------------------------------------
-- UI Callbacks
----------------------------------------------------------------------------------------------------

--- close the UI (button or shortcut key)
---
---@param event EventData.on_gui_click|EventData.on_gui_opened
function Gui.onWindowClosed(event)
    Framework.gui_manager:destroy_gui(event.player_index)
end

----------------------------------------------------------------------------------------------------
-- open gui handler
----------------------------------------------------------------------------------------------------

---@param event EventData.on_gui_opened
function Gui.onGuiOpened(event)
    local player = Player.get(event.player_index)
    if not player then return end

    -- close an eventually open gui
    Framework.gui_manager:destroy_gui(event.player_index)

    local entity = event and event.entity --[[@as LuaEntity]]
    if not entity then
        player.opened = nil
        return
    end

    assert(entity.unit_number)
    local entity_data = This.StackCombinator:getEntity(entity.unit_number)

    if not entity_data then
        log('Data missing for ' ..
            event.entity.name .. ' on ' .. event.entity.surface.name .. ' at ' .. serpent.line(event.entity.position) .. ' refusing to display UI')
        player.opened = nil
        return
    end

    ---@class stack_combinator.GuiContext
    ---@field last_config stack_combinator.Config?
    local gui_state = {
        last_config = nil,
    }

    local gui = Framework.gui_manager:create_gui {
        player_index = event.player_index,
        parent = player.gui.screen,
        ui_tree = Gui.getUi(entity_data),
        context = gui_state,
        update_callback = Gui.guiUpdater,
        entity_id = entity.unit_number
    }

    player.opened = gui.root
end

function Gui.onGhostGuiOpened(event)
    local player = Player.get(event.player_index)
    if not player then return end

    player.opened = nil
end

----------------------------------------------------------------------------------------------------
-- Event ticker
----------------------------------------------------------------------------------------------------

---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return false end

    ---@type stack_combinator.GuiContext
    local context = gui.context

    if not (context.last_config and table.compare(context.last_config, entity_data.config)) then
        update_gui(gui, entity_data)
        context.last_config = tools.copy(entity_data.config)
    end

    -- always update wire state and preview
    refresh_gui(gui, entity_data)

    return true
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function register_events()
    local entity_filter = tools.create_event_entity_matcher('name', const.main_entity_names)
    local ghost_entity_filter = tools.create_event_ghost_entity_matcher('ghost_name', const.main_entity_names)

    -- Gui updates / sync inserters
    Event.on_event(defines.events.on_gui_opened, Gui.onGuiOpened, entity_filter)
    Event.on_event(defines.events.on_gui_opened, Gui.onGhostGuiOpened, ghost_entity_filter)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_load()
    register_events()
end

local function on_init()
    register_events()
end

Event.on_init(on_init)
Event.on_load(on_load)
