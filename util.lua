local util = {}

local function get_single_string(item)
	item = ItemStack(item)
	item:set_count(1)
	return item:to_string()
end

function util.can_craft(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local needed = inv:get_list("rec")
	local output, decremented_input = minetest.get_craft_result({
		method = "normal",
		width = 3,
		items = needed,
	})

	if output.item:is_empty() then
		return false
	end

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

	-- now we need to check whether there's enough room for all the output, which is obnoxious, so use FakeInventory
	local fake_inv = futil.FakeInventory.create_copy(inv)
	local remainder = fake_inv:add_item("dst", output.item)
	if not remainder:is_empty() then
		return false
	end
	for _, item in ipairs(output.replacements) do
		remainder = fake_inv:add_item("dst", item)
		if not remainder:is_empty() then
			return false
		end
	end
	for _, item in ipairs(decremented_input.items) do
		remainder = fake_inv:add_item("dst", item)
		if not remainder:is_empty() then
			return false
		end
	end
	return true
end

function util.do_craft(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local needed = inv:get_list("rec")
	local output, decremented_input = minetest.get_craft_result({
		method = "normal",
		width = 3,
		items = needed,
	})

	if output.item:is_empty() then
		crafting_bench.log("error", "@ %s: tried to craft, but no output", minetest.pos_to_string(pos))
	end

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

crafting_bench.util = util
