---@diagnostic disable: need-check-nil
local qs_utils = require("scripts/qs_utils")
local flib_table = require("__flib__.table")
local utils = require("scripts/utils")

--@diagnostic disable: need-check-nil
---@class tracking
local tracking = {}

---@class RequestData
---@field entity LuaEntity
---@field player_index? uint
---@field request_type "entities"|"revivals"|"destroys"|"upgrades"|"construction"|"item_requests"|"cliffs"|"repairs"
---@field target? LuaEntityPrototype
---@field quality? string
---@field item_request_proxy? LuaEntity
---@field position? TilePosition

---@class EntityData
---@field entity? LuaEntity
---@field name string
---@field surface_index uint
---@field settings EntitySettings
---@field inventory? LuaInventory
---@field container? LuaEntity
---@field container_fluid? LuaEntity
---@field item_filter? string
---@field fluid_filter? string
---@field item_transfer_status? string
---@field fluid_transfer_status? string
---@field burnt_result_inventory? LuaInventory
---@field unit_number uint

---@class EntitySettings
---@field intake_limit? uint
---@field item_filter? { name: string?, quality: string? }
---@field fluid_filter? string
---@field surface_index? uint
---@field decraft? boolean

---Creates a request to be executed later if conditions are met
---@param request_data RequestData
function tracking.create_tracked_request(request_data)
    if not request_data.entity.valid then return end
    local request_type = request_data.request_type
    if request_type == "entities" then
        tracking.add_tracked_entity(request_data)
    else
        tracking.add_request(request_data)
    end
end

---Checks all surfaces and tracks trackable entities that aren't tracked yet
function tracking.recheck_trackable_entities()
    for _, surface in pairs(game.surfaces) do
        for entity_name, _ in pairs(Trackable_entities) do
            local entities = surface.find_entities_filtered { name = entity_name }
            for _, entity in pairs(entities) do
                if not storage.tracked_entities[entity_name][entity.unit_number] then
                    tracking.create_tracked_request({ request_type = "entities", entity = entity })
                end
            end
        end
    end
end

---@param request_data RequestData
function tracking.add_request(request_data)
    local request_type = request_data.request_type
    local request_table = {
        entity = request_data.entity,
        player_index = request_data.player_index,
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
            if instant_repair(request_table.entity) then
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
            if instant_decliffing(request_table.entity, request_table.player_index) then
                return nil, true, false
            else
                return nil, false, false
            end
        end)
    end
end)

script.on_nth_tick(Update_rate.chests.nth_tick, function(event)
    for i = 1, Update_rate.chests.per_tick do
        if next(storage.tracked_entities["digitizer-chest"]) then
            storage.request_ids["digitizer-chest"] = flib_table.for_n_of(storage.tracked_entities["digitizer-chest"], storage.request_ids["digitizer-chest"], 2, function(entity_data)
                tracking.update_entity(entity_data)
            end)
        end
    end
end)

script.on_nth_tick(84, function(event)
    if next(storage.tracked_entities["qf-storage-reader"]) then
        storage.request_ids["qf-storage-reader"] = flib_table.for_n_of(storage.tracked_entities["qf-storage-reader"], storage.request_ids["qf-storage-reader"], 2, function(entity_data)
            tracking.update_entity(entity_data)
        end)
    end
end)

script.on_nth_tick(8, function(event)
    if next(storage.tracked_requests["construction"]) then
        storage.request_ids["construction"] = flib_table.for_n_of(storage.tracked_requests["construction"], storage.request_ids["construction"], 3, function(request_table)
            local entity = request_table.entity
            local player_index = request_table.player_index
            if not entity.valid then return nil, true, false end
            if instant_fabrication(entity, player_index) then
                return nil, true, false
            else
                return nil, false, false
            end
        end)
    end
end)

---@param request_table RequestData
---@return nil
---@return boolean --true to remove the request from the table, false to keep it
---@return boolean
function tracking.update_item_request_proxy(request_table)
    local entity = request_table.entity
    if not entity.valid then return nil, true, false end
    local item_request_proxy = request_table.item_request_proxy
    if not item_request_proxy.valid then return nil, true, false end
    local insert_plan = item_request_proxy.insert_plan
    local removal_plan = item_request_proxy.removal_plan
    local player_index = request_table.player_index
    
    if not item_request_proxy or not item_request_proxy.valid then
        return nil, true, false
    end
    if not next(insert_plan) and not next(removal_plan) then
        request_table.item_request_proxy.destroy()
        return nil, true, false
    end
    local player_inventory = utils.get_player_inventory(nil, player_index)
    if handle_item_requests(entity, item_request_proxy.item_requests, insert_plan, removal_plan, player_inventory) then
        request_table.item_request_proxy.destroy()
        return nil, true, false
    end
    return nil, false, false
