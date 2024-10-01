---comment
---@param entity LuaEntity
---@param player_index int
function instant_fabrication(entity, player_index)
    local item_name = global.prototypes_data[entity.ghost_name].item_name
    if not item_name then game.print("instant_defabrication error - item name not found for " .. entity.ghost_name .. ", this shouldn't happen") return false end
    local player_inventory = game.players[player_index].get_inventory(defines.inventory.character_main)
    if not player_inventory then game.print("player inventory not found for " .. player_index) return end
    if not global.fabricator_inventory.item[item_name] then global.fabricator_inventory.item[item_name] = 0 end

    if player_inventory.get_item_count(item_name) > 0 then
        return revive_ghost(entity, player_inventory, "player")
    end
    if global.fabricator_inventory.item[item_name] > 0 then
        return revive_ghost(entity, player_inventory, "digital storage")
    end
    -- Nothing? Guess we are fabricating
    local recipe = get_craftable_recipe(item_name, player_inventory)
    if not recipe then return false end
    fabricate_recipe(recipe, player_inventory)
    return revive_ghost(entity, player_inventory, "digital storage")
end


---Fabricates a recipe. That recipe must be already checked
---@param recipe table
---@param player_inventory LuaInventory
function fabricate_recipe(recipe, player_inventory)
    for _, ingredient in pairs(recipe.ingredients) do
        local required = ingredient.amount
        if player_inventory.get_item_count(ingredient.name) > 0 then
            if player_inventory.get_item_count(ingredient.name) >= required then
                player_inventory.remove({name = ingredient.name, count = required})
            else
                required = required - player_inventory.get_item_count(ingredient.name)
                player_inventory.remove({name = ingredient.name, count = player_inventory.get_item_count(ingredient.name)})
                remove_from_storage({name = ingredient.name, amount = required, type = ingredient.type})
            end
        else
            remove_from_storage({name = ingredient.name, amount = required, type = ingredient.type})
        end

    end
    for _, product in pairs(recipe.products) do
            add_to_player_inventory(player_inventory, {name = product.name, type = product.type, amount = product.amount})
    end
end


---comment
---@param entity LuaEntity
---@param player_inventory LuaInventory
---@param inventory_type string
function revive_ghost(entity, player_inventory, inventory_type)
    local entity_name = global.prototypes_data[entity.ghost_name].item_name
    local modules = entity.item_requests
    _, revived_entity, item_request_proxy = entity.revive({raise_revive = true, return_item_request_proxy = true})
    if revived_entity and revived_entity.valid then
        if inventory_type == "digital storage" then
            remove_from_storage({name = entity_name, count = 1, type = "item"})
        else
            player_inventory.remove({name = entity_name, count = 1})
        end
        if modules and modules ~= {} then
            if not add_modules(revived_entity, modules, player_inventory) then create_tracked_request({entity = revived_entity, player_index = player_inventory.player_owner.index, item_request_proxy = item_request_proxy, request_type = "modules"}) end
        end
        return true
    end
    return false
end


---comment
---@param entity LuaEntity
---@param modules table
---@param inventory LuaInventory
function add_modules(entity, modules, inventory)
    local module_inventory = entity.get_module_inventory()
    local satisfied = true
    if not module_inventory then return true end
    for module, amount in pairs(modules) do
        local required = amount
        required = process_modules(entity, module, amount, inventory, "player")
        if required == 0 then goto continue end
        required = process_modules(entity, module, required, inventory, "digital storage")
        if required > 0 then satisfied = false end
        ::continue::
    end
    return satisfied
end


---comment
---@param entity LuaEntity
---@param module string
---@param amount int
---@param inventory LuaInventory
---@param inventory_type string
---@return int
function process_modules(entity, module, amount, inventory, inventory_type)
    if inventory_type == "digital storage" then
        if not global.fabricator_inventory.item[module] then global.fabricator_inventory.item[module] = 0 end
        if global.fabricator_inventory.item[module] > 0 then
            if global.fabricator_inventory.item[module] >= amount then
                insert_modules(entity, {name = module, count = amount}, inventory, "digital storage")
            else
                insert_modules(entity, {name = module, count = global.fabricator_inventory.item[module]},  inventory, "digital storage")
            end
        end
    else
        if inventory.get_item_count(module) > 0 then
            if inventory.get_item_count(module) >= amount then
                insert_modules(entity, {name = module, count = amount}, inventory, "player")
            else
                insert_modules(entity, {name = module, count = inventory.get_item_count(module)}, inventory, "player")
            end
        end
    end
    return amount - inventory.get_item_count(module)
end


---comment
---@param entity LuaEntity
---@param modules table {name = string, count = int}
---@param inventory LuaInventory
---@param inventory_type string
function insert_modules(entity, modules, inventory, inventory_type)
    local module_inventory = entity.get_module_inventory()
    if not module_inventory then return end
    if inventory_type == "digital storage" then
        remove_from_storage({name = modules.name, count = modules.count, type = "item"})
    else
        inventory.remove({name = modules.name, count = modules.count})
    end
    module_inventory.insert(modules)
end


---comment
---@param entity LuaEntity
---@param player_index int
function instant_defabrication(entity, player_index)
    local item_name = global.prototypes_data[entity.name].item_name
    add_to_storage({name = item_name, amount = 1, type = "item"}, true)
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
    if entity.prototype.loot then process_loot(entity.prototype.loot, player_inventory) end
    if entity.prototype.mineable_properties and entity.prototype.mineable_properties.products then process_mining(entity.prototype.mineable_properties, player_inventory) end
    if entity.prototype.type == "item-entity" then add_to_player_inventory(player_inventory, {name = entity.stack.name, amount = entity.stack.count, type = "item"}) end
    entity.destroy({raise_destroy = true})
end


---comment
---@param loot table
---@param player_inventory LuaInventory
function process_loot(loot, player_inventory)
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
    if not mining_properties or not mining_properties.products then return end
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


function decraft(item)
    local recipe = get_decraftable_recipe(item.name)
    if recipe then
        defabricate_recipe({products = recipe.ingredients, ingredients = recipe.products, count = item.count})
    end
end


function defabricate_recipe(recipe)
    local multiplier = 1
    if recipe.count and recipe.count > 1 then
        multiplier = math.min(recipe.count, how_many_can_craft(recipe, nil))
    end
    for _, ingredient in pairs(recipe.ingredients) do
        remove_from_storage({name = ingredient.name, amount = ingredient.amount * multiplier, type = ingredient.type})
    end
    for _, product in pairs(recipe.products) do
        add_to_storage({name = product.name, amount = product.amount * multiplier, type = product.type}, false)
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