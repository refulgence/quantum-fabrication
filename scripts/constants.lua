
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

QF_GUI.tabbed_pane = {}
QF_GUI.tabbed_pane.width = QF_GUI.storage_frame.width - QF_GUI.default.padding * 4 + 40
QF_GUI.tabbed_pane.height = QF_GUI.storage_frame.height - QF_GUI.default.padding * 4 - 36 + 20
QF_GUI.tabbed_pane.button_size = {width = 20, height = 20}
QF_GUI.tabbed_pane.name_width = 200
QF_GUI.tabbed_pane.count_width = 100
QF_GUI.tabbed_pane.button_width = 200
QF_GUI.tabbed_pane.recipe_usage_width = 200



DEFAULT_PADDING = 12
DRAGSPACE_FILLER_HEIGHT = 28
TABBED_PANE_HEIGHT = 36

STORAGE_FLOW_SIZE = {width = 580, height = 988}
RECIPE_FLOW_SIZE = {width = 840, height = STORAGE_FLOW_SIZE.height}
MAIN_FRAME_SIZE = {width = STORAGE_FLOW_SIZE.width + RECIPE_FLOW_SIZE.width + DEFAULT_PADDING * 3, height = STORAGE_FLOW_SIZE.height + DEFAULT_PADDING * 2 + DRAGSPACE_FILLER_HEIGHT}
TOOLTIP_CONTENT_SIZE = {width = STORAGE_FLOW_SIZE.width - DEFAULT_PADDING, height = STORAGE_FLOW_SIZE.height - DEFAULT_PADDING * 2}

TABBED_PANE_CONTENT_SIZE = {width = STORAGE_FLOW_SIZE.width - DEFAULT_PADDING * 4 + 40, height = STORAGE_FLOW_SIZE.height - DEFAULT_PADDING * 4 - TABBED_PANE_HEIGHT + 20}

SEARCHBAR_WIDTH = 200

TABBED_PANE_TAB_SIZE = {}
TABBED_PANE_TAB_SIZE["button"] = {width = 20, height = 20}

TABBED_PANE_TAB_WIDTH = {}
TABBED_PANE_TAB_WIDTH["item name"] = 200
TABBED_PANE_TAB_WIDTH["fluid name"] = TABBED_PANE_TAB_WIDTH["item name"]
TABBED_PANE_TAB_WIDTH["recipe name"] = TABBED_PANE_TAB_WIDTH["item name"]
TABBED_PANE_TAB_WIDTH["entity name"] = TABBED_PANE_TAB_WIDTH["item name"]

TABBED_PANE_TAB_WIDTH["item count"] = 100
TABBED_PANE_TAB_WIDTH["fluid count"] = TABBED_PANE_TAB_WIDTH["item count"]

TABBED_PANE_TAB_WIDTH["button"] = 200

TABBED_PANE_TAB_WIDTH["item recipe usage"] = 200

RECIPE_FLOW_TABLE_WIDTH = 840
RECIPE_FLOW_ITEM_GROUP_BUTTON_HEIGHT = 75
RECIPE_FLOW_ITEM_GROUP_MAX_NUMBER_OF_COLUMNS = 8
SUBGROUP_TABLE_COLUMNS = 20

Update_rate = {}
Update_rate["revivals"] = {rate = 11, slots = 12}
Update_rate["destroys"] = {rate = 8, slots = 5}
Update_rate["entities"] = {rate = 67, slots = 6}
Update_rate["requests"] = {rate = 87, slots = 4}

MIN_TEMPERATURE = 5000