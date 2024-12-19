---@class utils
local utils = {}

---@param t1 table
---@param t2 table
---@return table
function utils.merge_tables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

---@param t1 table
---@param t2 table
---@return table
function utils.merge_tables_no_index(t1, t2)
    for k, v in pairs(t2) do
        t1[#t1+1] = v
    end
    return t1
end

---Return true if there are any ghost tiles under the entity
---@param entity LuaEntity
---@return boolean
function utils.check_for_ghost_tiles(entity)
    if not entity.valid then return false end
    local surface = entity.surface
    local bounding_box = entity.bounding_box
    local tiles = surface.find_entities_filtered{
        area = bounding_box,
        name = "tile-ghost",
        limit = 1,
    }
    if next(tiles) then
        return true
    end
    return false
end

function utils.validate_surfaces()
    for index, surface_data in pairs(storage.surface_data.planets) do
        if not surface_data.surface.valid then
            storage.surface_data.planets[index] = nil
        else
            if surface_data.surface.platform then
                surface_data.type = "platforms"
                surface_data.platform = surface_data.surface.platform
                storage.surface_data.platforms[index] = surface_data
                storage.surface_data.planets[index] = nil
            end
        end
    end
    for index, surface_data in pairs(storage.surface_data.platforms) do
        if not surface_data.surface.valid then
            storage.surface_data.platforms[index] = nil
        end
    end
end

function utils.get_qualities()
    local quality_names = {}
    for quality_name, quality_data in pairs(prototypes.quality) do
        if quality_name ~= "quality-unknown" then
            quality_names[#quality_names + 1] = {
                name = quality_name,
                localised_name = quality_data.localised_name,
                icon = "[quality="..quality_name.."] "
            }
            if not script.feature_flags["quality"] then
                quality_names[#quality_names].icon = ""
            end
        end
    end
    return quality_names
end

---@param item_name string
---@return boolean
function utils.is_placeable(item_name)
    if storage.placeable[item_name] ~= nil then return storage.placeable[item_name] end
    local item_prototype = prototypes.item[item_name]
    if item_prototype and item_prototype.place_result and item_prototype.place_result.create_ghost_on_death or storage.tiles[item_name] then
        storage.placeable[item_name] = true
        return true
    end
    storage.placeable[item_name] = false
    return false
end

---@param item_name string
---@return boolean
function utils.is_module(item_name)
    if storage.modules[item_name] ~= nil then return storage.modules[item_name] end
    local item_prototype = prototypes.item[item_name]
    storage.modules[item_name] = item_prototype and item_prototype.type == "module"
    return storage.modules[item_name]
end

---You can only move buildings, modules, fuel, ammo and tools from the storage into your inventory.
---@param item_name any
---@return boolean
function utils.is_removable(item_name)
    if storage.removable[item_name] ~= nil then return storage.removable[item_name] end
    local item_prototype = prototypes.item[item_name]
    if item_prototype and (utils.is_module(item_name) or utils.is_placeable(item_name) or item_prototype.fuel_category or item_prototype.type == "ammo" or item_prototype.type == "tool") then
        storage.removable[item_name] = true
    else
        storage.removable[item_name] = false
    end
    return storage.removable[item_name]
end

---Returns player's inventory (or nil)
---@param player? LuaPlayer
---@param player_index? uint
---@return LuaInventory?
function utils.get_player_inventory(player, player_index)
    if not player then
        if not player_index then return nil end
        player = game.get_player(player_index)
        if not player then return nil end
    end
    local player_inventory = player.get_main_inventory()
    if player_inventory then return player_inventory end
    -- I don't even know if this does anything, but I'm too tired to check. It won't break anything.
    player_inventory = player.get_inventory(defines.inventory.character_main)
    if player_inventory then return player_inventory end
    return nil
end

---Returns true if a technology can be researched right now.
---@param technology LuaTechnology
---@return boolean
function utils.is_researchable(technology)
    if technology.researched then return false end
    for _, prerequisite in pairs(technology.prerequisites) do
        if not prerequisite.researched then
            return false
        end
    end
    return true
end

---@param technology LuaTechnology
function utils.research_technology(technology)
    technology.researched = true
    Research_finished = true
    game.print({"", "[technology="..technology.name.."]",{"qf-general.research-completed"}}, {sound_path = "utility/research_completed"})
    find_trigger_techs()
end

return utils