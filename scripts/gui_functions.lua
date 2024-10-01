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
    table.sort(sorted_materials, function(a, b) if a.count == b.count then return a.name > b.name end return a.count > b.count end)
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
        Craft_data[player.index][recipe.name] = how_many_can_craft(recipe, player_inventory) + in_inventory + in_storage
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
                local localised_name
                if not global.dictionary or not global.dictionary[player.index] or not global.dictionary[player.index][name] then
                    --game.print("dictionary error for" .. name)
                    localised_name = "error"
                else
                    localised_name = string.lower(global.dictionary[player.index][name])
                end
                if filter == "" or string.find(localised_name, filter) then
                    add_entry(recipe)
                end
            end
        end
        for _, material in pairs(Sorted_lists["Materials"]) do
            local localised_name
            if not global.dictionary or not global.dictionary[player.index] or not global.dictionary[player.index][material.name] then
                --game.print("dictionary error for" .. material.name)
                localised_name = "error"
            else
                localised_name = string.lower(global.dictionary[player.index][material.name])
            end
            if filter == "" or string.find(localised_name, filter) then
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
    if reset_searchbar then player.gui.screen.qf_fabricator_inventory_frame.titlebar.qf_search.text = "" end
    if reset_materials then
        build_storage_gui(player)
        build_recipe_gui(player)
    else
        build_recipe_gui(player)
    end
end


function show_tooltip(player)
    if not player.gui.screen.qf_fabricator_inventory_frame then return end
    local storage_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow
    storage_flow.storage_frame.visible = false
    storage_flow.tooltip_flow.visible = true
end


function hide_tooltip(player)
    if not player.gui.screen.qf_fabricator_inventory_frame then return end
    local storage_flow = player.gui.screen.qf_fabricator_inventory_frame.main_content_flow.storage_flow
    storage_flow.storage_frame.visible = true
    storage_flow.tooltip_flow.visible = false
end