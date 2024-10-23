function build_options_gui(player)
    local main_frame = player.gui.screen.add{type = "frame", name = "qf_fabricator_options_frame", direction = "vertical"}
    main_frame.style.width = QF_GUI.options_frame.width
    main_frame.style.maximal_height = QF_GUI.options_frame.max_height
    main_frame.auto_center = true

    -- Titlebar
    local titlebar = main_frame.add{type = "flow", name = "titlebar", direction = "horizontal"}
    titlebar.add{type = "label", caption = {"qf-options.options-title"}, style = "frame_title"}
    titlebar.add{type="empty-widget", name="dragspace_filler", style="draggable_space", ignored_by_interaction=true}
    titlebar.dragspace_filler.style.height = QF_GUI.dragspace.height
    titlebar.dragspace_filler.style.horizontally_stretchable = true
    titlebar.drag_target = main_frame
    titlebar.add{type = "sprite-button", name = "qf_options_close_button", style = "close_button", sprite="utility/close", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black"}

    -- Main content
    local main_content = main_frame.add{type = "frame", name = "main_content", direction = "horizontal", style="inside_shallow_frame_with_padding"}
    main_content.style.width = QF_GUI.options_frame.width - 24

    local general_flow = main_content.add{type = "flow", name = "general_flow", direction = "vertical"}
    general_flow.style.width = (QF_GUI.options_frame.width - 24) / 2 - 24
    general_flow.style.right_padding = 8

    main_content.add{type = "line", direction = "vertical"}

    local duplicate_flow = main_content.add{type = "flow", name = "duplicate_flow", direction = "vertical"}
    duplicate_flow.style.width = (QF_GUI.options_frame.width - 24) / 2 - 12
    duplicate_flow.style.left_padding = 8

    -- General section 
    local general_section_title = general_flow.add{type = "label", caption = {"qf-options.pref-title"}}
    general_section_title.style.font = "default-small-bold"

    local calc_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    calc_option_flow.add{type = "label", caption = {"qf-options.pref-calculate-craftable-numbers"}, tooltip = {"qf-options.pref-calculate-craftable-numbers-tooltip"}}
    calc_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    calc_option_flow.add{type = "checkbox", name = "qf_calculate_craftable_numbers", state = storage.player_gui[player.index].options.calculate_numbers}

    general_flow.add{type = "line", direction = "horizontal"}

    local mark_red_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    mark_red_option_flow.add{type = "label", caption = {"qf-options.pref-mark-noncraftables"}, tooltip = {"qf-options.pref-mark-noncraftables-tooltip"}}
    mark_red_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    mark_red_option_flow.add{type = "checkbox", name = "qf_mark_red", state = storage.player_gui[player.index].options.mark_red}

    general_flow.add{type = "line", direction = "horizontal"}

    local sort_option_flow = general_flow.add{type = "flow", direction = "horizontal"}
    sort_option_flow.add{type = "label", caption = {"qf-options.pref-sorting"}, tooltip = {"qf-options.pref-sorting-tooltip"}}
    sort_option_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    local drop_down = sort_option_flow.add{type = "drop-down", name = "qf_sort_by", items = {{"qf-options.pref-sorting-item-name"}, {"qf-options.pref-sorting-abc"}, {"qf-options.pref-sorting-available"}}, selected_index = storage.player_gui[player.index].options.sort_by}
    drop_down.style.width = 160
    drop_down.selected_index = storage.player_gui[player.index].options.sort_ingredients

    general_flow.add{type = "line", direction = "horizontal"}

    -- Debug section
    local debug_section_title = general_flow.add{type = "label", caption = {"qf-options.debug-title"}}
    debug_section_title.style.font = "default-small-bold"
    general_flow.add{type = "label", caption = {"qf-options.debug-caption"}, tooltip = {"qf-options.debug-caption-tooltip"}}.style.single_line = false

    general_flow.add{type = "button", name = "process_recipes_button", caption = {"qf-options.debug-reprocess-recipes"}, tooltip = {"qf-options.debug-reprocess-recipes-tooltip"}}
    general_flow.add{type = "button", name = "update_module_requests_button", caption = {"qf-options.debug-update_module_requests"}, tooltip = {"qf-options.debug-update_module_requests-tooltip"}}
    local auto_recheck_item_reques_proxies_flow = general_flow.add{type = "flow", direction = "horizontal"}
    auto_recheck_item_reques_proxies_flow.add{type = "label", caption = {"qf-options.debug-auto-recheck-item-request-proxy"}}
    auto_recheck_item_reques_proxies_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
    auto_recheck_item_reques_proxies_flow.add{type = "checkbox", name = "qf_auto_recheck_item_request_proxies", state = storage.options.auto_recheck_item_request_proxies}

    -- Duplicate section
    local duplicate_flow_title = duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling"}}
    duplicate_flow_title.style.font = "default-small-bold"
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption"}}.style.single_line = false
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption-green"}, tooltip = {"qf-options.duplicates-handling-caption-green-tooltip"}}
    duplicate_flow.add{type = "label", caption = {"qf-options.duplicates-handling-caption-red"}, tooltip = {"qf-options.duplicates-handling-caption-red-tooltip"}}

    local duplicate_main_frame = duplicate_flow.add{type = "frame", name = "duplicate_main_frame", direction = "vertical", style="inside_deep_frame"}
    local duplicate_main_pane = duplicate_main_frame.add{type = "scroll-pane", name = "duplicate_main_pane", direction = "vertical"}

    for product, recipes in pairs(storage.duplicate_recipes) do
        local duplicate_product_flow = duplicate_main_pane.add{type = "flow", direction = "horizontal"}
        local duplicate_product_label = duplicate_product_flow.add{type = "label", caption = {"", "[item="..product.."] ", prototypes.item[product].localised_name}}
        duplicate_product_label.style.height = 40
        duplicate_product_label.style.left_padding = 8
        duplicate_product_label.style.vertical_align = "center"
        duplicate_product_flow.add{type = "empty-widget"}.style.horizontally_stretchable = true
        local duplicate_product_table = duplicate_product_flow.add{type = "table", column_count = 4}
        for _, recipe in pairs(recipes) do
            local recipe_button = duplicate_product_table.add{type = "sprite-button", sprite = "item/" .. product, elem_tooltip = {type = "recipe", name = recipe}, style = storage.unpacked_recipes[recipe].priority_style}
            recipe_button.tags = {recipe_name = recipe, item_name = product, button_type = "recipe_priority_selector"}
        end
    end
end


function update_duplicate_handling_buttons(parent, product_name)
    parent.clear()
    for _, recipe in pairs(storage.duplicate_recipes[product_name]) do
        local recipe_button = parent.add{type = "sprite-button", sprite = "item/" .. product_name, elem_tooltip = {type = "recipe", name = recipe}, style = storage.unpacked_recipes[recipe].priority_style}
        recipe_button.tags = {recipe_name = recipe, item_name = product_name, button_type = "recipe_priority_selector"}
    end
end