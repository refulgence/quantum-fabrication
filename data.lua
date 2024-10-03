require "prototypes/custom-input"
require "prototypes/styles"
require "prototypes/digitizer-chest"
require "prototypes/digitizer-combinator"
require "prototypes/dedigitizer-reactor"
require "prototypes/shortcuts"

data:extend{{
	type = "sprite",
	name = "qf-vanilla-ghost-entity-icon",
	filename = "__core__/graphics/icons/mip/ghost-entity.png",
	priority = "extra-high-no-scale",
    flags = {"gui-icon"},
    mipmap_count = 3,
    scale = 0.5,
    size = 64
    },
    {type = "sprite",
    name = "qf-setting-icon",
    filename = "__quantum-fabricator__/graphics/icons/setting-icon.png",
    priority = "extra-high-no-scale",
    flags = {"gui-icon"},
    scale = 1,
    size = 32
    },
    {type = "sprite",
    name = "qf-setting-icon-white",
    filename = "__quantum-fabricator__/graphics/icons/setting-icon-white.png",
    priority = "extra-high-no-scale",
    flags = {"gui-icon"},
    scale = 1,
    size = 32}
}