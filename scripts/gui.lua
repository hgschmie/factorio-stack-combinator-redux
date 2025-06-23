------------------------------------------------------------------------
-- GUI code
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')
local table = require('stdlib.utils.table')

local Matchers = require('framework.matchers')
local tools = require('framework.tools')

local signal_converter = require('framework.signal_converter')

local const = require('lib.constants')

---@class stack_combinator.Gui
---@field NAME string
local Gui = {
    NAME = 'combinator-gui',
}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

--- Provides all the events used by the GUI and their mappings to functions. This must be outside the
--- GUI definition as it can not be serialized into storage.
---@return framework.gui_manager.event_definition
local function get_gui_event_definition()
    return {
        events = {
            onWindowClosed = Gui.onWindowClosed,
            onModeChanged = Gui.onModeChanged,
            onMergeInput = Gui.onMergeInput,
            onEnableSignal = Gui.onEnableSignal,
            onInvertSignal = Gui.onInvertSignal,
            onEmptyUnpowered = Gui.onEmptyUnpowered,
            onUseWagonStacks = Gui.onUseWagonStacks,
            onProcessFluid = Gui.onProcessFluid,
            onNonItemSignals = Gui.onNonItemSignals,
        },
        callback = Gui.guiUpdater,
    }
end

--- Returns the definition of the GUI. All events must be mapped onto constants from the gui_events array.
---@param gui framework.gui
---@return framework.gui.element_definition ui
function Gui.getUi(gui)
    local gui_events = gui.gui_events

    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    assert(entity_data)

    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = gui_events.onWindowClosed },
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
                        handler = { [defines.events.on_gui_click] = gui_events.onWindowClosed },
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
                                        name = 'status-lamp',
                                        style = 'framework_indicator',
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'status-label',
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
                                        handler = { [defines.events.on_gui_selection_state_changed] = gui_events.onModeChanged },
                                        items = {
                                            [const.defines.operations.multiply] = { const:locale('operation-mode-1') },
                                            [const.defines.operations.divide_ceil] = { const:locale('operation-mode-2') },
                                            [const.defines.operations.divide_floor] = { const:locale('operation-mode-3') },
                                            [const.defines.operations.round] = { const:locale('operation-mode-4') },
                                            [const.defines.operations.ceil] = { const:locale('operation-mode-5') },
                                            [const.defines.operations.floor] = { const:locale('operation-mode-6') },
                                        },
                                    },
                                    {
                                        type = 'label',
                                        style = 'label',
                                        name = 'operation-mode-description',
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
                                caption = { const:locale('merge-inputs') },
                                tooltip = { const:locale('merge-inputs-description') },
                                name = 'merge-inputs',
                                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onMergeInput },
                                state = false,
                            },
                            {
                                type = 'table',
                                column_count = 3,
                                children = {
                                    -- row 1
                                    {
                                        type = 'checkbox',
                                        caption = { 'gui-network-selector.red-label' },
                                        name = 'enable-signals-1',
                                        elem_tags = {
                                            wire_connector_id = defines.wire_connector_id.circuit_red,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onEnableSignal },
                                        state = true,
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { width = 8 },
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('invert-signals') },
                                        name = 'invert-signals-1',
                                        elem_tags = {
                                            wire_connector_id = defines.wire_connector_id.circuit_red,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onInvertSignal },
                                        state = false,
                                    },
                                    -- row 2
                                    {
                                        type = 'checkbox',
                                        caption = { 'gui-network-selector.green-label' },
                                        name = 'enable-signals-2',
                                        elem_tags = {
                                            wire_connector_id = defines.wire_connector_id.circuit_green,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onEnableSignal },
                                        state = true,
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = { width = 8 },
                                    },
                                    {
                                        type = 'checkbox',
                                        caption = { const:locale('invert-signals') },
                                        name = 'invert-signals-2',
                                        elem_tags = {
                                            wire_connector_id = defines.wire_connector_id.circuit_green,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onInvertSignal },
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'checkbox',
                                caption = { const:locale('empty-unpowered') },
                                tooltip = { const:locale('empty-unpowered-description') },
                                name = 'empty-unpowered',
                                handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onEmptyUnpowered },
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
                                        left_label_caption = { 'gui-constant.off' },
                                        right_label_caption = { 'gui-constant.on' },
                                        handler = { [defines.events.on_gui_switch_state_changed] = gui_events.onUseWagonStacks },
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
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onProcessFluid },
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
                                        elem_tags = {
                                            non_item_signal = const.defines.non_item_signal_type.pass,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onNonItemSignals },
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
                                        elem_tags = {
                                            non_item_signal = const.defines.non_item_signal_type.invert,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onNonItemSignals },
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
                                        elem_tags = {
                                            non_item_signal = const.defines.non_item_signal_type.drop,
                                        },
                                        handler = { [defines.events.on_gui_checked_state_changed] = gui_events.onNonItemSignals },
                                        state = false,
                                    },
                                },
                            },
                            {
                                type = 'table',
                                column_count = 2,
                                vertical_centering = false,
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

local color_map = {
    [defines.wire_connector_id.circuit_red] = 'red',
    [defines.wire_connector_id.circuit_green] = 'green',
}

local on_off_values = {
    left = false,
    right = true,
}

local values_on_off = table.invert(on_off_values)

---@param gui_element LuaGuiElement?
---@param entity_data stack_combinator.Data?
local function render_network_signals(gui_element, entity_data)
    if not entity_data then return end

    assert(gui_element)
    gui_element.clear()

    for _, connector_id in pairs { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green } do
        local signals = entity_data.main.get_signals(connector_id)
        if signals then
            local signal_count = 0
            for _, signal in ipairs(signals) do
                local button = gui_element.add {
                    type = 'sprite-button',
                    sprite = signal_converter:signal_to_sprite_name(signal),
                    number = signal.count,
                    quality = signal.signal.quality,
                    style = color_map[connector_id] .. '_circuit_network_content_slot',
                    tooltip = signal_converter:signal_to_prototype(signal).localised_name,
                    elem_tooltip = signal_converter:signal_to_elem_id(signal),
                    enabled = true,
                }
                signal_count = signal_count + 1
            end
            while (signal_count % 10) > 0 do
                gui_element.add {
                    type = 'sprite',
                    enabled = true,
                }
                signal_count = signal_count + 1
            end
        end
    end
end

---@param gui_element LuaGuiElement?
---@param entity_data stack_combinator.Data?
local function render_output_signals(gui_element, entity_data)
    if not entity_data then return end

    assert(gui_element)
    gui_element.clear()

    local output = entity_data.output.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior ]]
    assert(output)

    assert(output.sections_count == 1)
    local section = output.sections[1]
    assert(section.type == defines.logistic_section_type.manual)

    local filters = section.filters

    if not (filters) then return end

    for _, filter in pairs(filters) do
        if filter.value.name then
            local button = gui_element.add {
                type = 'sprite-button',
                style = 'compact_slot',
                number = filter.min,
                quality = filter.value.quality,
                sprite = signal_converter:logistic_filter_to_sprite_name(filter),
                tooltip = signal_converter:logistic_filter_to_prototype(filter).localised_name,
                elem_tooltip = signal_converter:logistic_filter_to_elem_id(filter),
                enabled = true,
            }
        end
    end
