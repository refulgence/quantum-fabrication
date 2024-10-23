---comment
---@param t1 table
---@param t2 table
---@return table
function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

-- do i even need so many
function int_to_str_si(n)
    if     n <= 99999 then
        return tostring(n)
    elseif n <= 999999 then
        return tostring(math.floor(n / 100) / 10) .. "k"
    elseif n <= 999999999 then
        return tostring(math.floor(n / 100000) / 10) .. "M"
    elseif n <= 999999999999 then
        return tostring(math.floor(n / 100000000) / 10) .. "G"
    elseif n <= 999999999999999 then
        return tostring(math.floor(n / 100000000000) / 10) .. "T"
    elseif n <= 999999999999999999 then
        return tostring(math.floor(n / 100000000000000) / 10) .. "P"
    else
        return tostring(math.floor(n / 100000000000000000) / 10) .. "E"
    end
end

---comment
---@param item_name string
---@return boolean
function is_placeable(item_name)
    if storage.placeable[item_name] ~= nil then return storage.placeable[item_name] end
    local item_prototype = prototypes.item[item_name]
    if item_prototype and item_prototype.place_result and item_prototype.place_result.create_ghost_on_death and not item_prototype.place_result.hidden then
        storage.placeable[item_name] = true
        return true
    end
    storage.placeable[item_name] = false
    return false
end

---comment
---@param item_name string
---@return boolean
function is_module(item_name)
    if storage.modules[item_name] ~= nil then return storage.modules[item_name] end
    local item_prototype = prototypes.item[item_name]
    storage.modules[item_name] = item_prototype and item_prototype.type == "module"
    return storage.modules[item_name]
end


---Returns the first enabled recipe for that item. this doesn't care about craftability
---@param item_name string
---@return table | nil
function get_decraftable_recipe(item_name)
    local recipes = storage.product_craft_data[item_name]
    local unpacked_recipes = storage.unpacked_recipes
    if not recipes then return nil end
    for i = 1, recipes[1].number_of_recipes do
        if unpacked_recipes[recipes[i].recipe_name].enabled and is_recipe_decraftable({ingredients = unpacked_recipes[recipes[i].recipe_name].products}) then
            return unpacked_recipes[recipes[i].recipe_name]
        end
    end
    return nil
end


---Returns the first enabled, craftable and non-blacklisted recipe for that item
---@param item_name string
---@param player_inventory LuaInventory
---@return table | nil
function get_craftable_recipe(item_name, player_inventory)
    local recipes = storage.product_craft_data[item_name]
    if not recipes then game.print("no recipes for " .. item_name .. ", this shouldn't happen") return nil end
    for i = 1, recipes[1].number_of_recipes do
        if storage.unpacked_recipes[recipes[i].recipe_name].enabled and is_recipe_craftable(storage.unpacked_recipes[recipes[i].recipe_name], player_inventory) and not recipes[i].blacklisted then
            return storage.unpacked_recipes[recipes[i].recipe_name]
        end
    end
    return nil
end

---comment
---@param recipe table
---@param player_inventory LuaInventory
---@return boolean
function is_recipe_craftable(recipe, player_inventory)
    for _, ingredient in pairs(recipe.ingredients) do
        if not storage.fabricator_inventory[ingredient.type][ingredient.name] then storage.fabricator_inventory[ingredient.type][ingredient.name] = 0 end
        if ingredient.type == "item" then
            if storage.fabricator_inventory[ingredient.type][ingredient.name] + player_inventory.get_item_count(ingredient.name) < ingredient.amount then
                return false
            end
        else
            if storage.fabricator_inventory[ingredient.type][ingredient.name] < ingredient.amount then
                return false
            end
        end
    end
    return true
end

