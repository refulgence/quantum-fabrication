---comment
---@param player LuaPlayer
function toggle_fabricator_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_inventory_frame
    local options_frame = player.gui.screen.qf_fabricator_options_frame
    if Research_finished then post_research_recheck() Research_finished = false end
    if main_frame == nil then
        build_fabricator_gui(player)
    else
        main_frame.destroy()
        if options_frame then options_frame.destroy() end
    end
end

---comment
---@param player LuaPlayer
function toggle_options_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_options_frame
    if main_frame == nil then
        build_options_gui(player)
    else
        main_frame.destroy()
    end
end


OPTIONS_FRAME = {}
OPTIONS_FRAME.width = 800
OPTIONS_FRAME.duplicate_size = {300, 300}


function build_options_gui(player)
    local main_frame = player.gui.screen.add{type = "frame", name = "qf_fabricator_options_frame", direction = "vertical"}
    main_frame.style.width = OPTIONS_FRAME.width
    main_frame.auto_center = true

    -- Titlebar
    local titlebar = main_frame.add{type = "flow", name = "titlebar", direction = "horizontal"}
    titlebar.add{type = "label", caption = {"qf-options.options-title"}, style = "frame_title"}
    titlebar.add{type="empty-widget", name="dragspace_filler", style="draggable_space", ignored_by_interaction=true}
    titlebar.dragspace_filler.style.height = DRAGSPACE_FILLER_HEIGHT
    titlebar.dragspace_filler.style.horizontally_stretchable = true
    titlebar.drag_target = main_frame
    titlebar.add{type = "sprite-button", name = "qf_options_close_button", style = "close_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black"}

    -- Main content
    local main_content = main_frame.add{type = "frame", name = "main_content", direction = "horizontal", style="inside_shallow_frame_with_padding"}
    main_content.style.width = OPTIONS_FRAME.width - 24

    local general_flow = main_content.add{type = "flow", name = "general_flow", direction = "vertical"}
    general_flow.style.width = (OPTIONS_FRAME.width - 24) / 2 - 24
    general_flow.style.right_padding = 8

    main_content.add{type = "line", direction = "vertical"}

    local duplicate_flow = main_content.add{type = "flow", name = "duplicate_flow", direction = "vertical"}
    duplicate_flow.style.width = (OPTIONS_FRAME.width - 24) / 2 - 12
    duplicate_flow.style.left_padding = 8

    -- General section 
    local general_section_title = general_flow.add{type = "label", caption = {"qf-options.pref-title"}}
    general_section_title.style.font = "heading-3"

    local calc_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    calc_option_flow.add{type = "label", caption = {"qf-options.pref-calculate-craftable-numbers"}, tooltip = {"qf-options.pref-calculate-craftable-numbers-tooltip"}}
    calc_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    calc_option_flow.add{type = "checkbox", name = "qf_calculate_craftable_numbers", state = global.player_gui[player.index].options.calculate_numbers}

    general_flow.add{type = "line", direction = "horizontal"}

    local mark_red_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    mark_red_option_flow.add{type = "label", caption = {"qf-options.pref-mark-noncraftables"}, tooltip = {"qf-options.pref-mark-noncraftables-tooltip"}}
    mark_red_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    mark_red_option_flow.add{type = "checkbox", name = "qf_mark_red", state = global.player_gui[player.index].options.mark_red}

    general_flow.add{type = "line", direction = "horizontal"}

    local sort_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    sort_option_flow.add{type = "label", caption = {"qf-options.pref-sorting"}}
    sort_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    local drop_down = sort_option_flow.add{type = "drop-down", name = "qf_sort_by", items = {{"qf-options.pref-sorting-abc"}, {"qf-options.pref-sorting-available"}}, selected_index = global.player_gui[player.index].options.sort_by}
    drop_down.style.width = 150

    general_flow.add{type = "line", direction = "horizontal"}

    -- Debug section

    local debug_section_title = general_flow.add{type = "label", caption = {"qf-options.debug-title"}}
    debug_section_title.style.font = "heading-3"
    general_flow.add{type = "label", caption = {"qf-options.debug-caption"}, tooltip = {"qf-options.debug-caption-tooltip"}}.style.single_line = false

    general_flow.add{type = "button", name = "process_recipes_button", caption = {"qf-options.debug-reprocess-recipes"}, tooltip = {"qf-options.debug-reprocess-recipes-tooltip"}}

    -- Duplicate section
    local duplicate_flow_title = duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling"}}
    duplicate_flow_title.style.font = "heading-3"
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption"}}.style.single_line = false
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption-green"}, tooltip = {"qf-options.duplicates-handling-caption-green-tooltip"}}
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption-red"}, tooltip = {"qf-options.duplicates-handling-caption-red-tooltip"}}

    local duplicate_main_frame = duplicate_flow.add{type = "frame", name = "duplicate_main_frame", direction = "vertical", style="inside_deep_frame"}
    --duplicate_main_frame.style.margin = 8
    local duplicate_main_pane = duplicate_main_frame.add{type = "scroll-pane", name = "duplicate_main_pane", direction = "vertical"}

    for product, recipes in pairs(global.duplicate_recipes) do
        local duplicate_product_flow = duplicate_main_pane.add{type = "flow", direction = "horizontal"}
        local duplicate_product_label = duplicate_product_flow.add{type = "label", caption = {"", "[item="..product.."] ", game.item_prototypes[product].localised_name}}
        duplicate_product_label.style.height = 40
        duplicate_product_label.style.vertical_align = "center"
        duplicate_product_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
        local duplicate_product_table = duplicate_product_flow.add{type = "table", column_count = 4}
        for _, recipe in pairs(recipes) do
            local recipe_button = duplicate_product_table.add{type = "sprite-button", sprite = "item/" .. product, elem_tooltip = {type = "recipe", name = recipe}, style = "slot_button"}
            recipe_button.tags = {recipe_name = recipe, item_name = product, button_type = "recipe_priority_selector"}
        end
    end
