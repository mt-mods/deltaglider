local S = hangglider.translator
local module = {}

local has_unifieddyes = minetest.get_modpath("unifieddyes")
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



function module.get_dye_name(name)
	-- Remove prefix and potential suffix
	name = string.gsub(name, dye_suffix_pattern_farlands, "")
	name = string.match(name, dye_prefix_pattern_universal.."(.+)$")
	return name
end


function module.get_dye_color(name)
	local color
	if has_unifieddyes then
		color = unifieddyes.get_color_from_dye_name(name)
	end

	if not color then
		color = module.get_dye_name(name)
		if color then
			color = dye_colors[color]
		end
	end
	return color
end

function module.get_color_name(name)
	return translated_colors[module.get_dye_name(name)]
end

function module.get_color_name_from_color(color)
	for name, color_hex in pairs(dye_colors) do
		if color == color_hex then
			return translated_colors[name]
		end
	end
	return nil
end


return module
