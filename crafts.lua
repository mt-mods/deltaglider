
local S = deltaglider.translator

local colors = assert(dofile(core.get_modpath("deltaglider") .. "/colors.lua"))

local has_basic_materials = minetest.get_modpath("basic_materials")
local has_pipeworks       = minetest.get_modpath("pipeworks")
local has_ropes           = minetest.get_modpath("ropes")


-- Materials
local stick              = xcompat.materials.stick
local fabric             = "group:wool"
local fabric_repair_only = xcompat.materials.paper
local string             = xcompat.materials.string
if core.get_modpath("fl_trees") then
	-- Fix for Farlands xcompat string alternative not working during crafting
	string = stick
end



-- Placeholder repairing recipes (Doesn't directly apply repair, see handler)
local repair_percentage = 100
local repair_items      = {fabric, fabric_repair_only}
minetest.register_craft({
	output = "deltaglider:glider",
	recipe = {
		{fabric_repair_only, fabric_repair_only,   fabric_repair_only},
		{fabric_repair_only, "deltaglider:glider", fabric_repair_only},
		{fabric_repair_only, fabric_repair_only,   fabric_repair_only},
	},
})

minetest.register_craft({
	output = "deltaglider:glider",
	recipe = {"deltaglider:glider", fabric},
	type = "shapeless",
})

-- Placeholder color recipe (Doesn't drectly apply color, see handler)
do
	local item = ItemStack("deltaglider:glider")
	item:get_meta():set_string("description", S("Colored Glider"))
	minetest.register_craft({
		output = item:to_string(),
		recipe = {"deltaglider:glider", "group:dye"},
		type = "shapeless",
	})
end

-- Recipe handler (This is what applies color and repair)
local function crafting_callback_handle_placeholder_recipe(crafted_item, _, old_craft_grid)
	if crafted_item:get_name() ~= "deltaglider:glider" then
		-- Function called for an unrelated crafting recipe
		return  
	end
	-- Get existing state and present materials
	local wear, repaired, dye_name, color, color_name, repaired = 0, false, nil, nil, nil
	for _,stack in ipairs(old_craft_grid) do
		local name = stack:get_name()
		if not name or name == "" then
			-- This stack is empty, skip all checks
		elseif name == "deltaglider:glider" then
			wear       = stack:get_wear()
			color      = stack:get_meta():get("glider_color")
			color_name = colors.get_color_name_from_color(color)
		elseif minetest.get_item_group(name, "dye") ~= 0 then
			dye_name = name
		else
			for _,repair_item in ipairs(repair_items) do
				if name == repair_item 
					or minetest.get_item_group(name, string.match(repair_item, "^group:(.*)$")) ~= 0 
				then 
					repaired = true
				end
			end
		end
	end

	-- Overwrite color with dye if present
	if dye_name then
		color      = colors.get_dye_color(dye_name)
		color_name = colors.get_color_name(dye_name)
	end

	-- Repair if any repair item present
	if repaired then
		wear = wear - (65535 * (repair_percentage / 100))
		if wear < 0 then wear = 0 end
	end

	-- Apply item changes if valid
	if wear and color and color_name then
		if color == "ffffff" then
			-- Return an uncolored glider
			return ItemStack({name = "deltaglider:glider", wear = wear})
		end
		local meta = crafted_item:get_meta()
		meta:set_string("description", S("@1 Delta Glider", color_name))
		meta:set_string("inventory_image", "deltaglider_glider.png^(deltaglider_glider_color.png^[multiply:#"..color..")")
		meta:set_string("glider_color", color)
		crafted_item:set_wear(wear)
		return crafted_item
	end
end
-- Register handler as a callback for any crafting action
minetest.register_on_craft(crafting_callback_handle_placeholder_recipe)


-- Hangglider recipe shape
local function register_glider_recipe(_string, _fabric, _stick)
	minetest.register_craft({
		output = "deltaglider:glider",
		recipe = {
			{ _string, _fabric, _string },
			{ _fabric, _fabric, _fabric },
			{ _stick,  _stick,  _stick  },
		}
	})
end


-- Register default recipe (So players have a fallback regardless of mod combo)
register_glider_recipe(string, fabric, stick)

-- Set up modded materials recipe
if has_ropes then
	string = "ropes:ropesegment"
end
if has_basic_materials then
	fabric = "basic_materials:plastic_sheet"
	string = "basic_materials:steel_wire"
	stick  = "basic_materials:steel_strip"
end
-- Prefer pipeworks stick if present
if has_pipeworks then
	stick = "pipeworks:tube_1"
end

-- Register modded materials recipe 
register_glider_recipe(string, fabric, stick)
