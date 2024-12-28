---@class ChunksUtils
local chunks_utils = {}

---@class ChunksData
---@field area BoundingBox
---@field surface_index uint

function chunks_utils.initialize_chunks()
    ---@type table <string, ChunksData>
    storage.chunks = {}
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
    local chunk_name = chunks_utils.get_chunk_name(surface_index, area)
    storage.chunks[chunk_name] = {
        area = area,
        surface_index = surface_index
    }
end

---@param surface_index uint
---@param area BoundingBox
---@return string --Unique name for this chunk
function chunks_utils.get_chunk_name(surface_index, area)
    return surface_index .. "_X:" .. area.left_top.x .. "_Y:" .. area.left_top.y
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