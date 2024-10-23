---comment
---@param player LuaPlayer
---@param entity LuaEntity
function create_dedigitizer_reactor_gui(player, entity)
    if player.gui.relative.dedigitizer_reactor_gui then player.gui.relative.dedigitizer_reactor_gui.destroy() end

    local main_frame = player.gui.relative.add{
        type = "frame",
        name = "dedigitizer_reactor_gui",
        direction = "vertical",
        caption = {"qf-dedigitizer.main-frame-title"},
        anchor = {gui = defines.relative_gui_type.reactor_gui, position = defines.relative_gui_position.right}
    }
    main_frame.style.width = 300

    local current_item_filter = storage.tracked_entities[entity.name][entity.unit_number].item_filter
    local current_fluid_filter = storage.tracked_entities[entity.name][entity.unit_number].fluid_filter
    local item_transfer_status = storage.tracked_entities[entity.name][entity.unit_number].item_transfer_status
    local fluid_transfer_status = storage.tracked_entities[entity.name][entity.unit_number].fluid_transfer_status
    local choose_item_flow = main_frame.add{
        type = "flow",
        name = "choose_item_flow",
        direction = "horizontal",
    }
    local choose_item_button = choose_item_flow.add{
        type = "choose-elem-button",
        name = "choose_item_button",
        elem_type = "item",
    }
    choose_item_button.tags = {unit_number = entity.unit_number}
    if current_item_filter and current_item_filter ~= "" then choose_item_button.elem_value = current_item_filter end
    local choose_item_label = choose_item_flow.add{
        type = "label",
        caption = {"qf-dedigitizer.choose-item"},
    }
    local item_transfer_status_label = main_frame.add{
        type = "label",
        name = "item_transfer_status_label",
    }
    item_transfer_status_label.style.single_line = false
    if item_transfer_status == "active" then
        local item_transfer_status_label_2 = main_frame.add{
            type = "label",
            name = "item_transfer_status_label_2",
        }
    end
    main_frame.add{
        type = "line",
        direction = "horizontal",
    }
    local choose_fluid_flow = main_frame.add{
        type = "flow",
        name = "choose_fluid_flow",
        direction = "horizontal",
    }
    local choose_fluid_button = choose_fluid_flow.add{
        type = "choose-elem-button",
        name = "choose_fluid_button",
        elem_type = "fluid",
    }
    choose_fluid_button.tags = {unit_number = entity.unit_number}
    if current_fluid_filter and current_fluid_filter ~= "" then choose_fluid_button.elem_value = current_fluid_filter end
    local choose_fluid_label = choose_fluid_flow.add{
        type = "label",
        caption = {"qf-dedigitizer.choose-fluid"},
    }
    local fluid_transfer_status_label = main_frame.add{
        type = "label",
        name = "fluid_transfer_status_label",
    }
    fluid_transfer_status_label.style.single_line = false
    if fluid_transfer_status == "active" then
        local fluid_transfer_status_label_2 = main_frame.add{
            type = "label",
            name = "fluid_transfer_status_label_2",
        }
    end
    update_dedigitizer_reactor_gui(player, entity)
end


---comment
---@param player LuaPlayer
---@param entity LuaEntity
function update_dedigitizer_reactor_gui(player, entity)
    local main_frame = player.gui.relative.dedigitizer_reactor_gui
    if not main_frame then return end
    local choose_item_button = main_frame.choose_item_flow.choose_item_button
    local choose_fluid_button = main_frame.choose_fluid_flow.choose_fluid_button
    local item_transfer_status = storage.tracked_entities[entity.name][entity.unit_number].item_transfer_status
    local fluid_transfer_status = storage.tracked_entities[entity.name][entity.unit_number].fluid_transfer_status
    local temperature = entity.temperature > Reactor_constants.fluid_transfer_rate
    local item_transfer_caption
    if not temperature then
        item_transfer_caption = {"qf-dedigitizer.low-temperature"}
    elseif not choose_item_button.elem_value then
        item_transfer_caption = {"qf-dedigitizer.status-inactive"}
    else
        if item_transfer_status == "empty storage" then
            item_transfer_caption = {"qf-dedigitizer.status-empty"}
        elseif item_transfer_status == "full container" then
            item_transfer_caption = {"qf-dedigitizer.status-full"}
        elseif item_transfer_status == "active" then
            item_transfer_caption = {"qf-dedigitizer.status-active"}
        else
            item_transfer_caption = {"qf-dedigitizer.status-inactive"}
        end
    end
    main_frame.item_transfer_status_label.caption = item_transfer_caption
    if item_transfer_status == "active" then
        main_frame.item_transfer_status_label_2.caption = {"qf-dedigitizer.transferring-item", Reactor_constants.item_transfer_rate, choose_item_button.elem_value}
    end
    local fluid_transfer_caption
    if  not temperature then
        fluid_transfer_caption = {"qf-dedigitizer.low-temperature"}
    elseif not choose_fluid_button.elem_value then
        fluid_transfer_caption = {"qf-dedigitizer.status-inactive"}
    else
        if fluid_transfer_status == "empty storage" then
            fluid_transfer_caption = {"qf-dedigitizer.status-empty"}
        elseif fluid_transfer_status == "full container" then
            fluid_transfer_caption = {"qf-dedigitizer.status-full"}
        elseif fluid_transfer_status == "active" then
            fluid_transfer_caption = {"qf-dedigitizer.status-active"}
        else
            fluid_transfer_caption = {"qf-dedigitizer.status-inactive"}
        end
    end
    main_frame.fluid_transfer_status_label.caption = fluid_transfer_caption
    if fluid_transfer_status == "active" then
        main_frame.fluid_transfer_status_label_2.caption = {"qf-dedigitizer.transferring-fluid", Reactor_constants.fluid_transfer_rate, choose_fluid_button.elem_value}
    end
end