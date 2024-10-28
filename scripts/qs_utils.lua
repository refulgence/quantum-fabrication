local utils = require("scripts/utils")

---@class QSItem Format for items/fluids used in storage and fabrication
---@field name string
---@field count? int One of count or amount is required. Think about a way to change it
---@field amount? int
---@field type "item"|"fluid"
---@field quality? string Quality name
---@field surface_index uint Surface where this item/fluid is stored or processed

---@class StorageStatusTable
---@field empty_storage boolean
---@field full_inventory boolean


---@class qs_utils
local qs_utils = {}


---@param qs_item QSItem
---@param try_defabricate? boolean
---@param count_override? int
function qs_utils.add_to_storage(qs_item, try_defabricate, count_override)
    if not qs_item then return end
    storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] + (count_override or (qs_item.count or qs_item.amount))
    if try_defabricate and settings.global["qf-allow-decrafting"].value and not storage.tiles[qs_item.name] then decraft(qs_item) end
end


---@param qs_item QSItem
---@param count_override? int
function qs_utils.remove_from_storage(qs_item, count_override)
    if not qs_item then return end
    storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] - (count_override or (qs_item.count or qs_item.amount))
end


---Actually it first adds all placeables/modules/ingredients to the storage and only then adds the leftovers to the player's inventory
---@param player_inventory? LuaInventory
---@param qs_item QSItem
function qs_utils.add_to_player_inventory(player_inventory, qs_item)
    if qs_item.type == "fluid" or utils.is_placeable(qs_item.name) or storage.ingredient[qs_item.name] or utils.is_module(qs_item.name) or not player_inventory then
        qs_utils.add_to_storage(qs_item, true)
    else
        local inserted = player_inventory.insert({name = qs_item.name, count = qs_item.count, quality = qs_item.quality})
        if qs_item.count - inserted > 0 then
            qs_item.count = qs_item.count - inserted
            qs_utils.add_to_storage(qs_item)
        end
    end
end

---TODO: initialize fabricator_inventory for newly created surfaces, so we won't have to do throught this thing again and again
---@param qs_item QSItem
function qs_utils.storage_item_check(qs_item)
    qs_utils.set_default_quality(qs_item)
    if not storage.fabricator_inventory[qs_item.surface_index] then
        storage.fabricator_inventory[qs_item.surface_index] = {}
    end
    if not storage.fabricator_inventory[qs_item.surface_index][qs_item.type] then
        storage.fabricator_inventory[qs_item.surface_index][qs_item.type] = {}
    end
    if not storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name] then
        storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name] = {}
    end
    if not storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] then
        storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = 0
    end
end

---Because liquids may not have quality? Might not be needed
---@param qs_item QSItem
function qs_utils.set_default_quality(qs_item)
    if not qs_item.quality then qs_item.quality = QS_DEFAULT_QUALITY end
end

---Transfers items/fluids from storage to target inventory. Used by dedigitizing reactors and that's it
---@param qs_item QSItem
---@param target_inventory LuaInventory | LuaEntity
---@return StorageStatusTable
function qs_utils.pull_from_storage(qs_item, target_inventory)
    local available = qs_utils.count_in_storage(qs_item)
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
        qs_item.count = inserted
        qs_utils.remove_from_storage(qs_item)
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    elseif qs_item.type == "fluid" then
        local current_fluid = target_inventory.get_fluid_contents()
        for name, amount in pairs(current_fluid) do
            if name == qs_item.name then
                ---@diagnostic disable-next-line: assign-type-mismatch
                local inserted = target_inventory.insert_fluid{name = qs_item.name, amount = to_be_provided}
                qs_item.amount = inserted
                qs_utils.remove_from_storage(qs_item)
                if inserted < to_be_provided then
                    status.full_inventory = true
                end
                return status
            else
                qs_utils.add_to_storage({surface_index = qs_item.surface_index, name = name, amount = target_inventory.remove_fluid{name = name, amount = amount}, type = "fluid"})
            end
        end
        ---@diagnostic disable-next-line: assign-type-mismatch
        local inserted = target_inventory.insert_fluid{name = qs_item.name, amount = to_be_provided}
        qs_item.amount = inserted
        qs_utils.remove_from_storage(qs_item)
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    return status
end

