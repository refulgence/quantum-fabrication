local qs_utils = require("scripts/qs_utils")
local qf_utils = require("scripts/qf_utils")
local flib_table = require("__flib__.table")


---Updates a table that links planets to their surface (so we'd have a shortcut)
function update_planet_surface_link()
    storage.planet_surface_link = {}
    for planet_name, planet in pairs(game.planets) do
        if planet.surface then
            storage.planet_surface_link[planet_name] = planet.surface.index
        end
    end
end

---Returns a linked surface index for a given space location, or for a surface the player is looking at
---@param space_location_prototype? LuaSpaceLocationPrototype
---@param player? LuaPlayer
---@return uint|nil
function get_storage_index(space_location_prototype, player)
    local index
    if space_location_prototype then
        index = storage.planet_surface_link[space_location_prototype.name]
    elseif player then
        local player_surface = player.surface
        if player_surface.platform and player_surface.platform.space_location then
            index = storage.planet_surface_link[player_surface.platform.space_location.name]
        else
            index = player_surface.index
        end
    end
    return index
end


---comment
function get_space_requests()
    local result = {}
    for _, surface in pairs(game.surfaces) do
        local platform = surface.platform
        if platform then
            local storage_index = get_storage_index(platform.space_location)
            if storage_index then
                local rocket_silo = game.get_surface(storage_index).find_entities_filtered({type = "rocket-silo", limit = 1})[1]
                if rocket_silo then
                    local hub = platform.hub
                    if hub then
                        local hub_inventory = hub.get_inventory(defines.inventory.hub_main)
                        local entity_targets = surface.find_entities_filtered({name = "entity-ghost"})
                        local qs_items_result = {}
                        for _, entity_target in pairs(entity_targets) do
                            local ghost_name = entity_target.ghost_name
                            if qs_items_result[ghost_name] then
                                qs_items_result[ghost_name].count = qs_items_result[ghost_name].count + 1
                            else
                                qs_items_result[ghost_name] = {
                                    name = ghost_name,
                                    count = 1,
                                    surface_index = storage_index,
                                    quality = entity_target.quality.name or QS_DEFAULT_QUALITY,
                                    type = "item"
                                }
                            end
                        end
                        local tile_target_count = surface.count_tiles_filtered({has_tile_ghost = true})
                        if tile_target_count > 0 then
                            qs_items_result["space-platform-foundation"] = {
                                name = "space-platform-foundation",
                                count = tile_target_count,
                                quality = QS_DEFAULT_QUALITY,
                                surface_index = storage_index,
                                type = "item"
                            }
                        end
                        if hub_inventory then
                            for index, qs_item in pairs(qs_items_result) do
                                qs_item.count = qs_item.count - hub_inventory.get_item_count({name = qs_item.name, quality = qs_item.quality})
                                if qs_item.count <= 0 then qs_items_result[index] = nil end
                            end
                        end
                        result[#result+1] = {
                            hub_inventory = platform.hub.get_inventory(defines.inventory.hub_main),
                            qs_items = qs_items_result,
                            rocket_silo = rocket_silo
                        }
                    end
                end
            end
        end
    end
    ---If we failed to send everything, then we'll reset coundown to attempt later
    if not send_to_space(result) then
        storage.space_countdowns.space_sendoff = 60
    end
end

---Returns true if everything was sent and false if it wasn't
---@param platform_payloads { hub_inventory: LuaInventory, rocket_silo: LuaEntity, qs_items: QSItem[] }[]
---@return boolean
function send_to_space(platform_payloads)
    local sent_everything = true
    for _, payload in pairs(platform_payloads) do
        local hub_inventory = payload.hub_inventory
        for _, qs_item in pairs(payload.qs_items) do
            local storage_index = payload.rocket_silo.surface_index
            if qs_item.count > qs_utils.count_in_storage(qs_item) then
                local recipe = qf_utils.get_craftable_recipe(qs_item)
                if recipe then
                    if qs_item.count > qf_utils.how_many_can_craft(recipe, qs_item.quality, storage_index, nil, true) then
                        sent_everything = false
                        goto continue
                    else
                        qf_utils.fabricate_recipe(recipe, qs_item.quality, storage_index, nil, qs_item.count)
                    end
                end
            end
            local transfer_cost = get_space_transfer_cost(qs_item, payload.rocket_silo)
            local rocket_parts_recipe = QS_ROCKET_PART_RECIPE
            if can_afford_space_transfer(transfer_cost, rocket_parts_recipe, storage_index) then
                for _, ingredient in pairs(rocket_parts_recipe.ingredients) do
                    local qs_item_rocket_part_ingredient = {
                        name = ingredient.name,
                        count = ingredient.amount * transfer_cost,
                        type = ingredient.type,
                        quality = QS_DEFAULT_QUALITY,
                        surface_index = storage_index
                    }
                    qs_utils.remove_from_storage(qs_item_rocket_part_ingredient)
                end
                local pull_result = qs_utils.pull_from_storage(qs_item, hub_inventory)
                if pull_result.full_inventory then
                    sent_everything = false
                    break
                end
                if pull_result.empty_storage then
                    sent_everything = false
                end
            else
                sent_everything = false
            end
            ::continue::
        end
    end
    return sent_everything
end

---Calculates how many rocket parts are needed to transfer given items
---@param qs_item QSItem
---@param rocket_silo LuaEntity
---@return uint --number of rocket parts to pay rounded down unless it's less than 1
function get_space_transfer_cost(qs_item, rocket_silo)
    local cost
    local weigth = qs_item.count * prototypes.item[qs_item.name].weight
    local rocket_parts_per_launch = rocket_silo.prototype.rocket_parts_required
    local rocket_weight_limit = 1000000
    local productivity = 1 + rocket_silo.productivity_bonus
    cost = rocket_parts_per_launch * weigth / rocket_weight_limit / productivity
    if cost < 1 then return 1 end
    return math.floor(cost)
end

---Takes a recipe for rocket parts and checks if it's more than the cost
---@param cost uint
---@param storage_index uint
function can_afford_space_transfer(cost, recipe, storage_index)
    for _, ingredient in pairs(recipe.ingredients) do
        local qs_item = {
            name = ingredient.name,
            count = ingredient.amount,
            type = ingredient.type,
            quality = QS_DEFAULT_QUALITY,
            surface_index = storage_index
        }
        if qs_utils.count_in_storage(qs_item) < cost then
            return false
        end
    end
    return true
end


---Special space-specific countdown handling.
script.on_nth_tick(17, function(event)
    if not storage.space_countdowns then
        storage.space_countdowns = {
            space_sendoff = nil,
        }
    end
    for type, countdown in pairs(storage.space_countdowns) do
        if countdown then
            storage.space_countdowns[type] = storage.space_countdowns[type] - 1
            if countdown == 0 then
                storage.space_countdowns[type] = nil
                if type == "space_sendoff" then
                    get_space_requests()
                end
            end
        end
    end
end)