end

---comment
---@param player LuaPlayer
function build_fabricator_gui(player)

    -- Main frame
    local main_frame = player.gui.screen.add{type = "frame", name = "qf_fabricator_inventory_frame", direction = "vertical"}
    main_frame.style.size = MAIN_FRAME_SIZE
    main_frame.auto_center = true

    -- Titlebar
    local titlebar = main_frame.add{type = "flow", name = "titlebar", direction = "horizontal"}
    titlebar.add{type = "label", caption = {"qf-inventory.main-frame-title"}, style = "frame_title"}
    titlebar.add{type="empty-widget", name="dragspace_filler", style="draggable_space", ignored_by_interaction=true}
    titlebar.dragspace_filler.style.height = DRAGSPACE_FILLER_HEIGHT
    titlebar.dragspace_filler.style.horizontally_stretchable = true
    titlebar.drag_target = main_frame

    local reset_button = titlebar.add{type = "button", name = "qf_reset_button", caption = {"qf-inventory.reset-filter"}}

    local searchbar = titlebar.add{name = "qf_search", type = "textfield", style = "titlebar_search_textfield", clear_and_focus_on_right_click = true}
    searchbar.style.width = SEARCHBAR_WIDTH
    local options_button = titlebar.add{type = "sprite-button", name = "qf_options_button", style = "frame_action_button", sprite="qf-setting-icon-white", hovered_sprite="qf-setting-icon", clicked_sprite="qf-setting-icon"}
    titlebar.add{type = "sprite-button", name = "qf_close_button", style = "close_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black"}

    

    -- Main content
    local main_content = main_frame.add{type = "flow", name = "main_content_flow", direction = "horizontal"}
    main_content.style.horizontal_spacing = 12

    -- Current data
    sort_tab_lists()
    get_craft_data(player)
    get_filtered_data(player, "")


    
    build_storage_gui(player)
    build_recipe_gui(player)

    player.opened = main_frame
end


