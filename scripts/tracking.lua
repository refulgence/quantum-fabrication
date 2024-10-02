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
    if not entity_data then game.print("Entity data not found for " .. entity.name .. " " .. entity.unit_number) return end
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
                add_to_storage({name = name, count = count, type = "item"}, true)
            end
            inventory.clear()
        end
        if entity_data.container_fluid and entity_data.container_fluid.get_fluid_contents() then
            for name, count in pairs(entity_data.container_fluid.get_fluid_contents()) do
                add_to_storage({name = name, count = count, type = "fluid"}, false)
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
                transfer_status = pull_from_storage({name = item_filter, type = "item", count = stack_size}, entity_data.inventory)
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

-- TODO: code it
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