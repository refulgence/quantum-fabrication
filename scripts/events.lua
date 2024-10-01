require "scripts/defabricator"


function on_init()
    global.fabricator_inventory = {}
    global.fabricator_inventory["item"] = {}
    global.fabricator_inventory["fluid"] = {}
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





function create_tracked_entity(entity)
    if not global.tracked_entities[entity.name] then global.tracked_entities[entity.name] = {} end
    local entity_data = {
        entity = entity,
        name = entity.name,
        lag_id = math.random(0, Update_rate["entities"].slots - 1),
    }
    local position = entity.position
    local surface = entity.surface
    local force = entity.force

    if entity.name == "digitizer-chest" then
        entity_data.inventory = entity.get_inventory(defines.inventory.chest)
        local pseudo_fluid_container = surface.create_entity{
            name = "digitizer-chest-fluid",
            position = position,
            force = force
        }
        pseudo_fluid_container.destructible = false
        pseudo_fluid_container.operable = false
        entity_data.container_fluid = pseudo_fluid_container
    elseif entity.name == "dedigitizer-reactor" then
        local pseudo_container = surface.create_entity{
            name = "dedigitizer-reactor-container",
            position = position,
            force = force
        }
        pseudo_container.destructible = false
        pseudo_container.operable = false
        entity_data.container = pseudo_container
        entity_data.inventory = pseudo_container.get_inventory(defines.inventory.chest)

        local pseudo_fluid_container = surface.create_entity{
            name = "dedigitizer-reactor-container-fluid",
            position = position,
            force = force
        }
        pseudo_fluid_container.destructible = false
        pseudo_fluid_container.operable = false
        entity_data.container_fluid = pseudo_fluid_container
        entity_data.item_filter = ""
        entity_data.fluid_filter = ""
        entity_data.item_transfer_status = "inactive"
        entity_data.fluid_transfer_status = "inactive"
    end

    global.tracked_entities[entity.name][entity.unit_number] = entity_data
end


function remove_tracked_entity(entity)
    local entity_data = global.tracked_entities[entity.name][entity.unit_number]
    if entity.name == "digitizer-chest" then
        entity_data.container_fluid.destroy()
    elseif entity.name == "dedigitizer-reactor" then
        entity_data.container.destroy()
        entity_data.container_fluid.destroy()
    end
    global.tracked_entities[entity.name][entity.unit_number] = nil
end

function update_tracked_entities(event)
    local smoothing = event.tick % Update_rate["entities"].slots
    for entity_name, entities in pairs(global.tracked_entities) do
        if entity_name ~= "dedigitizer-reactor" then
            for entity_id, entity_data in pairs(entities) do
                if entity_data.lag_id == smoothing then
                    update_entity(entity_data, entity_id)
                end
            end
        end
    end
end

function update_tracked_dedigitizer_reactors(event)
    if not global.tracked_entities["dedigitizer-reactor"] then return end
    for entity_id, entity_data in pairs(global.tracked_entities["dedigitizer-reactor"]) do
        update_entity(entity_data, entity_id)
    end
end

function update_entity(entity_data, entity_id)
    if entity_data.entity.name == "digitizer-chest" then
        local inventory = entity_data.inventory
        if inventory and not inventory.is_empty() and inventory.get_contents() then
            for name, count in pairs(inventory.get_contents()) do
                add_to_storage({name = name, count = count, type = "item"})
            end
            inventory.clear()
        end
        if entity_data.container_fluid and entity_data.container_fluid.get_fluid_contents() then
            for name, count in pairs(entity_data.container_fluid.get_fluid_contents()) do
                add_to_storage({name = name, count = count, type = "fluid"})
            end
            entity_data.container_fluid.clear_fluid_inside()
        end
        return
    end
    if entity_data.entity.name == "digitizer-combinator" then
        local index = 1
        for _, type in pairs({"item", "fluid"}) do
            for name, count in pairs(global.fabricator_inventory[type]) do
                if count > 0 then
                    local signal = {signal = {type = type, name = name}, count = count}
                    entity_data.entity.get_control_behavior().set_signal(index, signal)
                    index = index + 1
                end
            end
        end
        return
    end
    if entity_data.entity.name == "dedigitizer-reactor" then
        local energy_consumption = 10
        local item_filter = entity_data.item_filter
        local fluid_filter = entity_data.fluid_filter
        local transfer_status

        if entity_data.entity.temperature > MIN_TEMPERATURE then
            if item_filter and item_filter ~= "" then
                local stack_size = game.item_prototypes[item_filter].stack_size
                transfer_status = pull_from_storage({name = item_filter, type = "item", count = stack_size * 5}, entity_data.inventory)
                if transfer_status.empty_storage then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "empty storage"
                    energy_consumption = energy_consumption + 10
                end
                if transfer_status.full_inventory and not transfer_status.empty_storage then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "full inventory"
                    energy_consumption = energy_consumption + 80
                end
                if not transfer_status.empty_storage and not transfer_status.full_inventory then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "active"
                    energy_consumption = energy_consumption + 50
                end
            else
                global.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "inactive"
            end
    
            if fluid_filter and fluid_filter ~= "" then
                transfer_status = pull_from_storage({name = fluid_filter, type = "fluid", amount = 2000}, entity_data.container_fluid)
                if transfer_status.empty_storage then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "empty storage"
                    energy_consumption = energy_consumption + 10
                end
                if transfer_status.full_inventory and not transfer_status.empty_storage then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "full inventory"
                    energy_consumption = energy_consumption + 80
                end
                if not transfer_status.empty_storage and not transfer_status.full_inventory then
                    global.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "active"
                    energy_consumption = energy_consumption + 50
                end
            else
                global.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "inactive"
            end
        end

        if energy_consumption > entity_data.entity.temperature then
            entity_data.entity.temperature = 0
        else
            entity_data.entity.temperature = entity_data.entity.temperature - energy_consumption
        end

        return
    end
    remove_corrupted_memory(entity_data, entity_id)
