local flib_table = require("__flib__.table")

---@param player LuaPlayer
---@param entity LuaEntity
function create_dedigitizer_reactor_gui(player, entity)
    if player.gui.relative.dedigitizer_reactor_gui then player.gui.relative.dedigitizer_reactor_gui.destroy() end

    local entity_settings = storage.tracked_entities[entity.name][entity.unit_number].settings

    local main_frame = player.gui.relative.add{
        type = "frame",
        name = "dedigitizer_reactor_gui",
        direction = "vertical",
        caption = {"qf-entity.dedigitizing-reactor-title"},
        anchor = {
            gui = defines.relative_gui_type.reactor_gui,
            position = defines.relative_gui_position.right,
            name = "dedigitizer-reactor",
        },
    }

    local main_content_frame = main_frame.add{
        type = "frame",
        name = "main_content_frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    local choose_dedigitization_flow = main_content_frame.add{
        type = "flow",
        name = "choose_dedigitization_flow",
        direction = "horizontal",
    }
    local choose_item_button = choose_dedigitization_flow.add{
        type = "choose-elem-button",
        elem_type = "item-with-quality",
        name = "qf_choose_item_button",
        tooltip = {"qf-entity.dedigitizing-reactor-choose-item-tooltip"},
    }
    if entity_settings.item_filter then
        choose_item_button.elem_value = entity_settings.item_filter
    end
    choose_item_button.tags = {unit_number = entity.unit_number}


    local choose_fluid_button = choose_dedigitization_flow.add{
        type = "choose-elem-button",
        elem_type = "fluid",
        name = "qf_choose_fluid_button",
        tooltip = {"qf-entity.dedigitizing-reactor-choose-fluid-tooltip"},
    }
    if entity_settings.fluid_filter then
        choose_fluid_button.elem_value = entity_settings.fluid_filter
    end
    choose_fluid_button.tags = {unit_number = entity.unit_number}


    local choose_surface_dropdown = main_content_frame.add{
        type = "drop-down",
        name = "qf_choose_surface_dropdown",
        tooltip = {"qf-entity.dedigitizing-reactor-choose-surface-tooltip"},
    }
    local surface_items, surface_link = get_surface_dropdown_items(entity.surface.index)
    local selected_index = flib_table.invert(surface_link)[entity_settings.surface_index]
    if not selected_index then selected_index = 1 end
    choose_surface_dropdown.items = surface_items
    choose_surface_dropdown.selected_index = selected_index
    choose_surface_dropdown.tags = {unit_number = entity.unit_number, surface_link = surface_link}
end

---@param currect_surface_index uint
---@return table
---@return table
function get_surface_dropdown_items(currect_surface_index)
    local items = {}
    local surface_link = {}
    local index = 1
    for _, surface in pairs(game.surfaces) do
        if not surface.platform then
            local surface_index = surface.index
            local planet_name
            if surface.planet then
                planet_name = surface.planet.prototype.localised_name
            else
                planet_name = surface.localised_name or surface.name
            end
            local current = {""}
            if surface_index == currect_surface_index then
                current = {"qf-entity.surface-with-index-current"}
            end
            local item = {"qf-entity.surface-with-index", surface_index, planet_name, current}
            items[index] = item
            surface_link[index] = surface_index
            index = index + 1
        end
    end
    return items, surface_link
end