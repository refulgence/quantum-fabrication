---@diagnostic disable: need-check-nil
local qs_utils = require("scripts/qs_utils")

--@diagnostic disable: need-check-nil
---@class tracking
local tracking = {}

---@class RequestData
---@field entity LuaEntity
---@field player_index uint
---@field request_type "entities"|"revivals"|"destroys"|"upgrades"|"construction"|"item_requests"|"cliffs"|"tiles"
---@field target? LuaEntityPrototype
---@field quality? string
---@field item_request_proxy? LuaEntity
---@field lag_id? uint

---@class EntityData
---@field entity LuaEntity
---@field name string
---@field surface_index uint
---@field lag_id uint
---@field inventory? LuaInventory
---@field container? LuaEntity
---@field container_fluid? LuaEntity
---@field item_filter? string
---@field fluid_filter? string
---@field item_transfer_status? string
---@field fluid_transfer_status? string


---Creates a request to be executed later if conditions are met
---@param request_data RequestData
function tracking.create_tracked_request(request_data)
    local request_type = request_data.request_type
    if request_type == "entities" then
        tracking.add_tracked_entity(request_data)
    else
        tracking.add_request(request_data)
    end
end


---@param request_data RequestData
function tracking.add_request(request_data)
    local request_type = request_data.request_type
    local request_table = {
        entity = request_data.entity,
        player_index = request_data.player_index,
        lag_id = math.random(0, Update_rate.requests.slots - 1),
    }
    local index
    if request_type == "upgrades" then
        request_data.target = request_table.upgrade_target
        request_data.quality = request_table.quality
    elseif request_type == "item_requests" then
        request_data.item_request_proxy = request_table.item_request_proxy
    end

    if request_type == "cliffs" or request_type == "tiles" then
        storage.request_ids[request_type] = storage.request_ids[request_type] + 1
        index = storage.request_ids[request_type]
    else
        index = request_table.entity.unit_number
    end

    storage.tracked_requests[request_type][index] = request_table
end


---@param request_type any
---@param request_id any
function tracking.remove_tracked_request(request_type, request_id)
    storage.tracked_requests[request_type][request_id] = nil
end


---@param tick uint
---@param request_types? table
function tracking.update_tracked_requests(tick, request_types)
    local smoothing = tick % Update_rate.requests.slots
    if not request_types then request_types = {"construction", "item_requests", "upgrades", "revivals", "destroys", "cliffs", "tiles"} end
    for _, request_type in pairs(request_types) do
        local requests = storage.tracked_requests[request_type]
        for request_id, request_data in pairs(requests) do
            if request_data.lag_id == smoothing then
                tracking.update_request(request_data, request_type, request_id)
            end
        end
    end
end


---@param request_data RequestData
---@param request_type "construction"|"item_requests"|"upgrades"|"revivals"|"destroys"|"cliffs"|"tiles"
---@param request_id uint
function tracking.update_request(request_data, request_type, request_id)
    local entity = request_data.entity
    if not entity or not entity.valid then tracking.remove_tracked_request(request_type, request_id) return end
    local player_index = request_data.player_index

    if request_type == "revivals" then
        tracking.remove_tracked_request(request_type, request_id)
        if not instant_fabrication(entity, player_index) then
            tracking.create_tracked_request({
                entity = entity,
                player_index = player_index,
                request_type = "construction"
            })
        end
    elseif request_type == "destroys" then
        if instant_defabrication(entity, player_index) then
            tracking.remove_tracked_request(request_type, request_id)
        end
    elseif request_type == "upgrades" then
        if instant_upgrade(entity, request_data.target, request_data.quality, player_index) then
            tracking.remove_tracked_request(request_type, request_id)
        end
    elseif request_type == "construction" then
        if instant_fabrication(entity, player_index) then
            tracking.remove_tracked_request(request_type, request_id)
        end
    elseif request_type == "tiles" then
        -- TODO: try to support tile construction with new tech
        --if instant_fabrication(entity, player_index) then
        --    tracking.remove_tracked_request(request_type, request_id)
        --end
    elseif request_type == "cliffs" then
        if instant_decliffing(entity, player_index) then
            tracking.remove_tracked_request(request_type, request_id)
        end
    elseif request_type == "item_requests" then
        if not request_data.item_request_proxy or not request_data.item_request_proxy.valid then
            tracking.remove_tracked_request(request_type, request_id)
            return
        end
        local modules = request_data.item_request_proxy.item_requests
        if not modules then
            tracking.remove_tracked_request(request_type, request_id)
            request_data.item_request_proxy.destroy()
            return
        end
        local player_inventory = game.players[player_index].get_inventory(defines.inventory.character_main)
        if add_modules(entity, modules, player_inventory) then
            tracking.remove_tracked_request(request_type, request_id)
            request_data.item_request_proxy.destroy()
        end
    end
end


function tracking.update_lost_module_requests(player)
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{name = "item-request-proxy"}) do
            if not storage.tracked_requests["item_requests"][entity.proxy_target.unit_number] or storage.tracked_requests["item_requests"][entity.proxy_target.unit_number] ~= {} then
                tracking.create_tracked_request({
                    entity = entity.proxy_target,
                    player_index = player.index,
                    item_request_proxy = entity,
                    request_type = "item_requests"
                })
            end
        end
    end
end