end


---comment
---@param item table
---@param target_inventory LuaInventory | LuaEntity
---@return table
function pull_from_storage(item, target_inventory)
    if not global.fabricator_inventory[item.type][item.name] then global.fabricator_inventory[item.type][item.name] = 0 end
    local available = global.fabricator_inventory[item.type][item.name]
    local to_be_provided = item.count or item.amount
    local status = {empty_storage = false, full_inventory = false}
    if available == 0 then
        status.empty_storage = true
        return status
    end
    if available < to_be_provided then
        to_be_provided = available
        status.empty_storage = true
    end
    if item.type == "item" then
        local inserted = target_inventory.insert({name = item.name, count = to_be_provided, type = item.type})
        remove_from_storage({type = item.type, name = item.name, count = inserted})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    if item.type == "fluid" then
        local current_fluid = target_inventory.get_fluid_contents()
        for name, amount in pairs(current_fluid) do
            if name == item.name then
                local inserted = target_inventory.insert_fluid{name = item.name, amount = to_be_provided}
                remove_from_storage({type = item.type, name = item.name, amount = inserted})
                if inserted < to_be_provided then
                    status.full_inventory = true
                end
                return status
            else
                add_to_storage({name = name, amount = target_inventory.remove_fluid{name = name, amount = amount}, type = "fluid"})
            end
        end
        local inserted = target_inventory.insert_fluid{name = item.name, amount = to_be_provided}
        remove_from_storage({type = item.type, name = item.name, amount = inserted})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    return status
end

function remove_corrupted_memory(entity_data, entity_id)
    game.print("Removing corrupted memory for " .. entity_data.entity.name .. " " .. entity_id)
    global.tracked_entities[entity_data.name][entity_data.unit_number] = nil
end

---comment
---@param request_table table
function create_tracked_request(request_table)
    local request_data = {
        entity = request_table.entity,
        player_index = request_table.player_index,
        lag_id = math.random(0, Update_rate["requests"].slots - 1),
    }
    if request_table.request_type == "upgrades" then
        request_data.target = request_table.upgrade_target
    elseif request_table.request_type == "modules" then
        request_data.item_request_proxy = request_table.item_request_proxy
    end
    global.tracked_requests[request_table.request_type][request_table.entity.unit_number] = request_data
end

function remove_tracked_request(request_type, request_id)
    global.tracked_requests[request_type][request_id] = nil
end

function update_tracked_requests(event)
    local smoothing = event.tick % Update_rate["requests"].slots
    for request_type, requests in pairs(global.tracked_requests) do
        for request_id, request_data in pairs(requests) do
            if request_data.lag_id == smoothing then
                update_request(request_data, request_type, request_id)
            end
        end
    end
end

function update_tracked_revivals(event)
    local smoothing = event.tick % Update_rate["revivals"].slots
    for request_id, request_data in pairs(global.tracked_requests["revivals"]) do
        if request_data.lag_id == smoothing then
            update_request(request_data, "revivals", request_id)
        end
    end
end

function update_tracked_destroys(event)
    local smoothing = event.tick % Update_rate["destroys"].slots
    for request_id, request_data in pairs(global.tracked_requests["destroys"]) do
        if request_data.lag_id == smoothing then
            update_request(request_data, "destroys", request_id)
        end
    end
end