---comment
---@param player LuaPlayer
function build_storage_gui(player)
    local main_content_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow
    if player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow then player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow.destroy() end
    local storage_flow = main_content_flow.add{type = "flow", name = "storage_flow", direction = "vertical"}
    --storage_flow.style.size = STORAGE_FLOW_SIZE
    --storage_flow.style.top_padding = 12

    local storage_frame = storage_flow.add{type = "frame", name = "storage_frame", direction = "vertical", style="inside_shallow_frame"}
    storage_frame.style.size = STORAGE_FLOW_SIZE
    storage_frame.style.top_padding = 12

    local tabbed_pane = storage_frame.add{type = "tabbed-pane", name = "tabbed_pane"}
    local materials_tab = tabbed_pane.add{type = "tab", name = "materials_tab", caption = "Materials"}
    local placeables_tab = tabbed_pane.add{type = "tab", name = "placeables_tab", caption = "Placeables"}
    local others_tab = tabbed_pane.add{type = "tab", name = "others_tab", caption = "Others"}
    local tooltip_tab = tabbed_pane.add{type = "tab", name = "tooltip_tab", caption = "Tooltip"}

    local materials_tab_content = build_materials_tab(player)
    local placeables_tab_content = build_placeables_tab(player)
    local others_tab_content = build_others_tab(player)

    tabbed_pane.add_tab(materials_tab, materials_tab_content)
    tabbed_pane.add_tab(placeables_tab, placeables_tab_content)
    tabbed_pane.add_tab(others_tab, others_tab_content)

    tabbed_pane.selected_tab_index = global.player_gui[player.index].selected_tab_index
end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_materials_tab(player)
    local tabbed_pane = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow.storage_frame.tabbed_pane
    if tabbed_pane.materials_tab_content then tabbed_pane.materials_tab_content.destroy() end
    local materials_tab_content = tabbed_pane.add{type = "frame", name = "materials_tab_content", direction = "vertical", style="inside_deep_frame"}
    materials_tab_content.style.size = TABBED_PANE_CONTENT_SIZE

    local storage_scroll_pane = materials_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = TABBED_PANE_CONTENT_SIZE
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local sorted_list = Sorted_lists["Materials"]
    for _, item in pairs(sorted_list) do
        if Filtered_data[player.index].materials[item.name] then
            local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}
    
            local item_name_caption 
            if item.type == "item" then
                item_name_caption = {"", "[item="..item.name.."] ", game.item_prototypes[item.name].localised_name}
            else
                item_name_caption = {"", "[fluid="..item.name.."] ", game.fluid_prototypes[item.name].localised_name}
            end
    
            local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = {type=item.type, name = item.name}}
            item_name.style.font = "default-bold"
            item_name.style.horizontal_align = "left"
            item_name.style.width = TABBED_PANE_TAB_WIDTH["item name"]
    
            local item_count = item_entry.add{type="label", caption = "x" .. item.count}
            item_count.style.horizontal_align = "right"
            item_count.style.width = TABBED_PANE_TAB_WIDTH["item count"]
    
            local filler_space = item_entry.add{type="empty-widget"}
            filler_space.style.horizontally_stretchable = true
    
            -- what is this line? find out why it happens and why it's needed, because I don't think it should be needed
            if not global.ingredient_filter[item.name] then global.ingredient_filter[item.name] = {count = 0, recipes = {}} end
            local item_recipe_usage_number = global.ingredient_filter[item.name].count
            if item_recipe_usage_number > 0 then
                local item_recipe_usage_caption = {"qf-inventory.recipe-usage", item_recipe_usage_number}
                local item_recipe_usage = item_entry.add{type="label", caption = item_recipe_usage_caption}
                item_recipe_usage.style.horizontal_align = "right"
                item_recipe_usage.style.width = TABBED_PANE_TAB_WIDTH["item recipe usage"]
        
                local item_button = item_entry.add{type = "sprite-button", style = "frame_action_button", sprite="utility/search_white", hovered_sprite="utility/search_black", clicked_sprite="utility/search_black"}
                item_button.style.horizontal_align = "right"
                item_button.style.size = TABBED_PANE_TAB_SIZE["button"]
                item_button.tags = {button_type = "recipe_usage_search", item_name = item.name}
            end
        end
    end
    return materials_tab_content
