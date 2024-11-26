local qs_utils = require("scripts/qs_utils")
local qf_utils = require("scripts/qf_utils")
local tracking = require("scripts/tracking_utils")
local utils = require("scripts/utils")
local flib_table = require("__flib__.table")

---@param entity LuaEntity Entity to fabricate
---@param player_index? int
function instant_fabrication(entity, player_index)
    local surface_index = entity.surface_index
    if not storage.prototypes_data[entity.ghost_name] then return false end

    local qs_item = {
        name = storage.prototypes_data[entity.ghost_name].item_name,
        count = 1,
        type = "item",
        quality = entity.quality.name,
        surface_index = surface_index
    }

    local player
    local player_surface_index
    local player_inventory
    if player_index then
        player = game.get_player(player_index)
        if player then
            player_surface_index = player.surface_index
            player_inventory = player.get_inventory(defines.inventory.character_main)
        end
    end

    -- Check if requested item is available
    local in_storage, in_inventory = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)

    -- If it is, then just use it to instantly revive the entity
    if in_storage > 0 then
        return revive_ghost(entity, qs_item)
    elseif in_inventory > 0 then
        return revive_ghost(entity, qs_item, player_inventory)
    end

    -- Nothing? Guess we are fabricating
    local recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
    if not recipe then return false end
    qf_utils.fabricate_recipe(recipe, entity.quality.name, surface_index, player_inventory)
    return revive_ghost(entity, qs_item)
end

function instant_tileation()
    local schedule_retileation = false
    local player = game.get_player(storage.request_player_ids.tiles)
    local player_inventory
    local player_surface_index
    if player then
        player_inventory = player.get_inventory(defines.inventory.character_main)
        player_surface_index = player.physical_surface_index
    end
    
    local function remove_from_storage(indices, surface_index)
        for name, value in pairs(indices) do
            if value > 0 then
                qs_utils.advanced_remove_from_storage({
                    name = name,
                    type = "item",
                    count = value,
                    surface_index = surface_index,
                    quality = QS_DEFAULT_QUALITY
                }, nil, player_inventory)
            end
        end
    end

    utils.validate_surfaces()
    for _, surface_data in pairs(storage.surface_data.planets) do
        local surface = surface_data.surface
        local tiles = surface.find_entities_filtered({name = "tile-ghost"})
        if tiles then
            local tile_availability = qs_utils.get_available_tiles(surface.index, player_inventory, player_surface_index)
            local final_tiles = {}
            local indices = {}
            local overall_index = 1
            for tile_name, _ in pairs(storage.tiles) do
                indices[tile_name] = 0
            end
            for _, tile in pairs(tiles) do
                local tile_name = storage.tile_link[tile.ghost_name]
                if tile_availability[tile_name] > indices[tile_name] then
                    final_tiles[overall_index] = {
                        name = tile.ghost_name,
                        position = tile.position
                    }
                    overall_index = overall_index + 1
                    indices[tile_name] = indices[tile_name] + 1
                else
                    schedule_retileation = true
                end
            end
            surface.set_tiles(final_tiles)
            remove_from_storage(indices, surface.index)
        end
    end
    if schedule_retileation then
        storage.countdowns.tile_creation = 500
    end
end

