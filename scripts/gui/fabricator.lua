local utils = require("scripts/utils")
local gui_utils = require("scripts/gui/gui_utils")

---comment
---@param player LuaPlayer
function build_main_gui(player)
    local main_frame = player.gui.screen.add{
        type = "frame",
        name = "qf_fabricator_frame",
        direction = "vertical"
    }
    if storage.player_gui[player.index].fabricator_gui_position then
        main_frame.location = storage.player_gui[player.index].fabricator_gui_position
    else
        main_frame.auto_center = true
    end

    local main_content_flow = main_frame.add{
        type = "flow",
        name = "main_content_flow",
        direction = "horizontal"
    }
    main_content_flow.style.horizontal_spacing = QF_GUI.default.padding

    local recipe_flow = main_content_flow.add{
        type = "flow",
        name = "recipe_flow",
        direction = "vertical"
    }

    local storage_flow = main_content_flow.add{
        type = "flow",
        name = "storage_flow",
        direction = "vertical"
    }
    storage_flow.style.size = {width = QF_GUI.storage_frame.width, height = QF_GUI.storage_frame.height}

    -- Titlebar
    build_titlebar(player, recipe_flow)

    -- Recipe GUI
    gui_utils.get_filtered_data(player, "")

    build_main_recipe_gui(player, recipe_flow)

    if storage.player_gui[player.index].show_storage and not player.surface.platform then
        build_main_storage_gui(player, storage_flow)
        storage_flow.visible = true
    else
        storage_flow.visible = false
    end

    player.opened = main_frame

end


---comment
---@param player LuaPlayer
---@param titlebar_flow_parent LuaGuiElement
function build_titlebar(player, titlebar_flow_parent)
    local titlebar_flow = titlebar_flow_parent.add{
        type = "flow",
        name = "titlebar_flow",
        direction = "horizontal"
    }

    
    titlebar_flow.style.height = QF_GUI.titlebar.height
    local titlebar_label = titlebar_flow.add{
        type = "label",
        style = "frame_title"
    }
    
    local draggable_space = titlebar_flow.add{
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true
    }
    draggable_space.style.horizontally_stretchable = true
    draggable_space.style.height = QF_GUI.dragspace.height
    titlebar_flow.drag_target = player.gui.screen.qf_fabricator_frame

    titlebar_flow.add{
        type = "button",
        name = "filter_reset_button",
        caption = {"qf-inventory.reset-filter"}
    }
    local searchbar = titlebar_flow.add{
        type = "textfield",
        name = "searchbar",
        clear_and_focus_on_right_click = true
    }
    searchbar.style.width = QF_GUI.searchbar.width
    local toggle_storage_button = titlebar_flow.add{
        type = "sprite-button",
        name = "toggle_storage_button",
        sprite = "qf-toggle-storage-icon-white",
        hovered_sprite = "qf-toggle-storage-icon",
        clicked_sprite = "qf-toggle-storage-icon",
        style = "frame_action_button",
    }
    toggle_storage_button.toggled = storage.player_gui[player.index].show_storage
    toggle_storage_button.auto_toggle = true


    local surface = player.surface
    local titlebar_caption
    local toggle_storage_tooltip
    if surface.platform then
        titlebar_caption = {"", {"qf-inventory.recipe-frame-title-ghost"}, ": ", {"surface-name.space-platform"}}
        toggle_storage_tooltip = {"qf-inventory.toggle-storage-button-tooltip-platform"}
        toggle_storage_button.enabled = false
    else
        titlebar_caption = {"", {"qf-inventory.recipe-frame-title"}, ": ", surface.localised_name or surface.planet.prototype.localised_name}
        toggle_storage_tooltip = {"qf-inventory.toggle-storage-button-tooltip"}
    end

    toggle_storage_button.tooltip = toggle_storage_tooltip
    titlebar_label.caption = titlebar_caption

    -- Options buttons
    titlebar_flow.add{
        type = "sprite-button",
        name = "qf_options_button",
        style = "frame_action_button",
        sprite = "qf-setting-icon-white",
        hovered_sprite = "qf-setting-icon",
        clicked_sprite = "qf-setting-icon",
        tooltip = {"qf-inventory.options-button"}
    }
    titlebar_flow.add{
        type = "sprite-button",
        name = "qf_close_button",
        style = "close_button",
        sprite="utility/close",
        hovered_sprite="utility/close_black",
        clicked_sprite="utility/close_black"
    }