end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_placeables_tab(player)
    local tabbed_pane = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow.storage_frame.tabbed_pane
    local placeables_tab_content = tabbed_pane.add{type = "frame", name = "placeables_tab_content", direction = "vertical", style="inside_deep_frame"}
    placeables_tab_content.style.size = TABBED_PANE_CONTENT_SIZE

    local storage_scroll_pane = placeables_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = TABBED_PANE_CONTENT_SIZE
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local items_list = global.fabricator_inventory["item"]
    local sorted_list = {}
    for name, count in pairs(items_list) do
        if count > 0 and (is_placeable(name) or is_module(name)) then
            sorted_list[#sorted_list + 1] = {name = name, count = count}
        end
    end
    table.sort(sorted_list, function(a, b) return a.count > b.count end)
    for _, item in pairs(sorted_list) do
        local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}

        local item_name_caption
        local take_out_caption
        local button_sprite
        local button_tags
        if is_module(item.name) then
            item_name_caption = {"", "[item="..item.name.."] ", game.item_prototypes[item.name].localised_name}
            take_out_caption = {"qf-inventory.take-out-item"}
        else
            item_name_caption = {"", "[item="..item.name.."] ", game.item_prototypes[item.name].localised_name}
            take_out_caption = {"qf-inventory.take-out-ghost"}
            button_sprite = "qf-vanilla-ghost-entity-icon"
            button_tags = {button_type = "take_out_ghost", item_name = item.name}
        end

        local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = {type="item", name = item.name}}
        item_name.style.font = "default-bold"
        item_name.style.horizontal_align = "left"
        item_name.style.width = TABBED_PANE_TAB_WIDTH["item name"]

        local item_count = item_entry.add{type="label", caption = "x" .. item.count}
        item_count.style.horizontal_align = "right"
        item_count.style.width = TABBED_PANE_TAB_WIDTH["item count"]

        local filler_space = item_entry.add{type="empty-widget"}
        filler_space.style.horizontally_stretchable = true

        if not is_module(item.name) then
            local item_take_out_label = item_entry.add{type="label", caption = take_out_caption}
            item_take_out_label.style.horizontal_align = "right"
            item_take_out_label.style.width = TABBED_PANE_TAB_WIDTH["item recipe usage"]
    
            local item_take_out_button = item_entry.add{type = "sprite-button", style = "frame_action_button", sprite = button_sprite}
            item_take_out_button.style.horizontal_align = "right"
            item_take_out_button.style.size = TABBED_PANE_TAB_SIZE["button"]
            item_take_out_button.tags = button_tags
        else
            local item_take_out_label = item_entry.add{type="label", caption = "Modules are automatically inserted when requested"}
            item_take_out_label.style.horizontal_align = "right"
            item_take_out_label.style.width = TABBED_PANE_TAB_WIDTH["item recipe usage"]
        end
    end
    return placeables_tab_content
end