---@param entity LuaEntity
---@param target LuaEntityPrototype
---@param quality string
---@param player_index? int
---@return "success" | "no_recipe" | "error"
function instant_upgrade(entity, target, quality, player_index)
    
    local surface_index = entity.surface_index
    local player
    local player_inventory
    if player_index then
        player = game.get_player(player_index)
        if player then
            player_inventory = player.get_inventory(defines.inventory.character_main)
            player_surface_index = player.physical_surface_index
        end
    end

    local qs_item = {
        name = storage.prototypes_data[target.name].item_name,
        count = 1,
        type = "item",
        quality = quality,
        surface_index = surface_index
    }

    -- Check if requested item is available
    local in_storage, _, total = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
    local recipe
    -- If it's not, then we'll check for a recipe and return if it's not available either
    if total == 0 then
        recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
        if not recipe then return "no_recipe" end
    end

    -- I've spent an embarassing amount of time not understanding why only one of the underground belts pair would get upgraded.
    -- The answer was in the API docs. As usual. RTFM people, always RTFM.
    -- But still, it feels like fast_replace should work here like how it works for everything else.
    local underground_belt_type
    if entity.type == "underground-belt" then
        underground_belt_type = entity.belt_to_ground_type
    elseif entity.type == "loader" or entity.type == "loader-1x1" then
        underground_belt_type = entity.loader_type
    end

    local upgraded_entity = entity.surface.create_entity{
        name = target.name,
        position = entity.position,
        direction = entity.direction,
        quality = quality,
        force = entity.force,
        fast_replace = true,
        player = player,
        raise_built = true,
        type = underground_belt_type,
    }
  
    if upgraded_entity then
        if recipe then
            qf_utils.fabricate_recipe(recipe, quality, surface_index, player_inventory)
            qs_utils.remove_from_storage(qs_item)
        elseif in_storage == 0 then
            ---@diagnostic disable-next-line: need-check-nil
            player_inventory.remove({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
        else
            qs_utils.remove_from_storage(qs_item)
        end
        return "success"
    end

    -- If the upgrade failed not because we could not find a recipe, then we'll return an error becuase what is going on
    return "error"
end

---@param request_type "revivals"|"destroys"|"upgrades"
function register_request_table(request_type)
    local result = {}
    utils.validate_surfaces()
    for _, surface_data in pairs(storage.surface_data.planets) do
        local targets = surface_data.surface.find_entities_filtered(Request_table_filter_link[request_type])
        result = flib_table.array_merge({result, targets})
    end
    storage.tracked_requests[request_type] = result
end

---@param entity LuaEntity
function instant_repair(entity)
    if entity.health == entity.max_health then return true end
    local qs_item
    local in_storage
    for _, repair_tool in pairs(prototypes.get_item_filtered{{filter = "type", type = "repair-tool"}}) do
        for _, quality in pairs(utils.get_qualities()) do
            qs_item = {
                name = repair_tool.name,
                count = 1,
                type = "item",
                quality = quality.name,
                surface_index = entity.surface_index,
                durability = repair_tool.get_durability(quality.name)
            }
            in_storage = qs_utils.count_in_storage(qs_item)
            if in_storage > 0 then
                goto continue
            else
                qs_item = nil
            end
        end
    end
    ::continue::
    if not qs_item then return false end

    -- Since we can't emulate durability (I mean, we can, but...) we'll just make repair packs randomly break based on health healed
    -- It's not 100% accurate, but it works
    local to_heal = entity.max_health - entity.health
    local chance_to_break = (to_heal / (qs_item.durability * 2))
    if math.random() < chance_to_break then
        qs_utils.remove_from_storage(qs_item)
    end
    entity.health = entity.max_health
    return true
end

---@param entity LuaEntity
---@param qs_item QSItem
---@param player_inventory? LuaInventory only sent if we are intending to take items from the inventory
---@return boolean --true if it was revived, false otherwise
function revive_ghost(entity, qs_item, player_inventory)
    local item_requests = entity.item_requests
    local _, revived_entity, item_request_proxy = entity.revive({raise_revive = true, return_item_request_proxy = true})
    if revived_entity and revived_entity.valid then
        -- Note: this won't work properly for reviving entities that require multiple items. A problem for future me to solve when the need arises
        if not player_inventory then
            qs_utils.remove_from_storage(qs_item)
        else
            ---@diagnostic disable-next-line: need-check-nil
            player_inventory.remove({name = qs_item.name, count = 1, quality = qs_item.quality})
        end
        
        if item_request_proxy then
            local player_index
            if player_inventory then
                player_index = player_inventory.player_owner.index
            end
            if handle_item_requests(revived_entity, item_requests, item_request_proxy.insert_plan, item_request_proxy.removal_plan, player_inventory) == false then
                tracking.create_tracked_request({
                    entity = revived_entity,
                    item_request_proxy = item_request_proxy,
                    player_index = player_index,
                    request_type = "item_requests"
                })
            else
                if item_request_proxy then item_request_proxy.destroy() end
            end
        end
        return true
    end
    return false
end

---@param entity LuaEntity
---@param item_requests table
---@param insert_plan BlueprintInsertPlan
---@param removal_plan BlueprintInsertPlan
---@param player_inventory? LuaInventory
function handle_item_requests(entity, item_requests, insert_plan, removal_plan, player_inventory)
    local entity_inventories = {}
    local player_surface_index
    if player_inventory then
        local player = player_inventory.player_owner
        ---@diagnostic disable-next-line: need-check-nil
        player_surface_index = player.physical_surface_index
    end

    -- We only ever touch item requests when we can fully satisfy them
    for _, item in pairs(item_requests) do
        local qs_item = {
            name = item.name,
            quality = item.quality or QS_DEFAULT_QUALITY,
            type = "item",
            surface_index = entity.surface_index,
            count = item.count
        }
        local _, _, total = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
        if total < qs_item.count then
            return false
        end
    end

    for _, plan in pairs(removal_plan) do
        -- Item to be removed from the inventory and added to the Storage. We don't know the count yet.
        local qs_item = {
            name = plan.id.name,
            quality = plan.id.quality or QS_DEFAULT_QUALITY,
            type = "item",
            surface_index = entity.surface_index
        }
        for _, item_and_inventory_position in pairs(plan.items) do
            for _, inventory_position in pairs(item_and_inventory_position) do
                qs_item.count = inventory_position.count or 1
                if entity.type == "inserter" then
                    entity.held_stack.set_stack()
                else
                    if not entity_inventories[inventory_position.inventory] then
                        entity_inventories[inventory_position.inventory] = entity.get_inventory(inventory_position.inventory)
                    end
                    entity_inventories[inventory_position.inventory].remove({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
                end
                qs_utils.add_to_storage(qs_item, true)
            end
        end
    end

    for _, plan in pairs(insert_plan) do
        -- Item to be added to the inventory and removed from the Storage. We don't know the count yet.
        local qs_item = {
            name = plan.id.name,
            quality = plan.id.quality or QS_DEFAULT_QUALITY,
            count = 1,
            type = "item",
            surface_index = entity.surface_index
        }
        local in_storage, in_inventory = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
        for _, item_and_inventory_position in pairs(plan.items) do
            for _, inventory_position in pairs(item_and_inventory_position) do
                qs_item.count = inventory_position.count or 1
                if not entity_inventories[inventory_position.inventory] then
                    entity_inventories[inventory_position.inventory] = entity.get_inventory(inventory_position.inventory)
                end
                qs_utils.advanced_remove_from_storage(qs_item, {storage = in_storage, inventory = in_inventory}, player_inventory)
                entity_inventories[inventory_position.inventory].insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
            end
        end
    end
    return true
end