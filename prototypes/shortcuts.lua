data:extend(
{
	{
		type = "shortcut",
		name = "qf-fabricator-gui",
		order = "p[production]-g[gui]",
		action = "lua",
		icons =
		{{
			icon = "__quantum-fabricator__/graphics/icons/product-development-icon.png",
			icon_size = 32,
			scale = 1,
		}},
		small_icons =
		{{
			icon = "__quantum-fabricator__/graphics/icons/product-development-icon.png",
			icon_size = 32,
			scale = 1,
		}}
	},
	{
		type = "shortcut",
		name = "qf-fabricator-enable",
		order = "p[production]-g[gui]",
		action = "lua",
		toggleable = true,
		icons =
		{{
			icon = "__quantum-fabricator__/graphics/icons/manufacturing-production-icon.png",
			icon_size = 32,
			scale = 1,
		}},
		small_icons =
		{{
			icon = "__quantum-fabricator__/graphics/icons/manufacturing-production-icon.png",
			icon_size = 32,
			scale = 1,
		}}
	},
})
