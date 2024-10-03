data:extend(
{
	{
		type = "shortcut",
		name = "qf-fabricator-gui",
		order = "p[production]-g[gui]",
		action = "lua",
		icon =
		{
			filename = "__quantum-fabricator__/graphics/icons/product-development-icon.png",
			priority = "extra-high-no-scale",
			size = 32,
			scale = 1,
			flags = { "icon" }
		}
	},
    {
		type = "shortcut",
		name = "qf-storage-gui",
		order = "s[storage]-g[gui]",
		action = "lua",
		icon =
		{
			filename = "__quantum-fabricator__/graphics/icons/shelf-shelves-icon.png",
			priority = "extra-high-no-scale",
			size = 32,
			scale = 1,
			flags = { "icon" }
		}
	}
})
