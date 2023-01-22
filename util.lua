local get_craft_result = minetest.get_craft_result
local get_meta = minetest.get_meta
local pos_to_string = minetest.pos_to_string

local FakeInventory = futil.FakeInventory

local util = {}

local function get_single_string(item)
	item = ItemStack(item)
	item:set_count(1)
	return item:to_string()
end

local craft_result_cache = {}

function util.invalidate_craft_result_cache(pos)
	craft_result_cache[pos_to_string(pos)] = nil
end

function util.get_craft_result(pos)
	-- cache the craft result on Sokomine's recommendation
	local spos = pos_to_string(pos)
	local result = craft_result_cache[spos]

	local output, decremented_input, needed

	if result then
		output, decremented_input, needed = unpack(result)
	else
		local meta = get_meta(pos)
		local inv = meta:get_inventory()
		needed = inv:get_list("rec")

		output, decremented_input = get_craft_result({
			method = "normal",
			width = 3,
			items = needed,
		})

		craft_result_cache[spos] = { output, decremented_input, needed }
	end

	return output, decremented_input, needed
end

function util.can_craft(pos)
	local output, decremented_input, needed = util.get_craft_result(pos)

	if output.item:is_empty() then
		return false
	end

	local meta = get_meta(pos)
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

	-- now we need to check whether there's enough room for all the output, which is obnoxious, so use FakeInventory
	local fake_inv = FakeInventory.create_copy(inv)
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
	local output, decremented_input, needed = util.get_craft_result(pos)

	if output.item:is_empty() then
		crafting_bench.log("error", "@ %s: tried to craft, but no output", pos_to_string(pos))
	end

	local meta = get_meta(pos)
	local inv = meta:get_inventory()

	for i = 1, #needed do
		local item = needed[i]
		local taken = inv:remove_item("src", item)
		if not futil.items_equals(item, taken) then
			crafting_bench.log(
				"error",
				"@ %s: tried to take %s but only got %s",
				pos_to_string(pos),
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
			pos_to_string(pos),
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
				pos_to_string(pos),
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
				pos_to_string(pos),
				remainder:to_string()
			)
			minetest.add_item(pos, remainder)
		end
	end
end

crafting_bench.util = util
