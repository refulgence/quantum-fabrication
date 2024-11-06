local settings = {}

table.insert(settings,
    {
        type = "bool-setting",
        order = "af",
        name = "qf-allow-decrafting",
        setting_type = "runtime-global",
        default_value = true
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "af",
        name = "qf-direct-mining-puts-in-storage",
        setting_type = "runtime-per-user",
        default_value = false
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "af",
        name = "qf-enable-space-transfer",
        setting_type = "startup",
        default_value = true
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "cf",
        name = "qf-enable-auto-repair",
        setting_type = "startup",
        default_value = true
})

data:extend(settings)