end


---comment
---@param player LuaPlayer
---@param recipe_frame_parent LuaGuiElement
function build_main_recipe_gui(player, recipe_frame_parent)

    if recipe_frame_parent.recipe_flow then recipe_frame_parent.recipe_flow.destroy() end

    local recipe_frame = recipe_frame_parent.add{
        type = "frame",
        name = "recipe_flow",
        direction = "vertical",
        style="inside_shallow_frame"
    }
    recipe_frame.style.size = {width = QF_GUI.recipe_frame.width, height = QF_GUI.recipe_frame.height}

    if not storage.item_group_order then process_item_group_order() end

    local size = Filtered_data[player.index].size
    local filter = Filtered_data[player.index].content

    if filter and size and size > 0 then

        local group_table_rows = math.ceil(size / QF_GUI.recipe_frame.item_group_table.max_number_of_columns)
        local group_table_columns = math.min(size, QF_GUI.recipe_frame.item_group_table.max_number_of_columns)

        local extra_frame = recipe_frame.add{
            type = "frame",
            direction = "vertical"
        }
        extra_frame.style.size = {width = QF_GUI.recipe_frame.item_group_table.width + 8, height = group_table_rows * QF_GUI.recipe_frame.item_group_table.button_height + 10}
        extra_frame.style.top_padding = 0
        extra_frame.style.bottom_padding = 0
        extra_frame.style.left_padding = 0 --4
        extra_frame.style.right_padding = 0 --4

        local group_table = extra_frame.add{
            type = "table",
            name = "group_table",
            column_count = group_table_columns,
            style = "qf_item_group_table"
        }
        group_table.style.size = {width = QF_GUI.recipe_frame.item_group_table.width, height = group_table_rows * QF_GUI.recipe_frame.item_group_table.button_height + 10}
        group_table.style.horizontal_spacing = 0
        group_table.style.vertical_spacing = 0
        extra_frame.style.right_padding = 0
    
        
        local fallback
        for _, group in pairs(storage.item_group_order) do
            if filter[group.name] then
                if not fallback then fallback = group.name end
                local group_button = group_table.add{
                    type = "sprite-button",
                    name = group.name .. "_button",
                    sprite = "item-group/" .. group.name,
                    style = "menu_button"
                }
                group_button.style.height = QF_GUI.recipe_frame.item_group_table.button_height
                group_button.style.width = QF_GUI.recipe_frame.item_group_table.width / group_table_columns
                group_button.style.horizontally_stretchable = true
                group_button.tags = {button_type = "item_group_selector", group_name = group.name}
                group_button.tooltip = {"item-group-name." .. group.name}
            end
        end
        local current_selection = storage.player_gui[player.index].item_group_selection
        if group_table[current_selection .. "_button"] then
            group_table[current_selection .. "_button"].toggled = true
        else
            group_table[fallback .. "_button"].toggled = true
            storage.player_gui[player.index].item_group_selection = fallback
        end

        build_main_recipe_item_list_gui(player, recipe_frame)
    else
        local error_frame = recipe_frame.add{
            type = "frame",
            name = "error_frame",
            direction = "vertical",
            style = "inside_deep_frame"
        }
        error_frame.style.width = QF_GUI.recipe_frame.width
        error_frame.style.height = QF_GUI.recipe_frame.height
        error_frame.style.vertically_stretchable = true
        error_frame.style.horizontally_stretchable = true
        local error_label = error_frame.add{
            type = "label",
            name = "error_label",
            caption = {"qf-inventory.no-recipes-found"}
        }
        error_label.style.horizontal_align = "center"
        error_label.style.vertical_align = "center"
        error_label.style.font_color = {1.0, 0.0, 0.0}
        error_label.style.font = "default-bold"
    end

end

