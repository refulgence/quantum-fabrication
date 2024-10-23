
---@class QSItem Format for items/fluids used in storage and fabrication
---@field name string
---@field count? int
---@field amount? int
---@field type "item"|"fluid"
---@field quality? string Quality name

---@class StorageStatusTable
---@field empty_storage boolean
---@field full_inventory boolean


---@class qs_utils
local qs_utils = {}



---@param qs_item QSItem
---@param try_defabricate boolean
function qs_utils.add_to_storage(qs_item, try_defabricate)
    if not qs_item then return end
    qs_utils.storage_item_check(qs_item)
    storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] + (qs_item.count or qs_item.amount)
    if try_defabricate then decraft(qs_item) end
end


---@param qs_item QSItem
function qs_utils.remove_from_storage(qs_item)
    if not qs_item then return end
    qs_utils.storage_item_check(qs_item)
    storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] - (qs_item.count or qs_item.amount)
end




---Actually it first adds all placeables/modules/ingredients to the storage and only then adds the leftovers to the player's inventory
---@param player_inventory LuaInventory
---@param qs_item QSItem
function qs_utils.add_to_player_inventory(player_inventory, qs_item)
    qs_utils.storage_item_check(qs_item)
    if qs_item.type == "fluid" or is_placeable(qs_item.name) or storage.ingredient[qs_item.name] or is_module(qs_item.name) then
        qs_utils.add_to_storage(qs_item, true)
    else
        local inserted = player_inventory.insert({name = qs_item.name, count = qs_item.amount, quality = qs_item.quality})
        if qs_item.amount - inserted > 0 then qs_utils.add_to_storage({name = qs_item.name, amount = qs_item.amount - inserted, type = qs_item.type, quality = qs_item.quality}, false) end
    end
end


---@param qs_item QSItem
function qs_utils.storage_item_check(qs_item)
    qs_utils.set_default_quality(qs_item)
    if not storage.fabricator_inventory[qs_item.type] or not storage.fabricator_inventory[qs_item.type][qs_item.name] or not storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] then
        storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality] = 0
    end
end

---@param qs_item QSItem
function qs_utils.set_default_quality(qs_item)
    if not qs_item.quality then qs_item.quality = QS_DEFAULT_QUALITY end
end


---Transfers items/fluids from storage to target inventory. Used by dedigitizing reactors and that's it
---@param qs_item QSItem
---@param target_inventory LuaInventory | LuaEntity
---@return StorageStatusTable
function qs_utils.pull_from_storage(qs_item, target_inventory)
    qs_utils.storage_item_check(qs_item)
    local available = storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality]
    local to_be_provided = qs_item.count or qs_item.amount
    local status = {empty_storage = false, full_inventory = false}
    if available == 0 then
        status.empty_storage = true
        return status
    end
    if available < to_be_provided then
        to_be_provided = available
        status.empty_storage = true
    end
    if qs_item.type == "item" then
        local inserted = target_inventory.insert({name = qs_item.name, count = to_be_provided, type = qs_item.type, quality = qs_item.quality})
        qs_utils.remove_from_storage({type = qs_item.type, name = qs_item.name, count = inserted, quality = qs_item.quality})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    if qs_item.type == "fluid" then
        local current_fluid = target_inventory.get_fluid_contents()
        for name, amount in pairs(current_fluid) do
            if name == qs_item.name then
                ---@diagnostic disable-next-line: assign-type-mismatch
                local inserted = target_inventory.insert_fluid{name = qs_item.name, amount = to_be_provided}
                qs_utils.remove_from_storage({type = qs_item.type, name = qs_item.name, amount = inserted})
                if inserted < to_be_provided then
                    status.full_inventory = true
                end
                return status
            else
                qs_utils.add_to_storage({name = name, amount = target_inventory.remove_fluid{name = name, amount = amount}, type = "fluid"}, false)
            end
        end
        ---@diagnostic disable-next-line: assign-type-mismatch
        local inserted = target_inventory.insert_fluid{name = qs_item.name, amount = to_be_provided}
        qs_utils.remove_from_storage({type = qs_item.type, name = qs_item.name, amount = inserted})
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    return status
end



