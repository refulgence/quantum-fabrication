local utils = require("scripts/utils")

local pyalienlife = {}

pyalienlife["non duplicates"] = {
    ["arqad-hive-mk01"] = true,
    ["arqad-hive-mk02"] = true,
    ["arqad-hive-mk03"] = true,
    ["arqad-hive-mk04"] = true,
    ["auog-paddock-mk01"] = true,
    ["auog-paddock-mk02"] = true,
    ["auog-paddock-mk03"] = true,
    ["auog-paddock-mk04"] = true,
    ["bio-printer-mk01"] = true,
    ["bio-printer-mk02"] = true,
    ["bio-printer-mk03"] = true,
    ["bio-printer-mk04"] = true,
    ["bio-reactor-mk01"] = true,
    ["bio-reactor-mk02"] = true,
    ["bio-reactor-mk03"] = true,
    ["bio-reactor-mk04"] = true,
    ["bioport"] = true,
    ["cadaveric-arum-mk01"] = true,
    ["cadaveric-arum-mk02"] = true,
    ["cadaveric-arum-mk03"] = true,
    ["cadaveric-arum-mk04"] = true,
    ["compost-plant-mk01"] = true,
    ["compost-plant-mk02"] = true,
    ["compost-plant-mk03"] = true,
    ["compost-plant-mk04"] = true,
    ["creature-chamber-mk01"] = true,
    ["creature-chamber-mk02"] = true,
    ["creature-chamber-mk03"] = true,
    ["creature-chamber-mk04"] = true,
    ["cridren-enclosure-mk01"] = true,
    ["cridren-enclosure-mk02"] = true,
    ["cridren-enclosure-mk03"] = true,
    ["cridren-enclosure-mk04"] = true,
    ["data-array"] = true,
    ["ez-ranch-mk01"] = true,
    ["ez-ranch-mk02"] = true,
    ["ez-ranch-mk03"] = true,
    ["ez-ranch-mk04"] = true,
    ["fawogae-plantation-mk01"] = true,
    ["fawogae-plantation-mk02"] = true,
    ["fawogae-plantation-mk03"] = true,
    ["fawogae-plantation-mk04"] = true,
    ["fts-reactor"] = true,
    ["fts-reactor-mk02"] = true,
    ["fts-reactor-mk03"] = true,
    ["fts-reactor-mk04"] = true,
    ["fwf-mk01"] = true,
    ["guar-gum-plantation"] = true,
    ["guar-gum-plantation-mk02"] = true,
    ["guar-gum-plantation-mk03"] = true,
    ["guar-gum-plantation-mk04"] = true,
    ["kicalk-plantation-mk01"] = true,
    ["kicalk-plantation-mk02"] = true,
    ["kicalk-plantation-mk03"] = true,
    ["kicalk-plantation-mk04"] = true,
    ["moss-farm-mk01"] = true,
    ["moss-farm-mk02"] = true,
    ["moss-farm-mk03"] = true,
    ["moss-farm-mk04"] = true,
    ["mukmoux-pasture-mk01"] = true,
    ["mukmoux-pasture-mk02"] = true,
    ["mukmoux-pasture-mk03"] = true,
    ["mukmoux-pasture-mk04"] = true,
    ["nuclear-reactor-mk01"] = true,
    ["nuclear-reactor-mk02"] = true,
    ["nuclear-reactor-mk03"] = true,
    ["nuclear-reactor-mk04"] = true,
    ["prandium-lab-mk01"] = true,
    ["prandium-lab-mk02"] = true,
    ["prandium-lab-mk03"] = true,
    ["prandium-lab-mk04"] = true,
    ["provider-tank"] = true,
    ["ralesia-plantation-mk01"] = true,
    ["ralesia-plantation-mk02"] = true,
    ["ralesia-plantation-mk03"] = true,
    ["ralesia-plantation-mk04"] = true,
    ["requester-tank"] = true,
    ["seaweed-crop-mk01"] = true,
    ["seaweed-crop-mk02"] = true,
    ["seaweed-crop-mk03"] = true,
    ["seaweed-crop-mk04"] = true,
    ["trits-reef-mk01"] = true,
    ["trits-reef-mk02"] = true,
    ["trits-reef-mk03"] = true,
    ["trits-reef-mk04"] = true,
    ["vessel"] = true,
    ["vessel-to-ground"] = true,
    ["vonix-den-mk01"] = true,
    ["vonix-den-mk02"] = true,
    ["vonix-den-mk03"] = true,
    ["vrauks-paddock-mk01"] = true,
    ["vrauks-paddock-mk02"] = true,
    ["vrauks-paddock-mk03"] = true,
    ["vrauks-paddock-mk04"] = true,
    ["yotoi-aloe-orchard-mk01"] = true,
    ["yotoi-aloe-orchard-mk02"] = true,
    ["yotoi-aloe-orchard-mk03"] = true,
    ["yotoi-aloe-orchard-mk04"] = true,
    ["zipir-reef-mk01"] = true,
    ["zipir-reef-mk02"] = true,
    ["zipir-reef-mk03"] = true,
    ["zipir-reef-mk04"] = true,
}

pyalienlife["unpacking blacklist"] = {
    ["nuclear-reactor-mox-mk01-uncraft"] = true,
    ["nuclear-reactor-mox-mk02-uncraft"] = true,
    ["nuclear-reactor-mox-mk03-uncraft"] = true,
    ["nuclear-reactor-mox-mk04-uncraft"] = true,
}

pyalienlife["autocraft blacklist"] = {
    ["small-lamp"] = {
        ["vrauks-paddock-mk01-with-lamp"] = true,
        ["vrauks-paddock-mk02-with-lamp"] = true,
        ["vrauks-paddock-mk03-with-lamp"] = true,
        ["vrauks-paddock-mk04-with-lamp"] = true,
    }
}

pyalienlife["recipe blackliste"] = {
    ["nuclear-reactor-mox-mk01-uncraft"] = true,
    ["nuclear-reactor-mox-mk02-uncraft"] = true,
    ["nuclear-reactor-mox-mk03-uncraft"] = true,
    ["nuclear-reactor-mox-mk04-uncraft"] = true,
}

if not Actual_non_duplicates then Actual_non_duplicates = {} end
Actual_non_duplicates = utils.merge_tables(Actual_non_duplicates, pyalienlife["non duplicates"])

if not Unpacking_blacklist then Unpacking_blacklist = {} end
Unpacking_blacklist = utils.merge_tables(Unpacking_blacklist, pyalienlife["unpacking blacklist"])

if not Autocraft_blacklist then Autocraft_blacklist = {} end
Autocraft_blacklist = utils.merge_tables(Autocraft_blacklist, pyalienlife["autocraft blacklist"])

if not Recipe_blacklist then Recipe_blacklist = {} end
Recipe_blacklist = utils.merge_tables(Recipe_blacklist, pyalienlife["recipe blackliste"])