local mod_start_time = minetest.get_us_time()
minetest.log("action", "[MOD] bones loading")

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

bones = {
	version = {1, 0, 0},
	fork = "your-land",

	modname = modname,
	modpath = modpath,

	S = S,

	has = {
		armor_3d = minetest.get_modpath("3d_armor"),
		armor = minetest.get_modpath("armor"),
		default = minetest.get_modpath("default"),
	},

	log = function(level, messagefmt, ...)
		return minetest.log(level, ("[%s] %s"):format(modname, messagefmt:format(...)))
	end,

	dofile = function(...)
		return dofile(table.concat({modpath, ...}, DIR_DELIM) .. ".lua")
	end,
}

bones.dofile("settings")
bones.dofile("util")
bones.dofile("resources")
bones.dofile("formspec")
bones.dofile("api")
bones.dofile("node")
bones.dofile("entity")
bones.dofile("on_dieplayer")
bones.dofile("commands")

bones.log("action", "loaded in %s", (minetest.get_us_time() - mod_start_time) / 1e6)
