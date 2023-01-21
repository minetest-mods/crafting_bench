if not crafting_bench.has.hopper then
	return
end

-- Hopper compatibility

minetest.override_item("crafting_bench:workbench", {
	_doc_items_usagehelp = minetest.registered_nodes["crafting_bench:workbench"]._doc_items_usagehelp
		.. "\n\n"
		.. crafting_bench.S(
			"This workbench is compatible with hoppers. Hoppers will insert into the raw material inventory "
				.. "and remove items from the finished goods inventory."
		),
})

if hopper.add_container then
	hopper:add_container({
		{ "top", "crafting_bench:workbench", "dst" },
		{ "side", "crafting_bench:workbench", "src" },
		{ "bottom", "crafting_bench:workbench", "src" },
	})
end
