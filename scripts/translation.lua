flib_dictionary = require("__flib__.dictionary-lite")

---comment
---@param player_index int
---@param name string
---@param type string
function get_translation(player_index, name, type)
    if not flib_dictionary.get_all(player_index) then return end
    local language = global.__flib.dictionary.player_languages[player_index]
    if type == "unknown" then
        if global.__flib.dictionary.translated[language]["item"][name] then
            return global.__flib.dictionary.translated[language]["item"][name]
        else
            return global.__flib.dictionary.translated[language]["fluid"][name]
        end
    end
    return global.__flib.dictionary.translated[language][type][name]
end


---comment
---@param event any
function on_string_translated(event)
    flib_dictionary.on_string_translated(event)
end






function build_dictionaries()
  for type, prototypes in pairs({
    fluid = game.fluid_prototypes,
    item = game.item_prototypes,
    recipe = game.recipe_prototypes,
  }) do
    flib_dictionary.new(type)
    for name, prototype in pairs(prototypes) do
      flib_dictionary.add(type, name, { "?", prototype.localised_name, name })
    end
  end
end

function on_player_joined_game(event)
    flib_dictionary.on_player_joined_game(event)
end

function on_tick(event)
    flib_dictionary.on_tick(event)
end

script.on_event(defines.events.on_string_translated, on_string_translated)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)
script.on_event(defines.events.on_tick, on_tick)