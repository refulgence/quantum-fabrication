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
        order = "afa",
        name = "qf-allow-pulling-out",
        setting_type = "runtime-global",
        default_value = true
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "ag",
        name = "qf-direct-mining-puts-in-storage",
        setting_type = "runtime-per-user",
        default_value = false
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "aha",
        name = "qf-enable-space-transfer",
        setting_type = "startup",
        default_value = true
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "ahb",
        name = "qf-use-player-inventory",
        setting_type = "runtime-per-user",
        default_value = true
})
table.insert(settings,
    {
        type = "int-setting",
        order = "al",
        name = "qf-reactor-transfer-multi",
        setting_type = "runtime-global",
        default_value = 1,
        minimum_value = 1,
        maximum_value = 1000,
})
table.insert(settings,
    {
        type = "bool-setting",
        order = "am",
        name = "qf-reactor-free-transfer",
        setting_type = "runtime-global",
        default_value = false
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