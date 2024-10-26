local utils = require("scripts/utils")
local qs_utils = require("scripts/qs_utils")
local flib_dictionary = require("__flib__.dictionary")
local tracking = require("scripts/tracking_utils")

---@class QSPrototypeData
---@field name string
---@field type string
---@field localised_name LocalisedString
---@field localised_description LocalisedString
---@field item_name string

---@alias RecipeName string
---@alias ItemName string
---@alias ItemCount uint
---@alias SurfaceIndex uint
---@alias SurfaceName string
---@alias QualityName string

---@class QSUnpackedRecipeData
---@field ingredients table
---@field products table
---@field localised_name LocalisedString
---@field localised_description LocalisedString
---@field enabled boolean
---@field name string
---@field placeable_product string
---@field group_name string
---@field subgroup_name string
---@field order string
---@field priority_style string


function on_init()
    flib_dictionary.on_init()
    build_dictionaries()
    ---@type table <SurfaceIndex, table <"item"|"fluid", table <ItemName, table <QualityName, ItemCount>>>>
    storage.fabricator_inventory = {}
    ---@type table <RecipeName, QSUnpackedRecipeData>
    storage.unpacked_recipes = {}
    ---@type table <ItemName, boolean>
    storage.placeable = {}
    storage.recipe = {}
    ---@type table <ItemName, boolean>
    storage.modules = {}
    ---@type table <ItemName, boolean>
    storage.removable = {}
    ---@type table <ItemName, boolean>
    storage.ingredient = {}
    ---@type table <ItemName, { ["count"]: uint; ["recipes"]: table <RecipeName, boolean> }>
    storage.ingredient_filter = {}
    storage.player_gui = {}
    ---@type table <string, boolean>
    storage.options = {}
    storage.options.auto_recheck_item_request_proxies = false
    storage.sorted_lists = {}
    ---@type table <string, table<uint, RequestData>>
    storage.tracked_requests = {
        construction = {},
        item_requests = {},
        upgrades = {},
        revivals = {},
        destroys = {},
        cliffs = {},
        tiles = {},
    }
    storage.request_ids = {
        cliffs = 0,
        tiles = 0,
    }
    ---@type table <string, table<uint, EntityData>>
    storage.tracked_entities = {}
    ---@type table <string, QSPrototypeData>
    storage.prototypes_data = {}
    if not Actual_non_duplicates then Actual_non_duplicates = {} end
    process_data()
end

function on_config_changed()
    flib_dictionary.on_configuration_changed()
    build_dictionaries()
    process_data()
end

function on_mod_settings_changed()
end

---Check every existing surface (except space platforms) and initialize fabricator inventories for all items and qualities. Doesn't overwrite anything
function initialize_surfaces()
    for _, surface in pairs(game.surfaces) do
        if not surface.platform then
            initialize_fabricator_inventory(surface.index)
        end
    end
end

function on_surface_created(event)
    local surface = game.surfaces[event.surface_index]
    if not surface.platform then
        initialize_fabricator_inventory(event.surface_index)
    end
end


function on_surface_deleted(event)
    storage.fabricator_inventory[event.surface_index] = nil
end

---comment
---@param surface_index SurfaceIndex
---@param value? uint
function initialize_fabricator_inventory(surface_index, value)
    local qualities = utils.get_qualities()
    for _, type in pairs({"item", "fluid"}) do
        for _, thing in pairs(prototypes[type]) do
            if not thing.parameter then
                for _, quality in pairs(qualities) do
                    -- this line makes hesoyam not working, the horror!
                    if value then value = math.random(1, 100000000) end
                    local qs_item = qs_utils.to_qs_item({
                        name = thing.name,
                        type = type,
                        count = value,
                        quality = quality.name,
                        surface_index = surface_index
                    })
                    qs_utils.storage_item_check(qs_item)
                    if value then
                        qs_utils.add_to_storage(qs_item)
                    end
                end
            end
        end
    end
end

function on_created_player(event)
    if event.entity and event.entity.valid then
        if event.entity.type == "entity-ghost" then
            tracking.create_tracked_request({
                entity = event.entity,
                player_index = event.player_index,
                request_type = "revivals"
            })
        end
        on_created(event)
    end
end

function on_created(event)
    local entity = event.entity or event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "dedigitizer-reactor" then
            tracking.create_tracked_request({request_type = "entities", entity = entity, player_index = event.player_index})
        end
    end
end

function on_pre_mined(event)
    local entity = event.entity
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if entity.can_be_destroyed() and entity.type ~= "entity-ghost" then
            if storage.prototypes_data[entity.name] then
                local item_name = storage.prototypes_data[entity.name].item_name
                if utils.is_placeable(item_name) then
                    instant_defabrication(entity, player_index)
                end
            end
        end
    end
end

function on_deconstructed(event)
    local entity = event.entity
    local player_index = event.player_index
    if entity and entity.valid and player_index then
        if entity.type == "cliff" then
            tracking.create_tracked_request({
                entity = entity,
                player_index = player_index,
                request_type = "cliffs"
            })
            return
        end
        if entity.can_be_destroyed() and entity.type ~= "entity-ghost" then
            if entity.prototype.type == "tree" or entity.prototype.type == "simple-entity" or entity.prototype.type == "item-entity" then
                instant_deforestation(entity, player_index)
            elseif storage.prototypes_data[entity.name] then
                local item_name = storage.prototypes_data[entity.name].item_name
                if utils.is_placeable(item_name) then
                    tracking.create_tracked_request({
                        entity = entity,
                        player_index = player_index,
                        request_type = "destroys"
                    })
                end
            end
        end
    end
