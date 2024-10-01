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
    local entities = game.get_filtered_entity_prototypes(filters)
    global.prototypes_data = {}
    local result = {}
    for _, entity in pairs(entities) do
        if entity and entity.name and not entity.has_flag("hidden") and entity.items_to_place_this then
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
        global.prototypes_data[entity.name] = entity
    end
end

function process_recipe_enablement()
    for _, recipe in pairs(global.unpacked_recipes) do
        recipe.enabled = game.forces["player"].recipes[recipe.name].enabled
    end
end

function testing_cheat()
    for material, _ in pairs(global.ingredient) do
        local type = item_type_check(material)
        if type == "item" or type == "both" then
            if not global.fabricator_inventory["item"][material] then global.fabricator_inventory["item"][material] = 0 end
            global.fabricator_inventory["item"][material] = global.fabricator_inventory["item"][material] + math.random(1000, 1000000000)
        end
        if type == "fluid" or type == "both" then
            if not global.fabricator_inventory["fluid"][material] then global.fabricator_inventory["fluid"][material] = 0 end
            global.fabricator_inventory["fluid"][material] = global.fabricator_inventory["fluid"][material] + math.random(1000, 1000000000)
        end
    end
end

function item_type_check(item)
    local type
    local item_check = game.item_prototypes[item]
    local fluid_check = game.fluid_prototypes[item]
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
    local item_groups = game.item_group_prototypes
    local item_subgroups = game.item_subgroup_prototypes
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
    global.item_group_order = group_order
    global.item_subgroup_order = subgroup_order
end

-- we are making multiple tables at once here
function process_recipes()
    local duplicate_recipes = {}
    local seen = {}
    global.preprocessed_recipes = {}
    global.product_craft_data = {}
    for _, recipe in pairs(game.forces["player"].recipes) do
        -- Skip if hidden
        if not recipe.hidden then
            -- Check all products. We are looking for at least one placeable product
            for _, product in pairs(recipe.products) do
                if is_placeable(product.name) then
                    -- Only keep going if product is 100% success and is not a catalyst
                    if product.probability == 1 and not product.catalyst_amount then
                        local prototype
                        if product.type == "item" then
                            prototype = game.item_prototypes[product.name]
                        else
                            prototype = game.fluid_prototypes[product.name]
                        end
                        if not global.preprocessed_recipes[recipe.name] then
                            global.preprocessed_recipes[recipe.name] = {
                                name = recipe.name,
                                placeable_product = product.name,
                                group_name = recipe.group.name,
                                subgroup_name = recipe.subgroup.name,
                                order = recipe.order,
                                products = recipe.products,
                                ingredients = recipe.ingredients,
                                localised_name = recipe.localised_name,
                                localised_description = recipe.localised_description,
                                enabled = recipe.enabled
                            }
                        end
                        if not global.prototypes_data[product.name] then
                            global.prototypes_data[product.name] = {
                                name = product.name,
                                type = product.type,
                                localised_name = prototype.localised_name,
                                localised_description = prototype.localised_description,
                                order = prototype.order,
                                item_name = "error"
                            }
                        end
                        if not global.product_craft_data[product.name] then global.product_craft_data[product.name] = {} end
                        global.product_craft_data[product.name][#global.product_craft_data[product.name] + 1] = {
                            recipe_name = recipe.name,
                            priority = 1,
                            suitability = 0,
                            selected_priority = 0,
                            blacklisted = false,
                            number_of_recipes = 1
                        }
                        if not seen[product.name] then
                            seen[product.name] = true
                            duplicate_recipes[product.name] = {}
                        end
                        table.insert(duplicate_recipes[product.name], recipe.name)
                    end
                end
            end
        end
    end
    erase_non_duplicates(duplicate_recipes)
end




