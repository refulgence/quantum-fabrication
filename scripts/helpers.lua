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

---comment
---@param item string | table
---@return boolean
function is_placeable(item)
    local item_name
    if type(item) == "string" then
        item_name = item
    else
        if item.type ~= "item" then return false end
        item_name = item.name
    end
    if not global.placeable then global.placeable = {} end
    if global.placeable[item_name] ~= nil then return global.placeable[item_name] end
    local item_prototype = game.item_prototypes[item_name]
    --if item_prototype and item_prototype.place_result and item_prototype.place_result.type ~= "logistic-robot" and item_prototype.place_result.type ~= "construction-robot" and item_prototype.place_result.type ~= "unit" and item_prototype.place_result.type ~= "spider-vehicle" and item_prototype.place_result.type ~= "car" then
    if item_prototype and item_prototype.place_result and item_prototype.place_result.create_ghost_on_death and not item_prototype.place_result.has_flag("hidden") then
        global.placeable[item_name] = true
        return true
    end
    global.placeable[item_name] = false
    return false
end

---comment
---@param item_name string
---@return boolean
function is_module(item_name)
    local item_prototype = game.item_prototypes[item_name]
    return item_prototype and item_prototype.type == "module"
end


---Returns the first enabled recipe for that item. this doesn't care about craftability
---@param item_name string
---@param player_inventory LuaInventory
---@return table | nil
function get_decraftable_recipe(item_name, player_inventory)
    local recipes = global.product_craft_data[item_name]
    if not recipes then return nil end
    for _, recipe in ipairs(recipes) do
        if is_recipe_enabled(recipe.recipe_name) and is_recipe_craftable({ingredients = global.unpacked_recipes[recipe.recipe_name].products}, player_inventory) then
            return global.unpacked_recipes[recipe.recipe_name]
        end
    end
    return nil
end


---Returns the first enabled, craftable and non-blacklisted recipe for that item
---@param item_name string
---@param player_inventory LuaInventory
---@return table | nil
function get_craftable_recipe(item_name, player_inventory)
    local recipes = global.product_craft_data[item_name]
    if not recipes then game.print("no recipes for " .. item_name .. ", this shouldn't happen") return nil end
    for _, recipe in ipairs(recipes) do
        if is_recipe_enabled(recipe.recipe_name) and is_recipe_craftable(global.unpacked_recipes[recipe.recipe_name], player_inventory) and not recipe.blacklisted then
            return global.unpacked_recipes[recipe.recipe_name]
        end
    end
    return nil
end

---comment
---@param recipe_name string
---@return boolean
function is_recipe_enabled(recipe_name)
    return game.forces["player"].recipes[recipe_name].enabled
end

---comment
---@param recipe table
---@param player_inventory LuaInventory
---@return boolean
function is_recipe_craftable(recipe, player_inventory)
    for _, ingredient in pairs(recipe.ingredients) do
        if not global.fabricator_inventory[ingredient.type][ingredient.name] then global.fabricator_inventory[ingredient.type][ingredient.name] = 0 end
        if ingredient.type == "item" then
            if global.fabricator_inventory[ingredient.type][ingredient.name] + player_inventory.get_item_count(ingredient.name) < ingredient.amount then
                return false
            end
        else
            if global.fabricator_inventory[ingredient.type][ingredient.name] < ingredient.amount then
                return false
            end
        end
    end
    return true
end

