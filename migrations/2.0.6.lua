local utils = require("scripts/utils")
local qs_utils = require("scripts/qs_utils")

-- The following checks stored items and sets all negative counts to 0

local function storage_item_check(qs_item)
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
    if not storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] or storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] < 0 then
        storage.fabricator_inventory[qs_item.surface_index][qs_item.type][qs_item.name][qs_item.quality] = 0
    end
end

local qualities = utils.get_qualities()
for _, surface in pairs(game.surfaces) do
    local surface_index = surface.index
    for _, type in pairs({ "item", "fluid" }) do
        for _, thing in pairs(prototypes[type]) do
            if not thing.parameter then
                for _, quality in pairs(qualities) do
                    local qs_item = {
                        name = thing.name,
                        type = type,
                        count = 1,
                        quality = quality.name,
                        surface_index = surface_index
                    }
                    if qs_item.type == "fluid" then
                        qs_item.quality = QS_DEFAULT_QUALITY
                    end
                    storage_item_check(qs_item)
                end
            end
        end
    end
end

