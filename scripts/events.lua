


function on_init()
    global.fabricator_inventory = {item = {}, fluid = {}}
    global.unpacked_recipes = {}
    global.placeable = {}
    global.recipe = {}
    global.modules = {}
    global.ingredient = {}
    global.ingredient_filter = {}
    global.player_gui = {}
    global.dictionary = {}
    global.dictionary_helper = {}
    global.tracked_entities = {}
    global.tracked_requests = {construction = {}, modules = {}, upgrades = {}, revivals = {}, destroys = {}}
    if not Actual_non_duplicates then Actual_non_duplicates = {} end
    process_data()
end

function on_config_changed()
    process_data()
    for _, player in pairs(game.players) do
        fill_dictionary(player.index)
    end
end

function on_mod_settings_changed()
end


function on_created_player(event)
    if event.created_entity and event.created_entity.valid then
        if event.created_entity.type == "entity-ghost" then
            create_tracked_request({entity = event.created_entity, player_index = event.player_index, request_type = "revivals"})
        end
        on_created(event)
    end
end

function on_created(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "digitizer-combinator" or entity.name == "dedigitizer-reactor" then create_tracked_entity(entity) end
    end
end

function on_pre_mined(event)
    local entity = event.entity
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if entity.can_be_destroyed() and entity.type ~= "entity-ghost" then
            if entity.prototype.type == "tree" or entity.prototype.type == "simple-entity" or entity.prototype.type == "item-entity" then
                instant_deforestation(entity, player_index)
            elseif global.prototypes_data[entity.name] then
                local item_name = global.prototypes_data[entity.name].item_name
                if is_placeable(item_name) then
                    if not global.fabricator_inventory.item[item_name] then global.fabricator_inventory.item[item_name] = 0 end
                    create_tracked_request({entity = entity, player_index = player_index, request_type = "destroys"})
                end
            end
        end
        on_destroyed(event)
    end
end

function on_destroyed(event)
    local entity = event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "digitizer-combinator" or entity.name == "dedigitizer-reactor" then remove_tracked_entity(entity) end
    end
end

function on_upgrade(event)
    local entity = event.entity
    local target = event.target
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if not instant_upgrade(entity, target, player_index) then create_tracked_request({entity = entity, player_index = player_index, upgrade_target = target, request_type = "upgrades"}) end
    end
end



function on_player_created(event)
    fill_dictionary(event.player_index)
    global.player_gui[event.player_index] = {
        item_group_selection = 1,
        selected_tab_index = 1,
        show_storage = false,
        fabricator_gui_position = nil,
        options = {
            calculate_numbers = true,
            mark_red = true,
            sort_ingredients = 1
        }
    }
end



function sort_ingredients(player_index)
    for _, recipe in pairs(global.unpacked_recipes) do
        table.sort(global.unpacked_recipes[recipe.name].ingredients, function(a, b) return global.dictionary[player_index][a.name] < global.dictionary[player_index][b.name] end)
    end
end


function post_research_recheck()
    process_ingredient_filter()
    process_recipe_enablement()
end

function on_research_changed(event)
    Research_finished = true
end
script.on_nth_tick(338, function(event)
    if Research_finished then
        post_research_recheck()
        Research_finished = false
    end
end)

function on_console_command(command)
    local player_index = command.player_index
    local name = command.name
    if name == "qf_hesoyam" then
        debug_storage(250000, false)
        game.print("CHEAT: Fabricator inventory updated")
    elseif name == "qf_hesoyam_harder" then
        debug_storage(250000000, true)
        game.print("CHEAT: Fabricator inventory updated with a lot of stuff")
    elseif name == "qf_clear_storage" then
        global.fabricator_inventory = {item = {}, fluid = {}}
        game.print("CHEAT(?): Fabricator inventory cleared")
    elseif name == "qf_sort_by_abc" then
        sort_ingredients(player_index)
        game.print("Ingredients are sorted in alphabetical order (according to the current player's locale)")
    end
end


function debug_storage(amount, everything)
    if not everything then
        for material, _ in pairs(global.ingredient) do
            local type = item_type_check(material)
            if not global.fabricator_inventory[type][material] then global.fabricator_inventory[type][material] = 0 end
            add_to_storage({name = material, amount = amount, type = type}, false)
        end
    else
        for _, item in pairs(game.item_prototypes) do
            if not global.fabricator_inventory["item"][item.name] then global.fabricator_inventory["item"][item.name] = 0 end
            add_to_storage({name = item.name, amount = amount, type = "item"}, false)
        end
        for _, fluid in pairs(game.fluid_prototypes) do
            if not global.fabricator_inventory["fluid"][fluid.name] then global.fabricator_inventory["fluid"][fluid.name] = 0 end
            add_to_storage({name = fluid.name, amount = amount, type = "fluid"}, false)
        end
    end
end

function on_lua_shortcut(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.prototype_name == "qf-fabricator-gui" then
        toggle_qf_gui(player)
    end
end


commands.add_command("qf_hesoyam", nil, on_console_command)
commands.add_command("qf_hesoyam_harder", nil, on_console_command)
commands.add_command("qf_clear_storage", nil, on_console_command)
commands.add_command("qf_sort_by_abc", nil, on_console_command)

script.on_nth_tick(Update_rate["destroys"].rate, update_tracked_destroys)
script.on_nth_tick(Update_rate["revivals"].rate, update_tracked_revivals)
script.on_nth_tick(Update_rate["entities"].rate, update_tracked_entities)
script.on_nth_tick(Update_rate["requests"].rate, update_tracked_requests)
script.on_nth_tick(300, update_tracked_dedigitizer_reactors)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_changed)
script.on_init(on_init)
script.on_configuration_changed(on_config_changed)

script.on_event("qf-fabricator-gui-search", on_fabricator_gui_search_event)
script.on_event("qf-fabricator-gui-toggle", on_fabricator_gui_toggle_event)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)

script.on_event(defines.events.on_player_created, on_player_created)

script.on_event(defines.events.on_research_finished, on_research_changed)
script.on_event(defines.events.on_research_reversed, on_research_changed)

script.on_event(defines.events.on_built_entity, on_created_player)
script.on_event(defines.events.on_robot_built_entity, on_created)
script.on_event(defines.events.script_raised_built, on_created)
script.on_event(defines.events.script_raised_revive, on_created)

script.on_event(defines.events.on_marked_for_upgrade, on_upgrade)

script.on_event(defines.events.on_entity_died, on_destroyed)
script.on_event(defines.events.script_raised_destroy, on_destroyed)

script.on_event(defines.events.on_pre_player_mined_item, on_pre_mined)
script.on_event(defines.events.on_marked_for_deconstruction, on_pre_mined)
