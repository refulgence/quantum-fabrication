local settings = {}




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





table.insert(settings,
{
    type = "int-setting",
    name = "qf-update-rate",
    order = "kep",
    setting_type = "runtime-global",
    default_value = 7,
    minimum_value = 2,
    maximum_value = 1000
})
table.insert(settings,
{
    type = "int-setting",
    name = "qf-update-slots",
    order = "ker",
    setting_type = "runtime-global",
    default_value = 12,
    minimum_value = 1,
    maximum_value = 1000
})

    
  data:extend(settings)