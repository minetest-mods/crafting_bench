std = "lua51+luajit+minetest+crafting_bench"
unused_args = false
max_line_length = 120

stds.minetest = {
	read_globals = {
		"DIR_DELIM",
        "dump",
        "dump2",

        "math",
        "table",
        "string",
        "vector",

		"ItemStack",
        "PerlinNoise",
        "PerlinNoiseMap",
		"PseudoRandom",
		"PcgRandom",
		"SecureRandom",
		"Settings",
        "VoxelArea",
        "VoxelManip",

        "minetest",
	}
}

stds.crafting_bench = {
	globals = {
		"crafting_bench",
	},
	read_globals = {
	    "default",
	    "futil",
		"hopper",
	},
}