---comment
---@param player LuaPlayer
---@return LuaGuiElement
function build_others_tab(player)
    local tabbed_pane = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow.storage_frame.tabbed_pane
    local others_tab_content = tabbed_pane.add{type = "frame", name = "others_tab_content", direction = "vertical", style="inside_deep_frame"}
    others_tab_content.style.size = TABBED_PANE_CONTENT_SIZE

    local storage_scroll_pane = others_tab_content.add{type = "scroll-pane", name = "storage_scroll_pane", direction = "vertical"}
    storage_scroll_pane.style.size = TABBED_PANE_CONTENT_SIZE
    storage_scroll_pane.vertical_scroll_policy = "auto-and-reserve-space"

    local items_list = global.fabricator_inventory["item"]
    local fluids_list = global.fabricator_inventory["fluid"]
    local sorted_list = {}
    for name, count in pairs(items_list) do
        if count > 0 and not is_placeable(name) and not is_module(name) and not global.ingredient[name] then
            sorted_list[#sorted_list + 1] = {name = name, count = count, type = "item"}
        end
    end
    for name, count in pairs(fluids_list) do
        if count > 0 and not global.ingredient[name] then
            sorted_list[#sorted_list + 1] = {name = name, count = count, type = "fluid"}
        end
    end
    table.sort(sorted_list, function(a, b) return a.count > b.count end)

    local others_tab_label_1 = storage_scroll_pane.add{type="label", caption = {"qf-inventory.others-tab-caption-1"}}
    others_tab_label_1.style.font = "default-bold"
    local others_tab_label_2 = storage_scroll_pane.add{type="label", caption = {"qf-inventory.others-tab-caption-2"}}
    others_tab_label_2.style.font = "default-bold"

    for _, item in pairs(sorted_list) do
        local item_entry = storage_scroll_pane.add{type = "flow", direction = "horizontal"}
        local item_name_caption
        local elem_tooltip
        if item.type == "item" then
            item_name_caption = {"", "[item="..item.name.."] ", game.item_prototypes[item.name].localised_name}
            elem_tooltip = {type="item", name = item.name}
        else
            item_name_caption = {"", "[fluid="..item.name.."] ", game.fluid_prototypes[item.name].localised_name}
            elem_tooltip = {type="fluid", name = item.name}
        end
        
        local item_name = item_entry.add{type="label", caption = item_name_caption, elem_tooltip = elem_tooltip}
        item_name.style.font = "default-bold"
        item_name.style.horizontal_align = "left"
        item_name.style.width = TABBED_PANE_TAB_WIDTH["item name"]

        local item_count = item_entry.add{type="label", caption = "x" .. item.count}
        item_count.style.horizontal_align = "right"
        item_count.style.width = TABBED_PANE_TAB_WIDTH["item count"]

        local filler_space = item_entry.add{type="empty-widget"}
        filler_space.style.horizontally_stretchable = true
    end
    return others_tab_content
end


---comment
---@param player LuaPlayer
function build_recipe_gui(player)
    local main_content_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow
    if main_content_flow.recipe_flow then main_content_flow.recipe_flow.destroy() end
    local recipe_flow = main_content_flow.add{type = "frame", name = "recipe_flow", direction = "vertical", style="inside_shallow_frame"}
    recipe_flow.style.size = RECIPE_FLOW_SIZE

    if not global.item_group_order then process_item_group_order() end

    local size = Filtered_data[player.index].size
    local filter = Filtered_data[player.index].content

    if filter and size and size > 0 then

        local group_table_rows = math.ceil(size / RECIPE_FLOW_ITEM_GROUP_MAX_NUMBER_OF_COLUMNS)
        local group_table_columns = math.min(size, RECIPE_FLOW_ITEM_GROUP_MAX_NUMBER_OF_COLUMNS)

        local extra_frame = recipe_flow.add{type = "frame", direction = "vertical"}
        extra_frame.style.size = {width = RECIPE_FLOW_TABLE_WIDTH + 8, height = group_table_rows * RECIPE_FLOW_ITEM_GROUP_BUTTON_HEIGHT + 10}
        extra_frame.style.top_padding = 0
        extra_frame.style.bottom_padding = 0
        extra_frame.style.left_padding = 0 --4
        extra_frame.style.right_padding = 0 --4

        local group_table = extra_frame.add{type = "table", name = "group_table", column_count = group_table_columns, style = "qf_item_group_table"}
        group_table.style.size = {width = RECIPE_FLOW_TABLE_WIDTH, height = group_table_rows * RECIPE_FLOW_ITEM_GROUP_BUTTON_HEIGHT + 10}
        group_table.style.horizontal_spacing = 0
        group_table.style.vertical_spacing = 0
        extra_frame.style.right_padding = 0
    
        
        local fallback
        for _, group in pairs(global.item_group_order) do
            if filter[group.name] then
                if not fallback then fallback = group.name end
                local group_button = group_table.add{type = "sprite-button", name = group.name .. "_button", sprite = "item-group/" .. group.name, style = "menu_button"}
                group_button.style.height = RECIPE_FLOW_ITEM_GROUP_BUTTON_HEIGHT
                group_button.style.width = RECIPE_FLOW_TABLE_WIDTH / group_table_columns
                group_button.style.horizontally_stretchable = true
                group_button.tags = {button_type = "item_group_selector", group_name = group.name}
                group_button.tooltip = {"item-group-name." .. group.name}
            end
        end
        local current_selection = global.player_gui[player.index].item_group_selection
        if group_table[current_selection .. "_button"] then
            group_table[current_selection .. "_button"].toggled = true
        else
            group_table[fallback .. "_button"].toggled = true
            global.player_gui[player.index].item_group_selection = fallback
        end

        build_recipe_item_list_gui(player)
    else
        local error_frame = recipe_flow.add{type = "frame", name = "error_frame", direction = "vertical", style = "inside_deep_frame"}
        error_frame.style.size = RECIPE_FLOW_SIZE
        error_frame.style.vertically_stretchable = true
        error_frame.style.horizontally_stretchable = true
        local error_label = error_frame.add{type = "label", name = "error_label", caption = {"qf-inventory.no-recipes-found"}}
        error_label.style.horizontal_align = "center"
        error_label.style.vertical_align = "center"
        error_label.style.font_color = {1.0, 0.0, 0.0}
        error_label.style.font = "default-bold"
    end

end


---comment
---@param player LuaPlayer
function build_recipe_item_list_gui(player)
    local recipe_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.recipe_flow
    if recipe_flow.recipe_item_scroll_pane then recipe_flow.recipe_item_scroll_pane.destroy() end

    local recipe_item_scroll_pane = recipe_flow.add{type = "scroll-pane", name = "recipe_item_scroll_pane", direction = "vertical"}
    recipe_item_scroll_pane.style.width = RECIPE_FLOW_SIZE.width
    recipe_item_scroll_pane.style.natural_height = RECIPE_FLOW_SIZE.height - (75 * Filtered_data[player.index].size) - 10
    recipe_item_scroll_pane.style.vertically_stretchable = true
    recipe_item_scroll_pane.style.vertically_squashable = true
    recipe_item_scroll_pane.style.horizontally_squashable = true
    recipe_item_scroll_pane.style.horizontally_stretchable = true
    recipe_item_scroll_pane.vertical_scroll_policy = "always"
    recipe_item_scroll_pane.horizontal_scroll_policy = "never"

    local recipe_item_frame = recipe_item_scroll_pane.add{type = "frame", name = "recipe_item_list", style = "qf_item_slots", direction = "vertical"}
    recipe_item_frame.style.vertically_stretchable = true
    recipe_item_frame.style.vertically_squashable = true
    recipe_item_frame.style.horizontally_squashable = true
    recipe_item_frame.style.horizontally_stretchable = true
    recipe_item_frame.style.natural_height = RECIPE_FLOW_SIZE.height - (75 * Filtered_data[player.index].size) - 10
    --recipe_item_frame.style.vertical_spacing = 4
    recipe_item_frame.style.margin = 10

    local current_selection = global.player_gui[player.index].item_group_selection
    local filter = Filtered_data[player.index].content

    for _, subgroup in pairs(global.item_subgroup_order[current_selection]) do
        if filter and filter[current_selection] and filter[current_selection][subgroup.name] then
            local subgroup_table = recipe_item_frame.add{type = "table", column_count = SUBGROUP_TABLE_COLUMNS}
            subgroup_table.style.vertical_spacing = 0
            subgroup_table.style.horizontal_spacing = 0
            for _, item in pairs(filter[current_selection][subgroup.name]) do
                local item_button = subgroup_table.add{type = "sprite-button", sprite = "item/" .. item.item_name, tooltip = item.localised_name, style = "slot_button"}
                item_button.style.padding = 0
                item_button.number = Craft_data[player.index][item.item_name]
                item_button.raise_hover_events = true
                item_button.tags = {button_type = "take_out_ghost", item_name = item.item_name, hover_type = "recipe", recipe_name = item.recipe_name}
            end
        end
    end

end


---comment
---@param player LuaPlayer
function build_tooltip(player, item_name, recipe_name)
    local storage_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow
    if storage_flow.tooltip_flow then storage_flow.tooltip_flow.destroy() end

    local tooltip_flow = storage_flow.add{type = "flow", name = "tooltip_flow", direction = "vertical", visible = false}
    tooltip_flow.style.vertical_align = "center"
    tooltip_flow.style.size = STORAGE_FLOW_SIZE


    local tooltip_frame = tooltip_flow.add{type = "frame", name = "tooltip_frame", direction = "vertical", style="inside_shallow_frame"}
    tooltip_frame.style.size = STORAGE_FLOW_SIZE -- {width = STORAGE_FLOW_SIZE.width - 12, height = STORAGE_FLOW_SIZE.height - 12} --STORAGE_FLOW_SIZE
    tooltip_frame.style.margin = 0--6

    local filler_1 = tooltip_frame.add{type = "empty-widget"}
    filler_1.style.vertically_stretchable = true

    local tooltip_tab_content = tooltip_frame.add{type = "frame", name = "tooltip_tab_content", direction = "vertical", style="inside_shallow_frame"}
    tooltip_tab_content.style.vertically_stretchable = false
    --tooltip_tab_content.style.margin = 4
    tooltip_tab_content.style.vertical_align = "center"
    tooltip_tab_content.style.width = STORAGE_FLOW_SIZE.width --TOOLTIP_CONTENT_SIZE.width

    local ingredients = global.unpacked_recipes[recipe_name].ingredients
    local products = global.unpacked_recipes[recipe_name].products

    local item_name_frame = tooltip_tab_content.add{type = "frame", direction = "horizontal", style = "tooltip_title_frame_light"}
    local item_name_label = item_name_frame.add{type = "label", caption = global.unpacked_recipes[recipe_name].localised_name}
    item_name_label.style.font = "heading-2"
    item_name_label.style.font_color = {0.0, 0.0, 0.0}

    item_description_label_caption = {"?", global.prototypes_data[item_name].localised_description, ""}
    local item_description_label = tooltip_tab_content.add{type = "label", caption = item_description_label_caption}
    item_description_label.style.left_padding = 6
    item_description_label.style.width = STORAGE_FLOW_SIZE.width - 24
    item_description_label.style.single_line = false
    item_description_label.style.bottom_padding = 6

    --local recipe_name_frame = tooltip_tab_content.add{type = "frame", direction = "horizontal"}
    --local recipe_name_label = recipe_name_frame.add{type = "label", caption = "Recine name"}

    local recipe_frame = tooltip_tab_content.add{type = "frame", name = "recipe_frame", direction = "vertical", style = "inside_deep_frame"}
    recipe_frame.style.padding = 12
    local main_ingredient_label = recipe_frame.add{type = "label", caption = {"qf-inventory.ingredinets"}}
    main_ingredient_label.style.font = "heading-3"

    local column_count = 2
    local ingredient_table = recipe_frame.add{type = "table", column_count = column_count}

    for _, ingredient in pairs(ingredients) do
        local icon = "["..ingredient.type.."="..ingredient.name.."] "
        local localised_name
        if ingredient.type == "item" then
            localised_name = game.item_prototypes[ingredient.name].localised_name
        else
            localised_name = game.fluid_prototypes[ingredient.name].localised_name
        end
        local required = ingredient.amount
        local available = global.fabricator_inventory[ingredient.type][ingredient.name] or 0
        local ingredient_caption = {"", icon, localised_name}
        local font_color = {1.0, 1.0, 1.0}
        if available / required < 10 then
            font_color = {1.0, 1.0, 0.0}
        end
        if available < required then
            font_color = {1.0, 0.0, 0.0}
        end


        local ingredient_flow = ingredient_table.add{type = "flow", direction = "horizontal"}
        local ingredient_label = ingredient_flow.add{type = "label", caption = ingredient_caption}
        ingredient_label.style.width = 145
        ingredient_label.style.font_color = font_color

        local required_label = ingredient_flow.add{type = "label", caption = "x" .. required}
        required_label.style.horizontal_align = "right"
        required_label.style.width = 60
        required_label.style.font_color = font_color

        local available_label = ingredient_flow.add{type = "label", caption = "/ " .. int_to_str_si(available)}
        available_label.style.horizontal_align = "left"
        available_label.style.width = 65
        available_label.style.font_color = font_color

    end

    local separator_line = recipe_frame.add{type = "line", direction = "horizontal"}

    local product_flow = recipe_frame.add{type = "flow", name = "product_flow", direction = "vertical"}
    local main_product_label = product_flow.add{type = "label", caption = {"qf-inventory.products"}}
    main_product_label.style.font = "default-bold"

    for _, product in pairs(products) do
        local product_label_flow = product_flow.add{type = "flow", direction = "horizontal"}
        local icon = "["..product.type.."="..product.name.."] "
        local localised_name = game.item_prototypes[product.name].localised_name
        local product_caption = {"", icon, localised_name}
        local amount = product.amount
        local product_label = product_label_flow.add{type = "label", caption = product_caption}

        local amount_label = product_label_flow.add{type = "label", caption = "x" .. amount}
        amount_label.style.horizontal_align = "right"
    end

    local filler_2 = tooltip_frame.add{type = "empty-widget"}
    filler_2.style.vertically_stretchable = true

    local filler_3 = tooltip_frame.add{type = "empty-widget"}
    filler_3.style.height = 80
    filler_3.style.vertical_align = "bottom"

end

