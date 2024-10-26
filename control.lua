if script.active_mods["gvv"] then require("__gvv__.gvv")() end

if script.active_mods["pyalienlife"] then require("compatibility/pyalienlife") end

require "scripts/tracking"
require "scripts/process_data"
require "scripts/builder"
require "scripts/constants"
require "scripts/translation"
require "scripts/gui/events"
require "scripts/events"

require "scripts/gui/dedigitizer_reactor"

require "scripts/gui/fabricator"
require "scripts/gui/options"
require "scripts/gui/storage"
require "scripts/gui/tooltip"

