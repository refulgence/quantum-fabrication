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
    local availability = qs_utils.check_in_storage(qs_item, player_inventory, player_surface_index)

    -- If it is, then just use it to instantly revive the entity
    if availability then
        return revive_ghost(entity, qs_item, availability, player_inventory)
    end

    -- Nothing? Guess we are fabricating
    local recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
    if not recipe then return false end
    qf_utils.fabricate_recipe(recipe, entity.quality.name, surface_index, player_inventory)
    return revive_ghost(entity, qs_item, "storage")
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
            indices.overall = 1
            for tile_name, _ in pairs(storage.tiles) do
                indices[tile_name] = 0
            end
            for _, tile in pairs(tiles) do
                local tile_name = storage.tile_link[tile.ghost_name]
                if tile_availability[tile_name] > indices[tile_name] then
                    final_tiles[indices.overall] = {
                        name = tile.ghost_name,
                        position = tile.position
                    }
                    indices.overall = indices.overall + 1
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


function instant_revivals()
    local result = {}
    for _, surface in pairs(game.surfaces) do
        local ghosts = surface.find_entities_filtered({name = "entity-ghost"})
        result = flib_table.array_merge({result, ghosts})
    end
    storage.tracked_requests.revivals = result
end

function instant_destroys()
    local result = {}
    for _, surface in pairs(game.surfaces) do
        local targets = surface.find_entities_filtered({to_be_deconstructed = true})
        result = flib_table.array_merge({result, targets})
    end
    storage.tracked_requests.destroys = result
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
---@param inventory_type "storage"|"player"|"both"
---@param player_inventory? LuaInventory
---@return boolean
function revive_ghost(entity, qs_item, inventory_type, player_inventory)
    local entity_name = storage.prototypes_data[entity.ghost_name].item_name
    local entity_quality = entity.quality.name
    local item_requests = entity.item_requests
    local _, revived_entity, item_request_proxy = entity.revive({raise_revive = true, return_item_request_proxy = true})
    if revived_entity and revived_entity.valid then
        -- Note: this won't work properly for reviving entities that require multiple items. A problem for future me to solve when the need arises
        if inventory_type == "storage" or inventory_type == "both" then
            qs_utils.remove_from_storage(qs_item)
        elseif inventory_type == "player" then
            ---@diagnostic disable-next-line: need-check-nil
            player_inventory.remove({name = entity_name, count = 1, quality = entity_quality})
        end

        -- If there are module requests:
        -- (it gets all requests, but we only care about modules, everything else is outside of the scope of the mod)
        if item_requests and item_requests ~= {} then
            local player_index
            if player_inventory then
                player_index = player_inventory.player_owner.index
            end
            -- it's nil if the entity doesn't have module inventory or request didn't had modules in it
            if add_modules(revived_entity, item_requests, player_inventory) == false then
                tracking.create_tracked_request({
                    entity = revived_entity,
                    player_index = player_index,
                    item_request_proxy = item_request_proxy,
                    request_type = "item_requests"
                })
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
function add_modules(entity, item_requests, player_inventory)
    local module_inventory = entity.get_module_inventory()
    if not module_inventory then return nil end
    local satisfied = true
    local module_contents = module_inventory.get_contents()
    for _, item in pairs(item_requests) do
        if utils.is_module(item.name) then
            local qs_item = {
                name = item.name,
                count = item.count,
                quality = item.quality,
                type = "item",
                surface_index = entity.surface_index
            }

            qs_item.count = qs_item.count - (module_contents[qs_item.name] or 0)
            -- First we try to take from the player's inventory if it's provided
            if player_inventory then
                process_modules(entity, qs_item, "player", player_inventory)
                if qs_item.count == 0 then goto continue end
            end
            process_modules(entity, qs_item, "storage")
            if qs_item.count > 0 then satisfied = false end
        end
        ::continue::
    end
    return satisfied
end




---comment
---@param entity LuaEntity
---@param qs_item QSItem
---@param inventory_type "player"|"storage"
---@param player_inventory? LuaInventory
function process_modules(entity, qs_item, inventory_type, player_inventory)
    local count

    ---@param amount uint
    local function insert_modules(amount)
        local module_inventory = entity.get_module_inventory()
        if not module_inventory then return 0 end
        if inventory_type == "storage" then
            qs_utils.remove_from_storage(qs_item, amount)
        elseif inventory_type == "player" and player_inventory then
            player_inventory.remove({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
        end
        return module_inventory.insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
    end

    if inventory_type == "storage" then
        count = qs_utils.count_in_storage(qs_item)
    elseif inventory_type == "player" and player_inventory then
        count = player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
    else
        return nil
    end
    if count > 0 then
        if count >= qs_item.count then
            qs_item.count = qs_item.count - insert_modules(qs_item.count)
        else
            qs_item.count = qs_item.count - insert_modules(count)
        end
    end
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



---comment
---@param entity LuaEntity
---@param target LuaEntityPrototype
---@param quality string
---@param player_index? int
---@return boolean
function instant_upgrade(entity, target, quality, player_index)

    local surface_index = entity.surface_index
    local player
    local player_inventory
    if player_index then
        player = game.get_player(player_index)
        if player then
            player_inventory = player.get_inventory(defines.inventory.character_main)
        end
    end
    local qs_item = {
        name = target.name,
        count = 1,
        type = "item",
        quality = quality,
        surface_index = entity.surface_index
    }

    local recipe = qf_utils.get_craftable_recipe(qs_item, player_inventory)
    if not recipe then return false end

    local upgraded_entity = entity.surface.create_entity{
        name = target.name,
        position = entity.position,
        direction = entity.direction,
        quality = quality,
        force = entity.force,
        fast_replace = true,
        player = player,
        raise_built = true,
    }
    if upgraded_entity then
        qf_utils.fabricate_recipe(recipe, quality, surface_index, player_inventory)
        qs_utils.remove_from_storage(qs_item)
        return true
    end
    return false
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
    if qs_utils.check_in_storage(qs_item) then
        qs_utils.remove_from_storage(qs_item)
        entity.destroy({raise_destroy = true})
        return true
    end
    return false
end