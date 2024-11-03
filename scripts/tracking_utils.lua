---@diagnostic disable: need-check-nil
local qs_utils = require("scripts/qs_utils")
local flib_table = require("__flib__.table")

--@diagnostic disable: need-check-nil
---@class tracking
local tracking = {}

---@class RequestData
---@field entity? LuaEntity
---@field player_index? uint
---@field request_type "entities"|"revivals"|"destroys"|"upgrades"|"construction"|"item_requests"|"cliffs"|"repairs"
---@field target? LuaEntityPrototype
---@field quality? string
---@field item_request_proxy? LuaEntity
---@field lag_id? uint
---@field position? TilePosition

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
        request_table.target = request_data.target
        request_table.quality = request_data.quality
    elseif request_type == "item_requests" then
        request_table.item_request_proxy = request_data.item_request_proxy
    end

    if request_type == "cliffs" then
        storage.cliff_ids = storage.cliff_ids + 1
        index = storage.cliff_ids
    else
        index = request_table.entity.unit_number
    end
    request_table.index = index

    storage.tracked_requests[request_type][index] = request_table
end


---@param request_type "revivals"|"destroys"|"upgrades"|"construction"|"item_requests"|"cliffs"|"repairs"
---@param request_id uint
function tracking.remove_tracked_request(request_type, request_id)
    storage.tracked_requests[request_type][request_id] = nil
end


---@param tick uint
---@param request_types? table
function tracking.update_tracked_requests(tick, request_types)
    local smoothing = tick % Update_rate.requests.slots
    if not request_types then request_types = {"construction", "item_requests", "cliffs"} end
    for _, request_type in pairs(request_types) do
        local requests = storage.tracked_requests[request_type]
        for request_id, request_data in pairs(requests) do
            if request_data.lag_id == smoothing then
                tracking.update_request(request_data, request_type, request_id)
            end
        end
    end
end

function tracking.on_tick_update_requests()
    for i = 1, 3 do
        if next(storage.tracked_requests[On_tick_requests[i]]) then
            storage.request_ids[On_tick_requests[i]] = flib_table.for_n_of(storage.tracked_requests[On_tick_requests[i]], storage.request_ids[On_tick_requests[i]], 3, function(entity)
                return tracking.on_tick_update_handler(entity, On_tick_requests[i])
            end)
        end
    end
end

script.on_nth_tick(5, function(event)
    if next(storage.tracked_requests["repairs"]) and not storage.countdowns.in_combat then
        storage.request_ids["repairs"] = flib_table.for_n_of(storage.tracked_requests["repairs"], storage.request_ids["repairs"], 2, function(request_table)
            if not request_table.entity.valid then return nil, true, false end
            local player_index = storage.request_player_ids["repairs"]
            if instant_repair(request_table.entity, player_index) then
                return nil, true, false
            else
                return nil, false, false
            end
        end)
    end
end)

script.on_nth_tick(9, function(event)
    if next(storage.tracked_requests["item_requests"]) then
        storage.request_ids["item_requests"] = flib_table.for_n_of(storage.tracked_requests["item_requests"], storage.request_ids["item_requests"], 2, function(request_table)
            return tracking.update_item_request_proxy(request_table)
        end)
    end
end)


script.on_nth_tick(19, function(event)
    if next(storage.tracked_requests["cliffs"]) then
        storage.request_ids["cliffs"] = flib_table.for_n_of(storage.tracked_requests["cliffs"], storage.request_ids["cliffs"], 3, function(request_table)
            if not request_table.entity.valid then return nil, true, false end
            if instant_decliffing(request_table.entity) then
                return nil, true, false
            else
                return nil, false, false
            end
        end)
    end
end)


function tracking.update_item_request_proxy(request_table)
    local entity = request_table.entity
    if not entity.valid then return nil, true, false end
    local item_request_proxy = request_table.item_request_proxy
    local player_index = request_table.player_index
    
    if not item_request_proxy or not item_request_proxy.valid then
        return nil, true, false
    end
    local modules = item_request_proxy.item_requests
    if not modules then
        request_table.item_request_proxy.destroy()
        return nil, true, false
    end
    local player_inventory
    if player_index then
        player_inventory = game.get_player(player_index).get_inventory(defines.inventory.character_main)
    end
    if handle_item_requests(entity, modules, player_inventory) then
        request_table.item_request_proxy.destroy()
        return nil, true, false
    end
    return nil, false, false
end



function tracking.on_tick_update_handler(entity, request_type)
    if not entity.valid then return nil, true, false end
    local player_index = storage.request_player_ids[request_type]

    if request_type == "revivals" then
        if not instant_fabrication(entity, player_index) then
            tracking.create_tracked_request({
                entity = entity,
                player_index = player_index,
                request_type = "construction"
            })
        end
        return nil, true, false
    elseif request_type == "destroys" then
        if instant_defabrication(entity, player_index) then
            return nil, true, false
        else
            return nil, false, false
        end
    elseif request_type == "upgrades" then
        local target, quality_prototype = entity.get_upgrade_target()
        if not target then return nil, true, false end
        local quality
        if not quality_prototype then
            quality = QS_DEFAULT_QUALITY
        else
            quality = quality_prototype.name
        end
        local status = instant_upgrade(entity, target, quality, player_index)
        if status == "success" then
            return nil, true, false
        end
--[[     elseif request_type == "repairs" then
        if not instant_repair(entity, player_index) then
            return nil, false, false
        else
            return nil, true, false
        end ]]
    end

