local qs_utils = require("scripts/qs_utils")
local qf_utils = require("scripts/qf_utils")
local tracking = require("scripts/tracking_utils")
local utils = require("scripts/utils")
local flib_table = require("__flib__.table")

---comment
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
    elseif in_inventory and in_inventory > 0 then
        return revive_ghost(entity, qs_item, player_inventory)
    end

    -- Nothing? Guess we are fabricating
    local recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
    if not recipe then return false end
    qf_utils.fabricate_recipe(recipe, entity.quality.name, surface_index, player_inventory)
    return revive_ghost(entity, qs_item)
end


---@param entity LuaEntity
---@param player_index? int id of a player who placed the order
function instant_defabrication(entity, player_index)
    if not storage.prototypes_data[entity.name] then return false end

    local surface_index = entity.surface_index

    local qs_item = {
        name = storage.prototypes_data[entity.name].item_name,
        count = 1,
        type = "item",
        quality = entity.quality.name,
        surface_index = surface_index
    }
    if not qs_item.name then game.print("instant_defabrication error - item name not found for " .. entity.ghost_name .. ", this shouldn't happen") return false end

    local player_inventory
    if player_index then
        player_inventory = game.get_player(player_index).get_inventory(defines.inventory.character_main)
    end
    qs_utils.add_to_storage(qs_item, true)
    process_inventory(entity, player_inventory, surface_index)
    return entity.destroy({raise_destroy = true})
end


---Unlike others, this one doesn't care for player inventories
function instant_tileation()
    
    local function remove_from_storage(indices, surface_index)
        for name, value in pairs(indices) do
            qs_utils.remove_from_storage({name = name, type = "item", count = value, surface_index = surface_index, quality = QS_DEFAULT_QUALITY})
        end
    end

    local schedule_retileation = false

    for _, surface in pairs(game.surfaces) do
        local tiles = surface.find_entities_filtered({name = "tile-ghost"})
        if tiles then
            local tile_availability = qs_utils.get_available_tiles(surface.index)
            local final_tiles = {}
            local indices = {}
            local indices_overall = 1
            for tile_name, _ in pairs(storage.tiles) do
                indices[tile_name] = 0
            end
            for _, tile in pairs(tiles) do
                local tile_name = storage.tile_link[tile.ghost_name]
                if tile_availability[tile_name] > indices[tile_name] then
                    final_tiles[indices_overall] = {
                        name = tile.ghost_name,
                        position = tile.position
                    }
                    indices_overall = indices_overall + 1
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



---comment
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
        name = target.name,
        count = 1,
        type = "item",
        quality = quality,
        surface_index = surface_index
    }

    -- Check if requested item is available
    local in_storage, in_inventory = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
    local recipe
    -- If it's not, then we'll check for a recipe and return if it's not available either
    if in_storage == 0 and (not in_inventory or in_inventory == 0) then
        recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
        if not recipe then return "no_recipe" end
    end

    -- I've spent an embarassing amount of time not understanding why only one of the underground belts pair would get upgraded.
    -- The answer was in the API docs. As usual. RTFM people, always RTFM.
    -- But still, it feels like fast_replace should work here like how it works for everything else.
    local underground_belt_type
    if entity.type == "underground-belt" then
        underground_belt_type = entity.belt_to_ground_type
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


---comment
---@param request_type "revivals"|"destroys"|"upgrades"
function register_request_table(request_type)
    local result = {}
    for _, surface in pairs(game.surfaces) do
        local targets = surface.find_entities_filtered(Request_table_filter_link[request_type])
        result = flib_table.array_merge({result, targets})
    end
    storage.tracked_requests[request_type] = result
end

---comment
---@param entity LuaEntity
---@param player_index uint
function instant_repair(entity, player_index)
    if entity.health == entity.max_health then return true end
    local qs_item

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
            local player = game.get_player(player_index)
            local player_inventory
            local player_surface_index
            if player then
                player_inventory = player.get_inventory(defines.inventory.character_main)
                player_surface_index = player.physical_surface_index
            end
            local in_storage, in_inventory = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
            if in_storage > 0 or (in_inventory and in_inventory > 0) then
                goto continue
            else
                qs_item = nil
            end
        end
    end
    ::continue::
    if not qs_item then return false end

    local to_heal = entity.max_health - entity.health
    local chance_to_break
    if qs_item.durability then
        chance_to_break = (to_heal / (qs_item.durability * 2))
    else
        chance_to_break = 0.1
    end
    if math.random() < chance_to_break then
        qs_utils.remove_from_storage(qs_item)
    end
    entity.health = entity.max_health
    return true

