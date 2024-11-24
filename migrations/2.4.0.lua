local tracking = require("scripts/tracking_utils")


for _, player in pairs(game.players) do
    player.set_shortcut_toggled("qf-fabricator-enable", true)
end
storage.qf_enabled = true

for unit_number, entity_data in pairs(storage.tracked_entities["digitizer-chest"]) do
    local entity = entity_data.entity
    if entity then
        entity_data.settings.decraft = true
        storage.tracked_entities["digitizer-chest"][unit_number].unit_number = entity.unit_number
    end
    if not entity or not entity.valid then
        tracking.remove_tracked_entity(entity_data)
    end
end

for unit_number, entity_data in pairs(storage.tracked_entities["dedigitizer-reactor"]) do
    local entity = entity_data.entity
    if entity then
        storage.tracked_entities["dedigitizer-reactor"][unit_number].unit_number = entity.unit_number
    end
    if not entity or not entity.valid then
        tracking.remove_tracked_entity(entity_data)
    end
end

for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered{name = "digitizer-chest-fluid"}
    for _, entity in pairs(entities) do
        local parents = surface.find_entities_filtered{position = entity.position}
        local destroy = true
        for _, parent in pairs(parents) do
            if parent.name == "digitizer-chest" then
                destroy = false
            end
        end
        if destroy then
            entity.destroy()
        end
    end

    local entities = surface.find_entities_filtered{name = {"dedigitizer-reactor-container", "dedigitizer-reactor-container-fluid"}}
    for _, entity in pairs(entities) do
        local parents = surface.find_entities_filtered{position = entity.position}
        local destroy = true
        for _, parent in pairs(parents) do
            if parent.name == "dedigitizer-reactor" then
                destroy = false
            end
        end
        if destroy then
            entity.destroy()
        end
    end
end

for _, surface in pairs(game.surfaces) do
    local entities = surface.find_entities_filtered{name = "digitizer-chest-fluid"}
    for _, entity in pairs(entities) do
        local parents = surface.find_entities_filtered{position = entity.position}
        local destroy = true
        for _, parent in pairs(parents) do
            if parent.name == "digitizer-chest" then
                destroy = false
            end
        end
        if destroy then
            entity.destroy()
        end
    end

    local entities = surface.find_entities_filtered{name = {"dedigitizer-reactor-container", "dedigitizer-reactor-container-fluid"}}
    for _, entity in pairs(entities) do
        local parents = surface.find_entities_filtered{position = entity.position}
        local destroy = true
        for _, parent in pairs(parents) do
            if parent.name == "dedigitizer-reactor" then
                destroy = false
            end
        end
        if destroy then
            entity.destroy()
        end
    end
end