function update_request(request_data, request_type, request_id)
    local entity = request_data.entity
    if not entity or not entity.valid then remove_tracked_request(request_type, request_id) return end
    local player_index = request_data.player_index

    if request_type == "revivals" then
        remove_tracked_request(request_type, request_id)
        if not instant_fabrication(entity, player_index) then create_tracked_request({entity = entity, player_index = player_index, request_type = "construction"}) end
    elseif request_type == "destroys" then
        if instant_defabrication(entity, player_index) then remove_tracked_request(request_type, request_id) end
    elseif request_type == "upgrades" then
        if instant_upgrade(entity, request_data.target, player_index) then remove_tracked_request(request_type, request_id) end
    elseif request_type == "construction" then
        if instant_fabrication(entity, player_index) then remove_tracked_request(request_type, request_id) end
    elseif request_type == "modules" then
        local modules = request_data.item_request_proxy.item_requests
        local player_inventory = game.players[player_index].get_inventory(defines.inventory.character_main)
        if not player_inventory then game.print("Player inventory error?") return end
        if not modules then remove_tracked_request(request_type, request_id) end
        if add_modules(entity.entity, modules, player_inventory) then remove_tracked_request(request_type, request_id) end
    end
end



script.on_nth_tick(338, function(event)
    if Research_finished then
        process_ingredient_filter()
        process_recipe_enablement()
        Research_finished = false
    end
end)



function on_created(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "digitizer-combinator" or entity.name == "dedigitizer-reactor" then create_tracked_entity(entity) end
    end
end

function on_created_player(event)
    if event.created_entity and event.created_entity.valid then
        if event.created_entity.type == "entity-ghost" then
            create_tracked_request({entity = event.created_entity, player_index = event.player_index, request_type = "revivals"})
        end
        on_created(event)
    end
end


function on_destroyed(event)
    local entity = event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "digitizer-combinator" or entity.name == "dedigitizer-reactor" then remove_tracked_entity(entity) end
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
    end
end



-- Event on deconstruction
function on_upgrade(event)
    local entity = event.entity
    local target = event.target
    local player_index = event.player_index

    if entity and entity.valid and player_index then
        if not instant_upgrade(entity, target, player_index) then create_tracked_request({entity = entity, player_index = player_index, upgrade_target = target, request_type = "upgrades"}) end
    end
end


---comment
---@param entity LuaEntity
---@param target LuaEntityPrototype
---@param player_index int
---@return boolean
function instant_upgrade(entity, target, player_index)
    local player = game.get_player(player_index)
    if not player then return false end
    local player_inventory = player.get_inventory(defines.inventory.character_main)
    if not player_inventory then return false end
    local recipe = get_craftable_recipe(target.name, player_inventory)
    if not recipe then return false end
    local upgraded_entity = entity.surface.create_entity{
        name = target.name,
        position = entity.position,
        direction = entity.direction,
        force = entity.force,
        fast_replace = true,
        player = player,
        raise_built = true,}
    if upgraded_entity then
        fabricate_recipe(recipe, player_inventory)
        remove_from_storage({name = target.name, count = 1, type = "item"})
        return true
    end
    return false
end

---comment
---@param item table
function remove_from_storage(item)
    if not item then return end
    global.fabricator_inventory[item.type][item.name] = global.fabricator_inventory[item.type][item.name] - (item.count or item.amount)
end

---comment
---@param item table
function add_to_storage(item)
    if not item then return end
    if not global.fabricator_inventory[item.type][item.name] then global.fabricator_inventory[item.type][item.name] = 0 end
    global.fabricator_inventory[item.type][item.name] = global.fabricator_inventory[item.type][item.name] + (item.count or item.amount)
end


function on_player_created(event)
    fill_dictionary(event.player_index)
    global.player_gui[event.player_index] = {item_group_selection = 1, selected_tab_index = 1}
end



---comment
---@param event any
function on_fabricator_gui_toggle_event(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then return end
    toggle_fabricator_gui(player)
end

function on_shortcut(event)
    if event.prototype_name == "qf-fabricator-gui" then
        on_fabricator_gui_toggle_event(event)
    end
end



function on_research_changed(event)
    Research_finished = true
end

script.on_nth_tick(Update_rate["destroys"].rate, update_tracked_destroys)
script.on_nth_tick(Update_rate["revivals"].rate, update_tracked_revivals)
script.on_nth_tick(Update_rate["entities"].rate, update_tracked_entities)
script.on_nth_tick(Update_rate["requests"].rate, update_tracked_requests)
script.on_nth_tick(300, update_tracked_dedigitizer_reactors)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_changed)
script.on_init(on_init)
script.on_configuration_changed(on_config_changed)


script.on_event("qf-fabricator-gui", on_fabricator_gui_toggle_event)
script.on_event(defines.events.on_lua_shortcut, on_shortcut)

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
