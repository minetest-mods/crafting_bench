futil.check_version({ year = 2023, month = 2, day = 27 })  -- required for FakeInventory.room_for_all

local f = string.format

local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

minetest.register_alias("castle:workbench", "crafting_bench:workbench")

local usage_help = S(
	"The inventory on the left is for raw materials, the inventory on the right holds finished products. " ..
	"The crafting grid in the center defines what recipe this workbench will make use of; " ..
	"place raw materials into it in the crafting pattern corresponding to what you want to build."
)

if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	usage_help = usage_help .. "\n\n" .. S(
		"This workbench is compatible with hoppers. " ..
		"Hoppers will insert into the raw material inventory and remove items from the finished goods inventory."
	)
end

local crafting_rate = tonumber(minetest.settings:get("crafting_bench_crafting_rate")) or 5

crafting_bench = {
	log = function(level, messagefmt, ...)
		return minetest.log(level, f("[%s] %s", modname, f(messagefmt, ...)))
	end,
}

local function get_single_string(item)
	item = ItemStack(item)
	item:set_count(1)
	return item:to_string()
end

local function get_craft_result(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local needed = inv:get_list("rec")

	-- note: get_craft_result can be very slow, until minetest 5.7.0 is released
	-- see https://github.com/minetest/minetest/issues/13231
	local output, decremented_input = minetest.get_craft_result({
		method = "normal",
		width = 3,
		items = needed,
	})

	return output, decremented_input, needed
end

local function can_craft(pos)
	local output, decremented_input, needed = get_craft_result(pos)

	if output.item:is_empty() then
		return false
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local needed_counts = {}
	for _, item in ipairs(needed) do
		local itemstring = get_single_string(item)
		needed_counts[itemstring] = (needed_counts[itemstring] or 0) + item:get_count()
	end

	for itemstring, count in pairs(needed_counts) do
		local item = ItemStack(itemstring)
		item:set_count(count)
		if not inv:contains_item("src", item) then
			return false
		end
	end

	-- now we need to check whether there's enough room for all the output
	local to_add = {output.item}
	table.insert_all(to_add, output.replacements)
	table.insert_all(to_add, decremented_input.items)

	return futil.FakeInventory.room_for_all(inv, "dst", to_add)
end

local function do_craft(pos)
	local output, decremented_input, needed = get_craft_result(pos)

	if output.item:is_empty() then
		crafting_bench.log("error", "@ %s: tried to craft, but no output", minetest.pos_to_string(pos))
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	for i = 1, #needed do
		local item = needed[i]
		local taken = inv:remove_item("src", item)
		if not futil.items_equals(item, taken) then
			crafting_bench.log(
				"error",
				"@ %s: tried to take %s but only got %s",
				minetest.pos_to_string(pos),
				item:to_string(),
				taken:to_string()
			)
		end
	end
	local remainder = inv:add_item("dst", output.item)
	if not remainder:is_empty() then
		crafting_bench.log(
			"error",
			"@ %s: no room for %s, adding as an item in the world",
			minetest.pos_to_string(pos),
			remainder:to_string()
		)
		minetest.add_item(pos, remainder)
	end
	for _, item in ipairs(output.replacements) do
		remainder = inv:add_item("dst", item)
		if not remainder:is_empty() then
			crafting_bench.log(
				"error",
				"@ %s: no room for %s, adding as an item in the world",
				minetest.pos_to_string(pos),
				remainder:to_string()
			)
			minetest.add_item(pos, remainder)
		end
	end
	for _, item in ipairs(decremented_input.items) do
		remainder = inv:add_item("dst", item)
		if not remainder:is_empty() then
			crafting_bench.log(
				"error",
				"@ %s: no room for %s, adding as an item in the world",
				minetest.pos_to_string(pos),
				remainder:to_string()
			)
			minetest.add_item(pos, remainder)
		end
	end
end

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

local formspec =
	'size[10,10;]' ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	'label[1,0;'..S('Source Material')..']' ..
	'list[context;src;1,1;2,4;]' ..
	'label[4,0;'..S('Recipe to Use')..']' ..
	'list[context;rec;4,1;3,3;]' ..
	'label[7.5,0;'..S('Craft Output')..']' ..
	'list[context;dst;8,1;1,4;]' ..
	'list[current_player;main;1,6;8,4;]' ..
	'listring[context;dst]'..
	'listring[current_player;main]'..
	'listring[context;src]'..
	'listring[current_player;main]' ..
	'listring[context;rec]'..
	'listring[current_player;main]'

minetest.register_node("crafting_bench:workbench",{
	description = S("Workbench"),
	_doc_items_longdesc = S(
		"A workbench that does work for you. Set a crafting recipe and provide raw materials and items will " ..
		"magically craft themselves once every @1 seconds.", crafting_rate
	),
	_doc_items_usagehelp = usage_help,
	tiles = {
		"crafting_bench_workbench_top.png",
		"crafting_bench_workbench_bottom.png",
		"crafting_bench_workbench_side.png",
		"crafting_bench_workbench_side.png",
		"crafting_bench_workbench_back.png",
		"crafting_bench_workbench_front.png"
	},
	paramtype2 = "facedir",
	paramtype = "light",
	groups = {choppy=2,oddly_breakable_by_hand=2,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	drawtype = "normal",
	on_construct = function ( pos )
		local meta = minetest.get_meta( pos )
		meta:set_string( 'formspec', formspec)
		meta:set_string( 'infotext', S('Workbench'))
		local inv = meta:get_inventory()
		inv:set_size( 'src', 2 * 4 )
		inv:set_size( 'rec', 3 * 3 )
		inv:set_size( 'dst', 1 * 4 )
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
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

minetest.register_craft({
	output = "crafting_bench:workbench",
	recipe = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"default:wood", "default:wood","default:steel_ingot"},
		{"default:tree", "default:tree","default:steel_ingot"},
	}
})

-- Hopper compatibility
if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	hopper:add_container({
		{"top", "crafting_bench:workbench", "dst"},
		{"side", "crafting_bench:workbench", "src"},
		{"bottom", "crafting_bench:workbench", "src"},
	})
end

minetest.register_lbm({
	name = "crafting_bench:refund",
	label = "refund crafting bench recipe",
	nodenames = {"crafting_bench:workbench"},
	run_at_every_load = true,
	action = function(pos, node, dtime_s)
		local meta = minetest.get_meta(pos)
		if meta:get("refunded") then
			return
		end

		local inv = meta:get_inventory()
		local to_refund = minetest.deserialize(meta:get("to_refund"))

		if not to_refund then
			to_refund = {}
			for i, item in ipairs(inv:get_list("rec")) do
				if not item:is_empty() then
					table.insert(to_refund, item:to_string())
					if item:get_count() > 1 then
						inv:set_stack("rec", i, item:peek_item())
					end
				end
			end

			meta:set_string( 'formspec', formspec)
			update_timer(pos)
		end

		local remaining = {}
		for _, item in ipairs(to_refund) do
			local remainder = inv:add_item("dst", item)
			if not remainder:is_empty() then
				table.insert(remaining, remainder:to_string())
			end
		end

		if #remaining == 0 then
			meta:set_string("refunded", "true")
			meta:set_string("to_refund", "")

		else
			meta:set_string("to_refund", minetest.serialize(remaining))
		end
	end,
})
