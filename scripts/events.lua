
---@class QSPrototypeData
---@field name string
---@field type string
---@field localised_name LocalisedString
---@field localised_description LocalisedString
---@field item_name string




function on_init()
    flib_dictionary.on_init()
    build_dictionaries()
    storage.fabricator_inventory = {item = {}, fluid = {}}
    storage.unpacked_recipes = {}
    storage.placeable = {}
    storage.recipe = {}
    storage.modules = {}
    storage.ingredient = {}
    storage.ingredient_filter = {}
    storage.player_gui = {}
    storage.options = {}
    storage.options.auto_recheck_item_request_proxies = false
    storage.tracked_entities = {}
    storage.tracked_requests = {construction = {}, modules = {}, upgrades = {}, revivals = {}, destroys = {}}
    ---@type table <string, QSPrototypeData>
    storage.prototypes_data = {}
    if not Actual_non_duplicates then Actual_non_duplicates = {} end
    process_data()
end

function on_config_changed()
    flib_dictionary.on_configuration_changed()
    build_dictionaries()
    process_data()
end

function on_mod_settings_changed()
end


function on_created_player(event)
    if event.entity and event.entity.valid then
        if event.entity.type == "entity-ghost" then
            create_tracked_request({entity = event.entity, player_index = event.player_index, request_type = "revivals"})
        end
        on_created(event)
    end
end

function on_created(event)
    local entity = event.entity or event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "digitizer-combinator" or entity.name == "dedigitizer-reactor" then create_tracked_entity(entity) end
    end
end

function on_pre_mined(event)
    local entity = event.entity
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if entity.can_be_destroyed() and entity.type ~= "entity-ghost" then
            if storage.prototypes_data[entity.name] then
                local item_name = storage.prototypes_data[entity.name].item_name
                if utils.is_placeable(item_name) then
                    if not storage.fabricator_inventory.item[item_name] then storage.fabricator_inventory.item[item_name] = 0 end
                    instant_defabrication(entity, player_index)
                end
            end
        end
    end
end

function on_deconstructed(event)
    local entity = event.entity
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if entity.can_be_destroyed() and entity.type ~= "entity-ghost" then
            if entity.prototype.type == "tree" or entity.prototype.type == "simple-entity" or entity.prototype.type == "item-entity" then
                instant_deforestation(entity, player_index)
            elseif storage.prototypes_data[entity.name] then
                local item_name = storage.prototypes_data[entity.name].item_name
                if utils.is_placeable(item_name) then
                    if not storage.fabricator_inventory.item[item_name] then storage.fabricator_inventory.item[item_name] = 0 end
                    create_tracked_request({entity = entity, player_index = player_index, request_type = "destroys"})
                end
            end
        end
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
    storage.player_gui[event.player_index] = {
        item_group_selection = 1,
        selected_tab_index = 1,
        tooltip_workaround = 0,
        show_storage = false,
        fabricator_gui_position = nil,
        options = {
            calculate_numbers = true,
            mark_red = true,
            sort_ingredients = 1
        }
    }
end



function sort_ingredients(player_index, sort_type)
    for _, recipe in pairs(storage.unpacked_recipes) do
        if sort_type == "item_name" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.name < b.name end)
        elseif sort_type == "amount" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.amount < b.amount end)
        elseif sort_type == "localised_name" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return get_translation(player_index, a.name, "unknown") < get_translation(player_index, b.name, "unknown") end)
        end
    end
end

function on_player_joined_game(event)
    flib_dictionary.on_player_joined_game(event)
end
  
function on_tick(event)
    flib_dictionary.on_tick(event)
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
        storage.fabricator_inventory = {item = {}, fluid = {}}
        game.print("CHEAT(?): Fabricator inventory cleared")
    elseif name == "qf_update_module_requests" then
        update_lost_module_requests(game.players[player_index])
        game.print("Updating item request proxy tracking")
    end
end


function debug_storage(amount, everything)
    if not everything then
        for material, _ in pairs(storage.ingredient) do
            local type = item_type_check(material)
            if not storage.fabricator_inventory[type][material] then storage.fabricator_inventory[type][material] = 0 end
            add_to_storage({name = material, amount = amount, type = type}, false)
        end
    else
        for _, item in pairs(prototypes.item) do
            if not storage.fabricator_inventory["item"][item.name] then storage.fabricator_inventory["item"][item.name] = 0 end
            add_to_storage({name = item.name, amount = amount, type = "item"}, false)
        end
        for _, fluid in pairs(prototypes.fluid) do
            if not storage.fabricator_inventory["fluid"][fluid.name] then storage.fabricator_inventory["fluid"][fluid.name] = 0 end
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

commands.add_command("qf_update_module_requests", nil, on_console_command)
commands.add_command("qf_hesoyam", nil, on_console_command)
commands.add_command("qf_hesoyam_harder", nil, on_console_command)
commands.add_command("qf_clear_storage", nil, on_console_command)

script.on_nth_tick(Update_rate.destroys.rate, update_tracked_destroys)
script.on_nth_tick(Update_rate.revivals.rate, update_tracked_revivals)
script.on_nth_tick(Update_rate.entities.rate, update_tracked_entities)
script.on_nth_tick(Update_rate.requests.rate, update_tracked_requests)
script.on_nth_tick(Update_rate.reactors, update_tracked_dedigitizer_reactors)

script.on_nth_tick(Update_rate.item_request_proxy_recheck, function(event)
    if storage.options.auto_recheck_item_request_proxies then update_lost_module_requests(game.connected_players[1]) end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_changed)
script.on_init(on_init)
script.on_configuration_changed(on_config_changed)

script.on_event(defines.events.on_string_translated, on_string_translated)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_tick, on_tick)

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
script.on_event(defines.events.on_player_mined_entity, on_destroyed)

script.on_event(defines.events.on_pre_player_mined_item, on_pre_mined)
script.on_event(defines.events.on_marked_for_deconstruction, on_deconstructed)
