local qs_utils = require("scripts/qs_utils")
local qf_utils = require("scripts/qf_utils")
local flib_table = require("__flib__.table")
local utils = require("scripts/utils")

---@class PlatformPayload
---@field hub_inventory LuaInventory
---@field qs_items QSItem[]
---@field rocket_silo LuaEntity
---@field storage_index uint


--{ hub_inventory: LuaInventory, rocket_silo: LuaEntity, qs_items: QSItem[] }[]
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


function process_space_requests()
    local result = {}
    utils.validate_surfaces()
    local platforms = storage.surface_data.platforms
    local planets = storage.surface_data.planets
    for _, platform_data in pairs(platforms) do
        local platform = platform_data.platform
        if not platform then goto continue end
        local storage_index = get_storage_index(platform.space_location)
        if storage_index then
            local hub = platform_data.hub
            if not hub then hub = platform.hub end
            if hub then
                local hub_inventory = hub.get_inventory(defines.inventory.hub_main)
                local requester_point = hub.get_requester_point()
                local qs_items_result = {}
                local index = 1
                if requester_point and requester_point.filters then
                    for _, filter in pairs(requester_point.filters) do
                        ---@diagnostic disable-next-line: need-check-nil
                        local requested = filter.count - hub_inventory.get_item_count(filter.name)
                        if requested > 0 then
                            local qs_item = {
                                name = filter.name,
                                count = requested,
                                quality = filter.quality,
                                surface_index = storage_index,
                                type = "item"
                            }
                            qs_items_result[index] = qs_item
                            index = index + 1
                        end
                    end
                    local rocket_silo = planets[storage_index].rocket_silo
                    if not rocket_silo or not rocket_silo.valid then
                        rocket_silo = game.get_surface(storage_index).find_entities_filtered({type = "rocket-silo", limit = 1})[1]
                        if rocket_silo then
                            planets[storage_index].rocket_silo = rocket_silo
                        else
                            goto continue
                        end
                    end
                    result[#result + 1] = {
                        hub_inventory = hub_inventory,
                        qs_items = qs_items_result,
                        rocket_silo = rocket_silo,
                        storage_index = storage_index
                    }
                end
            end
        end
        ::continue::
    end
    ---If we failed to send everything, then we'll reset coundown to attempt later
    if not send_to_space(result) then
        storage.space_countdowns.space_sendoff = 60
    end
end


---Returns true if everything was sent and false if it wasn't
---@param platform_payloads PlatformPayload[]
---@return boolean
function send_to_space(platform_payloads)
    local sent_everything = true

    ---@param transfer_cost uint
    ---@param ingredients table
    ---@param storage_index uint
    local function pay_rocket_parts(transfer_cost, ingredients, storage_index)
        for _, ingredient in pairs(ingredients) do
            qs_utils.remove_from_storage({
                name = ingredient.name,
                count = ingredient.amount * transfer_cost,
                type = ingredient.type,
                quality = QS_DEFAULT_QUALITY,
                surface_index = storage_index
            })
        end
    end

    for _, payload in pairs(platform_payloads) do
        local hub_inventory = payload.hub_inventory
        local storage_index = payload.storage_index
        for _, qs_item in pairs(payload.qs_items) do
            -- How many items are needed and available
            local to_insert = qs_item.count
            local available = qs_utils.count_in_storage(qs_item)
            local insertable = hub_inventory.get_insertable_count({name = qs_item.name, quality = qs_item.quality})
            local rocket_parts_recipe = QS_ROCKET_PART_RECIPE
            local available_parts = qf_utils.how_many_can_craft(rocket_parts_recipe, "normal", storage_index)
            local cost_per_item = get_space_transfer_cost(qs_item, payload.rocket_silo)
            local sendable = math.floor(available_parts / cost_per_item)
            if sendable == 0 or insertable == 0 then
                sent_everything = false
                goto continue
            end
            -- Cannot send more items then can get inserted in the hub (common sense)
            if to_insert > insertable then
                to_insert = insertable
                sent_everything = false
            end
            -- Cannot send more items than we have rocket parts for
            if to_insert > sendable then
                to_insert = sendable
                sent_everything = false
            end
            -- If we don't have enough items, check if we could fabricate the missing ones
            if to_insert > available then
                local recipe = qf_utils.get_craftable_recipe(qs_item)
                if recipe then
                    local craftable = qf_utils.how_many_can_craft(recipe, qs_item.quality, storage_index, nil, true)
                    if craftable >= to_insert - available then
                        qf_utils.fabricate_recipe(recipe, qs_item.quality, storage_index, nil, to_insert - available)
                        goto sending
                    elseif craftable > 0 then
                        qf_utils.fabricate_recipe(recipe, qs_item.quality, storage_index, nil, craftable)
                        to_insert = available + craftable
                        sent_everything = false
                        goto sending
                    end
                end
                to_insert = available
                sent_everything = false
            end
            if to_insert == 0 then
                sent_everything = false
                goto continue
            end
            ::sending::
            -- Ok, now we know exactly how many items we can send to space, so let's do it!
            qs_item.count = to_insert
            pay_rocket_parts(math.ceil(cost_per_item * to_insert), rocket_parts_recipe.ingredients, storage_index)
            qs_utils.pull_from_storage(qs_item, hub_inventory)
            ::continue::
        end
    end
    return sent_everything
end


---Returns how many rocket parts are needed to transfer a single item
---@param qs_item QSItem
---@param rocket_silo LuaEntity
---@return double
function get_space_transfer_cost(qs_item, rocket_silo)
    local weight = prototypes.item[qs_item.name].weight
    local rocket_parts_per_launch = rocket_silo.prototype.rocket_parts_required
    local rocket_weight_limit = QS_ROCKET_WEIGHT_LIMIT
    local productivity = 1 + rocket_silo.productivity_bonus
    return rocket_parts_per_launch / (rocket_weight_limit / weight) / productivity
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

if settings.startup["qf-enable-space-transfer"].value then
    ---Special space-specific countdown handling.
    script.on_nth_tick(17, function(event)
        for type, countdown in pairs(storage.space_countdowns) do
            if countdown then
                storage.space_countdowns[type] = storage.space_countdowns[type] - 1
                if countdown == 0 then
                    storage.space_countdowns[type] = nil
                    if type == "space_sendoff" then
                        process_space_requests()
                    end
                end
            end
        end
    end)
end


function on_entity_logistic_slot_changed(event)
    local entity = event.entity
    if entity.valid and entity.type == "space-platform-hub" then
        storage.space_countdowns.space_sendoff = 5
    end
end

function on_space_platform_changed_state(event)
    local platform = event.platform
    local old_state = event.old_state
    local state = platform.state
    if old_state == defines.space_platform_state.on_the_path and state == defines.space_platform_state.waiting_at_station then
        storage.space_countdowns.space_sendoff = 5
    end
end




script.on_event(defines.events.on_entity_logistic_slot_changed, on_entity_logistic_slot_changed)
script.on_event(defines.events.on_space_platform_changed_state, on_space_platform_changed_state)