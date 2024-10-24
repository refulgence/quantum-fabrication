local flib_format = require("__flib__.format")

---comment
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
    main_ingredient_label.style.font = "default-small-bold"

    QF_GUI.tooltip_frame = {}
    QF_GUI.tooltip_frame.ing_label_width = 145
    QF_GUI.tooltip_frame.required_label_width = 60
    QF_GUI.tooltip_frame.available_label_width = 65

    local column_count
    if #ingredients > 12 then
        column_count = 2
    else
        column_count = 1
    end

    local ingredient_table = recipe_frame.add{type = "table", column_count = column_count}

    for _, ingredient in pairs(ingredients) do
        local icon = "["..ingredient.type.."="..ingredient.name.."] "
        local localised_name
        if ingredient.type == "item" then
            localised_name = prototypes.item[ingredient.name].localised_name
        else
            localised_name = prototypes.fluid[ingredient.name].localised_name
        end
        local required = ingredient.amount
        local available = storage.fabricator_inventory[ingredient.type][ingredient.name] or 0
        local ingredient_caption = {"", icon, localised_name}
        local font_color = {1.0, 1.0, 1.0}
        if available / required < 10 then
            font_color = {1.0, 1.0, 0.0}
        end
        if available < required then
            font_color = {1.0, 0.0, 0.0}
        end

        

        local ingredient_flow = ingredient_table.add{type = "flow", direction = "horizontal"}
        local ingredient_label = ingredient_flow.add{type = "label", caption = ingredient_caption}
        ingredient_label.style.width = QF_GUI.tooltip_frame.ing_label_width
        ingredient_label.style.font_color = font_color

        local required_label = ingredient_flow.add{type = "label", caption = "x" .. required}
        required_label.style.horizontal_align = "right"
        required_label.style.width = QF_GUI.tooltip_frame.required_label_width
        required_label.style.font_color = font_color

        local available_label = ingredient_flow.add{type = "label", caption = "/ " .. flib_format.number(available, true)}
        available_label.style.horizontal_align = "left"
        available_label.style.width = QF_GUI.tooltip_frame.available_label_width
        available_label.style.font_color = font_color

    end

    local separator_line = recipe_frame.add{type = "line", direction = "horizontal"}

    local product_flow = recipe_frame.add{type = "flow", name = "product_flow", direction = "vertical"}
    local main_product_label = product_flow.add{type = "label", caption = {"qf-inventory.products"}}
    main_product_label.style.font = "default-bold"

    for _, product in pairs(products) do
        local product_label_flow = product_flow.add{type = "flow", direction = "horizontal"}
        local icon = "["..product.type.."="..product.name.."] "
        local localised_name = prototypes.item[product.name].localised_name
        local product_caption = {"", icon, localised_name}
        local amount = product.amount
        local product_label = product_label_flow.add{type = "label", caption = product_caption}

        local amount_label = product_label_flow.add{type = "label", caption = "x" .. amount}
        amount_label.style.horizontal_align = "right"
    end


    if storage.duplicate_recipes[item_name] then
        local duplicate_label_caption = {"qf-inventory.tooltip-dupe"}
        if storage.unpacked_recipes[recipe_name].priority_style == "flib_slot_button_green" then
            duplicate_label_caption = {"qf-inventory.tooltip-dupe-prioritised"}
        elseif storage.unpacked_recipes[recipe_name].priority_style == "flib_slot_button_red" then
            duplicate_label_caption = {"qf-inventory.tooltip-dupe-blacklisted"}
        end
        local duplicate_label = tooltip_frame.add{type = "label", caption = duplicate_label_caption}
    end


    local label_height_approximate = 28

    tooltip_frame.tags = {
        width = QF_GUI.default.padding * 4 + (QF_GUI.tooltip_frame.ing_label_width + QF_GUI.tooltip_frame.required_label_width + QF_GUI.tooltip_frame.available_label_width) * column_count,
        heigth = QF_GUI.default.padding * 4 + label_height_approximate * 5 + (#ingredients / column_count + #products) * label_height_approximate
    }

end