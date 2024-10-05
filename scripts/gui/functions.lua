

---comment
---@param player LuaPlayer
function toggle_qf_gui(player)
    local main_frame = player.gui.screen.qf_fabricator_frame
    if Research_finished then post_research_recheck() Research_finished = false end
    if main_frame == nil then
        build_main_gui(player)
    else
        global.player_gui[player.index].fabricator_gui_position = main_frame.location
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
    global.player_gui[player.index].show_storage = not global.player_gui[player.index].show_storage
    if global.player_gui[player.index].show_storage then
        --main_frame.style.size = {width = QF_GUI.main_frame.width, height = QF_GUI.main_frame.height}
        if not main_frame.main_content_flow.storage_flow.storage_flow then build_main_storage_gui(player, main_frame.main_content_flow.storage_flow) end
        main_frame.main_content_flow.storage_flow.visible = true
    else
        --main_frame.style.size = {width = QF_GUI.main_frame.min_width, height = QF_GUI.main_frame.min_height}
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
function auto_position_tooltip(player, button_index)
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
end


---comment
function sort_tab_lists()
    Sorted_lists = {}
    local sorted_materials = {}
    local sorted_placeables = {}
    local sorted_others = {}
    local lists = {}
    lists["item"] = global.fabricator_inventory["item"]
    lists["fluid"] = global.fabricator_inventory["fluid"]
    for type, items_list in pairs(lists) do
        for name, count in pairs(items_list) do
            if count > 0 and global.ingredient[name] then
                sorted_materials[#sorted_materials + 1] = {name = name, count = count, type = type}
            end
            if count > 0 and (is_placeable(name) or is_module(name)) then
                sorted_placeables[#sorted_placeables + 1] = {name = name, count = count, type = type}
            end
            if count > 0 and not is_placeable(name) and not is_module(name) and not global.ingredient[name] then
                sorted_others[#sorted_others + 1] = {name = name, count = count, type = type}
            end
        end
    end
    table.sort(sorted_materials, function(a, b) if a.count == b.count then return a.name < b.name end return a.count > b.count end)
    table.sort(sorted_placeables, function(a, b) if a.count == b.count then return a.name < b.name end return a.count < b.count end)
    table.sort(sorted_others, function(a, b) if a.count == b.count then return a.name < b.name end return a.count < b.count end)
    Sorted_lists["Materials"] = sorted_materials
    Sorted_lists["Placeables"] = sorted_placeables
    Sorted_lists["Others"] = sorted_others
end


---comment
---@param player LuaPlayer
function get_craft_data(player)
    if not Craft_data then Craft_data = {} end
    Craft_data[player.index] = {}
    local player_inventory = player.get_inventory(defines.inventory.character_main)
    if not player_inventory then return end
    for _, recipe in pairs(global.unpacked_recipes) do
        local in_inventory = 0
        if item_type_check(recipe.placeable_product) == "item" then in_inventory = player_inventory.get_item_count(recipe.placeable_product) or 0 end
        local in_storage = global.fabricator_inventory["item"][recipe.placeable_product] or 0
        if global.player_gui[player.index].options.calculate_numbers then
            Craft_data[player.index][recipe.name] = how_many_can_craft(recipe, player_inventory) + in_inventory + in_storage
        else
            if is_recipe_craftable(recipe, player_inventory) then
                Craft_data[player.index][recipe.name] = 1
            else
                Craft_data[player.index][recipe.name] = 0
            end
        end
    end
end


---@param player LuaPlayer
---@param filter string | table if table, then we allows only recipes in that table; if stringe then we'll compare it to localised_name
function get_filtered_data(player, filter)
    if not Filtered_data then Filtered_data = {} end
    Filtered_data[player.index] = {content = {}, materials = {}, size = 0}
    local recipes = global.unpacked_recipes

    local function add_entry(recipe)
        if not global.player_gui[player.index].item_group_selection then global.player_gui[player.index].item_group_selection = recipe.group_name end -- questionable?
        if not Filtered_data[player.index].content[recipe.group_name] then Filtered_data[player.index].content[recipe.group_name] = {} Filtered_data[player.index].size = Filtered_data[player.index].size + 1 end
        if not Filtered_data[player.index].content[recipe.group_name][recipe.subgroup_name] then Filtered_data[player.index].content[recipe.group_name][recipe.subgroup_name] = {} end
        table.insert(Filtered_data[player.index].content[recipe.group_name][recipe.subgroup_name],{
            item_name = recipe.placeable_product,
            recipe_name = recipe.name,
            order = recipe.order,
            localised_name = recipe.localised_name,
            localised_description = recipe.localised_description
        })
    end

    if type(filter) == "string" then
        for name, recipe in pairs(recipes) do
            if global.unpacked_recipes[name].enabled then
                local localised_name = get_translation(player.index, name, "recipe")
                if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                    add_entry(recipe)
                end
            end
        end
        for _, material in pairs(Sorted_lists["Materials"]) do
            local localised_name = get_translation(player.index, material.name, "unknown")
            if filter == "" or not localised_name or string.find(string.lower(localised_name), filter) then
                Filtered_data[player.index].materials[material.name] = true
            end
        end
    else
        for name, recipe in pairs(recipes) do
            if global.unpacked_recipes[name].enabled then
                if filter[name] then
                    add_entry(recipe)
                end
            end
        end
    end
    for _, group in pairs(Filtered_data[player.index].content) do
        for _, subgroup in pairs(group) do
            table.sort(subgroup, function(a, b) if a.order == b.order then return a.recipe_name < b.recipe_name end return a.order < b.order end)
        end
    end
end

---comment
---@param player LuaPlayer
---@param filter string | table
---@param reset_searchbar boolean
function apply_gui_filter(player, filter, reset_searchbar, reset_materials)
    get_filtered_data(player, filter)
    if reset_searchbar then player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow.titlebar_flow.searchbar.text = "" end
    if reset_materials and global.player_gui[player.index].show_storage then
        build_main_storage_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.storage_flow)
    end
    build_main_recipe_gui(player, player.gui.screen.qf_fabricator_frame.main_content_flow.recipe_flow)
end
