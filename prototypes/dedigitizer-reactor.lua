pipecoverspictures = function()
  return
  {
    north =
    {
      layers =
      {
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
          priority = "extra-high",
          width = 128,
          height = 128,
          scale = 0.5
        },
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north-shadow.png",
          priority = "extra-high",
          width = 128,
          height = 128,
          scale = 0.5,
          draw_as_shadow = true
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
          width = 128,
          height = 128,
          scale = 0.5
        },
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east-shadow.png",
          priority = "extra-high",
          width = 128,
          height = 128,
          scale = 0.5,
          draw_as_shadow = true
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
          width = 128,
          height = 128,
          scale = 0.5
        },
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south-shadow.png",
          priority = "extra-high",
          width = 128,
          height = 128,
          scale = 0.5,
          draw_as_shadow = true
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
          width = 128,
          height = 128,
          scale = 0.5
        },
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west-shadow.png",
          priority = "extra-high",
          width = 128,
          height = 128,
          scale = 0.5,
          draw_as_shadow = true
        }
      }
    }
  }
end


local reactor_tint = {r = 1.0, g = 0.9, b = 1.0}
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
entity.icon = nil
entity.icons = {{
  icon  = "__base__/graphics/icons/nuclear-reactor.png",
  icon_size = 64,
  icon_mipmaps = 4,
  tint = reactor_tint,
}}
entity.picture.layers[1].tint = reactor_tint


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
    hidden = true,
    flags = {"placeable-neutral", "not-selectable-in-game", "not-on-map", "not-rotatable", "not-flammable", "placeable-off-grid", "no-automated-item-insertion"},
		collision_mask = {layers = {}},
		selectable_in_game = false,
    collision_box = {{-2.2, -2.2}, {2.2, 2.2}},
    inventory_size = 3,
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
  hidden = true,
  flags = {"placeable-neutral", "not-selectable-in-game", "not-on-map", "not-rotatable", "not-flammable", "placeable-off-grid"},
  collision_mask = {layers = {}},
  selectable_in_game = false,
  collision_box = {{-3.3, -3.3}, {3.3, 3.3}},
  fluid_box =
  {
    volume = 10000,
    pipe_covers = pipecoverspictures(),
    pipe_connections =
    {
      { position = {0, -2}, direction = 0},
      { position = {0, 2}, direction = 8},
      { position = {2, 0}, direction = 4},
      { position = {-2, 0}, direction = 12}
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
    subgroup = "energy",
    order = "f[nuclear-energy]-a[reactor]",
    place_result = "dedigitizer-reactor",
    stack_size = 10,
    icons = {{
      icon  = "__base__/graphics/icons/nuclear-reactor.png",
      icon_size = 64,
      icon_mipmaps = 4,
      tint = reactor_tint,
    }},
  }

local recipe =   {
    type = "recipe",
    name = "dedigitizer-reactor",
    energy_required = 8,
    enabled = false,
    ingredients =
    {
      {type = "item", name = "concrete", amount = 800},
      {type = "item", name = "steel-plate", amount = 800},
      {type = "item", name = "advanced-circuit", amount = 800},
      {type = "item", name = "copper-plate", amount = 800}
    },
    results = {{type = "item", name = "dedigitizer-reactor", amount = 1}},
    requester_paste_multiplier = 1,
    icons = {{
      icon  = "__base__/graphics/icons/nuclear-reactor.png",
      icon_size = 64,
      icon_mipmaps = 4,
      tint = reactor_tint,
    }},
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
    prerequisites = {"uranium-processing", "matter-digitization","processing-unit"},
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

if mods["space-age"] then
  technology.prerequisites = {"uranium-processing", "matter-digitization", "quantum-processor"}
  technology.unit =
  {
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
      {"metallurgic-science-pack", 1},
      {"agricultural-science-pack", 1},
      {"electromagnetic-science-pack", 1},
      {"cryogenic-science-pack", 1}
    },
    time = 60,
    count = 1000
  }
  recipe.ingredients =
  {
    {type = "item", name = "refined-concrete", amount = 800},
    {type = "item", name = "tungsten-plate", amount = 800},
    {type = "item", name = "quantum-processor", amount = 800},
    {type = "item", name = "superconductor", amount = 800}
  }
end


data:extend{item,entity,recipe,technology,container_entity,fluid_container_entity}