---comment
---@param recipe table
---@return boolean
function is_recipe_decraftable(recipe)
    for _, ingredient in pairs(recipe.ingredients) do
        if not storage.fabricator_inventory[ingredient.type][ingredient.name] then storage.fabricator_inventory[ingredient.type][ingredient.name] = 0 end
        if storage.fabricator_inventory[ingredient.type][ingredient.name] < ingredient.amount then
            return false
        end
    end
    return true
end


---comment
---@param recipe table
---@param player_inventory LuaInventory | nil
---@return int
function how_many_can_craft(recipe, player_inventory)
    local result
    for _, ingredient in pairs(recipe.ingredients) do
        if not storage.fabricator_inventory[ingredient.type][ingredient.name] then storage.fabricator_inventory[ingredient.type][ingredient.name] = 0 end
        local available = 0
        if ingredient.type == "item" and player_inventory then
            available = player_inventory.get_item_count(ingredient.name) + storage.fabricator_inventory[ingredient.type][ingredient.name]
        else
            available = storage.fabricator_inventory[ingredient.type][ingredient.name]
        end
        if available < ingredient.amount then
            return 0
        else
            if not result then
                result = math.floor(available / ingredient.amount)
            else
                result = math.min(result, math.floor(available / ingredient.amount))
            end
        end
    end
    return result or 0
end


---comment
---@param player_inventory LuaInventory
---@param item table
function add_to_player_inventory(player_inventory, item)
    if not storage.fabricator_inventory[item.type][item.name] then storage.fabricator_inventory[item.type][item.name] = 0 end
    if is_placeable(item.name) or is_module(item.name) or storage.ingredient[item.name] or item.type == "fluid" then
        add_to_storage(item, true)
    else
        local inserted = player_inventory.insert(item)
        if item.amount - inserted > 0 then add_to_storage({name = item.name, amount = item.amount - inserted, type = item.type}, false) end
    end
end


---comment
---@param item table
---@param try_defabricate boolean
function add_to_storage(item, try_defabricate)
    if not item then return end
    if not storage.fabricator_inventory[item.type][item.name] then storage.fabricator_inventory[item.type][item.name] = 0 end
    storage.fabricator_inventory[item.type][item.name] = storage.fabricator_inventory[item.type][item.name] + (item.count or item.amount)
    if try_defabricate then decraft(item) end
end


---comment
---@param item table
function remove_from_storage(item)
    if not item then return end
    storage.fabricator_inventory[item.type][item.name] = storage.fabricator_inventory[item.type][item.name] - (item.count or item.amount)
end


---comment
---@param item table
---@param target_inventory LuaInventory | LuaEntity
---@return table
function pull_from_storage(item, target_inventory)
    if not storage.fabricator_inventory[item.type][item.name] then storage.fabricator_inventory[item.type][item.name] = 0 end
    local available = storage.fabricator_inventory[item.type][item.name]
    local to_be_provided = item.count or item.amount
    local status = {empty_storage = false, full_inventory = false}
    if available == 0 then
        status.empty_storage = true
        return status
    end
    if available < to_be_provided then
        to_be_provided = available
        status.empty_storage = true
    end
    if item.type == "item" then
        local inserted = target_inventory.insert({name = item.name, count = to_be_provided, type = item.type})
        remove_from_storage({type = item.type, name = item.name, count = inserted})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    if item.type == "fluid" then
        local current_fluid = target_inventory.get_fluid_contents()
        for name, amount in pairs(current_fluid) do
            if name == item.name then
                local inserted = target_inventory.insert_fluid{name = item.name, amount = to_be_provided}
                remove_from_storage({type = item.type, name = item.name, amount = inserted})
                if inserted < to_be_provided then
                    status.full_inventory = true
                end
                return status
            else
                add_to_storage({name = name, amount = target_inventory.remove_fluid{name = name, amount = amount}, type = "fluid"}, false)
            end
        end
        local inserted = target_inventory.insert_fluid{name = item.name, amount = to_be_provided}
        remove_from_storage({type = item.type, name = item.name, amount = inserted})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    return status
end