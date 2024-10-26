local settings = {}

table.insert(settings,
    {
        type = "bool-setting",
        order = "af",
        name = "qf-allow-decrafting",
        setting_type = "runtime-global",
        default_value = true
    })

data:extend(settings)