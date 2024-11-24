local flib_format = require("__flib__.format")
local qf_utils = require("scripts/qf_utils")
local qs_utils = require("scripts/qs_utils")

---@param player LuaPlayer
---@param item_name string
---@param recipe_name string
function build_main_tooltip(player, item_name, recipe_name)

    local tooltip_frame = player.gui.screen.qf_recipe_tooltip
    if tooltip_frame then
        tooltip_frame.clear()
        tooltip_frame.visible = true
    else
        tooltip_frame = player.gui.screen.add{
            type = "frame",
            name = "qf_recipe_tooltip",
            direction = "vertical",
        }
        tooltip_frame.style.padding = 4
    end

    local ingredients = storage.unpacked_recipes[recipe_name].ingredients
    local products = storage.unpacked_recipes[recipe_name].products

    local item_name_frame = tooltip_frame.add{
        type = "frame",
        direction = "horizontal",
        style = "tooltip_title_frame_light"
    }
    local item_name_label = item_name_frame.add{
        type = "label",
        caption = storage.unpacked_recipes[recipe_name].localised_name
    }
    item_name_label.style.font = "heading-2"
    item_name_label.style.font_color = {0.0, 0.0, 0.0}

    item_description_label_caption = {"?", storage.prototypes_data[item_name].localised_description, ""}
    local item_description_label = tooltip_frame.add{
        type = "label",
        caption = item_description_label_caption}
    item_description_label.style.left_padding = 6
    item_description_label.style.single_line = false
    item_description_label.style.bottom_padding = 6

    local recipe_frame = tooltip_frame.add{
        type = "frame",
        name = "recipe_frame",
        direction = "vertical",
        style = "inside_deep_frame"}
    recipe_frame.style.padding = 12
    local main_ingredient_label = recipe_frame.add{type = "label", caption = {"qf-inventory.ingredinets"}}
    main_ingredient_label.style.font = "default-bold"

    local column_count
    if #ingredients > 24 and player.display_scale <= 1 then
        column_count = 6
    elseif #ingredients > 12 then
        column_count = 4
    else
        column_count = 2
    end

    item_description_label.style.maximal_width = 150 * column_count

    local surface_index = get_storage_index(nil, player)
    local quality = storage.player_gui[player.index].quality.name
    --local player_inventory = player.get_main_inventory()

    local ingredient_table = recipe_frame.add{type = "table", column_count = column_count}

    local player_inventory
    if game.players[player.index].mod_settings["qf-use-player-inventory"].value then
        player_inventory = player.get_main_inventory()
    end

    for _, ingredient in pairs(ingredients) do

        local actual_quality = quality
        if ingredient.type == "fluid" then
            actual_quality = QS_DEFAULT_QUALITY
        end
        local icon = "["..ingredient.type.."="..ingredient.name..",quality="..actual_quality.."] "
        local localised_name = prototypes[ingredient.type][ingredient.name].localised_name

        local required = ingredient.amount
        local qs_item = {
            name = ingredient.name,
            type = ingredient.type,
            count = required,
            quality = actual_quality,
            surface_index = surface_index
        }
        local _, _, available = qs_utils.count_in_storage(qs_item, player_inventory)
        local ingredient_caption = {"", icon, localised_name}
        local font_color = {1.0, 1.0, 1.0}
        if available / required < 10 then
            font_color = {1.0, 1.0, 0.0}
        end
        if available < required then
            font_color = {1.0, 0.0, 0.0}
        end

        local ingredient_label = ingredient_table.add{type = "label", caption = ingredient_caption}
        ingredient_label.style.width = QF_GUI.tooltip_frame.ing_label_width
        ingredient_label.style.font_color = font_color

        local amount_flow = ingredient_table.add{type = "flow", direction = "horizontal"}

        local required_label = amount_flow.add{type = "label", caption = "x" .. required}
        required_label.style.horizontal_align = "right"
        required_label.style.width = QF_GUI.tooltip_frame.required_label_width
        required_label.style.font_color = font_color

        local available_label = amount_flow.add{type = "label", caption = "/ " .. flib_format.number(available, true)}
        available_label.style.horizontal_align = "left"
        available_label.style.width = QF_GUI.tooltip_frame.available_label_width
        available_label.style.font_color = font_color

    end

    local separator_line = recipe_frame.add{type = "line", direction = "horizontal"}

    local product_flow = recipe_frame.add{type = "flow", name = "product_flow", direction = "vertical"}
    local main_product_label = product_flow.add{type = "label", caption = {"qf-inventory.products"}}
    main_product_label.style.font = "default-bold"

    for _, product in pairs(products) do
        local actual_quality = quality
        if product.type == "fluid" then
            actual_quality = QS_DEFAULT_QUALITY
        end
        local product_label_flow = product_flow.add{type = "flow", direction = "horizontal"}
        local icon = "["..product.type.."="..product.name..",quality="..actual_quality.."] "
        local localised_name = prototypes[product.type][product.name].localised_name
        local product_caption = {"", icon, localised_name}
        local amount = product.amount
        local product_label = product_label_flow.add{type = "label", caption = product_caption}

        local amount_label = product_label_flow.add{type = "label", caption = "x" .. amount}
        amount_label.style.horizontal_align = "right"
    end

    tooltip_frame.tags = {
        width = 36 + (column_count * 282 / 2),
        heigth = 120 + (math.ceil(#ingredients / column_count * 2) + #products) * 24 + 20 * 2 + 6
    }

    if not qf_utils.can_fabricate(item_name) then
        recipe_frame.visible = false
        local cant_fabricate_label = tooltip_frame.add{
            type = "label",
            caption = {"qf-inventory.cannot-fabricate"}
        }
        cant_fabricate_label.style.left_padding = 6
        cant_fabricate_label.style.single_line = false
        cant_fabricate_label.style.bottom_padding = 6
        cant_fabricate_label.style.font_color = {0.8, 0.8, 0.4}
        tooltip_frame.tags = {
            width = 278,
            heigth = 102 + 20 * 2 + 6,
        }
        goto continue
    end

    if storage.duplicate_recipes[item_name] then
        local duplicate_label_caption = {"qf-inventory.tooltip-dupe"}
        if storage.unpacked_recipes[recipe_name].priority_style == "flib_slot_button_green" then
            duplicate_label_caption = {"qf-inventory.tooltip-dupe-prioritised"}
        elseif storage.unpacked_recipes[recipe_name].priority_style == "flib_slot_button_red" then
            duplicate_label_caption = {"qf-inventory.tooltip-dupe-blacklisted"}
        end
        local duplicate_label = tooltip_frame.add{type = "label", caption = duplicate_label_caption}
        duplicate_label.style.single_line = false
    end

    ::continue::
end