-- only leave recipes that *could* be duplicates. we'll be checking if they are *actually* duplicates (as in, enabled at the same time) later
function erase_non_duplicates(recipes)
    global.duplicate_recipes = {}
    for product, recipe_names in pairs(recipes) do
        if #recipe_names > 1 then
            global.duplicate_recipes[product] = recipe_names
        end
    end
end

-- we test recipes by several factors to determine default priority
function calculate_default_priority()
    for product, recipe_names in pairs(global.duplicate_recipes) do
        local suitability = {}
        local max_ingredients
        local min_products
        local product_min_s
        local max = 0
        local min
        local product_min
        for _, recipe_name in pairs(recipe_names) do
            local recipe = global.preprocessed_recipes[recipe_name]
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
        suitability[max_ingredients] = suitability[max_ingredients] + 1
        suitability[min_products] = suitability[min_products] + 1
        suitability[product_min_s] = suitability[product_min_s] + 1
        for key, recipe in pairs(global.product_craft_data[product]) do
            global.product_craft_data[product][key].suitability = suitability[recipe.recipe_name]
            global.product_craft_data[product][key].number_of_recipes = #recipe_names
        end
        table.sort(global.product_craft_data[product], function(a, b) return a.suitability > b.suitability end)
    end
end


-- go through all recipes and unpack them
function process_unpacking()
    for recipe, recipe_data in pairs(global.preprocessed_recipes) do
        unpack_recipe_neo(recipe_data)
    end
end

-- Which recipe to use for fabricating?
-- no filter chosen = suitability, filter chosen = filter excluding blacklists, directly chosen = directly chosen
function get_fabricating_recipe(product)
    if Directly_chosen[product] then return Directly_chosen[product] end
    for _, recipe in pairs(global.product_craft_data[product]) do
        if game.forces["player"].recipes[recipe.recipe_name].enabled then return recipe end
    end
end

-- Which recipe to use for unpacking?
function get_unpacking_recipe(product)
    for _, recipe in pairs(global.product_craft_data[product]) do
        if game.forces["player"].recipes[recipe.recipe_name].enabled then return global.preprocessed_recipes[recipe.recipe_name] end
    end
    return global.preprocessed_recipes[global.product_craft_data[product][1].recipe_name]
end


---@param recipe table
---@return table
function unpack_recipe_neo(recipe)
    if global.unpacked_recipes[recipe.name] then return global.unpacked_recipes[recipe.name] end
    local new_ingredients = {}
    for _, ingredient in pairs(recipe.ingredients) do
        if is_placeable(ingredient.name) then
            new_ingredients = merge_tables(new_ingredients, unpack_recipe_neo(get_unpacking_recipe(ingredient.name)).ingredients)
        else
            table.insert(new_ingredients, ingredient)
        end
    end
    global.unpacked_recipes[recipe.name] = recipe
    global.unpacked_recipes[recipe.name].ingredients = deduplicate_ingredients_neo(new_ingredients)
    table.sort(global.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.name < b.name end)
    return global.unpacked_recipes[recipe.name]
end

---@param ingredients table
---@return table
function deduplicate_ingredients_neo(ingredients)
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
        if not global.ingredient[ingredient.name] then global.ingredient[ingredient.name] = true end
        local ingredient_table = {type = ingredient.type, name = ingredient.name, amount = seen[ingredient.name]}
        table.insert(result2, ingredient_table)
    end
    return result2
end

-- Count how many recipes are using an ingredient to be used for filter purposes in Recipe GUI
function process_ingredient_filter()
    for _, recipe in pairs(global.unpacked_recipes) do
        if game.forces["player"].recipes[recipe.name].enabled then
            for _, ingredient in pairs(recipe.ingredients) do
                if not global.ingredient_filter[ingredient.name] then global.ingredient_filter[ingredient.name] = {count = 0, recipes = {}} end
                global.ingredient_filter[ingredient.name].count = global.ingredient_filter[ingredient.name].count + 1
                global.ingredient_filter[ingredient.name].recipes[recipe.name] = true
            end
        end
    end
end