local qs_utils = require("scripts/qs_utils")
local qf_utils = require("scripts/qf_utils")
local utils = require("scripts/utils")

---@param entity LuaEntity
---@param player_index? int id of a player who placed the order
---@return boolean --returns false if defabrication failed AND we'll need to retry later; true otherwise
function instant_defabrication(entity, player_index)
    if not storage.prototypes_data[entity.name] then return false end
    if entity.surface.platform then return true end
    
    local surface_index = entity.surface_index
    local qs_item = {
        name = storage.prototypes_data[entity.name].item_name,
        count = 1,
        type = "item",
        quality = entity.quality.name,
        surface_index = surface_index
    }
    if not qs_item.name then game.print("instant_defabrication error - item name not found for " .. entity.ghost_name .. ", this shouldn't happen") return false end

    local player_inventory = utils.get_player_inventory(nil, player_index)
    qs_utils.add_to_storage(qs_item, true)
    process_inventory(entity, player_inventory, surface_index)
    if Transport_belt_types[entity.type] then
        process_transport_line(entity, player_inventory, surface_index)
    end
    qs_utils.increment_craft_stats(entity.name, -1)
    return entity.destroy({raise_destroy = true})
end

function instant_detileation()
    local function add_to_storage(indices, surface_index)
        for name, value in pairs(indices) do
            qs_utils.add_to_storage({name = name, type = "item", count = value, surface_index = surface_index, quality = QS_DEFAULT_QUALITY})
        end
    end

    local function set_hidden_tiles(surface, tiles)
        for _, tile in pairs(tiles) do
            if tile.double_hidden_tile then
                surface.set_hidden_tile(tile.position, tile.double_hidden_tile)
            end
        end
    end

    utils.validate_surfaces()
    for surface_index, surface_data in pairs(storage.surface_data.planets) do
        local surface = surface_data.surface
        local tiles = surface.find_tiles_filtered({to_be_deconstructed = true})
        local final_tiles = {}
        local indices = {}
        local final_index = 1
        for _, tile in pairs(tiles) do
            local hidden_tile = tile.hidden_tile
            local double_hidden_tile = tile.double_hidden_tile
            if hidden_tile then
                final_tiles[final_index] = {
                    name = hidden_tile,
                    position = tile.position,
                    double_hidden_tile = double_hidden_tile
                }
                final_index = final_index + 1
            end
            indices[storage.tile_link[tile.name]] = (indices[storage.tile_link[tile.name]] or 0) + 1
        end
        surface.set_tiles(final_tiles)
        set_hidden_tiles(surface, final_tiles)
        add_to_storage(indices, surface_index)
    end
end

---@param qs_item QSItem
function decraft(qs_item)
    local recipe = qf_utils.get_craftable_recipe(qs_item, nil, true)
    if recipe then
        qf_utils.fabricate_recipe(recipe, qs_item.quality, qs_item.surface_index, nil, qs_item.count, true)
    end
end

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

---@param entity LuaEntity
---@param player_inventory? LuaInventory
---@param surface_index uint
function process_transport_line(entity, player_inventory, surface_index)
    local max_lines = entity.get_max_transport_line_index()
    for line = 1, max_lines do
        local transport_line = entity.get_transport_line(line)
        local contents = transport_line.get_contents()
        for _, item in pairs(contents) do
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

---@param entity LuaEntity
---@param player_index? int
function instant_deforestation(entity, player_index)
    local player_inventory = utils.get_player_inventory(nil, player_index)
    local prototype = entity.prototype
    local surface_index = entity.surface_index
    if prototype.loot then
        process_loot(prototype.loot, player_inventory, surface_index)
    end
    if prototype.mineable_properties and prototype.mineable_properties.products then
        process_mining(prototype.mineable_properties, player_inventory, surface_index)
    end
    if prototype.type == "item-entity" then
        local qs_item = {
            name = entity.stack.name,
            count = entity.stack.count or 1,
            type = "item",
            quality = entity.stack.quality.name or QS_DEFAULT_QUALITY,
            surface_index = surface_index
        }
        qs_utils.add_to_player_inventory(player_inventory, qs_item)
    end
    if storage.trigger_techs_mine_actual[entity.name] then
        utils.research_technology(storage.trigger_techs_mine_actual[entity.name].technology)
    end
    entity.destroy({raise_destroy = true})
end

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
                surface_index = surface_index,
                quality = QS_DEFAULT_QUALITY
            }
            if qs_item.count > 0 then
                qs_utils.add_to_player_inventory(player_inventory, qs_item)
            end
        end
    end
end

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
            if qs_item.count > 0 then
                qs_utils.add_to_player_inventory(player_inventory, qs_item)
            end
        end
    end
end

---Handles removing cliffs via explosions
---@param entity LuaEntity
---@param player_index? uint
function instant_decliffing(entity, player_index)
    if not entity or not entity.valid then return true end
    local entity_prototype = entity.prototype
    local cliff_explosive = entity_prototype.cliff_explosive_prototype
    if not cliff_explosive then return true end
    local qs_item = {
        name = cliff_explosive,
        count = 1,
        type = "item",
        quality = QS_DEFAULT_QUALITY,
        surface_index = entity.surface_index
    }
    local player_inventory = utils.get_player_inventory(nil, player_index)
    local in_storage, _, total = qs_utils.count_in_storage(qs_item, player_inventory)
    if total > 0 then
        if in_storage > 0 then
            qs_utils.remove_from_storage(qs_item)
        else
            if player_inventory then
                player_inventory.remove({name = qs_item.name, count = 1, quality = qs_item.quality})
            end
        end
        entity.destroy({raise_destroy = true})
        return true
    end
    return false
end