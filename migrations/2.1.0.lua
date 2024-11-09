for _, entity_data in pairs(storage.tracked_entities["digitizer-chest"]) do
    local entity = entity_data.entity
    if entity then
        entity_data.settings = {}
        local limit_value = entity_data.entity.get_signal({type = "virtual", name = "signal-L"}, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
        entity_data.settings.intake_limit = limit_value
    end
end

for _, entity_data in pairs(storage.tracked_entities["dedigitizer-reactor"]) do
    local entity = entity_data.entity
    if entity then
        entity_data.settings = {}
        entity_data.burnt_result_inventory = entity.get_inventory(defines.inventory.burnt_result)
        local signals = entity.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
        local item_filter
        local fluid_filter
        local quality_filter
        local surface_id
        local highest_count_item = 0
        local highest_count_fluid = 0
        local highest_count_quality = 0
        if signals then
            for _, signal in pairs(signals) do
                if signal.signal.type == "item" or signal.signal.type == nil then
                    if signal.count > highest_count_item then
                        highest_count_item = signal.count
                        item_filter = signal.signal.name
                    end
                elseif signal.signal.type == "fluid" then
                    if signal.count > highest_count_fluid then
                        highest_count_fluid = signal.count
                        fluid_filter = signal.signal.name
                    end
                elseif signal.signal.type == "virtual" and signal.signal.name == "signal-S" then
                    surface_id = signal.count
                elseif signal.signal.type == "quality" then
                    if signal.count > highest_count_quality then
                        highest_count_quality = signal.count
                        quality_filter = signal.signal.name
                    end
                end
            end
        end
        entity_data.settings.item_filter = {name = item_filter, quality = quality_filter}
        entity_data.settings.fluid_filter = fluid_filter
        entity_data.settings.surface_index = surface_id
    end
end

storage.options.default_intake_limit = 0