end

---@param qs_item QSItem
function decraft(qs_item)
    local recipe = qf_utils.get_craftable_recipe(qs_item, nil, true)
    if recipe then
        qf_utils.fabricate_recipe(recipe, qs_item.quality, qs_item.surface_index, nil, qs_item.count, true)
    end
end


---comment
---@param entity LuaEntity
---@param qs_item QSItem
---@param player_inventory? LuaInventory
---@return boolean
function revive_ghost(entity, qs_item, player_inventory)
    local entity_name = storage.prototypes_data[entity.ghost_name].item_name
    local entity_quality = entity.quality.name
    local item_requests = entity.item_requests
    local _, revived_entity, item_request_proxy = entity.revive({raise_revive = true, return_item_request_proxy = true})
    if revived_entity and revived_entity.valid then
        -- Note: this won't work properly for reviving entities that require multiple items. A problem for future me to solve when the need arises
        if not player_inventory then
            qs_utils.remove_from_storage(qs_item)
        else
            ---@diagnostic disable-next-line: need-check-nil
            player_inventory.remove({name = entity_name, count = 1, quality = entity_quality})
        end

        -- If there are module requests:
        -- (it gets all requests, but we only care about modules, everything else is outside of the scope of the mod)
        if item_requests and item_requests ~= {} then
            -- it's nil if the entity doesn't have module inventory or request didn't had modules in it.
            -- If true or nil we destroy the proxy
            local player_index
            if player_inventory then
                player_index = player_inventory.player_owner.index
            end
            if handle_item_requests(revived_entity, item_requests, player_inventory) == false then
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

---comment
---@param entity LuaEntity
---@param item_requests table
---@param player_inventory? LuaInventory
function handle_item_requests(entity, item_requests, player_inventory)

    local module_inventory = entity.get_module_inventory()
    local fuel_inventory = entity.get_fuel_inventory()
    local ammo_inventory = entity.get_inventory(defines.inventory.turret_ammo)
    if not module_inventory and not fuel_inventory and not ammo_inventory then return nil end
    local satisfied = true
    local player_surface_index
    if player_inventory then
        local player = player_inventory.player_owner
        ---@diagnostic disable-next-line: need-check-nil
        player_surface_index = player.physical_surface_index
    end

    local module_contents
    if module_inventory then
        module_contents = module_inventory.get_contents()
    end
    local fuel_contents
    if fuel_inventory then
        fuel_contents = fuel_inventory.get_contents()
    end
    local ammo_contents
    if ammo_inventory then
        ammo_contents = ammo_inventory.get_contents()
    end

    local function process_insertion(qs_item, amount, entity_inventory)
        entity_inventory.insert({name = qs_item.name, count = amount, quality = qs_item.quality})
    end

    local function process_removal(qs_item, in_storage, in_inventory, entity_inventory)
        if in_storage > qs_item.count then
            qs_utils.remove_from_storage(qs_item)
            process_insertion(qs_item, qs_item.count, entity_inventory)
            qs_item.count = 0
        elseif in_storage > 0 then
            qs_item.count = qs_item.count - in_storage
            qs_utils.remove_from_storage(qs_item, in_storage)
            process_insertion(qs_item, in_storage, entity_inventory)
        end
        if qs_item.count > 0 then
            if in_inventory then
                if in_inventory > qs_item.count then
                    ---@diagnostic disable-next-line: need-check-nil
                    player_inventory.remove({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
                    process_insertion(qs_item, qs_item.count, entity_inventory)
                    qs_item.count = 0
                elseif in_inventory > 0 then
                    ---@diagnostic disable-next-line: need-check-nil
                    player_inventory.remove({name = qs_item.name, count = in_inventory, quality = qs_item.quality})
                    qs_item.count = qs_item.count - in_inventory
                    process_insertion(qs_item, in_inventory, entity_inventory)
                end
            end
        end
        return qs_item.count == 0
    end


    for _, item in pairs(item_requests) do
        local qs_item = {
            name = item.name,
            count = item.count,
            quality = item.quality,
            type = "item",
            surface_index = entity.surface_index
        }
        local in_storage, in_inventory = qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
        if utils.is_module(qs_item.name) and module_inventory and module_inventory.can_insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality}) then
            qs_item.count = qs_item.count - (module_contents[qs_item.name] or 0)
            satisfied = process_removal(qs_item, in_storage, in_inventory, module_inventory)
        elseif utils.is_fuel(qs_item.name) and fuel_inventory and fuel_inventory.can_insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality}) then
            qs_item.count = qs_item.count - (fuel_contents[qs_item.name] or 0)
            satisfied = process_removal(qs_item, in_storage, in_inventory, fuel_inventory)
        elseif utils.is_ammo(qs_item.name) and ammo_inventory and ammo_inventory.can_insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality}) then
            qs_item.count = qs_item.count - (ammo_contents[qs_item.name] or 0)
            satisfied = process_removal(qs_item, in_storage, in_inventory, ammo_inventory)
        end
    end
    return satisfied

