local utils = require("scripts/utils")
local flib_format = require("__flib__.format")
local qf_utils = require("scripts/qf_utils")

---comment
---@param player LuaPlayer
---@param storage_flow_parent LuaGuiElement
function build_main_storage_gui(player, storage_flow_parent)

    if storage_flow_parent.storage_flow then storage_flow_parent.storage_flow.destroy() end

    local storage_flow = storage_flow_parent.add{
        type = "flow",
        name = "storage_flow",
        direction = "vertical"
    }

    local storage_titlebar = storage_flow.add{
        type = "flow",
        name = "storage_titlebar",
        direction = "horizontal"
    }
    storage_titlebar.style.height = QF_GUI.titlebar.height

    local storage_index = get_storage_index(nil, player)

    storage_titlebar.add{
        type = "label",
        caption = {"", {"qf-inventory.storage-frame-title"}, " #", storage_index},
        style = "frame_title"
    }
    local draggable_space = storage_titlebar.add{
        type = "empty-widget",
        style = "draggable_space",
        ignored_by_interaction = true
    }
    draggable_space.style.horizontally_stretchable = true
    draggable_space.style.height = QF_GUI.dragspace.height
    storage_titlebar.drag_target = player.gui.screen.qf_fabricator_frame

    
    if player.surface.platform then
        ---@diagnostic disable-next-line: param-type-mismatch
        local numbers = qf_utils.how_many_can_craft(QS_ROCKET_PART_RECIPE, "normal", storage_index)
        local rocket_parts_label = storage_titlebar.add{
            type = "label",
            caption = {"", "[item=rocket-part]", "x", numbers},
            style = "frame_title",
            tooltip = {"qf-inventory.rocket-parts-hover"}
        }
    end


    
    local storage_frame = storage_flow.add{type = "frame", name = "storage_frame", direction = "vertical", style="inside_shallow_frame"}
    storage_frame.style.height = QF_GUI.storage_frame.height
    storage_frame.style.minimal_width = 0 --QF_GUI.storage_frame.width
    storage_frame.style.top_padding = QF_GUI.default.padding
    
    local tabbed_pane = storage_frame.add{type = "tabbed-pane", name = "tabbed_pane"}
    tabbed_pane.style.minimal_width = QF_GUI.storage_frame.width
    local materials_tab = tabbed_pane.add{type = "tab", name = "materials_tab", caption = {"qf-inventory.materials"}, tooltip = {"qf-inventory.materials-tooltip"}}
    local placeables_tab = tabbed_pane.add{type = "tab", name = "placeables_tab", caption = {"qf-inventory.placeables"}, tooltip = {"qf-inventory.placeables-tooltip"}}
    local others_tab = tabbed_pane.add{type = "tab", name = "others_tab", caption = {"qf-inventory.others"}, tooltip = {"qf-inventory.others-tooltip"}}
    
    local materials_tab_content = build_tab(player, tabbed_pane, "materials")
    local placeables_tab_content = build_tab(player, tabbed_pane, "placeables")
    local others_tab_content = build_tab(player, tabbed_pane, "others")

    tabbed_pane.add_tab(materials_tab, materials_tab_content)
    tabbed_pane.add_tab(placeables_tab, placeables_tab_content)
    tabbed_pane.add_tab(others_tab, others_tab_content)

    tabbed_pane.selected_tab_index = storage.player_gui[player.index].selected_tab_index

end


