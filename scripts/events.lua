


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
    global.player_gui[event.player_index] = {item_group_selection = 1, selected_tab_index = 1}
end


function on_research_changed(event)
    Research_finished = true
end
script.on_nth_tick(338, function(event)
    if Research_finished then
        process_ingredient_filter()
        process_recipe_enablement()
        Research_finished = false
    end
end)

script.on_nth_tick(Update_rate["destroys"].rate, update_tracked_destroys)
script.on_nth_tick(Update_rate["revivals"].rate, update_tracked_revivals)
script.on_nth_tick(Update_rate["entities"].rate, update_tracked_entities)
script.on_nth_tick(Update_rate["requests"].rate, update_tracked_requests)
script.on_nth_tick(300, update_tracked_dedigitizer_reactors)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_changed)
script.on_init(on_init)
script.on_configuration_changed(on_config_changed)


script.on_event("qf-fabricator-gui-search", on_fabricator_gui_search_event)
script.on_event("qf-fabricator-gui", on_fabricator_gui_toggle_event)
--script.on_event(defines.events.on_lua_shortcut, on_shortcut)

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