---Adds an entity to be tracked and creates necessary hidden entities
---@param request_data RequestData
function tracking.add_tracked_entity(request_data)
    local entity = request_data.entity
    if not storage.tracked_entities[entity.name] then storage.tracked_entities[entity.name] = {} end

    local entity_data = {
        entity = entity,
        name = entity.name,
        surface_index = entity.surface_index,
        lag_id = math.random(0, Update_rate.entities.slots - 1),
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
        ---@diagnostic disable-next-line: need-check-nil
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
    storage.tracked_entities[entity.name][entity.unit_number] = entity_data

end


---Remove tracked entity from the data and clear hidden entities
---@param entity LuaEntity
function tracking.remove_tracked_entity(entity)
    local entity_data = storage.tracked_entities[entity.name][entity.unit_number]
    if not entity_data then return end
    if entity.name == "digitizer-chest" then
        entity_data.container_fluid.destroy()
    elseif entity.name == "dedigitizer-reactor" then
        entity_data.container.destroy()
        entity_data.container_fluid.destroy()
    end
    storage.tracked_entities[entity.name][entity.unit_number] = nil
end


---@param tick uint
---@param entity_names? table
function tracking.update_tracked_entities(tick, entity_names)
    local smoothing = tick % Update_rate.entities.slots
    if not entity_names then entity_names = {"dedigitizer-reactor", "digitizer-chest"} end
    for _, entity_name in pairs(entity_names) do
        local entities = storage.tracked_entities[entity_name]
        if entities then
            for entity_id, entity_data in pairs(entities) do
                if entity_data.lag_id == smoothing then
                    tracking.update_entity(entity_data, entity_id)
                end
            end
        end
    end
end


function tracking.update_entity(entity_data, entity_id)
    local surface_index = entity_data.surface_index

    if entity_data.entity.name == "digitizer-chest" then
        local inventory = entity_data.inventory
        local limit_value = entity_data.entity.get_signal({type = "virtual", name = "signal-L"}, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
        if inventory and not inventory.is_empty() then
            local inventory_contents = inventory.get_contents()
            for _, item in pairs(inventory_contents) do
                local qs_item = qs_utils.to_qs_item({
                    name = item.name,
                    count = item.count,
                    type = "item",
                    quality = item.quality,
                    surface_index = surface_index
                })
                if limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value then
                    qs_utils.add_to_storage(qs_item, true)
                    inventory.remove({name = item.name, count = item.count, quality = item.quality})
                end
            end
        end
        if entity_data.container_fluid and entity_data.container_fluid.get_fluid_contents() then
            local clear
            for name, count in pairs(entity_data.container_fluid.get_fluid_contents()) do
                local qs_item = qs_utils.to_qs_item({
                    name = name,
                    count = count,
                    type = "fluid",
                    surface_index = surface_index
                })
                if limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value then
                    qs_utils.add_to_storage(qs_item)
                    clear = true
                end
            end
            if clear then entity_data.container_fluid.clear_fluid_inside() end
        end
        return
    end

    -- Ok, filters are broken because they are tables now, so we need to rework it later
    if entity_data.entity.name == "dedigitizer-reactor" then
        local energy_consumption = Reactor_constants.idle_cost
        local item_filter = entity_data.item_filter
        local fluid_filter = entity_data.fluid_filter
        local transfer_status

        if entity_data.entity.temperature > Reactor_constants.min_temperature then
            if item_filter and item_filter ~= "" then
                local qs_item = qs_utils.to_qs_item({
                    name = item_filter.name,
                    count = Reactor_constants.item_transfer_rate,
                    type = "item",
                    quality = item_filter.quality,
                    surface_index = surface_index
                })
                transfer_status = qs_utils.pull_from_storage(qs_item, entity_data.inventory)
                if transfer_status.empty_storage then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "empty storage"
                    energy_consumption = energy_consumption + Reactor_constants.empty_storage_cost
                end
                if transfer_status.full_inventory and not transfer_status.empty_storage then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "full inventory"
                    energy_consumption = energy_consumption + Reactor_constants.full_inventory_cost
                end
                if not transfer_status.empty_storage and not transfer_status.full_inventory then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "active"
                    energy_consumption = energy_consumption + Reactor_constants.active_cost
                end
            else
                storage.tracked_entities["dedigitizer-reactor"][entity_id].item_transfer_status = "inactive"
            end
    
            if fluid_filter and fluid_filter ~= "" then
                local qs_item = qs_utils.to_qs_item({
                    name = fluid_filter.name,
                    count = Reactor_constants.item_transfer_rate,
                    type = "fluid",
                    surface_index = surface_index
                })
                transfer_status = qs_utils.pull_from_storage(qs_item, entity_data.container_fluid)
                if transfer_status.empty_storage then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "empty storage"
                    energy_consumption = energy_consumption + Reactor_constants.empty_storage_cost
                end
                if transfer_status.full_inventory and not transfer_status.empty_storage then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "full inventory"
                    energy_consumption = energy_consumption + Reactor_constants.full_inventory_cost
                end
                if not transfer_status.empty_storage and not transfer_status.full_inventory then
                    storage.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "active"
                    energy_consumption = energy_consumption + Reactor_constants.active_cost
                end
            else
                storage.tracked_entities["dedigitizer-reactor"][entity_id].fluid_transfer_status = "inactive"
            end
        end

        if energy_consumption > entity_data.entity.temperature then
            entity_data.entity.temperature = 0
        else
            entity_data.entity.temperature = entity_data.entity.temperature - energy_consumption
        end

        return
    end
end





return tracking