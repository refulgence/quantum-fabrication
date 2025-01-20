local utils = require("scripts/utils")
local chunks_utils = require("scripts/chunks_utils")
local flib_table = require("__flib__.table")

--- These functions are only done on init and when configuration changes
function process_data()
    utils.validate_surfaces()
    initialize_surfaces()
    chunks_utils.initialize_chunks()
    reprocess_recipes()
    process_item_group_order()
    update_planet_surface_link()
    get_trigger_techs()
    find_trigger_techs()
end

function reprocess_recipes()
    process_tiles()
    process_entities()
    process_recipes()
    calculate_default_priority()
    process_unpacking()
    process_ingredient_filter()
end

---Obtains a list of all techs researched via crafting/building a placeable building
function get_trigger_techs()
    ---@type table <string, { trigger_type: string, item_name: string, count: uint, technology: LuaTechnology }>
    storage.trigger_techs = {}
    ---@type table <string, { technology: LuaTechnology }>
    storage.trigger_techs_mine = {}
    local tech_prototypes = prototypes.technology
    local technologies = game.forces["player"].technologies
    for name, prototype in pairs(tech_prototypes) do
        local trigger = prototype.research_trigger
        if trigger and not technologies[name].researched and (trigger.type == "craft-item" or trigger.type == "build-entity" or trigger.type == "mine-entity") then
            local item_name
            if trigger.item then
                item_name = trigger.item.name or trigger.item
            else
                item_name = trigger.entity.name or trigger.entity
            end
            if storage.placeable[item_name] and trigger.type ~= "mine-entity" then
                storage.trigger_techs[name] = {
                    trigger_type = trigger.type,
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    item_name = item_name,
                    ---@diagnostic disable-next-line: undefined-field
                    count = trigger.count or 1,
                    technology = technologies[name]
                }
            elseif trigger.type == "mine-entity" then
                storage.trigger_techs_mine[item_name] = {
                    technology = technologies[name]
                }
            end
        end
    end
end

function process_tiles()
    storage.tiles = {}
    storage.tile_link = {}
    local tiles = prototypes.get_tile_filtered{{filter = "item-to-place"}}
    for _, tile in pairs(tiles) do
        storage.tiles[tile.items_to_place_this[1].name] = true
        storage.tile_link[tile.name] = tile.items_to_place_this[1].name
    end
end

