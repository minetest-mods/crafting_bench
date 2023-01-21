local ci = crafting_bench.resources.craft_items

if ci.wood and ci.tree and ci.steel_ingot then
	minetest.register_craft({
		output = "crafting_bench:workbench",
		recipe = {
			{ ci.steel_ingot, ci.steel_ingot, ci.steel_ingot },
			{ ci.wood, ci.wood, ci.steel_ingot },
			{ ci.tree, ci.tree, ci.steel_ingot },
		},
	})
end
