if script.active_mods["gvv"] then require("__gvv__.gvv")() end

require "scripts/helpers"

if script.active_mods["pyalienlife"] then require("compatibility/pyalienlife") end

require "scripts/tracking"
require "scripts/process_data"
require "scripts/builder"
require "scripts/constants"
require "scripts/gui_events"
require "scripts/gui_functions"
require "scripts/gui"
require "scripts/translation"
require "scripts/events"
require "scripts/gui_dedigitizer"