end

---comment
---@param entity LuaEntity
---@param request_type string
---@return nil
---@return boolean --true to remove the request from the table, false to keep it
---@return boolean
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
    end
    return nil, false, false
end

---@param player LuaPlayer
function tracking.update_lost_module_requests(player)
    utils.validate_surfaces()
    for _, surface_data in pairs(storage.surface_data.planets) do
        for _, entity in pairs(surface_data.surface.find_entities_filtered{name = "item-request-proxy"}) do
            if entity.proxy_target and not storage.tracked_requests["item_requests"][entity.proxy_target.unit_number] then
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

---Updated way to get item request proxies
function tracking.update_lost_module_requests_neo()
    storage.request_ids.item_proxies = flib_table.for_n_of(storage.chunks, storage.request_ids.item_proxies, 1, function(chunk)
        local surface = game.surfaces[chunk.surface_index]
        if not surface then return nil, true, false end
        for _, entity in pairs(surface.find_entities_filtered{name = "item-request-proxy", area = chunk.area}) do
            if entity.proxy_target and not storage.tracked_requests["item_requests"][entity.proxy_target.unit_number] then
                tracking.create_tracked_request({
                    entity = entity.proxy_target,
                    item_request_proxy = entity,
                    request_type = "item_requests"
                })
            end
        end
    end)
end

---Adds an entity to be tracked and creates necessary hidden entities
---@param request_data RequestData
function tracking.add_tracked_entity(request_data)
    local entity = request_data.entity
    local player_index = request_data.player_index

    ---@type EntityData
    local entity_data = {
        entity = entity,
        name = entity.name,
        surface_index = entity.surface_index,
        settings = {},
        unit_number = entity.unit_number,
    }
    local position = entity.position
    local surface = entity.surface
    local force = entity.force

    if entity.name == "digitizer-chest" then
        entity_data.inventory = entity.get_inventory(defines.inventory.chest)
        entity_data.settings.intake_limit = storage.options.default_intake_limit
        entity_data.settings.decraft = storage.options.default_decraft
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
        entity_data.settings.item_filter = nil
        entity_data.settings.fluid_filter = nil

        local surface_index
        if surface.platform then
            surface_index = get_storage_index(surface.platform.space_location)
        end
        if not surface_index then surface_index = entity.surface_index end
        entity_data.settings.surface_index = surface_index

        entity_data.burnt_result_inventory = entity.get_inventory(defines.inventory.burnt_result)
        pseudo_fluid_container.destructible = false
        pseudo_fluid_container.operable = false
        entity_data.container_fluid = pseudo_fluid_container
    elseif entity.name == "qf-storage-reader" then
        local control_behavior = entity.get_control_behavior()
        if not control_behavior then return end
        ---@diagnostic disable-next-line: undefined-field
        control_behavior.get_section(1).filters = {{
            value = {
                type = "virtual",
                name = "signal-S",
            },
            min = entity_data.surface_index
        }}
    end
    storage.tracked_entities[entity.name][entity.unit_number] = entity_data
end

---Remove tracked entity from the data and clear hidden entities
---@param entity_data? EntityData
function tracking.remove_tracked_entity(entity_data)
    if not entity_data then return end
    local entity_name = entity_data.name
    if entity_name == "digitizer-chest" then
        entity_data.container_fluid.destroy()
    elseif entity_name == "dedigitizer-reactor" then
        entity_data.container.destroy()
        entity_data.container_fluid.destroy()
    end
    storage.tracked_entities[entity_name][entity_data.unit_number] = nil
end

function tracking.update_tracked_reactors()
    local entities = storage.tracked_entities["dedigitizer-reactor"]
    for _, entity_data in pairs(entities) do
        tracking.update_entity(entity_data)
    end
end

---@param entity LuaEntity
---@return EntityData?
function tracking.get_entity_data(entity)
    if not storage.tracked_entities[entity.name] or not storage.tracked_entities[entity.name][entity.unit_number] then return end
    return storage.tracked_entities[entity.name][entity.unit_number]
end

---@param source LuaEntity
---@param destination LuaEntity
function tracking.clone_settings(source, destination)
    storage.tracked_entities[destination.name][destination.unit_number].settings = flib_table.deep_copy(storage.tracked_entities[source.name][source.unit_number].settings)
