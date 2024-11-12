local flib_dictionary = require("__flib__.dictionary")

---comment
---@param player_index uint
---@param name string
---@param type string
---@param locale string
function get_translation(player_index, name, type, locale)
  if not storage.player_gui[player_index].translation_complete or not storage.__flib.dictionary.translated[locale] then return name end
  if type == "unknown" then
    if storage.__flib.dictionary.translated[locale]["item"][name] then
      return storage.__flib.dictionary.translated[locale]["item"][name]
    else
      return storage.__flib.dictionary.translated[locale]["fluid"][name]
    end
  end
  return storage.__flib.dictionary.translated[locale][type][name]
end

---comment
---@param event any
function on_string_translated(event)
  flib_dictionary.on_string_translated(event)
end

function build_dictionaries()
  for type, prototypes in pairs({
    fluid = prototypes.fluid,
    item = prototypes.item,
    recipe = prototypes.recipe,
  }) do
    flib_dictionary.new(type)
    for name, prototype in pairs(prototypes) do
      flib_dictionary.add(type, name, { "?", prototype.localised_name, name })
    end
  end
end

function on_player_locale_changed(event)
  storage.player_gui[event.player_index].translation_complete = false
  flib_dictionary.on_player_joined_game(event)
end

function on_player_dictionaries_ready(event)
  storage.player_gui[event.player_index].translation_complete = true
  process_sorted_lists(event.player_index)
end

script.on_event(flib_dictionary.on_player_dictionaries_ready, on_player_dictionaries_ready)
script.on_event(defines.events.on_player_locale_changed, on_player_locale_changed)