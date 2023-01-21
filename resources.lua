crafting_bench.resources = {
	sounds = {},
	craft_items = {},
	gui_format = "",
}

crafting_bench.resources.craft_items.wood = "group:wood"
crafting_bench.resources.craft_items.tree = "group:tree"

if crafting_bench.has.default then
	crafting_bench.resources.sounds.wood = default.node_sound_wood_defaults()
	crafting_bench.resources.gui_format = default.gui_bg .. default.gui_bg_img .. default.gui_slots
	crafting_bench.resources.craft_items.steel_ingot = "default:steel_ingot"
end