---@param item_name string
---@return boolean
function qs_utils.is_placeable(item_name)
    if storage.placeable[item_name] ~= nil then return storage.placeable[item_name] end
    local item_prototype = prototypes.item[item_name]
    if item_prototype and item_prototype.place_result and item_prototype.place_result.create_ghost_on_death and not item_prototype.place_result.hidden then
        storage.placeable[item_name] = true
        return true
    end
    storage.placeable[item_name] = false
    return false
end

---@param item_name string
---@return boolean
function qs_utils.is_module(item_name)
    if storage.modules[item_name] ~= nil then return storage.modules[item_name] end
    local item_prototype = prototypes.item[item_name]
    storage.modules[item_name] = item_prototype and item_prototype.type == "module"
    return storage.modules[item_name]
end


---Returns the first enabled recipe for that item. this doesn't care about craftability
---@param qs_item QSItem
---@return table | nil
function qs_utils.get_decraftable_recipe(qs_item)
    local item_name = qs_item.name
    local recipes = storage.product_craft_data[item_name]
    local unpacked_recipes = storage.unpacked_recipes
    if not recipes then return nil end
    for i = 1, recipes[1].number_of_recipes do
        if unpacked_recipes[recipes[i].recipe_name].enabled and qs_utils.is_recipe_decraftable({ingredients = unpacked_recipes[recipes[i].recipe_name].products}, qs_item.quality) then
            return unpacked_recipes[recipes[i].recipe_name]
        end
    end
    return nil
end


---Returns the first enabled, craftable and non-blacklisted recipe for that item
---@param qs_item QSItem
---@param player_inventory LuaInventory
---@return table | nil
function qs_utils.get_craftable_recipe(qs_item, player_inventory)
    local item_name = qs_item.name
    local recipes = storage.product_craft_data[item_name]
    if not recipes then game.print("no recipes for " .. item_name .. ", this shouldn't happen") return nil end
    for i = 1, recipes[1].number_of_recipes do
        if storage.unpacked_recipes[recipes[i].recipe_name].enabled and qs_utils.is_recipe_craftable(storage.unpacked_recipes[recipes[i].recipe_name], qs_item.quality, player_inventory) and not recipes[i].blacklisted then
            return storage.unpacked_recipes[recipes[i].recipe_name]
        end
    end
    return nil
end

---comment
---@param recipe table
---@param quality string
---@param player_inventory LuaInventory
---@return boolean
function qs_utils.is_recipe_craftable(recipe, quality, player_inventory)
    for _, ingredient in pairs(recipe.ingredients) do
        qs_utils.storage_item_check(ingredient)
        if qs_utils.count_in_storage({name = ingredient.name, type = ingredient.type, quality = quality}, player_inventory) < ingredient.amount then
            return false
        end
    end
    return true
end

---Question - why there are two functions that do pretty much the same thing? TODO: delete one of them
---@param recipe table
---@param quality string
---@return boolean
function qs_utils.is_recipe_decraftable(recipe, quality)
    for _, ingredient in pairs(recipe.ingredients) do
        qs_utils.storage_item_check(ingredient)
        if qs_utils.count_in_storage({name = ingredient.name, type = ingredient.type, quality = quality}) < ingredient.amount then
            return false
        end
    end
    return true
end


---How many of that item is available in storage (and player_inventory if it's provided)
---@param qs_item QSItem
---@param player_inventory? LuaInventory
function qs_utils.count_in_storage(qs_item, player_inventory)
    local available = storage.fabricator_inventory[qs_item.type][qs_item.name][qs_item.quality]
    if player_inventory and qs_item.type == "item" then
        available = available + player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
    end
    return available
end


---comment
---@param recipe table
---@param player_inventory LuaInventory | nil
---@return int
function qs_utils.how_many_can_craft(recipe, quality, player_inventory)
    local result
    for _, ingredient in pairs(recipe.ingredients) do
        qs_utils.storage_item_check(ingredient)
        local available = qs_utils.count_in_storage({name = ingredient.name, type = ingredient.type, quality = quality}, player_inventory)
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


return qs_utils