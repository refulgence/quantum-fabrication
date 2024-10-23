---comment
---@param player LuaPlayer
---@param storage_flow_parent LuaGuiElement
function build_main_storage_gui(player, storage_flow_parent)

    if storage_flow_parent.storage_flow then storage_flow_parent.storage_flow.destroy() end

    local storage_flow = storage_flow_parent.add{
        type = "flow",
        name = "storage_flow",
        direction = "vertical"
    }

    local storage_titlebar = storage_flow.add{
        type = "flow",
        name = "storage_titlebar",
        direction = "horizontal"
    }
    storage_titlebar.style.height = QF_GUI.titlebar.height
    storage_titlebar.add{
        type = "label",
        caption = {"qf-inventory.storage-frame-title"},
        style = "frame_title"
    }
    local draggable_space = storage_titlebar.add{
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true
    }
    draggable_space.style.horizontally_stretchable = true
    draggable_space.style.height = QF_GUI.dragspace.height
    storage_titlebar.drag_target = player.gui.screen.qf_fabricator_frame

    local storage_frame = storage_flow.add{type = "frame", name = "storage_frame", direction = "vertical", style="inside_shallow_frame"}
    storage_frame.style.size = {width = QF_GUI.storage_frame.width, height = QF_GUI.storage_frame.height}
    storage_frame.style.top_padding = QF_GUI.default.padding

    local tabbed_pane = storage_frame.add{type = "tabbed-pane", name = "tabbed_pane"}
    local materials_tab = tabbed_pane.add{type = "tab", name = "materials_tab", caption = "Materials"}
    local placeables_tab = tabbed_pane.add{type = "tab", name = "placeables_tab", caption = "Placeables"}
    local others_tab = tabbed_pane.add{type = "tab", name = "others_tab", caption = "Others"}

    local materials_tab_content = build_main_materials_tab(player, tabbed_pane)
    local placeables_tab_content = build_main_placeables_tab(player, tabbed_pane)
    local others_tab_content = build_main_others_tab(player, tabbed_pane)

    tabbed_pane.add_tab(materials_tab, materials_tab_content)
    tabbed_pane.add_tab(placeables_tab, placeables_tab_content)
    tabbed_pane.add_tab(others_tab, others_tab_content)

    tabbed_pane.selected_tab_index = storage.player_gui[player.index].selected_tab_index

end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_main_materials_tab(player, tabbed_pane)
    local materials_tab_content = tabbed_pane.add{type = "frame", name = "materials_tab_content", direction = "vertical", style="inside_deep_frame"}
    materials_tab_content.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}

    local storage_scroll_pane = materials_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local sorted_list = Sorted_lists["Materials"]
    for _, item in pairs(sorted_list) do
        if Filtered_data[player.index].materials[item.name] then
            local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}
    
            local item_name_caption
            if item.type == "item" then
                item_name_caption = {"", "[item="..item.name.."] ", prototypes.item[item.name].localised_name}
            else
                item_name_caption = {"", "[fluid="..item.name.."] ", prototypes.fluid[item.name].localised_name}
            end
    
            local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = {type=item.type, name = item.name}}
            item_name.style.font = "default-bold"
            item_name.style.horizontal_align = "left"
            item_name.style.width = QF_GUI.tabbed_pane.name_width
    
            local item_count = item_entry.add{type="label", caption = "x" .. item.count}
            item_count.style.horizontal_align = "right"
            item_count.style.width = QF_GUI.tabbed_pane.count_width
    
            local filler_space = item_entry.add{type="empty-widget"}
            filler_space.style.horizontally_stretchable = true
    
            -- what is this line? find out why it happens and why it's needed, because I don't think it should be needed
            if not storage.ingredient_filter[item.name] then storage.ingredient_filter[item.name] = {count = 0, recipes = {}} end
            local item_recipe_usage_number = storage.ingredient_filter[item.name].count
            if item_recipe_usage_number > 0 then
                local item_recipe_usage_caption = {"qf-inventory.recipe-usage", item_recipe_usage_number}
                local item_recipe_usage = item_entry.add{type="label", caption = item_recipe_usage_caption}
                item_recipe_usage.style.horizontal_align = "right"
                item_recipe_usage.style.width = QF_GUI.tabbed_pane.recipe_usage_width
        
                local item_button = item_entry.add{type = "sprite-button", style = "frame_action_button", sprite="utility/search"}
                item_button.style.horizontal_align = "right"
                item_button.style.size = QF_GUI.tabbed_pane.button_size
                item_button.tags = {button_type = "recipe_usage_search", item_name = item.name}
            end
        end
    end
    return materials_tab_content
