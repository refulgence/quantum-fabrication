local storage_reader_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
storage_reader_entity.name = "qf-storage-reader"
storage_reader_entity.minable = {mining_time = 0.2, result = "qf-storage-reader"}

local storage_reader_recipe = {
    type = "recipe",
    name = "qf-storage-reader",
    enabled = false,
    ingredients = {{type = "item", name = "copper-plate", amount = 10}, {type = "item", name = "electronic-circuit", amount = 5}},
    results = {{type = "item", name = "qf-storage-reader", amount = 1}}
}

local storage_reader_item = table.deepcopy(data.raw["item"]["constant-combinator"])
storage_reader_item.name = "qf-storage-reader"
storage_reader_item.place_result = "qf-storage-reader"

--Tech that unlocks this recipes is the same as the tech that unlocks the Digitizer chest

data:extend{storage_reader_entity,storage_reader_item,storage_reader_recipe}