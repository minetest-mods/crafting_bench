local S = crafting_bench.S
local crafting_rate = crafting_bench.settings.crafting_rate

local can_craft = crafting_bench.util.can_craft
local do_craft = crafting_bench.util.do_craft

local function update_timer(pos)
	local timer = minetest.get_node_timer(pos)
	local cc = can_craft(pos)
	local timer_is_started = timer:is_started()
	if cc and not timer_is_started then
		timer:start(crafting_rate)
	elseif not cc and timer_is_started then
		timer:stop()
	end
end

minetest.register_node("crafting_bench:workbench", {
	description = S("Workbench"),
	_doc_items_longdesc = S(
		"A workbench that does work for you. Set a crafting recipe and provide raw materials and items will "
			.. "magically craft themselves once every @1 seconds.",
		crafting_rate
	),
	_doc_items_usagehelp = S(
		"The inventory on the left is for raw materials, the inventory on the right holds finished products. "
			.. "The crafting grid in the center defines what recipe this workbench will make use of; place raw "
			.. "materials into it in the crafting pattern corresponding to what you want to build."
	),
	tiles = {
		"crafting_bench_workbench_top.png",
		"crafting_bench_workbench_bottom.png",
		"crafting_bench_workbench_side.png",
		"crafting_bench_workbench_side.png",
		"crafting_bench_workbench_back.png",
		"crafting_bench_workbench_front.png",
	},
	paramtype2 = "facedir",
	paramtype = "light",
	groups = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2 },
	sounds = crafting_bench.resources.sounds.wood,
	drawtype = "normal",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string(
			"formspec",
			table.concat({
				"size[10,10;]",
				crafting_bench.resources.gui_format,
				"label[1,0;",
				S("Source Material"),
				"]",
				"list[context;src;1,1;2,4;]",
				"label[4,0;",
				S("Recipe to Use"),
				"]",
				"list[context;rec;4,1;3,3;]",
				"label[7.5,0;",
				S("Craft Output"),
				"]",
				"list[context;dst;8,1;1,4;]",
				"list[current_player;main;1,6;8,4;]",
				"listring[current_name;dst]",
				"listring[current_player;main]",
				"listring[current_name;src]",
				"listring[current_player;main]",
			}, "")
		)
		meta:set_string("infotext", S("Workbench"))

		local inv = meta:get_inventory()
		inv:set_size("src", 2 * 4)
		inv:set_size("rec", 3 * 3)
		inv:set_size("dst", 1 * 4)
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("src") and inv:is_empty("dst")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if not minetest.is_player(player) or minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		if to_list == "dst" then
			return 0
		elseif to_list == "rec" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack(from_list, from_index)
			stack:set_count(1)
			inv:set_stack(to_list, to_index, stack)
			update_timer(pos)
			return 0
		elseif from_list == "rec" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_stack(from_list, from_index, "")
			update_timer(pos)
			return 0
		end

		return count
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(to_list, to_index)
		stack:set_count(count)

		crafting_bench.log(
			"action",
			"%s moves %s in workbench @ %s",
			player:get_player_name(),
			stack:to_string(),
			minetest.pos_to_string(pos)
		)

		update_timer(pos)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not minetest.is_player(player) or minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		if listname == "rec" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			stack:set_count(1)
			inv:set_stack("rec", index, stack)
			update_timer(pos)
			return 0
		elseif listname == "dst" then
			return 0
		end

		return stack:get_count()
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		crafting_bench.log(
			"action",
			"%s put %s in workbench @ %s",
			player:get_player_name(),
			stack:to_string(),
			minetest.pos_to_string(pos)
		)

		update_timer(pos)
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if not minetest.is_player(player) or minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		if listname == "rec" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_stack("rec", index, "")
			update_timer(pos)
			return 0
		end

		return stack:get_count()
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		crafting_bench.log(
			"action",
			"%s took %s from workbench @ %s",
			player:get_player_name(),
			stack:to_string(),
			minetest.pos_to_string(pos)
		)

		update_timer(pos)
	end,

	on_timer = function(pos, elapsed)
		do_craft(pos)

		if can_craft(pos) then
			return true
		end
	end,
})
