local utils = require("scripts/utils")
local qf_utils = require("scripts/qf_utils")
local qs_utils = require("scripts/qs_utils")
local flib_dictionary = require("__flib__.dictionary")

---@class gui_utils
local gui_utils = {}

---comment
---@param player LuaPlayer
function toggle_qf_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_frame
    if Research_finished then post_research_recheck() Research_finished = false end
    storage.player_gui[player.index].tooltip_workaround = 0
    if main_frame == nil then
        if not Craft_data then Craft_data = {} end
        if not Craft_data[player.index] then Craft_data[player.index] = {} end
        if not storage.sorted_lists[player.index] then
            if flib_dictionary.get_all(player.index) then
            process_sorted_lists(player.index)
            else
                return
            end
        end
        build_main_gui(player)
    else
        Craft_data[player.index] = nil
        storage.player_gui[player.index].fabricator_gui_position = main_frame.location
        main_frame.destroy()
        if player.gui.screen.qf_fabricator_options_frame then player.gui.screen.qf_fabricator_options_frame.destroy() end
        if player.gui.screen.qf_recipe_tooltip then player.gui.screen.qf_recipe_tooltip.destroy() end
    end
end


---comment
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

---comment
---@param player LuaPlayer
function toggle_options_gui(player)
    if player.gui.screen.qf_fabricator_options_frame == nil then
        build_options_gui(player)
    else
        player.gui.screen.qf_fabricator_options_frame.destroy()
    end
end


---comment
---@param player LuaPlayer
---@param button_index table
function gui_utils.auto_position_tooltip(player, button_index)
    -- Step 1: get coordinates of Recipe's frame
    local main_frame = player.gui.screen.qf_fabricator_frame
    local tooltip_frame = player.gui.screen.qf_recipe_tooltip
    if not main_frame or not tooltip_frame then return end
    local x = main_frame.location.x
    local y = main_frame.location.y
    -- Step 2: adjust for padding and borders
    x = x + QF_GUI.default.padding * 2
    y = y + QF_GUI.default.padding + QF_GUI.titlebar.height + (Filtered_data[player.index].size / QF_GUI.recipe_frame.item_group_table.max_number_of_columns) * QF_GUI.recipe_frame.item_group_table.button_height + 10
    -- This should bring up to top left corner of table gui
    -- Step 3: adjust for tooltip that's currenty being hovered up
    x = x + button_index.x * 40 + 15
    y = y + button_index.y * 40 + 15 + 40
    -- Step 4: adjusting for screen resolution
    if x + tooltip_frame.tags.width > player.display_resolution.width then
        x = x - tooltip_frame.tags.width - 15 - 15 - 40
    end
    if y + tooltip_frame.tags.heigth > player.display_resolution.height then
        y = player.display_resolution.height - tooltip_frame.tags.heigth
    end
    tooltip_frame.location = {x = x, y = y}
    tooltip_frame.bring_to_front()
end




---comment
---@param player_index uint
---@param player_inventory? LuaInventory
---@param surface_index uint
---@param quality_name string
---@param recipe_name string
function gui_utils.get_craft_data(player_index, player_inventory, surface_index, quality_name, recipe_name)
    if not Craft_data[player_index][surface_index] then Craft_data[player_index][surface_index] = {} end
    if not Craft_data[player_index][surface_index][recipe_name] then Craft_data[player_index][surface_index][recipe_name] = {} end

    local recipe = storage.unpacked_recipes[recipe_name]
    local qs_item = {
        name = recipe.placeable_product,
        count = 1,
        type = "item",
        quality = quality_name,
        surface_index = surface_index
    }
    local in_storage, _, total = qs_utils.count_in_storage(qs_item, player_inventory)
    if storage.tiles[recipe.placeable_product] then
        Craft_data[player_index][surface_index][recipe_name][quality_name] = in_storage
        return
    end
    if storage.player_gui[player_index].options.calculate_numbers then
        Craft_data[player_index][surface_index][recipe_name][quality_name] = qf_utils.how_many_can_craft(recipe, quality_name, surface_index, player_inventory, true) + total
    else
        if qf_utils.is_recipe_craftable(recipe, quality_name, surface_index, player_inventory, true) then
            Craft_data[player_index][surface_index][recipe_name][quality_name] = 1
        else
            Craft_data[player_index][surface_index][recipe_name][quality_name] = 0
        end
    end
end


---@param player LuaPlayer
---@param filter string | table if table, then we allows only recipes in that table; if stringe then we'll compare it to localised_name
function gui_utils.get_filtered_data(player, filter)
    if not Filtered_data then Filtered_data = {} end
    local player_index = player.index
    Filtered_data[player_index] = {content = {}, materials = {}, placeables = {}, others = {}, size = 0}
    local recipes = storage.unpacked_recipes

    local function add_entry(recipe)
        if not storage.player_gui[player_index].item_group_selection then
            storage.player_gui[player_index].item_group_selection = recipe.group_name
        end
        if not Filtered_data[player_index].content[recipe.group_name] then
            Filtered_data[player_index].content[recipe.group_name] = {}
            Filtered_data[player_index].size = Filtered_data[player_index].size + 1
        end
        if not Filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name] then
            Filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name] = {}
        end
        table.insert(Filtered_data[player_index].content[recipe.group_name][recipe.subgroup_name],{
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
                local localised_name = get_translation(player_index, name, "recipe")
                if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                    add_entry(recipe)
                end
            end
        end
        for _, tabbed_type in pairs({"materials", "placeables", "others"}) do
            for _, thing in pairs(storage.sorted_lists[player_index][tabbed_type]) do
                local localised_name = get_translation(player_index, thing.name, "unknown")
                if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                    Filtered_data[player_index][tabbed_type][thing.name] = true
                end
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
    for _, group in pairs(Filtered_data[player_index].content) do
        for _, subgroup in pairs(group) do
            table.sort(subgroup, function(a, b) if a.order == b.order then return a.recipe_name < b.recipe_name end return a.order < b.order end)
        end
    end
end

---comment
---@param player LuaPlayer
---@param filter string | table
---@param reset_searchbar boolean
function gui_utils.apply_gui_filter(player, filter, reset_searchbar, reset_materials)
    gui_utils.get_filtered_data(player, filter)
    if reset_searchbar then player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.titlebar_flow.searchbar.text = "" end
    if reset_materials and storage.player_gui[player.index].show_storage then
        build_main_storage_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.storage_flow)
    end
    build_main_recipe_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow)
end


return gui_utils