local utils = require("scripts/utils")
local qs_utils = require("scripts/qs_utils")
local gui_utils = require("scripts/gui/gui_utils")
local tracking = require("scripts/tracking_utils")

function on_gui_leave(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags
    if element_tags.hover_type == "recipe" then
        storage.player_gui[event.player_index].tooltip_workaround = storage.player_gui[event.player_index].tooltip_workaround - 1
        if storage.player_gui[event.player_index].tooltip_workaround <= 0 then
            if player.gui.screen.qf_recipe_tooltip then player.gui.screen.qf_recipe_tooltip.visible = false end
        end
    end
end

function on_gui_hover(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    local element = event.element
    local element_tags = element.tags
    if element_tags.hover_type == "recipe" then
        storage.player_gui[event.player_index].tooltip_workaround = storage.player_gui[event.player_index].tooltip_workaround + 1
        build_main_tooltip(player, element_tags.item_name, element_tags.recipe_name)
        gui_utils.auto_position_tooltip(player, element_tags.index)
    end
end

function on_gui_text_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if not event.element then return end
    if event.element.name == "searchbar" then
        Filtered_data_ok = false
        gui_utils.apply_gui_filter(player, event.text, nil, true)
        event.element.focus()
    elseif event.element.name == "qf_intake_limit_textfield" then
        gui_utils.set_intake_limit(event.element.text, event.element.tags.unit_number)
    end
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
        local previous_selection = element.parent[storage.player_gui[player.index].item_group_selection .. "_button"]
        if previous_selection then previous_selection.toggled = false end
        storage.player_gui[player.index].item_group_selection = element_tags.group_name
        element.toggled = true
        build_main_recipe_item_list_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.recipe_flow)
    elseif element_tags.button_type == "recipe_usage_search" then
        Filtered_data_ok = false
        gui_utils.apply_gui_filter(player, storage.ingredient_filter[element_tags.item_name].recipes, "Filtering recipes (Right click to reset)", false)
    elseif element.name == "filter_reset_button" then
        Filtered_data_ok = true
        gui_utils.apply_gui_filter(player, "", "", true)
    elseif element_tags.button_type == "recipe_priority_selector" then
        if event.button == defines.mouse_button_type.left then
            prioritise_recipe(element_tags)
        elseif event.button == defines.mouse_button_type.right then
            blacklist_recipe(element_tags)
        end
        table.sort(storage.product_craft_data[element_tags.item_name], function(a, b) return a.suitability > b.suitability end)
        update_duplicate_handling_buttons(element.parent, element_tags.item_name)
    elseif element_tags.button_type == "take_out_item" then
        local qs_item = {
            name = element_tags.item_name,
            count = 1,
            type = "item",
            quality = storage.player_gui[event.player_index].quality.name,
            surface_index = player.physical_surface_index
        }
        qs_utils.take_from_storage(qs_item, player)
    elseif element_tags.button_type == "take_out_ghost" then
        player.clear_cursor()
        player.cursor_ghost = {name = element_tags.item_name, quality = storage.player_gui[event.player_index].quality.name}
        toggle_qf_gui(player)
    elseif element.name == "qf_options_button" then
        toggle_options_gui(player)
    elseif element.name == "qf_reprocess_recipes_button" then
        reprocess_recipes()
    elseif element.name == "process_recipes_button" then
        game.print("Recipes rechecked, information is up to date")
        post_research_recheck()
    elseif element.name == "qf_options_close_button" then
        toggle_options_gui(player)
    elseif element.name == "toggle_storage_button" then
        toggle_storage_gui(player)
    elseif element.name == "qf_close_button" then
        toggle_qf_gui(player)
    elseif element.name == "update_module_requests_button" then
        tracking.update_lost_module_requests(player)
        game.print("Updating item request proxy tracking")
    elseif element.name == "qf_intake_limit_button" then
        storage.options.default_intake_limit = storage.tracked_entities["digitizer-chest"][element_tags.unit_number].settings.intake_limit
    elseif element.name == "qf_decraft_button" then
        storage.tracked_entities["digitizer-chest"][element_tags.unit_number].settings.decraft = not storage.tracked_entities["digitizer-chest"][element_tags.unit_number].settings.decraft
    end
end

function on_gui_opened(event)
    local entity = event.entity
    if event.gui_type ~= defines.gui_type.entity or not entity then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    if entity.name == "digitizer-chest" then
        create_digitizer_chest_gui(player, entity)
    elseif entity.name == "dedigitizer-reactor" then
        create_dedigitizer_reactor_gui(player, entity)
    end
end

function on_gui_elem_changed(event)
    local element = event.element
    local tags = element.tags
    local player = game.get_player(event.player_index)
    if not player then return end
    if element.name == "qf_choose_item_button" then
        storage.tracked_entities["dedigitizer-reactor"][tags.unit_number].settings.item_filter = element.elem_value
    elseif element.name == "qf_choose_fluid_button" then
        storage.tracked_entities["dedigitizer-reactor"][tags.unit_number].settings.fluid_filter = element.elem_value
    end
end

function prioritise_recipe(tags)
    local item_name = tags.item_name
    local recipe_name = tags.recipe_name
    for _, recipe in pairs(storage.product_craft_data[item_name]) do
        if recipe.recipe_name == recipe_name then
            if recipe.prioritised then
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 10
                recipe.priority_style = "slot_button"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            elseif recipe.blacklisted then
                recipe.prioritised = true
                recipe.blacklisted = false
                recipe.suitability = recipe.suitability + 20
                recipe.priority_style = "flib_slot_button_green"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_green"
            else
                recipe.prioritised = true
                recipe.suitability = recipe.suitability + 10
                recipe.priority_style = "flib_slot_button_green"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_green"
            end
        else
            if recipe.prioritised then
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 10
                recipe.priority_style = "slot_button"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            end
        end
        storage.recipe_priority[recipe.recipe_name] = recipe
    end
end

function blacklist_recipe(tags)
    local item_name = tags.item_name
    local recipe_name = tags.recipe_name
    for _, recipe in pairs(storage.product_craft_data[item_name]) do
        if recipe.recipe_name == recipe_name then
            if recipe.blacklisted then
                recipe.blacklisted = false
                recipe.suitability = recipe.suitability + 10
                recipe.priority_style = "slot_button"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "slot_button"
            elseif recipe.prioritised then
                recipe.blacklisted = true
                recipe.prioritised = false
                recipe.suitability = recipe.suitability - 20
                recipe.priority_style = "flib_slot_button_red"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_red"
            else
                recipe.blacklisted = true
                recipe.suitability = recipe.suitability - 10
                recipe.priority_style = "flib_slot_button_red"
                storage.unpacked_recipes[recipe.recipe_name].priority_style = "flib_slot_button_red"
            end
            storage.recipe_priority[recipe.recipe_name] = recipe
        end
    end
end

function on_gui_selected_tab_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    if element.name == "tabbed_pane" then
        storage.player_gui[event.player_index].selected_tab_index = element.selected_tab_index
    end
end

function on_gui_selection_state_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    local tags = event.element.tags
    if element.name == "qf_sort_by" then
        storage.player_gui[event.player_index].options.sort_ingredients = element.selected_index
        if element.selected_index == 1 then
            sort_ingredients(event.player_index, "item_name")
        elseif element.selected_index == 2 then
            sort_ingredients(event.player_index, "localised_name")
        elseif element.selected_index == 3 then
            sort_ingredients(event.player_index, "amount")
        end
    elseif element.name == "qf_quality_selection_dropdown" then
        storage.player_gui[event.player_index].quality.index = element.selected_index
        storage.player_gui[event.player_index].quality.name = utils.get_qualities()[element.selected_index].name
        build_main_recipe_item_list_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.recipe_flow)
    elseif element.name == "qf_choose_surface_dropdown" then
        storage.tracked_entities["dedigitizer-reactor"][tags.unit_number].settings.surface_index = tags.surface_link[element.selected_index]
    end
end

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
        storage.player_gui[event.player_index].options.calculate_numbers = element.state
    elseif element.name == "qf_mark_red" then
        storage.player_gui[event.player_index].options.mark_red = element.state
    elseif element.name == "qf_auto_recheck_item_request_proxies" then
        storage.options.auto_recheck_item_request_proxies = element.state
    end
end

script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)
script.on_event(defines.events.on_gui_leave, on_gui_leave)
script.on_event(defines.events.on_gui_hover, on_gui_hover)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_selected_tab_changed, on_gui_selected_tab_changed)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)