end






---@param request_data RequestData
---@param request_type "construction"|"item_requests"|"upgrades"|"revivals"|"destroys"|"cliffs"
---@param request_id uint
function tracking.update_request(request_data, request_type, request_id)
    local entity = request_data.entity
    if not entity or not entity.valid then tracking.remove_tracked_request(request_type, request_id) return end
    local player_index = request_data.player_index

    if request_type == "construction" then
        if instant_fabrication(entity, player_index) then
            tracking.remove_tracked_request(request_type, request_id)
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
        entity_data.lag_id = 0
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
                    tracking.update_entity(entity_data)
                end
            end
        end
    end
end


function tracking.update_entity(entity_data)
    local surface_index = entity_data.surface_index

    if entity_data.entity.name == "digitizer-chest" then
        local inventory = entity_data.inventory
        local limit_value = entity_data.entity.get_signal({type = "virtual", name = "signal-L"}, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
        if inventory and not inventory.is_empty() then
            local inventory_contents = inventory.get_contents()
            for _, item in pairs(inventory_contents) do
                local qs_item = {
                    name = item.name,
                    count = item.count,
                    type = "item",
                    quality = item.quality,
                    surface_index = surface_index
                }
                if limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value then
                    qs_utils.add_to_storage(qs_item, true)
                    inventory.remove({name = item.name, count = item.count, quality = item.quality})
                end
            end
        end
        if entity_data.container_fluid and entity_data.container_fluid.get_fluid_contents() then
            local clear
            for name, count in pairs(entity_data.container_fluid.get_fluid_contents()) do
                local qs_item = {
                    name = name,
                    count = count,
                    type = "fluid",
                    quality = QS_DEFAULT_QUALITY,
                    surface_index = surface_index
                }
                if limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value then
                    qs_utils.add_to_storage(qs_item)
                    clear = true
                end
            end
            if clear then entity_data.container_fluid.clear_fluid_inside() end
        end
        return
    end

    if entity_data.entity.name == "dedigitizer-reactor" then
        local energy_consumption = Reactor_constants.idle_cost
        local energy_consumption_multiplier = 1
        local transfer_rate_multiplier = 1

        if entity_data.entity.temperature > Reactor_constants.min_temperature then
            local signals = entity_data.entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            if signals then
                local item_filter
                local fluid_filter
                local quality_filter
                local surface_id
                local highest_count_item = 0
                local highest_count_fluid = 0
                local highest_count_quality = 0
                for _, signal in pairs(signals) do
                    if signal.signal.type == "item" or signal.signal.type == nil then
                        if signal.count > highest_count_item then
                            highest_count_item = signal.count
                            item_filter = signal.signal.name
                        end
                    elseif signal.signal.type == "fluid" then
                        if signal.count > highest_count_fluid then
                            highest_count_fluid = signal.count
                            fluid_filter = signal.signal.name
                        end
                    elseif signal.signal.type == "virtual" and signal.signal.name == "signal-S" then
                        surface_id = signal.count
                    elseif signal.signal.type == "quality" then
                        if signal.count > highest_count_quality then
                            highest_count_quality = signal.count
                            quality_filter = signal.signal.name
                        end
                    end
                end

                if not quality_filter then
                    quality_filter = QS_DEFAULT_QUALITY
                end
                if surface_id and surface_id ~= surface_index and storage.fabricator_inventory[surface_id] then
                    energy_consumption_multiplier = 5
                    transfer_rate_multiplier = 0.5
                else
                    surface_id = surface_index
                end
                if item_filter then
                    local qs_item = {
                        name = item_filter,
                        count = Reactor_constants.item_transfer_rate * transfer_rate_multiplier,
                        type = "item",
                        quality = quality_filter,
                        surface_index = surface_id
                    }
                    transfer_status = qs_utils.pull_from_storage(qs_item, entity_data.inventory)
                    if transfer_status.empty_storage then
                        energy_consumption = energy_consumption + Reactor_constants.empty_storage_cost
                    end
                    if transfer_status.full_inventory and not transfer_status.empty_storage then
                        energy_consumption = energy_consumption + Reactor_constants.full_inventory_cost
                    end
                    if not transfer_status.empty_storage and not transfer_status.full_inventory then
                        energy_consumption = energy_consumption + Reactor_constants.active_cost
                    end
                end

                if fluid_filter then
                    local qs_item = {
                        name = fluid_filter,
                        count = Reactor_constants.fluid_transfer_rate * transfer_rate_multiplier,
                        type = "fluid",
                        quality = QS_DEFAULT_QUALITY,
                        surface_index = surface_id
                    }
                    transfer_status = qs_utils.pull_from_storage(qs_item, entity_data.container_fluid)
                    if transfer_status.empty_storage then
                        energy_consumption = energy_consumption + Reactor_constants.empty_storage_cost
                    end
                    if transfer_status.full_inventory and not transfer_status.empty_storage then
                        energy_consumption = energy_consumption + Reactor_constants.full_inventory_cost
                    end
                    if not transfer_status.empty_storage and not transfer_status.full_inventory then
                        energy_consumption = energy_consumption + Reactor_constants.active_cost
                    end
                end



            end
        end

        if energy_consumption > entity_data.entity.temperature then
            entity_data.entity.temperature = 0
        else
            entity_data.entity.temperature = entity_data.entity.temperature - (energy_consumption * energy_consumption_multiplier)
        end

        return
    end
end





return tracking