local utils = require("scripts/utils")
local qf_utils = require("scripts/qf_utils")
local qs_utils = require("scripts/qs_utils")
local flib_dictionary = require("__flib__.dictionary")

---@class gui_utils
local gui_utils = {}

---@param player LuaPlayer
function toggle_qf_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_frame
    if Research_finished then post_research_recheck() Research_finished = false end
    storage.player_gui[player.index].tooltip_workaround = 0
    if main_frame == nil then
        if not storage.craft_data then storage.craft_data = {} end
        if not storage.craft_data[player.index] then storage.craft_data[player.index] = {} end
        if not storage.sorted_lists[player.index] then
            process_sorted_lists(player.index)
        end
        build_main_gui(player)
    else
        if storage.craft_data then
            storage.craft_data[player.index] = nil
        end
        storage.player_gui[player.index].fabricator_gui_position = main_frame.location
        main_frame.destroy()
        if player.gui.screen.qf_fabricator_options_frame then player.gui.screen.qf_fabricator_options_frame.destroy() end
        if player.gui.screen.qf_recipe_tooltip then player.gui.screen.qf_recipe_tooltip.destroy() end
    end
end

---@param player LuaPlayer
function toggle_storage_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_frame
    if not main_frame then return end
    storage.player_gui[player.index].show_storage = not storage.player_gui[player.index].show_storage
    if storage.player_gui[player.index].show_storage then
        if not main_frame.main_content_flow.storage_flow.storage_flow then build_main_storage_gui(player, main_frame.main_content_flow.storage_flow) end
        main_frame.main_content_flow.storage_flow.visible = true
    else
        main_frame.main_content_flow.storage_flow.visible = false
    end
end

---@param player LuaPlayer
function toggle_options_gui(player)
    if player.gui.screen.qf_fabricator_options_frame == nil then
        build_options_gui(player)
    else
        player.gui.screen.qf_fabricator_options_frame.destroy()
    end
end

---@param player LuaPlayer
---@param button_index table
function gui_utils.auto_position_tooltip(player, button_index)
    -- Step 1: get coordinates of Recipe's frame
    local main_frame = player.gui.screen.qf_fabricator_frame
    local tooltip_frame = player.gui.screen.qf_recipe_tooltip
    if not main_frame or not tooltip_frame then return end
    local x = main_frame.location.x
    local y = main_frame.location.y

    local button_size = 40
    local extra_padding = 15
    local scale = player.display_scale

    -- Step 2: adjust for padding and borders
    x = x + (QF_GUI.default.padding * 2) * scale
    y = y + (QF_GUI.default.padding + QF_GUI.titlebar.height + math.ceil(storage.filtered_data[player.index].size / QF_GUI.recipe_frame.item_group_table.max_number_of_columns) * QF_GUI.recipe_frame.item_group_table.button_height + 20) * scale
    -- This should bring up to top left corner of table gui
    -- Step 3: adjust for tooltip that's currenty being hovered up
    button_x = main_frame.location.x + (QF_GUI.default.padding * 2 + (button_index.x - 1) * button_size) * scale
    button_y = main_frame.location.y + (QF_GUI.default.padding + QF_GUI.titlebar.height + math.ceil(storage.filtered_data[player.index].size / QF_GUI.recipe_frame.item_group_table.max_number_of_columns) * QF_GUI.recipe_frame.item_group_table.button_height + 20 + (button_index.y - 1) * button_size) * scale
    x = x + (button_index.x * button_size + extra_padding) * scale
    y = y + (button_index.y * button_size + extra_padding) * scale
    -- Step 4: adjusting for screen resolution
    if x + (tooltip_frame.tags.width * scale) > player.display_resolution.width then
        x = x - (tooltip_frame.tags.width + extra_padding * 2 + button_size * 1) * scale
    end
    if y + (tooltip_frame.tags.heigth * scale) > player.display_resolution.height then
        y = y - (tooltip_frame.tags.heigth + extra_padding * 2 + button_size * 1) * scale
    end
    -- Step 5: adjust to prevent negative coordinates
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    -- Step 5.5: adjust for screen resolution
    if x > player.display_resolution.width - (tooltip_frame.tags.width + extra_padding * 2 + button_size * 1) * scale then x = player.display_resolution.width - (tooltip_frame.tags.width + extra_padding * 2 + button_size * 1) * scale end
    if y > player.display_resolution.height - (tooltip_frame.tags.heigth + extra_padding * 2 + button_size * 1) * scale then y = player.display_resolution.height - (tooltip_frame.tags.heigth + extra_padding * 2 + button_size * 1) * scale end
    -- Step 6: final adjustment in case tooltip is too close to the hovered button
    local adjust_top = player.display_resolution.height / 2 < button_y
    local adjust_left = player.display_resolution.width / 2 < button_x
    
    if is_overlapping(x, y, tooltip_frame.tags.width * scale, tooltip_frame.tags.heigth * scale, button_x, button_y, button_size * scale, button_size * scale) then
        if adjust_left then
            x = button_x + (extra_padding * 2 + button_size * 1) * scale
        else
            x = button_x - (tooltip_frame.tags.width + extra_padding * 2 + button_size * 1) * scale
        end
        if is_overlapping(x, y, tooltip_frame.tags.width * scale, tooltip_frame.tags.heigth * scale, button_x, button_y, button_size * scale, button_size * scale) then
            if adjust_top then
                y = button_y + (extra_padding * 2 + button_size * 1) * scale
            else
                y = button_y - (tooltip_frame.tags.heigth + extra_padding * 2 + button_size * 1) * scale
            end
        end
    end

    tooltip_frame.location = {x = x, y = y}
    tooltip_frame.bring_to_front()
