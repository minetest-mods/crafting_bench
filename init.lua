local S = minetest.get_translator("crafting_bench")

minetest.register_alias("castle:workbench", "crafting_bench:workbench")

local usage_help = S("The inventory on the left is for raw materials, the inventory on the right holds finished products. The crafting grid in the center defines what recipe this workbench will make use of; place raw materials into it in the crafting pattern corresponding to what you want to build.")

if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	usage_help = usage_help .. "\n\n" .. S("This workbench is compatible with hoppers. Hoppers will insert into the raw material inventory and remove items from the finished goods inventory.")
end


local crafting_rate = minetest.settings:get("crafting_bench_crafting_rate")
if crafting_rate == nil then crafting_rate = 5 end


minetest.register_node("crafting_bench:workbench",{
	description = S("Workbench"),
	_doc_items_longdesc = S("A workbench that does work for you. Set a crafting recipe and provide raw materials and items will magically craft themselves once every @1 seconds.", crafting_rate),
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
			meta:set_string( 'formspec',
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
			'list[current_player;main;1,6;8,4;]' )
		meta:set_string( 'infotext', S('Workbench'))
		local inv = meta:get_inventory()
		inv:set_size( 'src', 2 * 4 )
		inv:set_size( 'rec', 3 * 3 )
		inv:set_size( 'dst', 1 * 4 )
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name().." moves stuff in workbench at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name().." moves stuff to workbench at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name().." takes stuff from workbench at "..minetest.pos_to_string(pos))
	end,
})
local get_recipe = function ( inv )
	local result, needed, input
	needed = inv:get_list( 'rec' )

	result, input = minetest.get_craft_result( {
		method = 'normal',
		width = 3,
		items = needed
	})

	local totalneed = {}

	if result.item:is_empty() then
		result = nil
	else
		result = result.item
		for _, item in ipairs( needed ) do
			if item ~= nil and not item:is_empty() and not inv:contains_item( 'src', item ) then
				result = nil
				break
			end
			if item ~= nil and not item:is_empty() then
				if totalneed[item:get_name()] == nil then
					totalneed[item:get_name()] = 1
				else
					totalneed[item:get_name()] = totalneed[item:get_name()] + 1
				end
			end
		end
		for name, number in pairs( totalneed ) do
			local totallist = inv:get_list( 'src' )
			for i, srcitem in pairs( totallist ) do
				if srcitem:get_name() == name then
					local taken = srcitem:take_item( number )
					number = number - taken:get_count()
					totallist[i] = srcitem
				end
				if number <= 0 then
					break
				end
			end
			if number > 0 then
				result = nil
				break
			end
		end
	end

	return needed, input, result
end

minetest.register_abm( {
	nodenames = { 'crafting_bench:workbench' },
	interval = crafting_rate,
	chance = 1,
	action = function ( pos, node )
		local meta = minetest.get_meta( pos )
		local inv = meta:get_inventory()
		local result, newinput, needed
		if not inv:is_empty( 'src' ) then
			-- Check for a valid recipe and sufficient resources to craft it
			needed, newinput, result = get_recipe( inv )
			if result ~= nil and inv:room_for_item( 'dst', result ) then
				inv:add_item( 'dst', result )
				for i, item in pairs( needed ) do
					if item ~= nil and item ~= '' then
						inv:remove_item( 'src', ItemStack( item ) )
					end
					if newinput[i] ~= nil and not newinput[i]:is_empty() then
						inv:add_item( 'src', newinput[i] )
					end
				end
			end
		end
	end
} )

local function has_locked_chest_privilege(meta, player)
	if player:get_player_name() ~= meta:get_string("owner") then
		return false
	end
	return true
end

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
