---comment
---@param player_index int
function fill_dictionary(player_index)
    global.dictionary[player_index] = {}
    global.dictionary_helper[player_index] = {}
    local items = game.item_prototypes
    local fluids = game.fluid_prototypes
    for _, item in pairs(items) do
        translate(game.players[player_index], item.name, item.localised_name)
    end
    for _, fluid in pairs(fluids) do
        translate(game.players[player_index], fluid.name, fluid.localised_name)
    end
end


---comment
---@param player LuaPlayer
---@param item_name string
---@param localised_string LocalisedString
function translate(player, item_name, localised_string)
    local id = player.request_translation(localised_string)
    if not id then return end
    global.dictionary_helper[player.index][id] = item_name
end


---comment
---@param event any
function on_string_translated(event)
    local player_index = event.player_index
    local id = event.id
    local result = event.result
    local translated = event.translated
    if not player_index or not id then return end
    local item_name = global.dictionary_helper[player_index][id]
    if not item_name then return end
    if not translated then result = "Couldn't translated" end
    global.dictionary[player_index][item_name] = result
end


script.on_event(defines.events.on_string_translated, function(event)
    on_string_translated(event)
end)