end

function on_destroyed(event)
    local entity = event.entity
    if entity and entity.valid then
        if entity.name == "digitizer-chest" or entity.name == "dedigitizer-reactor" then
            tracking.remove_tracked_entity(entity)
        end
    end
end

function on_upgrade(event)
    local entity = event.entity
    local target = event.target
    local player_index = event.player_index
    local quality = event.quality
    if entity and entity.valid and player_index then
        if not instant_upgrade(entity, target, quality, player_index) then
            tracking.create_tracked_request({
                entity = entity,
                player_index = player_index,
                upgrade_target = target,
                quality = quality,
                request_type = "upgrades"
            })
        end
    end
end



function on_player_created(event)
    storage.player_gui[event.player_index] = {
        item_group_selection = 1,
        selected_tab_index = 1,
        tooltip_workaround = 0,
        show_storage = false,
        quality = {
            index = 1,
            name = "normal"
        },
        fabricator_gui_position = nil,
        options = {
            calculate_numbers = true,
            mark_red = true,
            sort_ingredients = 1
        },
        gui = {}
    }
end



function sort_ingredients(player_index, sort_type)
    for _, recipe in pairs(storage.unpacked_recipes) do
        if sort_type == "item_name" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.name < b.name end)
        elseif sort_type == "amount" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return a.amount < b.amount end)
        elseif sort_type == "localised_name" then
            table.sort(storage.unpacked_recipes[recipe.name].ingredients, function(a, b) return get_translation(player_index, a.name, "unknown") < get_translation(player_index, b.name, "unknown") end)
        end
    end
end

function on_player_joined_game(event)
    flib_dictionary.on_player_joined_game(event)
end
  
function on_tick(event)
    flib_dictionary.on_tick(event)
end

function post_research_recheck()
    process_ingredient_filter()
    process_recipe_enablement()
end

function on_research_changed(event)
    Research_finished = true
end
script.on_nth_tick(338, function(event)
    if Research_finished then
        post_research_recheck()
        Research_finished = false
    end
end)

function on_console_command(command)
    local player_index = command.player_index
    local name = command.name
    if name == "qf_hesoyam" then
        debug_storage(250000, false)
        game.print("CHEAT: Fabricator inventory updated")
    elseif name == "qf_hesoyam_harder" then
        debug_storage(250000000, true)
        game.print("CHEAT: Fabricator inventory updated with a lot of stuff")
    elseif name == "qf_clear_storage" then
        storage.fabricator_inventory = {item = {}, fluid = {}}
        game.print("CHEAT(?): Fabricator inventory cleared")
    elseif name == "qf_update_module_requests" then
        tracking.update_lost_module_requests(game.players[player_index])
        game.print("Updating item request proxy tracking")
    end
end


function debug_storage(amount, everything)
    initialize_fabricator_inventory(1, amount)
end






function on_lua_shortcut(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.prototype_name == "qf-fabricator-gui" then
        toggle_qf_gui(player)
    end
end

commands.add_command("qf_update_module_requests", nil, on_console_command)
commands.add_command("qf_hesoyam", nil, on_console_command)
commands.add_command("qf_hesoyam_harder", nil, on_console_command)
commands.add_command("qf_clear_storage", nil, on_console_command)

script.on_nth_tick(Update_rate.destroys.rate, function(event) tracking.update_tracked_requests(event.tick, {"destroys"}) end)
script.on_nth_tick(Update_rate.revivals.rate, function(event) tracking.update_tracked_requests(event.tick, {"revivals"}) end)
script.on_nth_tick(Update_rate.requests.rate, function(event) tracking.update_tracked_requests(event.tick) end)
script.on_nth_tick(Update_rate.entities.rate, function(event) tracking.update_tracked_entities(event.tick, {"digitizer-chest"}) end)
script.on_nth_tick(Update_rate.reactors,      function(event) tracking.update_tracked_entities(0, {"dedigitizer-reactor"}) end)

script.on_nth_tick(Update_rate.item_request_proxy_recheck, function(event)
    if storage.options.auto_recheck_item_request_proxies then tracking.update_lost_module_requests(game.connected_players[1]) end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_changed)
script.on_init(on_init)
script.on_configuration_changed(on_config_changed)

script.on_event(defines.events.on_string_translated, on_string_translated)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_tick, on_tick)

script.on_event("qf-fabricator-gui-search", on_fabricator_gui_search_event)
script.on_event("qf-fabricator-gui-toggle", on_fabricator_gui_toggle_event)
script.on_event(defines.events.on_lua_shortcut, on_lua_shortcut)

script.on_event(defines.events.on_player_created, on_player_created)

script.on_event(defines.events.on_research_finished, on_research_changed)
script.on_event(defines.events.on_research_reversed, on_research_changed)

script.on_event(defines.events.on_built_entity, on_created_player)
script.on_event(defines.events.on_robot_built_entity, on_created)
script.on_event(defines.events.script_raised_built, on_created)
script.on_event(defines.events.script_raised_revive, on_created)

script.on_event(defines.events.on_marked_for_upgrade, on_upgrade)

script.on_event(defines.events.on_entity_died, on_destroyed)
script.on_event(defines.events.script_raised_destroy, on_destroyed)
script.on_event(defines.events.on_player_mined_entity, on_destroyed)

script.on_event(defines.events.on_pre_player_mined_item, on_pre_mined)
script.on_event(defines.events.on_marked_for_deconstruction, on_deconstructed)

script.on_event(defines.events.on_surface_created, on_surface_created)
script.on_event(defines.events.on_surface_deleted, on_surface_deleted)
 