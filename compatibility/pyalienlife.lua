local pyalienlife = {}

pyalienlife["unpacking blacklist"] = {
    ["nuclear-reactor-mox-mk01-uncraft"] = true,
    ["nuclear-reactor-mox-mk02-uncraft"] = true,
    ["nuclear-reactor-mox-mk03-uncraft"] = true,
    ["nuclear-reactor-mox-mk04-uncraft"] = true,
}

pyalienlife["autocraft blacklist"] = {
    ["small-lamp"] = {
        ["vrauk-paddock-mk01-with-lamp"] = true,
        ["vrauk-paddock-mk02-with-lamp"] = true,
        ["vrauk-paddock-mk03-with-lamp"] = true,
        ["vrauk-paddock-mk04-with-lamp"] = true,
    }
}



if not Unpacking_blacklist then Unpacking_blacklist = {} end
Unpacking_blacklist = merge_tables(Unpacking_blacklist, pyalienlife["unpacking blacklist"])

if not Autocraft_blacklist then Autocraft_blacklist = {} end
Autocraft_blacklist = merge_tables(Autocraft_blacklist, pyalienlife["autocraft blacklist"])