---How many of that item is available in storage (and player_inventory if it's provided)
---@param qs_item QSItem
---@param player_inventory? LuaInventory
function qs_utils.count_in_storage(qs_item, player_inventory)
    local available = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality]
    if player_inventory and qs_item.type == "item" then
        available = available + player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
    end
    return available
end


---Checks is qs_item is available in player's inventory, or in storage and returns which one
---@param qs_item any
---@param player_inventory? any
---@param player_surface_index? any
---@return "storage"|"player"|"both"|nil
function qs_utils.check_in_storage(qs_item, player_inventory, player_surface_index)
    if qs_utils.count_in_storage(qs_item) > 0 then
        return "storage"
    end
    if qs_item.type == "item" and player_inventory and qs_item.surface_index == player_surface_index
    and player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality}) > 0 then
        return "player"
    end
    if qs_item.type == "item" and player_inventory and qs_item.surface_index == player_surface_index
    and player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality}) + qs_utils.count_in_storage(qs_item) > 0 then
        return "both"
    end
    return nil
end

---Returns a table
---@param surface_index uint
---@return table
function qs_utils.get_available_tiles(surface_index)
    local result = {}
    for tile_name, _ in pairs(storage.tiles) do
        result[tile_name] = qs_utils.count_in_storage({
            name = tile_name,
            surface_index = surface_index,
            quality = QS_DEFAULT_QUALITY,
            type = "item",
        })
    end
    return result
end


---Converts an array of items to QSItem format (which basically means enforce quality and surface_index)
---@param items table
---@param surface_index uint
---@param quality? string
---@return table
function qs_utils.items_to_qs_items(items, surface_index, quality)
    local qs_items = {}
    for _, item in pairs(items) do
        qs_items[#qs_items + 1] = qs_utils.to_qs_item(item, surface_index, quality)
    end
    return qs_items
end

---Converts a single item/fluid to QSItem format (which basically means enforce quality and surface_index)
---This is also where we can change amount to count for fluids because why are they different?
---@param item table
---@param surface_index_override? uint
---@param quality? string
---@return QSItem
function qs_utils.to_qs_item(item, surface_index_override, quality)
    local qs_quality
    if item.quality then
        if item.quality.name then
            qs_quality = item.quality.name
        else
            qs_quality = item.quality
        end
    else
        qs_quality = quality or QS_DEFAULT_QUALITY
    end
    if item.type == "fluid" then
        qs_quality = QS_DEFAULT_QUALITY
    end
    return {
        name = item.name,
        count = item.count,
        amount = item.amount,
        type = item.type or "item",
        quality = qs_quality,
        surface_index = surface_index_override or item.surface_index
    }
end

---Takes a stack of items from storage to the player's inventory. Only if the player is physically present on the same surface (to prevent some cheesing)
---@param qs_item any
---@param player any
function qs_utils.take_from_storage(qs_item, player)
    local item_name = qs_item.name
    local quality_name = qs_item.quality
    local prototype = prototypes.item[item_name]
    if not prototype then return end
    local player_inventory = player.get_inventory(defines.inventory.character_main)
    local available = qs_utils.count_in_storage(qs_item)
    if available == 0 then return end
    local stack_size = prototype.stack_size
    if available < stack_size then
        stack_size = available
    end
    local inserted = player_inventory.insert({name = item_name, count = stack_size, quality = quality_name})
    qs_utils.remove_from_storage(qs_item, inserted)
    update_removal_tab_label(player, item_name, quality_name)
end


return qs_utils