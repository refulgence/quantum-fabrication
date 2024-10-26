
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



function utils.get_qualities()
    local quality_names = {}
    for quality_name, quality_data in pairs(prototypes.quality) do
        if quality_name ~= "quality-unknown" then
            quality_names[#quality_names + 1] = {
                name = quality_name,
                localised_name = quality_data.localised_name,
                icon = "[quality="..quality_name.."] "
            }
        end
    end
    return quality_names
end

---comment
---@return table <uint, string>
function utils.get_surfaces()
    local surfaces = {}
    for name, surface in pairs(game.surfaces) do
        if not surface.platform then
            surfaces[surface.index] = name
        end
    end
    return surfaces
end


---@param item_name string
---@return boolean
function utils.is_placeable(item_name)
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
function utils.is_module(item_name)
    if storage.modules[item_name] ~= nil then return storage.modules[item_name] end
    local item_prototype = prototypes.item[item_name]
    storage.modules[item_name] = item_prototype and item_prototype.type == "module"
    return storage.modules[item_name]
end

---You can only remove buildings, modules, fuel, ammo and tools from the storage into your inventory.
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




return utils