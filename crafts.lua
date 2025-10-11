
local S = deltaglider.translator

local has_basic_materials = minetest.get_modpath("basic_materials")
local has_farming         = minetest.get_modpath("farming")
local has_pipeworks       = minetest.get_modpath("pipeworks")
local has_ropes           = minetest.get_modpath("ropes")
local has_wool            = minetest.get_modpath("wool")
local has_unifieddyes     = minetest.get_modpath("unifieddyes")
local dye_prefix_pattern_universal = "^.*dyes?:" -- Known dye prefix matches: dyes, mcl_dyes, mcl_dye, fl_dyes.
local dye_suffix_pattern_farlands  = "_dye$"     -- A suffix appended to dye names in the Farlands game.

local dye_colors = {
	black      = "111111",
	blue       = "0000ff",
	brown      = "592c00",
	cyan       = "00ffff",
	dark_green = "005900",
	dark_grey  = "444444",
	green      = "00ff00",
	grey       = "888888",
	light_blue = "258ec9",
	lime       = "60ac19",
	magenta    = "ff00ff",
	orange     = "ff7f00",
	pink       = "ff7f9f",
	purple     = "6821a0",
	red        = "ff0000",
	silver     = "818177",
	violet     = "8000ff",
	white      = "ffffff",
	yellow     = "ffff00",
}

local translated_colors = {
	black      = S("Black"),
	blue       = S("Blue"),
	brown      = S("Brown"),
	cyan       = S("Cyan"),
	dark_green = S("Dark Green"),
	dark_grey  = S("Dark Grey"),
	green      = S("Green"),
	grey       = S("Grey"),
	light_blue = S("Light Blue"),
	lime       = S("Lime"),
	magenta    = S("Magenta"),
	orange     = S("Orange"),
	pink       = S("Pink"),
	purple     = S("Purple"),
	red        = S("Red"),
	silver     = S("Light Grey"),
	violet     = S("Violet"),
	white      = S("White"),
	yellow     = S("Yellow"),
}



local function get_dye_name(name)
	-- Remove prefix and potential suffix
	name = string.gsub(name, dye_suffix_pattern_farlands, "")
	name = string.match(name, dye_prefix_pattern_universal.."(.+)$")
	return name
end



local function get_dye_color(name)
	local color
	if has_unifieddyes then
		color = unifieddyes.get_color_from_dye_name(name)
	end

	if not color then
		color = get_dye_name(name)
		if color then
			color = dye_colors[color]
		end
	end
	return color
end

local function get_color_name(name)
	return translated_colors[get_dye_name(name)]
end

local function get_color_name_from_color(color)
	for name, color_hex in pairs(dye_colors) do
		if color == color_hex then
			return translated_colors[name]
		end
	end
	return nil
end


-- Recipes ---------------------------------------------------------------------
-- Materials
local stick              = xcompat.materials.stick
local fabric             = "group:wool"
local fabric_repair_only = xcompat.materials.paper
local string             = xcompat.materials.string
if core.get_modpath("fl_trees") then
	-- Fix for Farlands xcompat string alternative not working during crafting
	string = stick
end

local repair_items      = {fabric, fabric_repair_only}
local repair_percentage = 100


-- Placeholder repairing recipes (Doesn't directly apply repair, see handler)
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
		if name and name ~= "" then
			if name == "deltaglider:glider" then
				wear       = stack:get_wear()
				color      = stack:get_meta():get("glider_color")
				color_name = get_color_name_from_color(color)
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
	end

	-- Overwrite color with dye if present
	if dye_name then
		color      = get_dye_color(dye_name)
		color_name = get_color_name(dye_name)
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
