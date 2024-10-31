if script.active_mods["gvv"] then require("__gvv__.gvv")() end

if script.active_mods["pyalienlife"] then require("compatibility/pyalienlife") end

require "scripts/constants"
require "scripts/process_data"
require "scripts/builder"
require "scripts/debuilder"
require "scripts/space_platforms"

require "scripts/translation"
require "scripts/gui/events"
require "scripts/events"

require "scripts/gui/fabricator"
require "scripts/gui/options"
require "scripts/gui/storage"
require "scripts/gui/tooltip"

