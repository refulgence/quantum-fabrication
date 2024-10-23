--- These functions are only done on init and when configuration changes
function process_data()
    Directly_chosen = {}
    reprocess_recipes()
    process_item_group_order()
    --testing_cheat()
end

function reprocess_recipes()
    process_entities()
    process_recipes()
    calculate_default_priority()
    process_unpacking()
    process_ingredient_filter()
end

-- This mainly exists to obtain precious items_to_place_this data 
function process_entities()
    local filters = {{filter = "buildable"}}
    local entities = prototypes.get_entity_filtered(filters)
    storage.prototypes_data = {}
    local result = {}
    for _, entity in pairs(entities) do
        if entity and entity.name and not entity.hidden and entity.items_to_place_this then
            result[#result + 1] = {
                name = entity.name,
                type = entity.type,
                localised_name = entity.localised_name,
                localised_description = entity.localised_description,
                item_name = entity.items_to_place_this[1].name
            }
        end
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    for _, entity in pairs(result) do
        storage.prototypes_data[entity.name] = entity
    end
end

function process_recipe_enablement()
    for _, recipe in pairs(storage.unpacked_recipes) do
        recipe.enabled = game.forces["player"].recipes[recipe.name].enabled
    end
end



function item_type_check(item)
    local type
    local item_check = prototypes.item[item]
    local fluid_check = prototypes.fluid[item]
    if item_check and not fluid_check then type = "item" end
    if not item_check and fluid_check then type = "fluid" end
    if item_check and fluid_check then type = "both" end
    if not item_check and not fluid_check then type = "neither" end
    return type
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
    for _, recipe in pairs(game.forces["player"].recipes) do
        -- Skip if hidden
        if not recipe.hidden and not Recipe_blacklist[recipe.name] then
            -- Check all products. We are looking for at least one placeable product
            for _, product in pairs(recipe.products) do
                if is_placeable(product.name) then
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
        if #recipe_names > 1 and not Actual_non_duplicates[product] then
            storage.duplicate_recipes[product] = recipe_names
        end
    end
end


-- we test recipes by several factors to determine default priority
function calculate_default_priority()
    for product, recipe_names in pairs(storage.duplicate_recipes) do
        local suitability = {}
        local max_ingredients
        local min_products
        local product_min_s
        local max = 0
        local min
        local product_min
        for _, recipe_name in pairs(recipe_names) do
            local recipe = storage.preprocessed_recipes[recipe_name]
            suitability[recipe_name] = 0
            if #recipe.products == 1 then
                suitability[recipe_name] = suitability[recipe_name] + 1
            end
            if #recipe.ingredients > max then
                max = #recipe.ingredients
                max_ingredients = recipe_name
            end
            if not min or #recipe.products < min then
                min = #recipe.products
                min_products = recipe_name
            end
            for _, product_2 in pairs(recipe.products) do
                if is_placeable(product_2.name) then
                    if not product_min or product_2.amount < product_min then
                        product_min = product_2.amount
                        product_min_s = recipe_name
                    end
                end
            end
        end
        if max_ingredients then suitability[max_ingredients] = suitability[max_ingredients] + 1 end
        if min_products then suitability[min_products] = suitability[min_products] + 1 end
        if product_min_s then suitability[product_min_s] = suitability[product_min_s] + 1 end
        for key, recipe in pairs(storage.product_craft_data[product]) do
            storage.product_craft_data[product][key].suitability = suitability[recipe.recipe_name]
            storage.product_craft_data[product][key].number_of_recipes = #recipe_names
        end
        table.sort(storage.product_craft_data[product], function(a, b) return a.suitability > b.suitability end)
    end
end


-- go through all recipes and unpack them
function process_unpacking()
    local data = "Processing unpacking.\n"
    helpers.write_file("Log.txt", data, true)
    for _, recipe_data in pairs(storage.preprocessed_recipes) do
        unpack_recipe(recipe_data)
    end
end


-- Which recipe to use for unpacking?
function get_unpacking_recipe(product)
    local data = "Getting unpacking recipe for " .. product .."\n"
    helpers.write_file("Log.txt", data, true)
    for _, recipe in pairs(storage.product_craft_data[product]) do
        if game.forces["player"].recipes[recipe.recipe_name].enabled then
            data = "Found a recipe, it's " .. recipe.recipe_name .."\n"
            helpers.write_file("Log.txt", data, true)
            return storage.preprocessed_recipes[recipe.recipe_name]
        end
    end
    data = "No recipes found, returning smth default.\n"
    helpers.write_file("Log.txt", data, true)
    return storage.preprocessed_recipes[storage.product_craft_data[product][1].recipe_name]
end


---@param recipe table
---@return table
function unpack_recipe(recipe)
    -- if this recipe is already unpacked, then simply return it
    if storage.unpacked_recipes[recipe.name] then return storage.unpacked_recipes[recipe.name] end
    local new_ingredients = {}

    local data = "\n\nProcessing unpacking for recipe " .. recipe.name .."\n"
    helpers.write_file("Log.txt", data, true)

    for _, ingredient in pairs(recipe.ingredients) do
        if is_placeable(ingredient.name) then
            data = "- ingredient " .. ingredient.name .. " is placeable, proceeding to recursive unpacking.\n"
            helpers.write_file("Log.txt", data, true)
            new_ingredients = merge_tables_no_index(new_ingredients, unpack_recipe(get_unpacking_recipe(ingredient.name)).ingredients)
        else
            table.insert(new_ingredients, ingredient)
            data = "- ingredient " .. ingredient.name .. " is not placeable, adding it to the list.\n"
            helpers.write_file("Log.txt", data, true)
        end
    end
    storage.unpacked_recipes[recipe.name] = recipe

    data = "Processing recipe " .. recipe.name .. " with " .. #recipe.ingredients .. " ingredients.\n"
    helpers.write_file("Log.txt", data, true)

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

    local data

    for _, ingredient in pairs(ingredients) do
        if not seen[ingredient.name] then
            table.insert(result, ingredient)
            seen[ingredient.name] = ingredient.amount
            data = "Ingredient " .. ingredient.name .. " is not seen yet, current amount is " .. ingredient.amount .."\n"
        else
            seen[ingredient.name] = seen[ingredient.name] + ingredient.amount
            data = "Ingredient " .. ingredient.name .. " is seen, current amount is " .. ingredient.amount .."\n"
        end
        
        helpers.write_file("Log.txt", data, true)
    end

    data = "Finished 1st stage of processing.\n"
    helpers.write_file("Log.txt", data, true)

    for _, ingredient in pairs(result) do
        if not storage.ingredient[ingredient.name] then storage.ingredient[ingredient.name] = true end
        local ingredient_table = {type = ingredient.type, name = ingredient.name, amount = seen[ingredient.name]}
        table.insert(result2, ingredient_table)

        data = "Processing ingredient " .. ingredient.name .. " with amount " .. seen[ingredient.name] .. "\n"
        helpers.write_file("Log.txt", data, true)

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