end

---@param gui framework.gui
---@param connection_state table<defines.wire_connector_id, boolean> Network state, as returned by refresh_gui
---@param entity_data stack_combinator.Data
local function update_gui(gui, connection_state, entity_data)
    local config = entity_data.config

    local operation_mode = gui:find_element('operation-mode')
    operation_mode.selected_index = config.op
    local operation_mode_description = gui:find_element('operation-mode-description')
    operation_mode_description.caption = { const:locale('operation-mode-description-' .. config.op) }

    local merge_inputs = gui:find_element('merge-inputs')
    merge_inputs.state = config.merge_inputs

    -- turn enabled and inverted button for the networks on and off and handle tooltips
    for _, connection_id in pairs { defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green } do
        local network_settings = config.network_settings[connection_id]
        local checkbox = gui:find_element('enable-signals-' .. connection_id)

        local network_enabled = connection_state[connection_id] or false
        checkbox.state = network_settings.enable
        checkbox.enabled = network_enabled and not config.merge_inputs
        checkbox.tooltip = {
            'gui-network-selector.' .. (config.merge_inputs and 'not-relevant'
                or (color_map[connection_id] .. (network_enabled and '-connected' or '-not-connected')))
        }

        local invert = gui:find_element('invert-signals-' .. connection_id)
        local enabled = network_enabled and (network_settings.enable or config.merge_inputs)
        invert.state = network_settings.invert
        invert.enabled = enabled
        invert.tooltip = enabled and { const:locale('invert-signals-description-' .. connection_id) } or nil
    end

    local empty_unpowered = gui:find_element('empty-unpowered')
    empty_unpowered.state = config.empty_unpowered

    local use_wagon_stacks = gui:find_element('use-wagon-stacks')
    use_wagon_stacks.switch_state = values_on_off[config.use_wagon_stacks]

    local process_fluid = gui:find_element('process-fluid')
    process_fluid.state = config.process_fluids or false
    process_fluid.enabled = config.use_wagon_stacks

    for _, value in pairs(const.defines.non_item_signal_type) do
        local radio_button = gui:find_element('non-item-signals-' .. tostring(value))
        radio_button.state = config.non_item_signals == value
    end
end

