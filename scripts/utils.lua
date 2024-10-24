
---@class utils
local utils = {}



---comment
---@param t1 table
---@param t2 table
---@return table
function utils.merge_tables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

---Somehow the version from above worked fine in 1.1 but stopped working in 2.0. Curious.
---@param t1 table
---@param t2 table
---@return table
function utils.merge_tables_no_index(t1, t2)
    for k, v in pairs(t2) do
        t1[#t1+1] = v
    end
    return t1
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





return utils