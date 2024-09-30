

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "digitizer-combinator"
entity.minable = {mining_time = 0.2, result = "digitizer-combinator"}
entity.item_slot_count = 10000


local item =  {
    type = "item",
    name = "digitizer-combinator",
    icon = "__base__/graphics/icons/constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "circuit-network",
    place_result="digitizer-combinator",
    order = "c[combinators]-h[digitizer-combinator]",
    stack_size= 50
  }


  local recipe = {
    type = "recipe",
    name = "digitizer-combinator",
    enabled = false,
    ingredients =
    {
      {"copper-cable", 5},
      {"electronic-circuit", 2}
    },
    result = "digitizer-combinator"
  }

  local technology = {
    type = "technology",
    name = "digitizer-combinator",
    icon_size = 256, icon_mipmaps = 4,
    icon = "__base__/graphics/technology/circuit-network.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "digitizer-combinator"
      }
    },
    prerequisites = {"circuit-network"},
    unit =
    {
      count = 100,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1}
      },
      time = 15
    },
    order = "a-d-d-b"
  }


  data:extend{item,entity,recipe,technology}