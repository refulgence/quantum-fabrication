---@param player LuaPlayer
---@param entity LuaEntity
function create_digitizer_chest_gui(player, entity)
    if player.gui.relative.qf_digitizer_chest_frame then player.gui.relative.qf_digitizer_chest_frame.destroy() end
    main_frame = player.gui.relative.add{
        type = "frame",
        name = "qf_digitizer_chest_frame",
        caption = {"qf-entity.digitizer-chest-title"},
        anchor = {
            gui = defines.relative_gui_type.container_gui,
            position = defines.relative_gui_position.right,
            name = "digitizer-chest",
        },
        direction = "vertical"}

    local entity_settings = storage.tracked_entities[entity.name][entity.unit_number].settings
    local text = tostring(entity_settings.intake_limit)
    if text == "0" then text = "" end

    local main_content_frame = main_frame.add{
        type = "frame",
        name = "main_content_frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }

    local intake_limit_caption = main_content_frame.add{
        type = "label",
        name = "intake_limit_caption",
        caption = {"qf-general.has-tooltip", {"qf-entity.digitizer-chest-intake"}},
        tooltip = {"qf-entity.digitizer-chest-intake-tooltip"},
    }
    local intake_limit_textfield = main_content_frame.add{
        type = "textfield",
        name = "qf_intake_limit_textfield",
        text = text,
        numeric = true,
        lose_focus_on_confirm = true,
    }
    intake_limit_textfield.tags = {unit_number = entity.unit_number}
    intake_limit_textfield.style.width = 150
    
    local decraft_button = main_content_frame.add{
        type = "button",
        name = "qf_decraft_button",
        caption = {"qf-entity.digitizer-chest-decraft"},
        tooltip = {"qf-entity.digitizer-chest-decraft-tooltip"},
    }
    decraft_button.auto_toggle = true
    decraft_button.toggled = entity_settings.decraft
    decraft_button.tags = {unit_number = entity.unit_number}
    decraft_button.style.width = 150

    local intake_limit_button = main_content_frame.add{
        type = "button",
        name = "qf_intake_limit_button",
        caption = {"qf-entity.digitizer-chest-make-default"},
        tooltip = {"qf-entity.digitizer-chest-make-default-tooltip"},
    }
    intake_limit_button.tags = {unit_number = entity.unit_number}
    intake_limit_button.style.width = 150
end