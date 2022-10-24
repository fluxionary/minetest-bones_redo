local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

assert(
	type(futil.version) == "number" and futil.version >= os.time({year = 2022, month = 10, day = 24}),
	"please update futil"
)

bones = {
	version = os.time({year = 2022, month = 10, day = 24}),
	fork = "your-land",

	modname = modname,
	modpath = modpath,
	mod_storage = minetest.get_mod_storage(),

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

bones.mod_storage = nil
