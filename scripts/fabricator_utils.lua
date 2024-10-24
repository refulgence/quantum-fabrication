local qs_utils = require("scripts/storage_utils")

---@class qf_utils
local qf_utils = {}



---comment
---@param recipe table
---@param quality string
---@param player_inventory? LuaInventory
---@param surface_index uint
---@return int
function qf_utils.how_many_can_craft(recipe, quality, player_inventory, surface_index)
    local result
    for _, ingredient in pairs(recipe.ingredients) do
        qs_utils.storage_item_check(ingredient)
        local available = qs_utils.count_in_storage({name = ingredient.name, type = ingredient.type, quality = quality, surface_index = surface_index}, player_inventory)
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
---@param recipe table
---@param quality string
---@param player_inventory? LuaInventory
---@param surface_index uint
---@return boolean
function qf_utils.is_recipe_craftable(recipe, quality, player_inventory, surface_index)
    for _, ingredient in pairs(recipe.ingredients) do
        local qs_item = {name = ingredient.name, type = ingredient.type, quality = quality, surface_index = surface_index}
        qs_utils.storage_item_check(qs_item)
        if qs_utils.count_in_storage(qs_item, player_inventory) < ingredient.amount then
            return false
        end
    end
    return true
end


---@param qs_item QSItem
---@param player_inventory? LuaInventory
---@param decraft? boolean
---@return table | nil
function qf_utils.get_craftable_recipe(qs_item, player_inventory, decraft)
    local item_name = qs_item.name
    local recipes = storage.product_craft_data[item_name]
    local unpacked_recipes = storage.unpacked_recipes
    if not recipes then return nil end
    for i = 1, recipes[1].number_of_recipes do
        local recipe = unpacked_recipes[recipes[i].recipe_name]
        if recipe.enabled
        and qf_utils.is_recipe_craftable(recipe, qs_item.quality, player_inventory, qs_item.surface_index)
        and not recipes[i].blacklisted then
            if decraft then
                recipe.ingredients, recipe.products = recipe.products, recipe.ingredients
            end
            return recipe
        end
    end
    return nil
end


---Fabricates a recipe. That recipe must be already checked or we could dip into negative storage and other funny stuff
---@param recipe table
---@param quality string
---@param surface_index uint
---@param player_inventory? LuaInventory
---@param multiplier? int
function qf_utils.fabricate_recipe(recipe, quality, surface_index, player_inventory, multiplier)
    if multiplier then
        multiplier = math.min(multiplier, qf_utils.how_many_can_craft(recipe, quality, player_inventory, surface_index))
    else
        multiplier = 1
    end

    for _, ingredient in pairs(recipe.ingredients) do
        local qs_item = qs_utils.to_qs_item({
            name = ingredient.name,
            type = ingredient.type,
            count = ingredient.amount * multiplier,
            quality = quality,
            surface_index = surface_index
        })

        local player_item_count
        if player_inventory and qs_item.type == "item" then
            player_item_count = player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
        end

        if player_item_count and player_item_count > 0 then
            if player_item_count >= qs_item.count then
                ---@diagnostic disable-next-line: need-check-nil
                player_inventory.remove({name = ingredient.name, count = qs_item.count, quality = quality})
            else
                ---@diagnostic disable-next-line: need-check-nil
                player_inventory.remove({name = ingredient.name, count = player_item_count, quality = quality})
                qs_item.count = qs_item.count - player_item_count
                qs_utils.remove_from_storage(qs_item)
            end
        else
            qs_utils.remove_from_storage(qs_item)
        end

    end
    -- This doesn't work for products with variable amounts. Let's just pretend recipes with such products do not exist for now
    for _, product in pairs(recipe.products) do
        local qs_item = qs_utils.to_qs_item({
            name = product.name,
            type = product.type,
            count = product.amount * multiplier,
            quality = quality,
            surface_index = surface_index
        })
            qs_utils.add_to_storage(qs_item, false)
    end
end



return qf_utils