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

    local fluid_container_entity = {
      type = "storage-tank",
      name = "digitizer-chest-fluid",
      icon = "__quantum-fabricator__/graphics/entity/nothing.png",
      icon_size = 1,
      picture = {
        filename = "__quantum-fabricator__/graphics/entity/nothing.png",
        height = 1,
        width = 1,
      },
      pictures =
        {
          picture = {
            filename = "__quantum-fabricator__/graphics/entity/nothing.png",
            height = 1,
            width = 1,
          },
          fluid_background =
          {
            filename = "__quantum-fabricator__/graphics/entity/nothing.png",
            height = 1,
            width = 1,
          },
          window_background =
          {
            filename = "__quantum-fabricator__/graphics/entity/nothing.png",
            height = 1,
            width = 1,
          },
          flow_sprite =
          {
            filename = "__quantum-fabricator__/graphics/entity/nothing.png",
            height = 1,
            width = 1,
          },
          gas_flow =
          {
            filename = "__quantum-fabricator__/graphics/entity/nothing.png",
            height = 1,
            width = 1,
          },
        },
      flags = {"placeable-neutral", "hidden", "not-selectable-in-game", "not-on-map", "not-rotatable", "not-flammable", "placeable-off-grid", "no-automated-item-insertion"},
      collision_mask = {},
      selectable_in_game = false,
      collision_box = {{-0.3, -0.3}, {0.3, 0.3}},
      fluid_box =
      {
        base_area = 10,
        base_level = -1,
        pipe_covers = {
          north =
          {
            layers =
            {
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-north.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5
                }
              },
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                draw_as_shadow = true,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-north-shadow.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5,
                  draw_as_shadow = true
                }
              }
            }
          },
          east =
          {
            layers =
            {
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-east.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5
                }
              },
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                draw_as_shadow = true,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-east-shadow.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5,
                  draw_as_shadow = true
                }
              }
            }
          },
          south =
          {
            layers =
            {
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-south.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5
                }
              },
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                draw_as_shadow = true,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-south-shadow.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5,
                  draw_as_shadow = true
                }
              }
            }
          },
          west =
          {
            layers =
            {
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-west.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5
                }
              },
              {
                filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
                priority = "extra-high",
                width = 64,
                height = 64,
                draw_as_shadow = true,
                hr_version =
                {
                  filename = "__base__/graphics/entity/pipe-covers/hr-pipe-cover-west-shadow.png",
                  priority = "extra-high",
                  width = 128,
                  height = 128,
                  scale = 0.5,
                  draw_as_shadow = true
                }
              }
            }
          }
        },
        height = 1,
        pipe_connections =
        {
          { position = {0, -1}, type = "input" },
          { position = {1, 0}, type = "input" },
          { position = {0, 1}, type = "input" },
          { position = {-1, 0}, type = "input" }
        },
        hide_connection_info = false,
      },
      two_direction_only = true,
      window_bounding_box = {{-0.125, 0.6875}, {0.1875, 1.1875}},
      flow_length_in_ticks = 360,
    }

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



data:extend{item,entity,recipe,technology,fluid_container_entity}