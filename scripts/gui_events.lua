function on_gui_hover(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags

    if element_tags.hover_type == "recipe" then
        build_tooltip(player, element_tags.item_name, element_tags.recipe_name)
        show_tooltip(player)
    end
end

function on_gui_leave(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags

    if element_tags.hover_type == "recipe" then
        hide_tooltip(player)
    end
end

function on_gui_elem_changed(event)
    local element = event.element
    local unit_id = element.tags.unit_number
    local player = game.get_player(event.player_index)

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

    if event.element.name == "qf_search" then
        apply_gui_filter(player, event.text, false, true)
        event.element.focus()
    end
end

function on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity or not event.entity or event.entity.name ~= "dedigitizer-reactor" then return end
    local player = game.get_player(event.player_index)
	local entity = event.entity
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
        toggle_fabricator_gui(player)
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
        build_recipe_item_list_gui(player)
        return
    end
    if element_tags.button_type == "recipe_usage_search" then
        apply_gui_filter(player, global.ingredient_filter[element_tags.item_name].recipes, true, false)
        return
    end
    if element.name == "qf_reset_button" then
        apply_gui_filter(player, "", true, true)
        return
    end
    if element_tags.button_type == "take_out_ghost" then
        player.clear_cursor()
        player.cursor_ghost = element_tags.item_name
        --Directly_chosen[element_tags.recipe_name] = element_tags.recipe_name
        toggle_fabricator_gui(player)
        return
    end
    if element.name == "qf_options_button" then
        toggle_options_gui(player)
        return
    end
    if element.name == "qf_options_close_button" then
        toggle_options_gui(player)
        return
    end
    if element.name == "qf_close_button" then
        toggle_fabricator_gui(player)
        return
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
end

---comment
---@param event any
function on_fabricator_gui_toggle_event(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    toggle_fabricator_gui(player)
end

function on_fabricator_gui_search_event(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if player.gui.screen.qf_fabricator_inventory_frame and not player.gui.screen.qf_fabricator_options_frame then
        player.gui.screen.qf_fabricator_inventory_frame.titlebar.qf_search.focus()
    end
end


script.on_event(defines.events.on_gui_hover, on_gui_hover)
script.on_event(defines.events.on_gui_leave, on_gui_leave)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_selected_tab_changed, on_gui_selected_tab_changed)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)