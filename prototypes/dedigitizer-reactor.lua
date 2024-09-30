

local entity = table.deepcopy(data.raw["reactor"]["nuclear-reactor"])
entity.name = "dedigitizer-reactor"
entity.minable = {mining_time = 0.2, result = "dedigitizer-reactor"}
entity.consumption = "210MW"
entity.heat_buffer = {
    max_temperature = 10000,
    specific_heat = "10MJ",
    max_transfer = "10GW",
    minimum_glow_temperature = 5000,
}
entity.connection_patches_connected = nil
entity.connection_patches_disconnected = nil
entity.heat_connection_patches_connected = nil
entity.heat_connection_patches_disconnected = nil

local container_entity = {
    type = "container",
    name = "dedigitizer-reactor-container",
    icon = "__quantum-fabricator__/graphics/entity/nothing.png",
    icon_size = 1,
    picture = {
			filename = "__quantum-fabricator__/graphics/entity/nothing.png",
			height = 1,
			width = 1,
		},
    flags = {"placeable-neutral", "hidden", "not-selectable-in-game", "not-on-map", "not-rotatable", "not-flammable", "placeable-off-grid", "no-automated-item-insertion"},
		collision_mask = {},
		selectable_in_game = false,
    collision_box = {{-2.2, -2.2}, {2.2, 2.2}},
    inventory_size = 48,
}

local fluid_container_entity = {
  type = "storage-tank",
  name = "dedigitizer-reactor-container-fluid",
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
  collision_box = {{-2.3, -2.3}, {2.3, 2.3}},
  fluid_box =
  {
    base_area = 10,
    base_level = 2,
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
      { position = {0, -3}, type = "output" },
      { position = {3, 0}, type = "output" },
      { position = {0, 3}, type = "output" },
      { position = {-3, 0}, type = "output" }
    },
    hide_connection_info = false,
  },
  two_direction_only = true,
  window_bounding_box = {{-0.125, 0.6875}, {0.1875, 1.1875}},
  flow_length_in_ticks = 360,
}

local item = {
    type = "item",
    name = "dedigitizer-reactor",
    icon = "__base__/graphics/icons/nuclear-reactor.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "energy",
    order = "f[nuclear-energy]-a[reactor]",
    place_result = "dedigitizer-reactor",
    stack_size = 10
  }

local recipe =   {
    type = "recipe",
    name = "dedigitizer-reactor",
    energy_required = 8,
    enabled = false,
    ingredients =
    {
      {"concrete", 500},
      {"steel-plate", 500},
      {"advanced-circuit", 500},
      {"copper-plate", 500}
    },
    result = "dedigitizer-reactor",
    requester_paste_multiplier = 1
  }

local technology = {
    type = "technology",
    name = "matter-dedigitization",
    icon_size = 256, icon_mipmaps = 4,
    icon = "__base__/graphics/technology/nuclear-power.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "dedigitizer-reactor"
      }
    },
    prerequisites = {"uranium-processing", "matter-digitization","advanced-electronics-2"},
    unit =
    {
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      },
      time = 30,
      count = 1000
    },
    order = "e-p-b-c-t"
  }

  data:extend{item,entity,recipe,technology,container_entity,fluid_container_entity}