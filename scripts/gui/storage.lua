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
        local silo = storage.surface_data.planets[storage_index].rocket_silo
        if silo and silo.valid and silo.get_recipe() then
            local rocket_part_recipe, rocket_part_quality = silo.get_recipe()
            local rocket_part_results = rocket_part_recipe.products[1].amount
            local numbers = qf_utils.how_many_can_craft(rocket_part_recipe, rocket_part_quality.name, storage_index)
            local rocket_parts_label = storage_titlebar.add{
                type = "label",
                caption = {"", "[item=rocket-part]", "x", numbers * rocket_part_results},
                style = "frame_title",
                tooltip = {"qf-inventory.rocket-parts-hover"}
            }
        end
    end

    local storage_frame = storage_flow.add{type = "frame", name = "storage_frame", direction = "vertical", style="inside_deep_frame"}
    storage_frame.style.height = QF_GUI.storage_frame.height / player.display_scale
    storage_frame.style.minimal_width = 0 --QF_GUI.storage_frame.width
    

    build_tab(player, storage_frame)

end

---@param player any
---@param parent_frame any
function build_tab(player, parent_frame)

    local scroll_pane = parent_frame.add{
        type = "scroll-pane",
        name = "scroll_pane",
        direction = "vertical"
    }
    scroll_pane.style.height = QF_GUI.storage_frame.height / player.display_scale
    --scroll_pane.style.minimal_width = QF_GUI.tabbed_pane.width
    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.vertical_scroll_policy = "always"
    scroll_pane.horizontal_scroll_policy = "never"

    local qualities = utils.get_qualities()
    local column_count = 3 + #qualities

    -- Used to determine minimal_width for the scroll pane. Because we have to go for very janky workarounds here to support extra qualities w/o making it look bad
    local max_qualities = 0

    storage.player_gui[player.index].gui.content_table = scroll_pane.add{
        type = "table",
        name = "content_table",
        column_count = column_count
    }
    local content_table = storage.player_gui[player.index].gui.content_table
    content_table.style.vertical_spacing = 0
    content_table.style.bottom_margin = 8

    local storage_index = get_storage_index(nil, player)

    -- We can't take out items from space platforms and different planets
    local allow_take_out = not player.surface.platform and storage_index == player.physical_surface_index and settings.global["qf-allow-pulling-out"].value

    local sorted_list = storage.sorted_lists[player.index]
    local fabricator_inventory = storage.fabricator_inventory[storage_index]
    for _, item in pairs(sorted_list) do
        if storage.filtered_data[player.index].storage[item.name] then
            local item_type = item.type
            local item_name = item.name
            local item_name_caption = {"", "["..item_type.."="..item_name.."] ", item.localised_name}

            local skip = true
            local amount_captions = {}
            local index = 0
            local temp_max_qualities = 0
            for _, quality in pairs(qualities) do
                if item.type == "item" or quality.name == QS_DEFAULT_QUALITY then
                    local amount = fabricator_inventory[item_type][item_name][quality.name]
                    if amount ~= 0 then
                        skip = false
                        temp_max_qualities = temp_max_qualities + 1
                        amount_captions[#amount_captions + 1] = {caption = "x" .. flib_format.number(amount, true) .. quality.icon, quality = quality.name}
                    else
                        amount_captions[#amount_captions + 1] = {caption = "", quality = quality.name}
                    end
                else
                    amount_captions[#amount_captions + 1] = {caption = "", quality = quality.name}
                end
                index = index + 1
            end
            if temp_max_qualities > max_qualities then
                max_qualities = temp_max_qualities
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
            
            local placeables_final_flow = content_table.add{type = "flow", direction = "horizontal"}
            if allow_take_out and item_type == "item" then
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
            ::continue::
        end
    end
    -- Enables horizontal scrolling if there is more than 5 qualities in a single row
    if max_qualities > 5 or player.display_scale > 1 then
        max_qualities = 5
        scroll_pane.horizontal_scroll_policy = "auto"
        scroll_pane.style.minimal_width = (400 + max_qualities * 80) / player.display_scale
    end
end

function update_removal_tab_label(player, item_name, quality_name)
    if not player.gui.screen.qf_fabricator_frame then return end
    local count = storage.fabricator_inventory[player.surface.index]["item"][item_name][quality_name]
    local table = storage.player_gui[player.index].gui.content_table
    table["label_container_" .. item_name .. "_" .. quality_name]["storage_tab_item_count_label_" .. item_name .. "_" .. quality_name].caption = "x" .. flib_format.number(count, true) .. "[quality="..quality_name.."] "
end
