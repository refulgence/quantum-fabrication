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
                global.fabricator_inventory[ingredient.type][ingredient.name] = global.fabricator_inventory[ingredient.type][ingredient.name] - required
            end
        else
            global.fabricator_inventory[ingredient.type][ingredient.name] = global.fabricator_inventory[ingredient.type][ingredient.name] - required
        end

    end
    for _, product in pairs(recipe.products) do
            add_to_player_inventory(player_inventory, {name = product.name, type = product.type, amount = product.amount})
    end
end


---comment
---@param player_inventory LuaInventory
---@param item table
function add_to_player_inventory(player_inventory, item)
    if not global.fabricator_inventory[item.type][item.name] then global.fabricator_inventory[item.type][item.name] = 0 end
    if is_placeable(item.name) or is_module(item.name) or global.ingredient[item.name] or item.type == "fluid" then
        global.fabricator_inventory[item.type][item.name] = global.fabricator_inventory[item.type][item.name] + item.amount
    else
        local inserted = player_inventory.insert(item)
        global.fabricator_inventory.item[item.name] = global.fabricator_inventory.item[item.name] + item.amount - inserted
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
            global.fabricator_inventory.item[entity_name] = global.fabricator_inventory.item[entity_name] - 1
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
        global.fabricator_inventory.item[modules.name] = global.fabricator_inventory.item[modules.name] - modules.count
    else
        inventory.remove({name = modules.name, count = modules.count})
    end
    module_inventory.insert(modules)
end