end

function is_overlapping(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

---@param player_index uint
---@param player_inventory? LuaInventory
---@param surface_index uint
---@param quality_name string
---@param recipe_name string
function gui_utils.get_craft_data(player_index, player_inventory, surface_index, quality_name, recipe_name)
    if not storage.craft_data[player_index][surface_index] then storage.craft_data[player_index][surface_index] = {} end
    if not storage.craft_data[player_index][surface_index][recipe_name] then storage.craft_data[player_index][surface_index][recipe_name] = {} end

    if not settings.get_player_settings(player_index)["qf-use-player-inventory"].value then
        player_inventory = nil
    end

    local recipe = storage.unpacked_recipes[recipe_name]
    local qs_item = {
        name = recipe.placeable_product,
        count = 1,
        type = "item",
        quality = quality_name,
        surface_index = surface_index
    }
    local _, _, total = qs_utils.count_in_storage(qs_item, player_inventory)
    if storage.tiles[recipe.placeable_product] then
        storage.craft_data[player_index][surface_index][recipe_name][quality_name] = total
        return
    end
    if storage.player_gui[player_index].options.calculate_numbers then
        storage.craft_data[player_index][surface_index][recipe_name][quality_name] = qf_utils.how_many_can_craft(recipe, quality_name, surface_index, player_inventory, true) + total
    else
        if qf_utils.is_recipe_craftable(recipe, quality_name, surface_index, player_inventory, true) then
            storage.craft_data[player_index][surface_index][recipe_name][quality_name] = 1
        else
            storage.craft_data[player_index][surface_index][recipe_name][quality_name] = 0
        end
    end
end

---@param player LuaPlayer
---@param filter string | table if table, then we allows only recipes in that table; if stringe then we'll compare it to localised_name
function gui_utils.get_filtered_data(player, filter)
    if not storage.filtered_data then storage.filtered_data = {} end
    local player_index = player.index
    local locale = player.locale
    storage.filtered_data[player_index] = {content = {}, storage = {}, size = 0}
    local recipes = storage.unpacked_recipes

    local function add_entry(recipe)
        if not storage.player_gui[player_index].item_group_selection then
            storage.player_gui[player_index].item_group_selection = recipe.group_name
        end
        if not storage.filtered_data[player_index].content[recipe.group_name] then
            storage.filtered_data[player_index].content[recipe.group_name] = {}
            storage.filtered_data[player_index].size = storage.filtered_data[player_index].size + 1
        end
        if not storage.filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name] then
            storage.filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name] = {}
        end
        table.insert(storage.filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name],{
            item_name = recipe.placeable_product,
            recipe_name = recipe.name,
            order = recipe.order,
            localised_name = recipe.localised_name,
            localised_description = recipe.localised_description
        })
    end

    if type(filter) == "string" then
        for name, recipe in pairs(recipes) do
            if storage.unpacked_recipes[name].enabled then
                local localised_name = get_translation(player_index, name, "recipe", locale)
                if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                    add_entry(recipe)
                end
            end
        end
        for _, thing in pairs(storage.sorted_lists[player_index]) do
            local localised_name = get_translation(player_index, thing.name, "unknown", locale)
            if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                storage.filtered_data[player_index].storage[thing.name] = true
            end
        end
    else
        for name, recipe in pairs(recipes) do
            if storage.unpacked_recipes[name].enabled then
                if filter[name] then
                    add_entry(recipe)
                end
            end
        end
    end
    for _, group in pairs(storage.filtered_data[player_index].content) do
        for _, subgroup in pairs(group) do
            table.sort(subgroup, function(a, b) if a.order == b.order then return a.recipe_name < b.recipe_name end return a.order < b.order end)
        end
    end
end

---@param player LuaPlayer
---@param filter string | table
---@param reset_searchbar string|nil
function gui_utils.apply_gui_filter(player, filter, reset_searchbar, reset_materials)
    gui_utils.get_filtered_data(player, filter)
    if reset_searchbar then player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.titlebar_flow.searchbar.text = reset_searchbar end
    if reset_materials and storage.player_gui[player.index].show_storage then
        build_main_storage_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.storage_flow)
    end
    build_main_recipe_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow)
end

---@param text string
---@param unit_number uint
function gui_utils.set_intake_limit(text, unit_number)
    local entity_data = storage.tracked_entities["digitizer-chest"][unit_number]
    if not entity_data then return end
    local number = tonumber(text)
    if not number then number = 0 end
    entity_data.settings.intake_limit = number
end

return gui_utils