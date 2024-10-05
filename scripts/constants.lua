
-- GUI stuff
QF_GUI = {}
QF_GUI.default = {}
QF_GUI.default.padding = 12
QF_GUI.titlebar = {}
QF_GUI.titlebar.height = 30
QF_GUI.dragspace = {}
QF_GUI.dragspace.height = 28
QF_GUI.searchbar = {}
QF_GUI.searchbar.width = 300
QF_GUI.storage_frame = {}
QF_GUI.storage_frame.width = 580
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
QF_GUI.main_frame.width = QF_GUI.storage_frame.width + QF_GUI.recipe_frame.width + QF_GUI.default.padding * 3
QF_GUI.main_frame.height = QF_GUI.storage_frame.height + QF_GUI.default.padding * 2 + QF_GUI.titlebar.height
QF_GUI.main_frame.min_width = QF_GUI.main_frame.width - QF_GUI.storage_frame.width - QF_GUI.default.padding
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

Update_rate = {}
Update_rate.revivals = {rate = 11, slots = 12}
Update_rate.destroys = {rate = 8, slots = 5}
Update_rate.entities = {rate = 67, slots = 6}
Update_rate.requests = {rate = 87, slots = 4}
Update_rate.reactors = 60

Reactor_constants = {}
Reactor_constants.idle_cost = 4
Reactor_constants.active_cost = 20
Reactor_constants.full_inventory_cost = 32
Reactor_constants.empty_storage_cost = 4
Reactor_constants.min_temperature = 5000
Reactor_constants.item_transfer_rate = 10
Reactor_constants.fluid_transfer_rate = 1000