---comment
---@param player any
---@param tabbed_pane any
---@param tab_type "materials"|"placeables"|"others"
function build_tab(player, tabbed_pane, tab_type)
    
    local tab_content = tabbed_pane.add{
        type = "frame",
        name = tab_type .. "_tab_content",
        direction = "vertical",
        style="inside_deep_frame"
    }
    tab_content.style.height = QF_GUI.tabbed_pane.height
    tab_content.style.minimal_width = QF_GUI.tabbed_pane.width
    tab_content.style.padding = 4

    local scroll_pane = tab_content.add{
        type = "scroll-pane",
        name = tab_type .. "scroll_pane",
        direction = "vertical"
    }
    scroll_pane.style.height = QF_GUI.tabbed_pane.height
    --scroll_pane.style.minimal_width = QF_GUI.tabbed_pane.width
    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.vertical_scroll_policy = "auto"
    scroll_pane.horizontal_scroll_policy = "never"

    local qualities = utils.get_qualities()
    local column_count = 2 + #qualities
    if column_count > QS_MAX_COLUMN_COUNT then column_count = QS_MAX_COLUMN_COUNT end
    if tab_type == "others" then
        column_count = column_count - 1
    end

    local content_table
    if tab_type == "placeables" then
        storage.player_gui[player.index].gui.content_table = scroll_pane.add{
            type = "table",
            name = tab_type .. "content_table",
            column_count = column_count
        }
        content_table = storage.player_gui[player.index].gui.content_table
    else
        content_table = scroll_pane.add{
            type = "table",
            name = tab_type .. "content_table",
            column_count = column_count
        }
    end
    content_table.style.vertical_spacing = 0
    content_table.style.bottom_margin = 8

    local storage_index = get_storage_index(nil, player)

    local sorted_list = storage.sorted_lists[player.index][tab_type]
    local fabricator_inventory = storage.fabricator_inventory[storage_index]
    for _, item in pairs(sorted_list) do
        if Filtered_data[player.index][tab_type][item.name] then
            local item_type = item.type
            local item_name = item.name
            local item_name_caption = {"", "["..item_type.."="..item_name.."] ", item.localised_name}

            local skip = true
            local amount_captions = {}
            local index = 0
            for _, quality in pairs(qualities) do
                if item.type == "item" or quality.name == QS_DEFAULT_QUALITY then
                    local amount = fabricator_inventory[item_type][item_name][quality.name]
                    if amount > 0 then
                        skip = false
                        amount_captions[#amount_captions + 1] = {caption = "x" .. flib_format.number(amount, true) .. quality.icon, quality = quality.name}
                    else
                        amount_captions[#amount_captions + 1] = {caption = "", quality = quality.name}
                    end
                else
                    amount_captions[#amount_captions + 1] = {caption = "", quality = quality.name}
                end
                index = index + 1
                if index >= column_count then break end
            end
            if skip then goto continue end
    
            --Entry name
            local item_name_label_container = content_table.add{type = "flow", direction = "horizontal"}
            local item_name_label = item_name_label_container.add{
                type = "label",
                caption = item_name_caption,
                elem_tooltip = {type = item_type, name = item_name}
            }
            item_name_label.style.font = "default-bold"
            item_name_label.style.horizontal_align = "left"
            item_name_label.style.maximal_width = 300

            --Quality things
            for _, amount_caption in pairs(amount_captions) do
                local item_count_label_container = content_table.add{
                    type = "flow",
                    name = "label_container_" .. item.name .. "_" .. amount_caption.quality,
                    direction = "horizontal"}
                item_count_label_container.style.horizontal_align = "right"
                item_count_label_container.style.padding = 0
                if amount_caption.caption ~= "" then
                    local empty_space = item_count_label_container.add{type="empty-widget"}
                    empty_space.style.horizontally_stretchable = true
                    --empty_space.style.maximal_width = 50
                    empty_space.style.minimal_width = 5
                    item_count_label_container.style.padding = 4
                end
                local item_count_label = item_count_label_container.add{
                    type = "label",
                    name = "storage_tab_item_count_label_" .. item.name .. "_" .. amount_caption.quality,
                    caption = amount_caption.caption
                }
                item_count_label.style.horizontal_align = "right"
            end

            local empty_space_for_finale = item_name_label_container.add{type="empty-widget"}
            empty_space_for_finale.style.horizontally_stretchable = true
        
            if tab_type == "materials" then
                local materials_final_flow = content_table.add{type = "flow", direction = "horizontal"}
                -- what is this line? find out why it happens and why it's needed, because I don't think it should be needed
                if not storage.ingredient_filter[item_name] then storage.ingredient_filter[item_name] = {count = 0, recipes = {}} end
                local item_recipe_usage_number = storage.ingredient_filter[item_name].count
                if item_recipe_usage_number > 0 then
                    local item_recipe_usage_caption = {"qf-inventory.recipe-usage", item_recipe_usage_number}
                    local item_button = materials_final_flow.add{
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite="utility/search",
                        tooltip = item_recipe_usage_caption
                    }
                    item_button.style.horizontal_align = "right"
                    item_button.style.size = QF_GUI.tabbed_pane.button_size
                    item_button.tags = {button_type = "recipe_usage_search", item_name = item_name}
                end
            elseif tab_type == "placeables" then
                local placeables_final_flow = content_table.add{type = "flow", direction = "horizontal"}

                if not player.surface.platform then
                    local take_out_caption = {"qf-inventory.take-out-item-quality"}
                    if not script.feature_flags["quality"] then take_out_caption = {"qf-inventory.take-out-item"} end
                    local button_sprite = "qf-vanilla-ghost-entity-icon"
                    local button_tags = {button_type = "take_out_item", item_name = item.name}
                    
                    
                    local item_take_out_button = placeables_final_flow.add{
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/downloading",
                        tooltip = take_out_caption
                    }
                    item_take_out_button.style.horizontal_align = "right"
                    item_take_out_button.style.size = QF_GUI.tabbed_pane.button_size
                    item_take_out_button.tags = button_tags
                end
            end

            ::continue::
        end
    end

    return tab_content

end


function update_removal_tab_label(player, item_name, quality_name)
    if not player.gui.screen.qf_fabricator_frame then return end
    local count = storage.fabricator_inventory[player.surface.index]["item"][item_name][quality_name]
    local table = storage.player_gui[player.index].gui.content_table
    table["label_container_" .. item_name .. "_" .. quality_name]["storage_tab_item_count_label_" .. item_name .. "_" .. quality_name].caption = "x" .. flib_format.number(count, true) .. "[quality="..quality_name.."] "
end