local s = minetest.settings

crafting_bench.settings = {
	crafting_rate = tonumber(s:get("crafting_bench_crafting_rate")) or 5,
}
