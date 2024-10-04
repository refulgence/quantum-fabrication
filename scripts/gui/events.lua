function on_gui_hover(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags
    if element_tags.hover_type == "recipe" then
        build_main_tooltip(player, element_tags.item_name, element_tags.recipe_name)
        auto_position_tooltip(player, element_tags.index)
    end
end

function on_gui_leave(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags
    if element_tags.hover_type == "recipe" then
        if player.gui.screen.qf_recipe_tooltip then player.gui.screen.qf_recipe_tooltip.destroy() end
    end
end


function on_gui_elem_changed(event)
    local element = event.element
    local unit_id = element.tags.unit_number
    local player = game.get_player(event.player_index)
    if not player then return end
    if element.name == "choose_item_button" then
        global.tracked_entities["dedigitizer-reactor"][unit_id].item_filter = element.elem_value
        update_dedigitizer_reactor_gui(player, global.tracked_entities["dedigitizer-reactor"][unit_id].entity)
        return
    end
    if element.name == "choose_fluid_button" then
        global.tracked_entities["dedigitizer-reactor"][unit_id].fluid_filter = element.elem_value
        update_dedigitizer_reactor_gui(player, global.tracked_entities["dedigitizer-reactor"][unit_id].entity)
        return
    end
end

function on_gui_text_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    if event.element.name == "searchbar" then
        apply_gui_filter(player, event.text, false, true)
        event.element.focus()
    end
end

function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity or event.entity.name ~= "dedigitizer-reactor" then return end
    local player = game.get_player(event.player_index)
	local entity = event.entity
    if not player then return end
    create_dedigitizer_reactor_gui(player, entity)
end

function on_gui_closed(event)
	local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
	if event.gui_type == defines.gui_type.item then
		local gui = player.gui.relative.dedigitizer_reactor_gui
		if gui then gui.destroy() end
	end
    if event.element.name == "qf_fabricator_inventory_frame" then
        toggle_qf_gui(player)
        return
    end
    if event.element.name == "qf_fabricator_frame" then
        toggle_qf_gui(player)
        return
    end
end

function on_gui_click(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    local element_tags = element.tags
    if element_tags.button_type == "item_group_selector" then
        local previous_selection = element.parent[global.player_gui[player.index].item_group_selection .. "_button"]
        if previous_selection then previous_selection.toggled = false end
        global.player_gui[player.index].item_group_selection = element_tags.group_name
        element.toggled = true
        build_main_recipe_item_list_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.recipe_flow)
    elseif element_tags.button_type == "recipe_usage_search" then
        apply_gui_filter(player, global.ingredient_filter[element_tags.item_name].recipes, true, false)
    elseif element.name == "filter_reset_button" then
        apply_gui_filter(player, "", true, true)
    elseif element_tags.button_type == "recipe_priority_selector" then
        if event.button == defines.mouse_button_type.left then
            prioritise_recipe(element_tags)
        elseif event.button == defines.mouse_button_type.right then
            blacklist_recipe(element_tags)
        end
        table.sort(global.product_craft_data[element_tags.item_name], function(a, b) return a.suitability > b.suitability end)
        update_duplicate_handling_buttons(player, element.parent, element_tags.item_name)
        --{recipe_name = recipe, item_name = product, button_type = "recipe_priority_selector"}
    elseif element_tags.button_type == "take_out_ghost" then
        player.clear_cursor()
        player.cursor_ghost = element_tags.item_name
        --Directly_chosen[element_tags.recipe_name] = element_tags.recipe_name
        toggle_qf_gui(player)
    elseif element.name == "qf_options_button" then
        toggle_options_gui(player)
    elseif element.name == "process_recipes_button" then
        game.print("Recipes rechecked, information is up to date")
        post_research_recheck()
    elseif element.name == "qf_options_close_button" then
        toggle_options_gui(player)
    elseif element.name == "toggle_storage_button" then
        toggle_storage_gui(player)
    elseif element.name == "qf_close_button" then
        toggle_qf_gui(player)
    end
end

function prioritise_recipe(tags)
    local item_name = tags.item_name
    local recipe_name = tags.recipe_name
    for _, recipe in pairs(global.product_craft_data[item_name]) do
        if recipe.recipe_name == recipe_name then
            if recipe.prioritised then
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 10
                global.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            elseif recipe.blacklisted then
                recipe.prioritised = true
                recipe.blacklisted = false
                recipe.suitability = recipe.suitability + 20
                global.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_green"
            else
                recipe.prioritised = true
                recipe.suitability = recipe.suitability + 10
                global.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_green"
            end
        else
            if recipe.prioritised then
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 10
                global.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            end
        end
    end
end

function blacklist_recipe(tags)
    local item_name = tags.item_name
    local recipe_name = tags.recipe_name
    for _, recipe in pairs(global.product_craft_data[item_name]) do
        if recipe.recipe_name == recipe_name then
            if recipe.blacklisted then
                recipe.blacklisted = false
                recipe.suitability = recipe.suitability + 10
                global.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            elseif recipe.prioritised then
                recipe.blacklisted = true
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 20
                global.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_red"
            else
                recipe.blacklisted = true
                recipe.suitability = recipe.suitability - 10
                global.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_red"
            end
        end
    end
end



function on_gui_selected_tab_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    if element.name == "tabbed_pane" then
        global.player_gui[event.player_index].selected_tab_index = element.selected_tab_index
    end
end

function on_gui_selection_state_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    if element.name == "qf_sort_by" then
        global.player_gui[event.player_index].options.sort_ingredients = element.selected_index
        if element.selected_index == 1 then
            sort_ingredients(event.player_index, "item_name")
        elseif element.selected_index == 2 then
            sort_ingredients(event.player_index, "localised_name")
        elseif element.selected_index == 3 then
            sort_ingredients(event.player_index, "amount")
        end
    end
end

---comment
---@param event any
function on_fabricator_gui_toggle_event(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    toggle_qf_gui(player)
end

function on_fabricator_gui_search_event(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if player.gui.screen.qf_fabricator_frame and not player.gui.screen.qf_fabricator_options_frame then
        player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.titlebar_flow.searchbar.focus()
    end
end

function on_gui_checked_state_changed(event)
    local element = event.element
    local player_index = event.player_index
    if not player_index or not element then return end
    if element.name == "qf_calculate_craftable_numbers" then
        global.player_gui[event.player_index].options.calculate_numbers = element.state
    elseif element.name == "qf_mark_red" then
        global.player_gui[event.player_index].options.mark_red = element.state
    end
end




script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
script.on_event(defines.events.on_gui_hover, on_gui_hover)
script.on_event(defines.events.on_gui_leave, on_gui_leave)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_selected_tab_changed, on_gui_selected_tab_changed)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)