end


---comment
---@param entity LuaEntity
---@param player_inventory? LuaInventory
---@param surface_index uint
function process_inventory(entity, player_inventory, surface_index)
    local max_index = entity.get_max_inventory_index()
    if not max_index then return end
    for i = 1, max_index do
        ---@diagnostic disable-next-line: param-type-mismatch
        local inventory = entity.get_inventory(i)
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
                qs_utils.add_to_player_inventory(player_inventory, qs_item)
            end
        end
    end
end


---comment
---@param entity LuaEntity
---@param player_index int
function instant_deforestation(entity, player_index)
    local player_inventory
    if player_index then
        player_inventory = game.get_player(player_index).get_inventory(defines.inventory.character_main)
    end
    local surface_index = entity.surface_index
    if entity.prototype.loot then
        process_loot(entity.prototype.loot, player_inventory, surface_index)
    end
    if entity.prototype.mineable_properties and entity.prototype.mineable_properties.products then
        process_mining(entity.prototype.mineable_properties, player_inventory, surface_index)
    end
    if entity.prototype.type == "item-entity" then
        local qs_item = {
            name = entity.stack.name,
            count = entity.stack.count,
            type = "item",
            quality = entity.stack.quality or QS_DEFAULT_QUALITY,
            surface_index = surface_index
        }
        qs_utils.add_to_player_inventory(player_inventory, qs_item)
    end
    entity.destroy({raise_destroy = true})
end




---comment
---@param loot table
---@param player_inventory? LuaInventory
---@param surface_index uint
function process_loot(loot, player_inventory, surface_index)
    for _, item in pairs(loot) do
        if item.probability >= math.random() then
            local qs_item = {
                name = item.item,
                count = math.random(item.count_min, item.count_max),
                type = "item",
                surface_index = surface_index
            }
            qs_utils.add_to_player_inventory(player_inventory, qs_item)
        end
    end
end


---comment
---@param mining_properties table
---@param player_inventory? LuaInventory
---@param surface_index uint
function process_mining(mining_properties, player_inventory, surface_index)
    if not mining_properties or not mining_properties.products then return end
    for _, item in pairs(mining_properties.products) do
        if item.probability >= math.random() then
            local qs_item = {
                name = item.name,
                count = 1,
                type = "item",
                surface_index = surface_index,
                quality = item.quality or QS_DEFAULT_QUALITY
            }
            if item.amount then
                qs_item.count = item.amount
            else
                qs_item.count = math.random(item.amount_min, item.amount_max)
            end
            qs_utils.add_to_player_inventory(player_inventory, qs_item)
        end
    end
end




---Handles removing cliffs via explosions
---@param entity LuaEntity
function instant_decliffing(entity)
    if not entity or not entity.valid then return true end
    local entity_prototype = entity.prototype
    local cliff_explosive = entity_prototype.cliff_explosive_prototype
    if not cliff_explosive then return true end
    local qs_item = {
        name = cliff_explosive,
        count = 1,
        type = "item",
        surface_index = entity.surface_index
    }
    if qs_utils.count_in_storage(qs_item) > 0 then
        qs_utils.remove_from_storage(qs_item)
        entity.destroy({raise_destroy = true})
        return true
    end
    return false
end