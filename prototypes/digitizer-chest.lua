local entity = table.deepcopy(data.raw["container"]["steel-chest"])
entity.name = "digitizer-chest"
entity.icon = "__quantum-fabricator__/graphics/icons/digitizer-chest.png"
entity.flags = {"placeable-neutral", "player-creation", "no-automated-item-removal"}
entity.minable = {mining_time = 0.2, result = "digitizer-chest"}
entity.corpse = nil
entity.inventory_size = 48
entity.picture =
    {
      layers =
      {
        {
          filename = "__quantum-fabricator__/graphics/entity/digitizer-chest/digitizer-chest.png", --
          priority = "extra-high",
          width = 34,
          height = 38,
          shift = util.by_pixel(0, -0.2),
          hr_version =
          {
            filename = "__quantum-fabricator__/graphics/entity/digitizer-chest/hr-digitizer-chest.png", --
            priority = "extra-high",
            width = 66,
            height = 74,
            shift = util.by_pixel(-0.25, -0.2),
            scale = 0.5
          }
        },
        {
          filename = "__quantum-fabricator__/graphics/entity/digitizer-chest/digitizer-chest-shadow.png", --
          priority = "extra-high",
          width = 56,
          height = 24,
          shift = util.by_pixel(12, 5),
          draw_as_shadow = true,
          hr_version =
          {
            filename = "__quantum-fabricator__/graphics/entity/digitizer-chest/hr-digitizer-chest-shadow.png", --
            priority = "extra-high",
            width = 112,
            height = 46,
            shift = util.by_pixel(12, 4.5),
            draw_as_shadow = true,
            scale = 0.5
          }
        }
      }
    }
    --circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
    --circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
    --circuit_wire_max_distance = default_circuit_wire_max_distance


local item = {
    type = "item",
    name = "digitizer-chest",
    icon = "__quantum-fabricator__/graphics/icons/digitizer-chest.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "storage",
    order = "a[items]-g[digitizer-chest]",
    place_result = "digitizer-chest",
    stack_size = 50
  }

local recipe = {
    type = "recipe",
    name = "digitizer-chest",
    enabled = false,
    ingredients = {{"steel-plate", 12}, {"advanced-circuit", 8}},
    result = "digitizer-chest"
  }

local technology = {
    type = "technology",
    name = "matter-digitization",
    icon_size = 256, icon_mipmaps = 4,
    icon = "__base__/graphics/technology/advanced-electronics.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "digitizer-chest"
      },
    },
    prerequisites = {"steel-processing", "advanced-electronics"},
    unit =
    {
      count = 250,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1}
      },
      time = 15
    },
    order = "a-d-c-a"
  }



data:extend{item,entity,recipe,technology}