---Creates sorted lists to be used later in storage gui
---@param player_indices? table|uint
function process_sorted_lists(player_indices)
    if not storage.sorted_lists then storage.sorted_lists = {} end
    if not player_indices then
        player_indices = {}
        for player_index, _ in pairs(game.players) do
            player_indices[#player_indices + 1] = player_index
        end
    else
        if type(player_indices) ~= "table" then
            player_indices = { player_indices }
        end
    end

    for _, player_index in pairs(player_indices) do
        storage.sorted_lists[player_index] = {}
        local locale = game.get_player(player_index).locale
        local sorted_all = {}
        local lists = {
            ["item"] = prototypes.item,
            ["fluid"] = prototypes.fluid
        }
        for item_type, list in pairs(lists) do
            for item_name, item in pairs(list) do
                if not item.parameter then
                    sorted_all[#sorted_all + 1] = {name = item_name, type = item_type, localised_name = item.localised_name}
                end
            end
        end
        table.sort(sorted_all, function(a, b) return get_translation(player_index, a.name, "unknown", locale) < get_translation(player_index, b.name, "unknown", locale) end)
        storage.sorted_lists[player_index] = sorted_all
    end
end

-- This mainly exists to obtain precious items_to_place_this data 
function process_entities()
    local entities = prototypes.get_entity_filtered({{filter = "buildable"}})
    local tiles = prototypes.tile
    storage.prototypes_data = {}
    if not storage.craft_stats then storage.craft_stats = {} end
    local result = {}

    local function add_to_result(thing)
        if thing and thing.name and thing.items_to_place_this then
            result[#result + 1] = {
                name = thing.name,
                type = thing.type,
                localised_name = thing.localised_name,
                localised_description = thing.localised_description,
                item_name = thing.items_to_place_this[1].name
            }
        end
    end

    for _, entity in pairs(entities) do
        add_to_result(entity)
    end
    for _, tile in pairs(tiles) do
        if tile.items_to_place_this and next(tile.items_to_place_this) and tile.items_to_place_this[1].name then
            local item_prototype = prototypes.item[tile.items_to_place_this[1].name]
            local thing = {
                name = item_prototype.name,
                type = "tile",
                localised_name = item_prototype.localised_name,
                localised_description = item_prototype.localised_description,
                items_to_place_this = tile.items_to_place_this
            }
            add_to_result(thing)
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    for _, entity in pairs(result) do
        storage.prototypes_data[entity.name] = entity
        storage.craft_stats[entity.name] = storage.craft_stats[entity.name] or 0
    end
end

function process_recipe_enablement()
    local recipes = game.forces["player"].recipes
    for _, recipe in pairs(storage.unpacked_recipes) do
        recipe.enabled = recipes[recipe.name].enabled
    end
end

-- Sorts item groups and subgroups for Recipe GUI
function process_item_group_order()
    local group_order = {}
    local subgroup_order = {}
    local item_groups = prototypes.item_group
    local item_subgroups = prototypes.item_subgroup
    for _, group in pairs(item_groups) do
        group_order[#group_order+1] = {name = group.name, order = group.order}
    end
    table.sort(group_order, function(a, b) if a.order == b.order then return a.name < b.name end return a.order < b.order end)
    local subgroup_count = {}
    for _, subgroup in pairs(item_subgroups) do
        local group = subgroup.group
        if not subgroup_order[group.name] then subgroup_order[group.name] = {} subgroup_count[group.name] = 0 end
        subgroup_order[group.name][subgroup_count[group.name] + 1] = {name = subgroup.name, order = subgroup.order}
        subgroup_count[group.name] = subgroup_count[group.name] + 1
    end
    for _, group in pairs(subgroup_order) do
        table.sort(group, function(a, b) if a.order == b.order then return a.name < b.name end return a.order < b.order end)
    end
    storage.item_group_order = group_order
    storage.item_subgroup_order = subgroup_order
end

-- we are making multiple tables at once here
function process_recipes()
    local duplicate_recipes = {}
    local seen = {}
    storage.preprocessed_recipes = {}
    storage.product_craft_data = {}
    storage.unpacked_recipes = {}
    for _, recipe in pairs(game.forces["player"].recipes) do
        -- Skip if hidden
        if not recipe.hidden and not Recipe_blacklist[recipe.name] then
            -- Check all products. We are looking for at least one placeable product
            for _, product in pairs(recipe.products) do
                if product.type == "item" and utils.is_placeable(product.name) then
                    -- Skip if this product/recipe pair is blacklisted
                    if Autocraft_blacklist[product.name] and Autocraft_blacklist[product.name][recipe.name] then goto continue end
                    -- Only keep going if product is 100% success and is not a catalyst
                    if product.probability == 1 and not product.ignored_by_productivity then
                        local prototype = prototypes.item[product.name]
                        if not storage.preprocessed_recipes[recipe.name] then
                            storage.preprocessed_recipes[recipe.name] = {
                                name = recipe.name,
                                placeable_product = product.name,
                                group_name = recipe.group.name,
                                subgroup_name = recipe.subgroup.name,
                                order = recipe.order,
                                products = recipe.products,
                                ingredients = recipe.ingredients,
                                localised_name = recipe.localised_name,
                                localised_description = recipe.localised_description,
                                enabled = recipe.enabled,
                                priority_style = "slot_button"
                            }
                        end
                        if not storage.prototypes_data[product.name] then
                            storage.prototypes_data[product.name] = {
                                name = product.name,
                                type = product.type,
                                localised_name = prototype.localised_name,
                                localised_description = prototype.localised_description,
                                order = prototype.order,
                                item_name = "error"
                            }
                        end
                        if not storage.product_craft_data[product.name] then storage.product_craft_data[product.name] = {} end
                        storage.product_craft_data[product.name][#storage.product_craft_data[product.name] + 1] = {
                            recipe_name = recipe.name,
                            suitability = 0,
                            prioritised = false,
                            blacklisted = false,
                            number_of_recipes = 1
                        }
                        if not seen[product.name] then
                            seen[product.name] = true
                            duplicate_recipes[product.name] = {}
                        end
                        table.insert(duplicate_recipes[product.name], recipe.name)
                    end
                    ::continue::
                end
            end
        end
    end
    erase_non_duplicates(duplicate_recipes)
end

-- only leave recipes that *could* be duplicates. we'll be checking if they are *actually* duplicates (as in, enabled at the same time) later
function erase_non_duplicates(recipes)
    storage.duplicate_recipes = {}
    for product, recipe_names in pairs(recipes) do
        if #recipe_names > 1 and not Actual_non_duplicates[product] and not storage.tiles[product] then
            storage.duplicate_recipes[product] = recipe_names
        end
    end
end

-- we test recipes by several factors to determine default priority
function calculate_default_priority()
    for product, recipe_names in pairs(storage.duplicate_recipes) do
        local suitability = {}
        local max = 1
        local min
        for _, recipe_name in pairs(recipe_names) do
            local recipe = storage.preprocessed_recipes[recipe_name]
            suitability[recipe_name] = 0
            if #recipe.products == 1 then
                suitability[recipe_name] = suitability[recipe_name] + 1
            end
            if #recipe.ingredients > max then
                max = #recipe.ingredients
            end
            if not min or #recipe.products < min then
                min = #recipe.products
            end
            local has_fluid = false
            local has_non_fluid = false
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.type == "fluid" then
                    has_fluid = true
                else
                    has_non_fluid = true
                end
            end
            if has_fluid then suitability[recipe_name] = suitability[recipe_name] - 1 end
            if has_non_fluid then suitability[recipe_name] = suitability[recipe_name] + 1 end
        end
        for key, recipe in pairs(storage.product_craft_data[product]) do
            local true_recipe = storage.preprocessed_recipes[recipe.recipe_name]
            storage.product_craft_data[product][key].suitability = suitability[recipe.recipe_name] + (#true_recipe.ingredients / max) + (min / #true_recipe.products)
            storage.product_craft_data[product][key].number_of_recipes = #recipe_names
        end
        table.sort(storage.product_craft_data[product], function(a, b) return a.suitability > b.suitability end)
    end
end

-- go through all recipes and unpack them
function process_unpacking()
    Visited = {}
    for _, recipe_data in pairs(storage.preprocessed_recipes) do
        unpack_recipe(recipe_data)
    end
end

-- Which recipe to use for unpacking?
function get_unpacking_recipe(product)
    for _, recipe in pairs(storage.product_craft_data[product]) do
        if game.forces["player"].recipes[recipe.recipe_name].enabled then
            return storage.preprocessed_recipes[recipe.recipe_name]
        end
    end
    return storage.preprocessed_recipes[storage.product_craft_data[product][1].recipe_name]
end

---@param recipe table
---@return table
function unpack_recipe(recipe)
    -- if this recipe is already unpacked, then simply return it
    if storage.unpacked_recipes[recipe.name] then return storage.unpacked_recipes[recipe.name] end

    -- if this recipe is a tile or has already been visited, then simply return it because we do not unpack tiles and we don't want get caught in an infinite loop
    if storage.tiles[recipe.products[1].name] or Visited[recipe.name] then
        storage.unpacked_recipes[recipe.name] = recipe
        if Visited[recipe.name] then game.print("[Quantum Fabricator] Bad case of recursion detected with " .. recipe.name .. ", skipping.") end
        return storage.unpacked_recipes[recipe.name]
    end

    Visited[recipe.name] = true
    local new_ingredients = {}
    for _, ingredient in pairs(recipe.ingredients) do
        if utils.is_placeable(ingredient.name) and not storage.tiles[ingredient.name] and not Unpacking_blacklist[ingredient.name] and storage.product_craft_data[ingredient.name] then
            local unpacked_recipe = flib_table.deep_copy(unpack_recipe(get_unpacking_recipe(ingredient.name)))
            new_new_ingredients = unpacked_recipe.ingredients
            local product_multiplier = 1
            for _, product in pairs(unpacked_recipe.products) do
                if utils.is_placeable(product.name) then
                    product_multiplier = product.amount
                    break
                end
            end
            for _, new_ingredient in pairs(new_new_ingredients) do
                new_ingredient.amount = math.ceil(new_ingredient.amount * ingredient.amount / product_multiplier)
            end
            new_ingredients = utils.merge_tables_no_index(new_ingredients, new_new_ingredients)
        else
            table.insert(new_ingredients, ingredient)
        end
    end
    storage.unpacked_recipes[recipe.name] = recipe
    storage.unpacked_recipes[recipe.name].ingredients = deduplicate_ingredients(new_ingredients)
    table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.name < b.name end)
    return storage.unpacked_recipes[recipe.name]
end

---@param ingredients table
---@return table
function deduplicate_ingredients(ingredients)
    local result = {}
    local result2 = {}
    local seen = {}

    for _, ingredient in pairs(ingredients) do
        if not seen[ingredient.name] then
            table.insert(result, ingredient)
            seen[ingredient.name] = ingredient.amount
        else
            seen[ingredient.name] = seen[ingredient.name] + ingredient.amount
        end
    end

    for _, ingredient in pairs(result) do
        if not storage.ingredient[ingredient.name] then storage.ingredient[ingredient.name] = true end
        local ingredient_table = {type = ingredient.type, name = ingredient.name, amount = seen[ingredient.name]}
        table.insert(result2, ingredient_table)
    end
    return result2
end

-- Count how many recipes are using an ingredient to be used for filter purposes in Recipe GUI
function process_ingredient_filter()
    for _, recipe in pairs(storage.unpacked_recipes) do
        if game.forces["player"].recipes[recipe.name].enabled then
            for _, ingredient in pairs(recipe.ingredients) do
                if not storage.ingredient_filter[ingredient.name] then storage.ingredient_filter[ingredient.name] = {count = 0, recipes = {}} end
                storage.ingredient_filter[ingredient.name].count = storage.ingredient_filter[ingredient.name].count + 1
                storage.ingredient_filter[ingredient.name].recipes[recipe.name] = true
            end
        end
    end
end