
-- GUI stuff
QF_GUI = {}
QF_GUI.default = {}
QF_GUI.default.padding = 12
QF_GUI.titlebar = {}
QF_GUI.titlebar.height = 30
QF_GUI.dragspace = {}
QF_GUI.dragspace.height = 28
QF_GUI.searchbar = {}
QF_GUI.searchbar.width = 250
QF_GUI.storage_frame = {}
QF_GUI.storage_frame.width = 580 / 2
QF_GUI.storage_frame.height = 988
QF_GUI.recipe_frame = {}
QF_GUI.recipe_frame.width = 840
QF_GUI.recipe_frame.height = QF_GUI.storage_frame.height
QF_GUI.recipe_frame.item_group_table = {}
QF_GUI.recipe_frame.item_group_table.width = 840
QF_GUI.recipe_frame.item_group_table.button_height = 75
QF_GUI.recipe_frame.item_group_table.max_number_of_columns = 8
QF_GUI.recipe_frame.item_group_table.subgroup_table_columns = 20
QF_GUI.main_frame = {}
QF_GUI.main_frame.width = (QF_GUI.storage_frame.width + QF_GUI.recipe_frame.width + QF_GUI.default.padding * 3) / 2
QF_GUI.main_frame.height = QF_GUI.storage_frame.height + QF_GUI.default.padding * 2 + QF_GUI.titlebar.height
QF_GUI.main_frame.min_width = (QF_GUI.main_frame.width - QF_GUI.storage_frame.width - QF_GUI.default.padding) / 2
QF_GUI.main_frame.min_height = QF_GUI.main_frame.height
QF_GUI.options_frame = {}
QF_GUI.options_frame.width = 800
QF_GUI.options_frame.max_height = 900

QF_GUI.tabbed_pane = {}
QF_GUI.tabbed_pane.width = QF_GUI.storage_frame.width - QF_GUI.default.padding * 4 + 40
QF_GUI.tabbed_pane.height = QF_GUI.storage_frame.height - QF_GUI.default.padding * 4 - 36 + 20
QF_GUI.tabbed_pane.button_size = {width = 20, height = 20}
QF_GUI.tabbed_pane.name_width = 200
QF_GUI.tabbed_pane.count_width = 100
QF_GUI.tabbed_pane.button_width = 200
QF_GUI.tabbed_pane.recipe_usage_width = 200

QF_GUI.tooltip_frame = {}
QF_GUI.tooltip_frame.ing_label_width = 145
QF_GUI.tooltip_frame.required_label_width = 60
QF_GUI.tooltip_frame.available_label_width = 65


Update_rate = {}
Update_rate.revivals = {rate = 5, slots = 12}
Update_rate.destroys = {rate = 3, slots = 5}
Update_rate.entities = {rate = 67, slots = 6}
Update_rate.requests = {rate = 87, slots = 4}
Update_rate.reactors = 60
Update_rate.item_request_proxy_recheck = 244

Reactor_constants = {}
Reactor_constants.idle_cost = 4
Reactor_constants.active_cost = 20
Reactor_constants.full_inventory_cost = 32
Reactor_constants.empty_storage_cost = 4
Reactor_constants.min_temperature = 5000
Reactor_constants.item_transfer_rate = 4
Reactor_constants.fluid_transfer_rate = 80

Request_table_filter_link = {
    ["revivals"] = {name = "entity-ghost"},
    ["destroys"] = {to_be_deconstructed = true},
    ["upgrades"] = {to_be_upgraded = true},
}

On_tick_requests = {
    [1] = "revivals",
    [2] = "destroys",
    [3] = "upgrades",
    [4] = "repairs",
}

Transport_belt_types = {
    ["transport-belt"] = true,
    ["underground-belt"] = true,
    ["splitter"] = true,
    ["loader"] = true,
    ["loader-1x1"] = true,
    ["linked-belt"] = true,
    ["lane-splitter"] = true
}

Non_blueprintable_types = {
    ["tree"] = true,
    ["plant"] = true,
    ["simple-entity"] = true,
    ["construction-robot"] = true,
    ["logistic-robot"] = true
}

Cloneable_entities = {
    ["digitizer-chest"] = true,
    ["dedigitizer-reactor"] = true,
}

if not Actual_non_duplicates then Actual_non_duplicates = {} end
if not Unpacking_blacklist then Unpacking_blacklist = {} end
if not Autocraft_blacklist then Autocraft_blacklist = {} end
if not Recipe_blacklist then Recipe_blacklist = {} end

QS_DEFAULT_QUALITY = "normal"
QS_ROCKET_WEIGHT_LIMIT = 1000000
QS_SPACE_FOUNDATION_NAME = "space-platform-foundation"