end

---@param entity_data EntityData
function tracking.update_entity(entity_data)
    local entity = entity_data.entity
    if not entity or not entity.valid then tracking.remove_tracked_entity(entity_data) return end
    local surface_index = entity_data.surface_index

    if entity_data.entity.name == "digitizer-chest" then
        local inventory = entity_data.inventory
        local signals = entity_data.entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
        local fetchable = settings.global["qf-super-digitizing-chests"].value

        local limit_value = entity_data.settings.intake_limit
        local decraft = entity_data.settings.decraft
        local storage_index = surface_index
        local fixed_quantity = 0
        local quality = "normal"
        local inventory_processing = {
            items = {},
            fluids = {
                name = "",
                count = 0,
            },
            preprocessed_items = {}
        }
        if signals then
            for _, signal in pairs(signals) do
                if signal.count > 0 then
                    if (signal.signal.type == nil or signal.signal.type == "item") and fetchable then
                        local item_quality = signal.signal.quality
                        if item_quality then
                            inventory_processing.items[signal.signal.name .. "-" .. item_quality] = {
                                name = signal.signal.name,
                                quality = signal.signal.quality,
                                count = signal.count
                            }
                        else
                            table.insert(inventory_processing.preprocessed_items, {
                                name = signal.signal.name,
                                count = signal.count
                            })
                        end
                    elseif signal.signal.type == "fluid" and fetchable then
                        -- Only fluid with the highest signal count will be added
                        if signal.count > inventory_processing.fluids.count then
                            inventory_processing.fluids = {
                                name = signal.signal.name,
                                count = signal.count
                            }
                        end
                    elseif signal.signal.type == "virtual" then
                        if signal.signal.name == "signal-S" then
                            storage_index = signal.count
                        elseif signal.signal.name == "signal-L" then
                            limit_value = signal.count
                        elseif signal.signal.name == "signal-D" then
                            decraft = signal.count > 0
                        elseif signal.signal.name == "signal-F" then
                            fixed_quantity = signal.count
                        end
                    elseif signal.signal.type == "quality" then
                        quality = signal.signal.name
                    end
                end
            end
            for _, item in pairs(inventory_processing.preprocessed_items) do
                local t_name = item.name .. "-" .. quality
                if not inventory_processing.items[t_name] then
                    inventory_processing.items[t_name] = {
                        name = item.name,
                        quality = quality,
                        count = 0
                    }
                end
                inventory_processing.items[t_name].count = inventory_processing.items[t_name].count + item.count
            end
        end

        -- Set fixed quantity if it exists
        if fixed_quantity > 0 then
            for _, item in pairs(inventory_processing.items) do
                item.count = fixed_quantity
            end
            if inventory_processing.fluids.count > 0 then
                inventory_processing.fluids.count = fixed_quantity
            end
        end

        -- We are only allower to select storage_index if the map setting is enabled
        if not storage.fabricator_inventory[storage_index] or not fetchable then
            storage_index = surface_index
        end

        if inventory then
            if not inventory.is_empty() then
                local inventory_contents = inventory.get_contents()
                local control_behavior = entity.get_control_behavior()
                -- If the container has "Read contents" checked, then we'll need to substract stored items from a signal value later
                local read_contents = false
                ---@diagnostic disable-next-line: undefined-field
                if control_behavior and control_behavior.read_contents then
                    read_contents = true
                end
                for _, item in pairs(inventory_contents) do
                    local qs_item = {
                        name = item.name,
                        count = item.count,
                        type = "item",
                        quality = item.quality,
                        surface_index = storage_index
                    }
                    local removable = limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value
                    -- if we have a signal for this item and that quality...
                    local t_name = item.name .. "-" .. item.quality
                    if inventory_processing.items[t_name] then
                        -- Substracting "fake" requests, but only if we didn't already set count to fixed value
                        if read_contents and fixed_quantity == 0 then
                            inventory_processing.items[t_name].count = inventory_processing.items[t_name].count - qs_item.count
                        end
                        -- Deciding what to do with items - store, fetch or ignore
                        if qs_item.count == inventory_processing.items[t_name].count then
                            inventory_processing.items[t_name] = nil
                            removable = false
                        elseif qs_item.count > inventory_processing.items[t_name].count then
                            qs_item.count = qs_item.count - inventory_processing.items[t_name].count
                            inventory_processing.items[t_name] = nil
                        else
                            inventory_processing.items[t_name].count = inventory_processing.items[t_name].count - qs_item.count
                            removable = false
                        end
                    end
                    if removable then
                        qs_utils.add_to_storage(qs_item, decraft)
                        inventory.remove({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
                    end
                end
            end
            for _, item in pairs(inventory_processing.items) do
                local qs_item = {
                    name = item.name,
                    count = item.count,
                    type = "item",
                    quality = item.quality,
                    surface_index = storage_index
                }
                qs_utils.pull_from_storage(qs_item, inventory)
            end
        end
        if entity_data.container_fluid and entity_data.container_fluid.get_fluid_contents() then
            for name, count in pairs(entity_data.container_fluid.get_fluid_contents()) do
                local qs_item = {
                    name = name,
                    count = count,
                    type = "fluid",
                    quality = QS_DEFAULT_QUALITY,
                    surface_index = storage_index
                }
                local removable = limit_value == 0 or qs_utils.count_in_storage(qs_item) < limit_value
                if inventory_processing.fluids.count > 0 then
                    if qs_item.count == inventory_processing.fluids.count then
                        inventory_processing.fluids.count = 0
                        removable = false
                    elseif qs_item.count > inventory_processing.fluids.count then
                        qs_item.count = qs_item.count - inventory_processing.fluids.count
                        inventory_processing.fluids.count = 0
                    else
                        inventory_processing.fluids.count = inventory_processing.fluids.count - qs_item.count
                        removable = false
                    end
                end
                if removable then
                    qs_utils.add_to_storage(qs_item)
                    entity_data.container_fluid.remove_fluid({name = name, amount = count})
                end
            end
            if inventory_processing.fluids.count > 0 then
                local qs_item = {
                    name = inventory_processing.fluids.name,
                    count = inventory_processing.fluids.count,
                    type = "fluid",
                    quality = QS_DEFAULT_QUALITY,
                    surface_index = storage_index
                }
                qs_utils.pull_from_storage(qs_item, entity_data.container_fluid)
            end
        end
        return
    end

    if entity_data.entity.name == "dedigitizer-reactor" then
        local energy_consumption = Reactor_constants.idle_cost
        local energy_consumption_multiplier = 1
        local transfer_rate_multiplier = 1 * settings.global["qf-reactor-transfer-multi"].value

        local burnt_result_contents = entity_data.burnt_result_inventory.get_contents()
        if next(burnt_result_contents) then
            ---@diagnostic disable-next-line: param-type-mismatch
            entity_data.inventory.insert(burnt_result_contents[1])
            entity_data.burnt_result_inventory.clear()
        end

        if entity_data.entity.temperature > Reactor_constants.min_temperature or settings.global["qf-reactor-free-transfer"].value then
            local signals = entity_data.entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
            
            local item_filter
            local fluid_filter
            local quality_filter
            local surface_id
            local highest_count_item = 0
            local highest_count_fluid = 0
            local highest_count_quality = 0
            if signals then
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
            end
            if not item_filter and entity_data.settings.item_filter then
                item_filter = entity_data.settings.item_filter.name
            end
            if not quality_filter and entity_data.settings.item_filter then
                quality_filter = entity_data.settings.item_filter.quality
            end
            if not fluid_filter then
                fluid_filter = entity_data.settings.fluid_filter
            end
            if not surface_id then
                surface_id = entity_data.settings.surface_index
            end
            if not quality_filter then
                quality_filter = QS_DEFAULT_QUALITY
            end
            if surface_id and surface_id ~= surface_index and storage.fabricator_inventory[surface_id] and (item_filter or fluid_filter) then
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

        if energy_consumption > entity_data.entity.temperature then
            entity_data.entity.temperature = 0
        else
            entity_data.entity.temperature = entity_data.entity.temperature - (energy_consumption * energy_consumption_multiplier)
        end

        return
    end

    if entity_data.entity.name == "qf-storage-reader" then
        ---@type LuaConstantCombinatorControlBehavior
        ---@diagnostic disable-next-line: assign-type-mismatch
        local control_behavior = entity.get_control_behavior()
        if not control_behavior then return end
        while control_behavior.sections_count < 2 do
            control_behavior.add_section()
        end
        local storage_index
        for _, signal in pairs(control_behavior.get_section(1).filters) do
            if signal.value.name == "signal-S" then
                storage_index = signal.min
            end
        end
        if not storage_index or not storage.fabricator_inventory[storage_index] then storage_index = entity_data.surface_index end
        local signals = qs_utils.get_storage_signals(storage_index)
        control_behavior.get_section(2).filters = signals
        return
    end
end


return tracking