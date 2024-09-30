local settings = {}

table.insert(settings,
{
    type = "bool-setting",
    order = "cc",
    name = "qf-use-player-inventory",
    setting_type = "runtime-global",
    default_value = true
})
table.insert(settings,
{
    type = "bool-setting",
    order = "ce",
    name = "qf-prioritize-player-inventory",
    setting_type = "runtime-global",
    default_value = true
})

table.insert(settings,
{
    type = "bool-setting",
    order = "dc",
    name = "qf-defabricator-enable",
    setting_type = "runtime-global",
    default_value = true
})

-- Deconstructor
table.insert(settings,
{
    type = "string-setting",
    order = "ff",
    name = "qf-deconstructor-inventory",
    setting_type = "runtime-global",
    default_value = "both",
    allowed_values = {"only-digital", "only-player", "both"}
})


table.insert(settings,
{
    type = "string-setting",
    order = "hf",
    name = "qf-builder-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true
})
table.insert(settings,
{
    type = "string-setting",
    order = "hh",
    name = "qf-fabricator-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true
})
table.insert(settings,
{
    type = "string-setting",
    order = "hy",
    name = "qf-defabricator-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true
})
table.insert(settings,
{
    type = "string-setting",
    order = "hz",
    name = "qf-recipe-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true
})



-- Digitizer
table.insert(settings,
{
    type = "string-setting",
    order = "kc",
    name = "qf-digitizer-blacklist",
    setting_type = "runtime-global",
    default_value = "",
    allow_blank = true
})
table.insert(settings,
{
    type = "int-setting",
    name = "qf-dedigitizer-speed",
    order = "ke",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 100
})

    
  data:extend(settings)