---comment
---@param player LuaPlayer
---@param recipe_frame LuaGuiElement
function build_main_recipe_item_list_gui(player, recipe_frame)

    if recipe_frame.recipe_item_scroll_pane then recipe_frame.recipe_item_scroll_pane.destroy() end

    local recipe_item_scroll_pane = recipe_frame.add{
        type = "scroll-pane",
        name = "recipe_item_scroll_pane",
        direction = "vertical"
    }
    recipe_item_scroll_pane.style.width = QF_GUI.recipe_frame.width
    recipe_item_scroll_pane.style.natural_height = QF_GUI.recipe_frame.height - (75 * Filtered_data[player.index].size) - 10
    recipe_item_scroll_pane.style.vertically_stretchable = true
    recipe_item_scroll_pane.style.vertically_squashable = true
    recipe_item_scroll_pane.style.horizontally_squashable = true
    recipe_item_scroll_pane.style.horizontally_stretchable = true
    recipe_item_scroll_pane.vertical_scroll_policy = "always"
    recipe_item_scroll_pane.horizontal_scroll_policy = "never"

    local recipe_item_frame = recipe_item_scroll_pane.add{
        type = "frame",
        name = "recipe_item_list",
        style = "qf_item_slots",
        direction = "vertical"
    }
    recipe_item_frame.style.vertically_stretchable = true
    recipe_item_frame.style.vertically_squashable = true
    recipe_item_frame.style.horizontally_squashable = true
    recipe_item_frame.style.horizontally_stretchable = true
    recipe_item_frame.style.natural_height = QF_GUI.recipe_frame.height - (75 * Filtered_data[player.index].size) - 10
    --recipe_item_frame.style.vertical_spacing = 4
    recipe_item_frame.style.margin = 10

    local current_selection = storage.player_gui[player.index].item_group_selection
    local filter = Filtered_data[player.index].content

    local y_index = 0
    for _, subgroup in pairs(storage.item_subgroup_order[current_selection]) do
        if filter and filter[current_selection] and filter[current_selection][subgroup.name] then
            y_index = y_index + 1
            local subgroup_table = recipe_item_frame.add{
                type = "table",
                column_count = QF_GUI.recipe_frame.item_group_table.subgroup_table_columns
            }
            subgroup_table.style.vertical_spacing = 0
            subgroup_table.style.horizontal_spacing = 0
            local x_index = 0
            for _, item in pairs(filter[current_selection][subgroup.name]) do
                x_index = x_index + 1
                if x_index > QF_GUI.recipe_frame.item_group_table.subgroup_table_columns then
                    x_index = 1
                    y_index = y_index + 1
                end
                local style = "slot_button"
                if Craft_data[player.index][item.recipe_name] == 0 then
                    if storage.player_gui[player.index].options.mark_red then
                        style = "flib_slot_button_red"
                    end
                end
                local item_button = subgroup_table.add{
                    type = "sprite-button",
                    sprite = "item/" .. item.item_name,
                    style = style
                }
                item_button.style.padding = 0


                if storage.player_gui[player.index].options.calculate_numbers or storage.player_gui[player.index].options.mark_red then
                    if not Craft_data[player.index][surface_index] or not Craft_data[player.index][surface_index][recipe_name] or not Craft_data[player.index][surface_index][recipe_name][quality_name] then
                        gui_utils.get_craft_data(player_index, player_inventory, surface_index, quality_name, recipe_name)
                    end
                    if Craft_data[player.index][surface_index][recipe_name][quality_name] == 0 then
                        if storage.player_gui[player.index].options.mark_red then
                            item_button.style = "flib_slot_button_red"
                        end
                    end
                    if storage.player_gui[player.index].options.calculate_numbers then
                        item_button.number = Craft_data[player.index][surface_index][recipe_name][quality_name]
                    end
                end
                item_button.raise_hover_events = true
                item_button.tags = {
                    button_type = "take_out_ghost",
                    item_name = item.item_name,
                    hover_type = "recipe",
                    recipe_name = item.recipe_name,
                    index = {x = x_index, y = y_index}
                }
            end
        end
    end

end




