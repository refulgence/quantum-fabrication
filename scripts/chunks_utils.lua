---@class ChunksUtils
local chunks_utils = {}

---@class ChunksData
---@field area BoundingBox
---@field surface_index uint

function chunks_utils.initialize_chunks()
    ---@type table <string, ChunksData>
    storage.chunks = {}
    storage.chunks_num = 1
    for _, surface in pairs(game.surfaces) do
        for chunk in surface.get_chunks() do
            local entities = surface.find_entities_filtered{area = chunk.area, force = "player", limit = 1}
            if next(entities) then
                chunks_utils.add_chunk(surface.index, chunk.area)
            end
        end
    end
end

---Adds a chunk to the table
---@param surface_index uint
---@param position MapPosition|BoundingBox
function chunks_utils.add_chunk(surface_index, position)
    local area = chunks_utils.to_chunk(position)
    storage.chunks[storage.chunks_num] = {
        area = area,
        surface_index = surface_index
    }
    storage.chunks_num = storage.chunks_num + 1
end

---Converts map position to chunk's BoundingBox
---@param position MapPosition
---@return BoundingBox
function chunks_utils.to_chunk(position)
    if not position.x then return position end
    local left_top_x = math.floor(position.x / 32) * 32
    local left_top_y = math.floor(position.y / 32) * 32
    local right_bottom_x = left_top_x + 32
    local right_bottom_y = left_top_y + 32
    return {left_top = {x = left_top_x, y = left_top_y}, right_bottom = {x = right_bottom_x, y = right_bottom_y}}
end

return chunks_utils