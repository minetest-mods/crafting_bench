futil.check_version({ year = 2023, month = 01, day = 21 })

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local f = string.format

crafting_bench = {
	version = os.time({ year = 2023, month = 01, day = 21 }),
	author = "Philipbenr and DanDuncombe",
	license = "MIT",
	media_license = "CC-BY-SA-3.0",

	modname = modname,
	modpath = modpath,
	S = S,

	has = {
		default = minetest.get_modpath("default"),
		hopper = minetest.get_modpath("hopper"),
	},

	log = function(level, message, ...)
		minetest.log(level, f("[%s] %s", modname, f(message, ...)))
	end,

	dofile = function(...)
		dofile(table.concat({ modpath, ... }, DIR_DELIM) .. ".lua")
	end,
}

crafting_bench.dofile("settings")
crafting_bench.dofile("resources")
crafting_bench.dofile("util")
crafting_bench.dofile("crafting_bench")
crafting_bench.dofile("craft")
crafting_bench.dofile("compat", "init")
