---comment
---@param entity LuaEntity
---@param player_index int
function instant_defabrication(entity, player_index)
    local item_name = global.prototypes_data[entity.name].item_name
    local player_inventory = game.players[player_index].get_inventory(defines.inventory.character_main)
    if not player_inventory then return end
    add_to_player_inventory(player_inventory, {name = item_name, amount = 1, type = "item"})
    local recipe = get_decraftable_recipe(item_name, player_inventory)
    if recipe then
        fabricate_recipe({products = recipe.ingredients, ingredients = recipe.products}, player_inventory)
    end
    return entity.destroy({raise_destroy = true})
end

---comment
---@param entity LuaEntity
---@param player_inventory LuaInventory
function process_inventory(entity, player_inventory)
    local max_index = entity.get_max_inventory_index()
    if not max_index then return end
    for i = 1, max_index do
        local inventory = entity.get_inventory(i)
        if inventory and not inventory.is_empty() and inventory.get_contents() then
            for name, count in pairs(inventory.get_contents()) do
                add_to_player_inventory(player_inventory, {name = name, amount = count, type = "item"})
            end
        end
    end
end

---comment
---@param entity LuaEntity
---@param player_index int
function instant_deforestation(entity, player_index)
    local player_inventory = game.players[player_index].get_inventory(defines.inventory.character_main)
    if not player_inventory then return end
    process_loot(entity.prototype.loot, player_inventory)
    process_mining(entity.prototype.mineable_properties, player_inventory)
    entity.destroy()
end

---comment
---@param loot table
---@param player_inventory LuaInventory
function process_loot(loot, player_inventory)
    if not loot then return end
    for _, item in pairs(loot) do
        if item.probability >= math.random() then
            add_to_player_inventory(player_inventory, {name = item.item, amount = math.random(item.count_min, item.count_max), type = "item"})
        end
    end
end

---comment
---@param mining_properties table
---@param player_inventory LuaInventory
function process_mining(mining_properties, player_inventory)
    if not mining_properties then return end
    for _, item in pairs(mining_properties.products) do
        if item.probability >= math.random() then
            if item.amount then
                add_to_player_inventory(player_inventory, {name = item.name, amount = item.amount, type = item.type})
            else
                add_to_player_inventory(player_inventory, {name = item.name, amount = math.random(item.amount_min, item.amount_max), type = item.type})
            end
        end
    end
end