end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_main_placeables_tab(player, tabbed_pane)
    local placeables_tab_content = tabbed_pane.add{type = "frame", name = "placeables_tab_content", direction = "vertical", style="inside_deep_frame"}
    placeables_tab_content.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}

    local storage_scroll_pane = placeables_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local sorted_list = Sorted_lists["Placeables"]
    for _, item in pairs(sorted_list) do
        local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}

        local item_name_caption
        local take_out_caption
        local button_sprite
        local button_tags
        if is_module(item.name) then
            item_name_caption = {"", "[item="..item.name.."] ", prototypes.item[item.name].localised_name}
            take_out_caption = {"qf-inventory.take-out-item"}
        else
            item_name_caption = {"", "[item="..item.name.."] ", prototypes.item[item.name].localised_name}
            take_out_caption = {"qf-inventory.take-out-ghost"}
            button_sprite = "qf-vanilla-ghost-entity-icon"
            button_tags = {button_type = "take_out_ghost", item_name = item.name}
        end

        local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = {type="item", name = item.name}}
        item_name.style.font = "default-bold"
        item_name.style.horizontal_align = "left"
        item_name.style.width = QF_GUI.tabbed_pane.name_width

        local item_count = item_entry.add{type="label", caption = "x" .. item.count}
        item_count.style.horizontal_align = "right"
        item_count.style.width = QF_GUI.tabbed_pane.count_width

        local filler_space = item_entry.add{type="empty-widget"}
        filler_space.style.horizontally_stretchable = true

        if not is_module(item.name) then
            local item_take_out_label = item_entry.add{type="label", caption = take_out_caption}
            item_take_out_label.style.horizontal_align = "right"
            item_take_out_label.style.width = QF_GUI.tabbed_pane.recipe_usage_width
    
            local item_take_out_button = item_entry.add{type = "sprite-button", style = "frame_action_button", sprite = button_sprite}
            item_take_out_button.style.horizontal_align = "right"
            item_take_out_button.style.size = QF_GUI.tabbed_pane.button_size
            item_take_out_button.tags = button_tags
        else
            local item_take_out_label = item_entry.add{type="label", caption = "Modules are automatically inserted when requested"}
            item_take_out_label.style.horizontal_align = "right"
            item_take_out_label.style.width = QF_GUI.tabbed_pane.recipe_usage_width
        end
    end
    return placeables_tab_content
end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_main_others_tab(player, tabbed_pane)
    local others_tab_content = tabbed_pane.add{type = "frame", name = "others_tab_content", direction = "vertical", style="inside_deep_frame"}
    others_tab_content.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}

    local storage_scroll_pane = others_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = {width = QF_GUI.tabbed_pane.width, height = QF_GUI.tabbed_pane.height}
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local sorted_list = Sorted_lists["Others"]

    local others_tab_label_1 = storage_scroll_pane.add{type="label", caption = {"qf-inventory.others-tab-caption-1"}}
    others_tab_label_1.style.font = "default-bold"
    local others_tab_label_2 = storage_scroll_pane.add{type="label", caption = {"qf-inventory.others-tab-caption-2"}}
    others_tab_label_2.style.font = "default-bold"

    for _, item in pairs(sorted_list) do
        local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}
        local item_name_caption
        local elem_tooltip
        if item.type == "item" then
            item_name_caption = {"", "[item="..item.name.."] ", prototypes.item[item.name].localised_name}
            elem_tooltip = {type="item", name = item.name}
        else
            item_name_caption = {"", "[fluid="..item.name.."] ", prototypes.fluid[item.name].localised_name}
            elem_tooltip = {type="fluid", name = item.name}
        end
        
        local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = elem_tooltip}
        item_name.style.font = "default-bold"
        item_name.style.horizontal_align = "left"
        item_name.style.width = QF_GUI.tabbed_pane.name_width

        local item_count = item_entry.add{type="label", caption = "x" .. item.count}
        item_count.style.horizontal_align = "right"
        item_count.style.width = QF_GUI.tabbed_pane.count_width

        local filler_space = item_entry.add{type="empty-widget"}
        filler_space.style.horizontally_stretchable = true
    end
    return others_tab_content
end