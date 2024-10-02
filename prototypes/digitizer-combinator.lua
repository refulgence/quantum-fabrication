
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "digitizer-combinator"
entity.minable = {mining_time = 0.2, result = "digitizer-combinator"}
entity.item_slot_count = 10000
entity.icons = {{
  icon  = "__quantum-fabricator__/graphics/icons/digitizer-combinator.png",
  icon_size = 64,
  icon_mipmaps = 4,
}}
entity.sprites = make_4way_animation_from_spritesheet {
  layers = {
    {
      filename = "__quantum-fabricator__/graphics/entity/digitizer-combinator/digitizer-combinator.png",
      width = 58,
      height = 52,
      frame_count = 1,
      shift = util.by_pixel(0, 5),
      hr_version = {
        scale = 0.5,
        filename = "__quantum-fabricator__/graphics/entity/digitizer-combinator/hr-digitizer-combinator.png",
        width = 114,
        height = 102,
        frame_count = 1,
        shift = util.by_pixel(0, 5)
      }
    },
    {
      filename = "__base__/graphics/entity/combinator/constant-combinator-shadow.png",
      width = 50,
      height = 30,
      frame_count = 1,
      shift = util.by_pixel(9, 6),
      draw_as_shadow = true,
      hr_version = {
        scale = 0.5,
        filename = "__base__/graphics/entity/combinator/hr-constant-combinator-shadow.png",
        width = 98,
        height = 66,
        frame_count = 1,
        shift = util.by_pixel(8.5, 5.5),
        draw_as_shadow = true
      }
    }
  }
}

local item =  {
    type = "item",
    name = "digitizer-combinator",
    icon = "__quantum-fabricator__/graphics/icons/digitizer-combinator.png",
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