---@param gui framework.gui
---@param entity_data stack_combinator.Data
---@return table<defines.wire_connector_id, boolean> connection_state
local function refresh_gui(gui, entity_data)
    local entity_status = entity_data.main.status or defines.entity_status.working

    local lamp = gui:find_element('status-lamp')
    lamp.sprite = tools.STATUS_SPRITES[entity_status]

    local status = gui:find_element('status-label')
    status.caption = { tools.STATUS_NAMES[entity_status] }

    -- render input signals
    local input_signals = gui:find_element('input-signal-view')
    render_network_signals(input_signals, entity_data)

    -- render output signals
    local output_signals = gui:find_element('output-signal-view')
    render_output_signals(output_signals, entity_data)

    local  connection_state = {}

    -- render network ids for Input/Output network header
    for _, pin in pairs { 'input', 'output' } do
        local connections = gui:find_element('connections_' .. pin)
        connections.caption = { 'gui-control-behavior.not-connected' }
        for _, color in pairs { 'red', 'green' } do
            local pin_name = ('combinator_%s_%s'):format(pin, color)

            local connector_id = defines.wire_connector_id[pin_name]
            local wire_connector = entity_data.main.get_wire_connector(connector_id, false)
            local connect = false

            local wire_connection = gui:find_element(pin_name)
            wire_connection.caption = nil

            if wire_connector then
                for _, connection in pairs(wire_connector.connections) do
                    connect = connect or (connection.origin == defines.wire_origin.player)
                    if connect then break end
                end
            end

            connection_state[connector_id] = connect
            wire_connection.visible = connect
            if connect then
                connections.caption = { 'gui-control-behavior.connected-to-network' }
                wire_connection.caption = { ('gui-control-behavior.%s-network-id'):format(color), wire_connector.network_id }
            end
        end
    end
    return connection_state
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

---@param event EventData.on_gui_selection_state_changed
---@param gui framework.gui
function Gui.onModeChanged(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    entity_data.config.op = event.element.selected_index --[[@as stack_combinator.operations ]]
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onMergeInput(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    -- Update the merge input configuration based on the checkbox state
    entity_data.config.merge_inputs = event.element.state
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onEnableSignal(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    local wire_connector_id = event.element.tags and event.element.tags['wire_connector_id']
    if not wire_connector_id then return end

    entity_data.config.network_settings[wire_connector_id].enable = event.element.state
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onInvertSignal(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    local wire_connector_id = event.element.tags and event.element.tags['wire_connector_id']
    if not wire_connector_id then return end

    entity_data.config.network_settings[wire_connector_id].invert = event.element.state
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onEmptyUnpowered(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    entity_data.config.empty_unpowered = event.element.state
end

---@param event EventData.on_gui_switch_state_changed
---@param gui framework.gui
function Gui.onUseWagonStacks(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    entity_data.config.use_wagon_stacks = on_off_values[event.element.switch_state]
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onProcessFluid(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    entity_data.config.process_fluids = event.element.state
end

---@param event EventData.on_gui_checked_state_changed
---@param gui framework.gui
function Gui.onNonItemSignals(event, gui)
    local entity_data = This.StackCombinator:getEntity(gui.entity_id)
    if not entity_data then return end

    local non_item_signal = event.element.tags and event.element.tags['non_item_signal']
    if not non_item_signal then return end

    entity_data.config.non_item_signals = non_item_signal
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
    ---@field last_connection_state table<defines.wire_connector_id, boolean>?
    local gui_state = {
        last_config = nil,
        last_connection_state = nil,
    }

    local gui = Framework.gui_manager:create_gui {
        type = Gui.NAME,
        player_index = event.player_index,
        parent = player.gui.screen,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
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

    -- always update wire state and preview
    local connection_state = refresh_gui(gui, entity_data)

    local refresh_config = not (context.last_config and table.compare(context.last_config, entity_data.config))
    local refresh_state = not (context.last_connection_state and table.compare(context.last_connection_state, connection_state))

    if refresh_config or refresh_state then
        update_gui(gui, connection_state, entity_data)
    end

    if refresh_config then
        context.last_config = tools.copy(entity_data.config)
    end

    if refresh_state then
        context.last_connection_state = connection_state
    end

    return true
end

--------------------------------------------------------------------------------
-- event registration
--------------------------------------------------------------------------------

local function init_gui()
    Framework.gui_manager:register_gui_type(Gui.NAME, get_gui_event_definition())

    local match_main_entity = Matchers:matchEventEntityName(const.stack_combinator_name)
    local match_ghost_main_entity = Matchers:matchEventEntityGhostName(const.stack_combinator_name)

    -- Gui updates / sync inserters
    Event.on_event(defines.events.on_gui_opened, Gui.onGuiOpened, match_main_entity)
    Event.on_event(defines.events.on_gui_opened, Gui.onGhostGuiOpened, match_ghost_main_entity)
end

Event.on_init(init_gui)
Event.on_load(init_gui)
