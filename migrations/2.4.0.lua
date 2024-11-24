for _, player in pairs(game.players) do
    player.set_shortcut_toggled("qf-fabricator-enable", true)
end
storage.qf_enabled = true

for _, entity_data in pairs(storage.tracked_entities["digitizer-chest"]) do
    local entity = entity_data.entity
    if entity then
        entity_data.settings.decraft = true
    end
end