local utils = require("scripts/utils")

---@class QSItem Format for items/fluids used in storage and fabrication
---@field name string
---@field count int One of count or amount is required. Think about a way to change it
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
    storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] + (count_override or qs_item.count)
    if try_defabricate and settings.global["qf-allow-decrafting"].value and not storage.tiles[qs_item.name] then decraft(qs_item) end
end


---@param qs_item QSItem
---@param count_override? int
function qs_utils.remove_from_storage(qs_item, count_override)
    if not qs_item then return end
    storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] - (count_override or qs_item.count)
end

---Removes items from both the Storage and the player's inventory
---@param qs_item QSItem
---@param available? {storage: uint, inventory: uint|nil}
---@param player_inventory? LuaInventory
---@param count_override? uint
---@return uint --number of items removed from the storage
---@return uint|nil --number of items removed from the inventory
---@return boolean --true if all items were removed
function qs_utils.advanced_remove_from_storage(qs_item, available, player_inventory, count_override)
    local to_remove = count_override or qs_item.count
    local removed_from_storage, removed_from_inventory = 0, 0
    if not available then
        available = {}
        available.storage, available.inventory = qs_utils.count_in_storage(qs_item, player_inventory)
    end
    if available.storage >= to_remove then
        removed_from_storage = to_remove
        qs_utils.remove_from_storage(qs_item, to_remove)
        return removed_from_storage, removed_from_inventory, true
    elseif available.storage > 0 then
        removed_from_storage = available.storage
        qs_utils.remove_from_storage(qs_item, available.storage)
        to_remove = to_remove - available.storage
    end
    if player_inventory then
        if available.inventory >= to_remove then
            removed_from_inventory = to_remove
            player_inventory.remove({name = qs_item.name, count = to_remove, quality = qs_item.quality})
            return removed_from_storage, removed_from_inventory, true
        elseif available.inventory > 0 then
            removed_from_inventory = available.inventory
            player_inventory.remove({name = qs_item.name, count = available.inventory, quality = qs_item.quality})
            to_remove = to_remove - available.inventory
        end
    end
    return removed_from_storage, removed_from_inventory, false
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

---Initializes the storage table for this particular item.
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

---Transfers items/fluids from storage to target inventory. Used by dedigitizing reactors and space requests
---@param qs_item QSItem
---@param target_inventory LuaInventory | LuaEntity
---@return StorageStatusTable
function qs_utils.pull_from_storage(qs_item, target_inventory)
    local in_storage = qs_utils.count_in_storage(qs_item)
    local to_be_provided = qs_item.count
    local status = {empty_storage = false, full_inventory = false}
    if in_storage <= 0 then
        status.empty_storage = true
        return status
    end
    if in_storage < to_be_provided then
        to_be_provided = in_storage
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
                qs_item.count = inserted
                qs_utils.remove_from_storage(qs_item)
                if inserted < to_be_provided then
                    status.full_inventory = true
                end
                return status
            else
                qs_utils.add_to_storage({surface_index = qs_item.surface_index, name = name, count = target_inventory.remove_fluid{name = name, amount = amount}, type = "fluid"})
            end
        end
        ---@diagnostic disable-next-line: assign-type-mismatch
        local inserted = target_inventory.insert_fluid{name = qs_item.name, amount = to_be_provided}
        qs_item.count = inserted
        qs_utils.remove_from_storage(qs_item)
        if inserted < to_be_provided then
            status.full_inventory = true
        end
    end
    return status
end

---How many of that item is available in the storage (and player_inventory if it's provided)
---@param qs_item QSItem
---@param player_inventory? LuaInventory
---@param player_surface_index? uint
---@return uint
---@return uint
---@return uint
function qs_utils.count_in_storage(qs_item, player_inventory, player_surface_index)
    local in_storage = storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality]
    local in_player_inventory = 0
    if player_inventory and qs_item.type == "item" then
        if not player_surface_index then
            local player = player_inventory.player_owner
            if player then
                player_surface_index = player.physical_surface_index
            else
                return in_storage, 0, in_storage
            end
        end
        if qs_item.surface_index == player_surface_index then
            in_player_inventory = player_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
        end
    end
    return in_storage, in_player_inventory, in_storage + in_player_inventory
end

---@param surface_index uint
---@param player_inventory? LuaInventory
---@param player_surface_index? uint
---@return {[string]: uint}
function qs_utils.get_available_tiles(surface_index, player_inventory, player_surface_index)
    local result = {}
    for tile_name, _ in pairs(storage.tiles) do
        _, _, result[tile_name] = qs_utils.count_in_storage({
            name = tile_name,
            count = 1,
            surface_index = surface_index,
            quality = QS_DEFAULT_QUALITY,
            type = "item",
        }, player_inventory, player_surface_index)
    end
    return result
end

---Takes a stack of items from storage to the player's inventory. Only if the player is physically present on the same surface (to prevent some cheesing)
---@param qs_item QSItem
---@param player LuaPlayer
function qs_utils.take_from_storage(qs_item, player)
    local item_name = qs_item.name
    local prototype = prototypes.item[item_name]
    if not prototype then return end
    local in_storage = qs_utils.count_in_storage(qs_item)
    if in_storage <= 0 then return end
    local quality_name = qs_item.quality
    local player_inventory = utils.get_player_inventory(player)
    if not player_inventory then return end
    local stack_size = prototype.stack_size
    if in_storage < stack_size then
        stack_size = in_storage
    end
    local inserted = player_inventory.insert({name = item_name, count = stack_size, quality = quality_name})
    qs_utils.remove_from_storage(qs_item, inserted)
    update_removal_tab_label(player, item_name, quality_name)
end

---Adds item to temp table for statistics
---@param name string
---@param quality string
---@param type string
---@param surface_index uint
function qs_utils.add_temp_prod_statistics(name, quality, type, surface_index, count)
    local uniq_name = name .. "_" .. quality .. "_" .. type .. "_" .. surface_index
    if not storage.temp_statistics[uniq_name] then
        storage.temp_statistics[uniq_name] = {name = name, type = type, quality = quality, count = count, surface_index = surface_index}
    else
        storage.temp_statistics[uniq_name].count = storage.temp_statistics[uniq_name].count + count
    end
    storage.countdowns.temp_statistics = 2
end

---Processes the entire temp_statistics table at once and resets it
function qs_utils.add_production_statistics()
    local item_stats = {}
    local fluid_stats = {}
    for _, item in pairs(storage.temp_statistics) do
        local surface_index = item.surface_index
        if not item_stats[surface_index] then item_stats[surface_index] = game.forces["player"].get_item_production_statistics(surface_index) end
        if not fluid_stats[surface_index] then fluid_stats[surface_index] = game.forces["player"].get_fluid_production_statistics(surface_index) end
        if item.type == "item" then
            item_stats[surface_index].on_flow({name = item.name, quality = item.quality}, item.count)
        else
            fluid_stats[surface_index].on_flow(item.name, item.count)
        end
    end
    storage.temp_statistics = {}
end

---@param storage_index uint
---@return LogisticFilter[]
function qs_utils.get_storage_signals(storage_index)
    local signals = {}
    for _, type in pairs({"item", "fluid"}) do
        for name, item in pairs(storage.fabricator_inventory[storage_index][type]) do
            for quality, count in pairs(item) do
                local temp_count = count
                if temp_count > 2147483647 then temp_count = 2147483647 end
                if temp_count > 0 then
                    signals[#signals + 1] = {
                        value = {type = type, quality = quality, name = name},
                        min = temp_count,
                    }
                end
            end
        end
    end
    return signals
end

return qs_utils