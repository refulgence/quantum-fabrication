-- Because we'll need to operate big numbers eventually, so let's prepare


---Returns stored amount as a string and a number (which cannot be bigger than int32)
---@param item_name string
---@param item_type string
---@return string
---@return int
function bn_get_storage(item_name, item_type)
    local amount_str = ""
    local amount_int = 0
    return amount_str, amount_int
end

---Adds amount of item to storage
---@param item_name any
---@param item_type any
---@param amount any
function bn_storage_add(item_name, item_type, amount)
end

---Removes amount of item from storage, returns how much got actually removed
---@param item_name any
---@param item_type any
---@param amount any
---@return int
function bn_storage_remove(item_name, item_type, amount)
    local removed = 0
    return removed
end

---Converts string to number, clamps to int32
---@param string any
---@return integer
function bn_convert_string_to_number(string)
    local number = 0
    return number
end