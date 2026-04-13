--[[
 This script enhances the visualization of cellular automaton patterns in Golly by applying user-defined colors 
 based on the age of each cell and allowing for customizable background color selection.
 
 Features:
 - User prompts to define a custom color palette with preset or custom RGB values.
 - Automatic transformation of the selected area into a toroidal universe (torus).
 - Dynamic coloring of cells based on their ages, with the ability to cycle through colors as cells evolve.
 - Background color selection from a list of preset options or custom RGB values.
 - Overlay creation based on the size of the user's selection for enhanced visualization.
 - Capability to save the current overlay as a PNG image.
 
 Instructions:
 1. Before running the script, make a selection in Golly to focus on a specific area of the pattern.
 2. Run the script, which will automatically convert the selected area into a torus.
 3. Follow the prompts to choose a color palette and a background color.
 4. The script will then automate the evolution of the pattern, applying colors based on the age of the cells.
 5. Press the space bar to manually advance generations, or input the number of generations to run automatically.
 6. At any point, press 's' to save the overlay as a PNG image.

 Note:
 - Ensure that a selection is made in Golly before running the script, as the visualization operates on the selected area.
 - The script automatically applies a toroidal transformation to the selection, with no user option to disable it.

  Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Oct. 2025.

]]--


local g = golly()
local ov = g.overlay
-----------------------------------------------------------------------------------------------

-- Centralized color definitions table
local color_definitions = {
    -- Your existing color presets
    ["red"] = "255 0 0",
    ["pink"] = "255 192 203",
    ["purple"] = "128 0 128",
    ["magenta"] = "255 0 255",
    ["blue"] = "0 0 255",
    ["light blue"] = "173 216 230",
    ["white"] = "255 255 255",
    ["green"] = "0 128 0",
    ["cyan"] = "0 255 255",
    ["orange"] = "255 165 0",
    ["yellow"] = "255 255 0",
    ["black"] = "0 0 0",
    ["gray"] = "128 128 128",
    ["silver"] = "192 192 192",
    ["gold"] = "255 215 0",
    ["maroon"] = "128 0 0",
    ["brown"] = "165 42 42",
    ["tan"] = "210 180 140",
    ["peach"] = "255 218 185",
    ["lime"] = "0 255 0",
    ["olive"] = "128 128 0",
    ["teal"] = "0 128 128",
    ["navy"] = "0 0 128",
    ["light aqua"] = "173 216 230",
    ["coral pink"] = "255 127 80",
    ["seafoam green"] = "128 255 210",
    ["deep teal"] = "0 128 128",
    ["sandy beige"] = "240 230 140",
    ["navy blue"] = "0 0 128",
    ["sunset orange"] = "255 165 0",
    ["cloud white"] = "255 255 255",
    ["burnt orange"] = "204 85 0",
    ["mustard yellow"] = "255 219 88",
    ["crimson red"] = "220 20 60",
    ["olive green"] = "128 128 0",
    ["chestnut brown"] = "205 92 92",
    ["pumpkin orange"] = "255 102 0",
    ["golden rod"] = "218 165 32",
    ["rust brown"] = "139 69 19",
    ["blossom pink"] = "255 182 193",
    ["lilac"] = "200 162 200",
    ["mint green"] = "152 255 152",
    ["sunshine yellow"] = "255 255 102",
    ["sky blue"] = "135 206 235",
    ["lavender"] = "230 230 250",
    ["peach"] = "255 218 185",
    ["soft green"] = "144 238 144",
    ["turquoise blue"] = "64 224 208",
    ["hot pink"] = "255 105 180",
    ["sunset gold"] = "255 215 0",
    ["deep purple"] = "75 0 130",
    ["lime green"] = "50 205 50",
    ["neon orange"] = "255 165 0",
    ["vibrant red"] = "255 0 0",
    ["muted gray"] = "169 169 169",
    ["charcoal gray"] = "54 69 79",
    ["light gray"] = "211 211 211",
    ["soft white"] = "245 245 245",
    ["steel blue"] = "70 130 180",
    ["slate gray"] = "112 128 144",
    ["ash gray"] = "178 190 181",
    ["graphite black"] = "0 0 0",
    ["terracotta"] = "204 78 55",
    ["warm pink"] = "255 105 180",
    ["soft lavender"] = "204 153 255",
    ["dusky blue"] = "100 149 237",
    ["mauve"] = "224 176 255",
    ["dusty rose"] = "188 143 143",
    ["pine green"] = "1 68 33",
    ["moss green"] = "173 223 173",
    ["bark brown"] = "101 67 33",
    ["fern green"] = "113 145 141",
    ["cedar wood"] = "139 69 19",
    ["icy blue"] = "173 216 230",
    ["snow white"] = "255 250 250",
    ["frosty gray"] = "211 211 211",
    ["midnight blue"] = "25 25 112",
    ["evergreen"] = "0 100 0",
    ["slate blue"] = "106 90 205",
    ["dusty gray"] = "169 169 169",
    ["vivid violet"] = "138 43 226",
    ["electric blue"] = "0 191 255",
    ["bright yellow"] = "255 255 0",
    ["neon green"] = "57 255 20",
    ["flamingo pink"] = "255 105 180",
    ["orange red"] = "255 69 0",
    ["lime yellow"] = "255 255 102",
    ["hot magenta"] = "255 0 255",
    ["concrete gray"] = "128 128 128",
    ["brick red"] = "178 34 34",
    ["urban green"] = "34 139 34",
    ["deep charcoal"] = "54 69 79",
    ["cyan"] = "0 255 255",
    ["muted yellow"] = "255 204 0",
    ["sienna brown"] = "160 82 45",
    ["lavender"] = "230 230 250", 
    ["deep rose"] = "199 21 133", 
    ["violet"] = "238 130 238", 
    ["crimson"] = "220 20 60", 
    ["teal"] = "0 128 128", 
    ["navy blue"] = "0 0 128", 
    ["mint green"] = "152 255 152", 
    ["sky blue"] = "135 206 235", 
    ["lime green"] = "50 205 50",
    ["coral"] = "255 127 80", 
    ["turquoise"] = "64 224 208",
    ["goldenrod"] = "218 165 32",
    ["forest green"] = "34 139 34",
    ["beige"] = "245 245 220"
}
-----------------------------------------------------------------------------------------------

-- Function to present color palettes to the user.
local function show_palette_options(numcolors)
    local palettes = {
        ["1"] = {
            "a) Red",
            "b) Blue",
            "c) Cyan",
            "d) [Oceanic Harmony]: Light Aqua",
            "e) [Autumn Harvest]: Burnt Orange",
            "f) [Spring Boot]: Blossom Pink",
            "g) [Retro Pop]: Turquoise Blue",
            "h) [Minimalist Monochrome]: Charcoal Gray",
            "i) [Desert Sunset]: Terracotta",
            "j) [Forest Palette]: Pine Green",
            "k) [Winter Chill]: Icy Blue",
            "l) [Bright & Bold]: Vivid Violet",
            "m) [Urban Jungle]: Concrete Gray",
            "n) Enter your own RGB value"
        },
        ["2"] = {
            "a) Red, Pink",
            "b) Blue, Light Blue",
            "c) Cyan, Orange",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow",
            "f) [Spring Boot]: Blossom Pink, Lilac",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray",
            "i) [Desert Sunset]: Terracotta, Sandy Beige",
            "j) [Forest Palette]: Pine Green, Moss Green",
            "k) [Winter Chill]: Icy Blue, Snow White",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue",
            "m) [Urban Jungle]: Concrete Gray, Brick Red",
            "n) Enter your own RGB values"
        },
        ["3"] = {
            "a) Red, Pink, Purple",
            "b) Blue, Light Blue, White",
            "c) Cyan, Orange, Yellow",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green",
            "n) Enter your own RGB values"
        },
        ["4"] = {
            "a) Red, Pink, Purple, Magenta",
            "b) Blue, Light Blue, White, Green",
            "c) Cyan, Orange, Yellow, Green",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green, Deep Teal",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red, Olive Green",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green, Sunshine Yellow",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold, Deep Purple",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White, Steel Blue",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink, Soft Lavender",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown, Fern Green",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray, Crimson Red",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow, Neon Green",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green, Steel Blue",
            "n) Enter your own RGB values"
        },
        ["5"] = {
            "a) Red, Pink, Purple, Magenta, Lavender",
            "b) Blue, Light Blue, White, Green, Teal",
            "c) Cyan, Orange, Yellow, Green, Lime Green",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green, Deep Teal, Sandy Beige",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red, Olive Green, Chestnut Brown",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green, Sunshine Yellow, Sky Blue",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold, Deep Purple, Lime Green",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White, Steel Blue, Slate Gray",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink, Soft Lavender, Dusky Blue",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown, Fern Green, Cedar Wood",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray, Crimson Red, Midnight Blue",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow, Neon Green, Flamingo Pink",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green, Steel Blue, Deep Charcoal",
            "n) Enter your own RGB values"
        },
        ["6"] = {
            "a) Red, Pink, Purple, Magenta, Lavender, Deep Rose",
            "b) Blue, Light Blue, White, Green, Teal, Navy Blue",
            "c) Cyan, Orange, Yellow, Green, Lime Green, Coral",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green, Deep Teal, Sandy Beige, Navy Blue",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red, Olive Green, Chestnut Brown, Pumpkin Orange",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green, Sunshine Yellow, Sky Blue, Lavender",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold, Deep Purple, Lime Green, Neon Orange",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White, Steel Blue, Slate Gray, Ash Gray",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink, Soft Lavender, Dusky Blue, Sunset Orange",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown, Fern Green, Cedar Wood, Forest Floor",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray, Crimson Red, Midnight Blue, Evergreen",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow, Neon Green, Flamingo Pink, Orange Red",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green, Steel Blue, Deep Charcoal, Cyan",
            "n) Enter your own RGB values"
        },
        ["7"] = {
            "a) Red, Pink, Purple, Magenta, Lavender, Deep Rose, Violet",
            "b) Blue, Light Blue, White, Green, Teal, Navy Blue, Mint Green",
            "c) Cyan, Orange, Yellow, Green, Lime Green, Coral, Turquoise",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green, Deep Teal, Sandy Beige, Navy Blue, Sunset Orange",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red, Olive Green, Chestnut Brown, Pumpkin Orange, Golden Rod",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green, Sunshine Yellow, Sky Blue, Lavender, Peach",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold, Deep Purple, Lime Green, Neon Orange, Vibrant Red",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White, Steel Blue, Slate Gray, Ash Gray, Graphite Black",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink, Soft Lavender, Dusky Blue, Sunset Orange, Mauve",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown, Fern Green, Cedar Wood, Forest Floor, Olive Drab",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray, Crimson Red, Midnight Blue, Evergreen, Slate Blue",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow, Neon Green, Flamingo Pink, Orange Red, Lime Yellow",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green, Steel Blue, Deep Charcoal, Cyan, Muted Yellow",
            "n) Enter your own RGB values"
        },
        ["8"] = {
            "a) Red, Pink, Purple, Magenta, Lavender, Deep Rose, Violet, Crimson",
            "b) Blue, Light Blue, White, Green, Teal, Navy Blue, Mint Green, Sky Blue",
            "c) Cyan, Orange, Yellow, Green, Lime Green, Coral, Turquoise, Goldenrod",
            "d) [Oceanic Harmony]: Light Aqua, Coral Pink, Seafoam Green, Deep Teal, Sandy Beige, Navy Blue, Sunset Orange, Cloud White",
            "e) [Autumn Harvest]: Burnt Orange, Mustard Yellow, Crimson Red, Olive Green, Chestnut Brown, Pumpkin Orange, Golden Rod, Rust Brown",
            "f) [Spring Boot]: Blossom Pink, Lilac, Mint Green, Sunshine Yellow, Sky Blue, Lavender, Peach, Soft Green",
            "g) [Retro Pop]: Turquoise Blue, Hot Pink, Sunset Gold, Deep Purple, Lime Green, Neon Orange, Vibrant Red, Muted Gray",
            "h) [Minimalist Monochrome]: Charcoal Gray, Light Gray, Soft White, Steel Blue, Slate Gray, Ash Gray, Graphite Black, Cloud White",
            "i) [Desert Sunset]: Terracotta, Sandy Beige, Warm Pink, Soft Lavender, Dusky Blue, Sunset Orange, Mauve, Dusty Rose",
            "j) [Forest Palette]: Pine Green, Moss Green, Bark Brown, Fern Green, Cedar Wood, Forest Floor, Olive Drab, Earthy Beige",
            "k) [Winter Chill]: Icy Blue, Snow White, Frosty Gray, Crimson Red, Midnight Blue, Evergreen, Slate Blue, Dusty Gray",
            "l) [Bright & Bold]: Vivid Violet, Electric Blue, Bright Yellow, Neon Green, Flamingo Pink, Orange Red, Lime Yellow, Hot Magenta",
            "m) [Urban Jungle]: Concrete Gray, Brick Red, Urban Green, Steel Blue, Deep Charcoal, Cyan, Muted Yellow, Sienna Brown",
            "n) Enter your own RGB values"
        }

        
        
    }
    
    -- Determine which palette options to show
    local options
    if numcolors <= 8 then
        -- Show only the palette corresponding to `numcolors`
        options = palettes[tostring(numcolors)]
    else
        -- Show options for 8 colors, as the user is allowed extra custom RGB entries later
        options = palettes["8"]
    end
    
    -- Build the display string for the user
    local palette_string
    if numcolors > 8 then
        palette_string = "Your color count (" .. numcolors .. ") exceeds 8.\nChoose a base 8-color palette — colors will cycle through it for all " .. numcolors .. " steps:\n"
    else
        palette_string = "Choose a color palette or enter your own RGB values:\n"
    end
    for _, option in ipairs(options) do
        palette_string = palette_string .. option .. "\n"
    end

    -- Get the user's choice (palette letter)
    local palette_letter = g.getstring(palette_string, "", "Palette Choice")
    palette_letter = palette_letter:lower() -- Convert to lowercase for consistency

    -- Concatenate numcolors (up to 8) and the palette letter for preset colors
    local palette_choice = tostring(math.min(numcolors, 8)) .. palette_letter

    -- Check if the user chose to enter their own RGB values for all colors
    if palette_letter == "n" then
        return "custom" -- Use a special value to indicate full custom input
    end

    return { preset = palette_choice }
end
-----------------------------------------------------------------------------------------------

-- This is the make-torus.lua script from Golly. 
-- Use the current selection to create a toroidal universe.
local function make_torus()
    -- Get the current selection.
    local selrect = g.getselrect()

    -- If no selection is made, show a message and exit the script.
    if #selrect == 0 then
        g.exit("There is no selection. Please select an area before running the script. A torus will automatically be created from your selection.")
    end

    -- Unpack the selection coordinates and size.
    local x, y, wd, ht = table.unpack(selrect)
    local selcells = g.getcells(selrect)

    -- Clear the grid if it's not empty.
    if not g.empty() then
        g.clear(0)
        g.clear(1)
    end

    -- Get the current rule, remove any existing suffix, and add the toroidal suffix.
    local rule = g.getrule()
    rule = rule:match("^(.+):") or rule
    g.setrule(string.format("%s:T%d,%d", rule, wd, ht))

    -- Adjust the selection to be centered on the grid.
    local newx = -math.floor(wd / 2)
    local newy = -math.floor(ht / 2)
    selrect[1] = newx
    selrect[2] = newy
    g.select(selrect)

    -- Place the original cells in the new selection.
    if #selcells > 0 then
        g.putcells(selcells, newx - x, newy - y)
    end

    -- Fit the selection in the viewport.
    g.fitsel()
end

-----------------------------------------------------------------------------------------------
-- Automatically make a torus without asking the user for confirmation.
make_torus()

-- Clone the layer after the torus is created, and tile layers

-- -------- Ask for LIGHTWEIGHT MODE up front --------
local lm_prompt = "Use LIGHTWEIGHT mode? (y/n)\n\nLightweight mode = no overlay shown/updated during run;\nonly the final saved PNG will include the colored overlay."
local lm_ans = g.getstring(lm_prompt, "", "Lightweight Mode")
local lightweight = (lm_ans == "y" or lm_ans == "Y")

if not lightweight then
    local cloneindex = g.clone()
    g.setoption("tilelayers", 1)
end
-----------------------------------------------------------------------------------------------

-- Function to prompt the user for RGB values.
local function get_rgb(prompt)
    local rgb = g.getstring(prompt, "", "RGB Input")
    local r, g, b = string.match(rgb, "(%d+)%s+(%d+)%s+(%d+)")
    return tonumber(r), tonumber(g), tonumber(b)
end

-----------------------------------------------------------------------------------------------

-- Collect color values from the preset palette, reuse previous values, or let the user input custom RGB values.
local function apply_palette_choice(palette_data, numcolors)
    local colors = {}

    -- If the user chose full custom input
    if palette_data == "custom" then
        for i = 1, numcolors do
            local r, g, b = get_rgb("Enter RGB values for COLOR # " .. i .. " separated by spaces (e.g., '255 0 0' for red):")
            if not r or not g or not b then 
                g.exit("Invalid RGB values for color #" .. i) 
            end
            colors[i] = r .. " " .. g .. " " .. b
        end
        return colors
    end

    -- If the user chose a preset, build colors by cycling through it
    local preset = palette_data.preset

        -- Map palette choices to actual color definitions
        local color_map = {
            -- Palette for 1 color
            ["1a"] = { color_definitions["red"] },
            ["1b"] = { color_definitions["blue"] },
            ["1c"] = { color_definitions["cyan"] },
            ["1d"] = { color_definitions["light aqua"] },
            ["1e"] = { color_definitions["burnt orange"] },
            ["1f"] = { color_definitions["blossom pink"] },
            ["1g"] = { color_definitions["turquoise blue"] },
            ["1h"] = { color_definitions["charcoal gray"] },
            ["1i"] = { color_definitions["terracotta"] },
            ["1j"] = { color_definitions["pine green"] },
            ["1k"] = { color_definitions["icy blue"] },
            ["1l"] = { color_definitions["vivid violet"] },
            ["1m"] = { color_definitions["concrete gray"] },

            -- Palette for 2 colors
            ["2a"] = { color_definitions["red"], color_definitions["pink"] },
            ["2b"] = { color_definitions["blue"], color_definitions["light blue"] },
            ["2c"] = { color_definitions["cyan"], color_definitions["orange"] },
            ["2d"] = { color_definitions["light aqua"], color_definitions["coral pink"] },
            ["2e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"] },
            ["2f"] = { color_definitions["blossom pink"], color_definitions["lilac"] },
            ["2g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"] },
            ["2h"] = { color_definitions["charcoal gray"], color_definitions["light gray"] },
            ["2i"] = { color_definitions["terracotta"], color_definitions["sandy beige"] },
            ["2j"] = { color_definitions["pine green"], color_definitions["moss green"] },
            ["2k"] = { color_definitions["icy blue"], color_definitions["snow white"] },
            ["2l"] = { color_definitions["vivid violet"], color_definitions["electric blue"] },
            ["2m"] = { color_definitions["concrete gray"], color_definitions["brick red"] },

            -- Palette for 3 colors
            ["3a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"] },
            ["3b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"] },
            ["3c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"] },
            ["3d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"] },
            ["3e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"] },
            ["3f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"] },
            ["3g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"] },
            ["3h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"] },
            ["3i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"] },
            ["3j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"] },
            ["3k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"] },
            ["3l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"] },
            ["3m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"] },

            -- Palette for 4 colors
            ["4a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"], color_definitions["magenta"] },
            ["4b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"], color_definitions["green"] },
            ["4c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"], color_definitions["green"] },
            ["4d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"], color_definitions["deep teal"] },
            ["4e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"], color_definitions["olive green"] },
            ["4f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"], color_definitions["sunshine yellow"] },
            ["4g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"], color_definitions["deep purple"] },
            ["4h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"], color_definitions["steel blue"] },
            ["4i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"], color_definitions["soft lavender"] },
            ["4j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"], color_definitions["fern green"] },
            ["4k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"], color_definitions["crimson red"] },
            ["4l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"], color_definitions["neon green"] },
            ["4m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"], color_definitions["steel blue"] },

            -- Palette for 5 colors
            ["5a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"], color_definitions["magenta"], color_definitions["lavender"] },
            ["5b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"], color_definitions["green"], color_definitions["teal"] },
            ["5c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"], color_definitions["green"], color_definitions["lime green"] },
            ["5d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"], color_definitions["deep teal"], color_definitions["sandy beige"] },
            ["5e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"], color_definitions["olive green"], color_definitions["chestnut brown"] },
            ["5f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"], color_definitions["sunshine yellow"], color_definitions["sky blue"] },
            ["5g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"], color_definitions["deep purple"], color_definitions["lime green"] },
            ["5h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"], color_definitions["steel blue"], color_definitions["slate gray"] },
            ["5i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"], color_definitions["soft lavender"], color_definitions["dusky blue"] },
            ["5j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"], color_definitions["fern green"], color_definitions["cedar wood"] },
            ["5k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"], color_definitions["crimson red"], color_definitions["midnight blue"] },
            ["5l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"], color_definitions["neon green"], color_definitions["flamingo pink"] },
            ["5m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"], color_definitions["steel blue"], color_definitions["deep charcoal"] },

            -- Palette for 6 colors
            ["6a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"], color_definitions["magenta"], color_definitions["lavender"], color_definitions["deep rose"] },
            ["6b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"], color_definitions["green"], color_definitions["teal"], color_definitions["navy blue"] },
            ["6c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"], color_definitions["green"], color_definitions["lime green"], color_definitions["coral"] },
            ["6d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"], color_definitions["deep teal"], color_definitions["sandy beige"], color_definitions["navy blue"] },
            ["6e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"], color_definitions["olive green"], color_definitions["chestnut brown"], color_definitions["pumpkin orange"] },
            ["6f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"], color_definitions["sunshine yellow"], color_definitions["sky blue"], color_definitions["lavender"] },
            ["6g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"], color_definitions["deep purple"], color_definitions["lime green"], color_definitions["neon orange"] },
            ["6h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"], color_definitions["steel blue"], color_definitions["slate gray"], color_definitions["ash gray"] },
            ["6i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"], color_definitions["soft lavender"], color_definitions["dusky blue"], color_definitions["sunset orange"] },
            ["6j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"], color_definitions["fern green"], color_definitions["cedar wood"], color_definitions["forest floor"] },
            ["6k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"], color_definitions["crimson red"], color_definitions["midnight blue"], color_definitions["evergreen"] },
            ["6l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"], color_definitions["neon green"], color_definitions["flamingo pink"], color_definitions["orange red"] },
            ["6m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"], color_definitions["steel blue"], color_definitions["deep charcoal"], color_definitions["cyan"] },

            -- Palette for 7 colors
            ["7a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"], color_definitions["magenta"], color_definitions["lavender"], color_definitions["deep rose"], color_definitions["violet"] },
            ["7b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"], color_definitions["green"], color_definitions["teal"], color_definitions["navy blue"], color_definitions["mint green"] },
            ["7c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"], color_definitions["green"], color_definitions["lime green"], color_definitions["coral"], color_definitions["turquoise"] },
            ["7d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"], color_definitions["deep teal"], color_definitions["sandy beige"], color_definitions["navy blue"], color_definitions["sunset orange"] },
            ["7e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"], color_definitions["olive green"], color_definitions["chestnut brown"], color_definitions["pumpkin orange"], color_definitions["golden rod"] },
            ["7f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"], color_definitions["sunshine yellow"], color_definitions["sky blue"], color_definitions["lavender"], color_definitions["peach"] },
            ["7g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"], color_definitions["deep purple"], color_definitions["lime green"], color_definitions["neon orange"], color_definitions["vibrant red"] },
            ["7h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"], color_definitions["steel blue"], color_definitions["slate gray"], color_definitions["ash gray"], color_definitions["graphite black"] },
            ["7i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"], color_definitions["soft lavender"], color_definitions["dusky blue"], color_definitions["sunset orange"], color_definitions["mauve"] },
            ["7j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"], color_definitions["fern green"], color_definitions["cedar wood"], color_definitions["forest floor"], color_definitions["olive drab"] },
            ["7k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"], color_definitions["crimson red"], color_definitions["midnight blue"], color_definitions["evergreen"], color_definitions["slate blue"] },
            ["7l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"], color_definitions["neon green"], color_definitions["flamingo pink"], color_definitions["orange red"], color_definitions["lime yellow"] },
            ["7m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"], color_definitions["steel blue"], color_definitions["deep charcoal"], color_definitions["cyan"], color_definitions["muted yellow"] },

            -- Palette for 8 colors
            ["8a"] = { color_definitions["red"], color_definitions["pink"], color_definitions["purple"], color_definitions["magenta"], color_definitions["lavender"], color_definitions["deep rose"], color_definitions["violet"], color_definitions["crimson"] },
            ["8b"] = { color_definitions["blue"], color_definitions["light blue"], color_definitions["white"], color_definitions["green"], color_definitions["teal"], color_definitions["navy blue"], color_definitions["mint green"], color_definitions["sky blue"] },
            ["8c"] = { color_definitions["cyan"], color_definitions["orange"], color_definitions["yellow"], color_definitions["green"], color_definitions["lime green"], color_definitions["coral"], color_definitions["turquoise"], color_definitions["goldenrod"] },
            ["8d"] = { color_definitions["light aqua"], color_definitions["coral pink"], color_definitions["seafoam green"], color_definitions["deep teal"], color_definitions["sandy beige"], color_definitions["navy blue"], color_definitions["sunset orange"], color_definitions["cloud white"] },
            ["8e"] = { color_definitions["burnt orange"], color_definitions["mustard yellow"], color_definitions["crimson red"], color_definitions["olive green"], color_definitions["chestnut brown"], color_definitions["pumpkin orange"], color_definitions["golden rod"], color_definitions["rust brown"] },
            ["8f"] = { color_definitions["blossom pink"], color_definitions["lilac"], color_definitions["mint green"], color_definitions["sunshine yellow"], color_definitions["sky blue"], color_definitions["lavender"], color_definitions["peach"], color_definitions["soft green"] },
            ["8g"] = { color_definitions["turquoise blue"], color_definitions["hot pink"], color_definitions["sunset gold"], color_definitions["deep purple"], color_definitions["lime green"], color_definitions["neon orange"], color_definitions["vibrant red"], color_definitions["muted gray"] },
            ["8h"] = { color_definitions["charcoal gray"], color_definitions["light gray"], color_definitions["soft white"], color_definitions["steel blue"], color_definitions["slate gray"], color_definitions["ash gray"], color_definitions["graphite black"], color_definitions["cloud white"] },
            ["8i"] = { color_definitions["terracotta"], color_definitions["sandy beige"], color_definitions["warm pink"], color_definitions["soft lavender"], color_definitions["dusky blue"], color_definitions["sunset orange"], color_definitions["mauve"], color_definitions["dusty rose"] },
            ["8j"] = { color_definitions["pine green"], color_definitions["moss green"], color_definitions["bark brown"], color_definitions["fern green"], color_definitions["cedar wood"], color_definitions["forest floor"], color_definitions["olive drab"], color_definitions["earthy beige"] },
            ["8k"] = { color_definitions["icy blue"], color_definitions["snow white"], color_definitions["frosty gray"], color_definitions["crimson red"], color_definitions["midnight blue"], color_definitions["evergreen"], color_definitions["slate blue"], color_definitions["dusty gray"] },
            ["8l"] = { color_definitions["vivid violet"], color_definitions["electric blue"], color_definitions["bright yellow"], color_definitions["neon green"], color_definitions["flamingo pink"], color_definitions["orange red"], color_definitions["lime yellow"], color_definitions["hot magenta"] },
            ["8m"] = { color_definitions["concrete gray"], color_definitions["brick red"], color_definitions["urban green"], color_definitions["steel blue"], color_definitions["deep charcoal"], color_definitions["cyan"], color_definitions["muted yellow"], color_definitions["sienna brown"] }
        }

    -- Get the preset base colors from the map
    local base_colors = color_map[preset]
    if not base_colors then
        g.exit("Invalid palette selection.")
    end

    -- Fill colors up to numcolors, cycling through the base palette if needed
    for i = 1, numcolors do
        colors[i] = base_colors[((i - 1) % #base_colors) + 1]
    end

    return colors
end

-- Main script execution


local numcolors = tonumber(g.getstring("Input the number of colors you would like to use.", "4", "Number of Colors"))
if not numcolors or numcolors < 1 then 
    g.exit("Invalid number of colors.") 
end

-- Show the palette options and get the selected palette data
local palette_data = show_palette_options(numcolors)

-- Apply the palette choice using the selected preset and additional RGB values if necessary
local colors = apply_palette_choice(palette_data, numcolors)


-----------------------------------------------------------------------------------------------
-- Function to prompt for background color selection
local function show_background_options()
    local bg_options = {
        "a) Black",
        "b) White",
        "c) Light Gray",
        "d) Charcoal Gray",
        "e) Navy",
        "f) Forest Green",
        "g) Sky Blue",
        "h) Beige",
        "i) Enter your own RGB values"
    }

    -- Build the display string for background color options
    local bg_prompt = "Choose a background color or enter your own RGB values:\n"
    for _, option in ipairs(bg_options) do
        bg_prompt = bg_prompt .. option .. "\n"
    end

    -- Get the user's choice for background color
    local bg_choice = g.getstring(bg_prompt, "", "Background Color Choice")
    bg_choice = bg_choice:lower() -- Convert to lowercase for consistency

    -- If user chooses to enter their own RGB values
    if bg_choice == "i" then
        return "custom"
    end

    -- Map the user's choice to actual color definitions
    local bg_map = {
        a = color_definitions["black"],
        b = color_definitions["white"],
        c = color_definitions["light gray"],
        d = color_definitions["charcoal gray"],
        e = color_definitions["navy"],
        f = color_definitions["forest green"],
        g = color_definitions["sky blue"],
        h = color_definitions["beige"]
    }

    -- Retrieve the background color from the map
    return bg_map[bg_choice]
end

-----------------------------------------------------------------------------------------------
-- Prompt for the background color and store it
local background_choice = show_background_options()
local background_color

-- Handle custom background color input if chosen
if background_choice == "custom" then
    local prompt_bg = "Enter RGB values for the BACKGROUND COLOR separated by spaces (e.g., '0 0 0' for black):"
    local br, bg, bb = get_rgb(prompt_bg)
    if not br or not bg or not bb then 
        g.exit("Invalid RGB values for background color.") 
    end
    background_color = {r=br, g=bg, b=bb}
else
    -- Convert the selected preset background color to RGB
    local br, bg, bb = string.match(background_choice, "(%d+)%s+(%d+)%s+(%d+)")
    background_color = {r=tonumber(br), g=tonumber(bg), b=tonumber(bb)}
end


-----------------------------------------------------------------------------------------------

-- Retrieve the current selection rectangle from UI.
local selrect = g.getselrect()
if #selrect == 0 then 
    g.exit("There is no selection.")
end
local selx, sely, selwd, selht = table.unpack(selrect)
-----------------------------------------------------------------------------------------------

-- Prompt once for PNG scale (1 = no scaling; try 2, 3, 4, ...)
-- === Export / drawing scale ===
local S = tonumber(
  g.getstring("Enter integer scale factor for final PNG (e.g. 2,4,8,16):", "4", "Scale Factor")
)
if not S or S < 1 then S = 1 end
-- -------- Create overlay ONLY for non-lightweight real-time mode --------
-- In lightweight mode, we DO NOT create an overlay here.
if not lightweight then
  ov("create " .. (selwd * S) .. " " .. (selht * S))
  ov("position middle")
  ov("blend 1")
end

-----------------------------------------------------------------------------------------------
-- Function to determine the next color index, wrapping around to the first color.
-- This function is used to cycle through colors for cell aging visualization.
local function nextColorIndex(index)
    return (index % #colors) + 1
end

-----------------------------------------------------------------------------------------------
-- Initialize a table to track the ages of cells.
local cellAges = {}
local colorIndex = 1
-----------------------------------------------------------------------------------------------
-- Prompt the user to specify the number of generations to run.
-- This determines how long the cellular automaton will evolve before stopping.
local rungens = g.getstring("Enter the number of generations to run\nOR\nLeave blank for manual time stepping with space bar:\n", "", "Run Generations")
rungens = tonumber(rungens)
if not rungens then 
    rungens = 0 
end

-----------------------------------------------------------------------------------------------
-- Function to perform a coloring time step.
-- This function updates the overlay based on the ages of cells and user-defined colors.
local function color_step()
  local newCellAges = {}
  local cells = g.getcells(selrect)

  if not lightweight then
    -- prep background
    ov("position middle")
    ov("blend 1")
    ov("rgba "..background_color.r.." "..background_color.g.." "..background_color.b.." 255")
    ov("fill")
  end

  for i = 1, #cells, 2 do
    local x, y = cells[i] - selx, cells[i+1] - sely
    local key = x .. ":" .. y

    if not cellAges[key] then
      newCellAges[key] = colorIndex
      if not lightweight then ov("rgba " .. colors[colorIndex] .. " 255") end
    else
      newCellAges[key] = cellAges[key]
      if not lightweight then ov("rgba " .. colors[cellAges[key]] .. " 255") end
    end

    if not lightweight then
      local dx, dy = x * S, y * S
      ov("fill " .. dx .. " " .. dy .. " " .. S .. " " .. S)
    end
  end

  cellAges = newCellAges
  colorIndex = nextColorIndex(colorIndex)

  if not lightweight then
    ov("update")
    g.update()
  end
end

-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------

-- === WORKING DIRECTORY SETUP ===
-- To always save PNGs in your preferred folder:
-- Replace the path below with the full path to your working directory.
-- On Mac or Linux: "/Users/yourname/Desktop/saved-images/"
-- On Windows: "C:\\Users\\yourname\\Desktop\\saved-images\\"


--local savedir = "/Users/yourname/Desktop/saved-images/"

local savedir = g.getdir("data")



-- -------- Save current overlay to PNG --------
-- In lightweight mode, we build the overlay OFF-SCREEN, never update/show it.
local function save_png(savedir)
  -- Ask user for path
  local pngpath = g.savedialog("Save overlay as PNG file", "PNG (*.png)|*.png", savedir, "overlay.png")
  if #pngpath == 0 then return savedir end

  if lightweight then
    -- Build overlay off-screen: NO ov('update') and NO g.update()
    ov("create " .. (selwd * S) .. " " .. (selht * S))
    ov("blend 1") -- opaque composition while drawing to the off-screen buffer

    -- background
    ov("rgba "..background_color.r.." "..background_color.g.." "..background_color.b.." 255")
    ov("fill")

    -- draw all cells according to current tracked ages
    for key, idx in pairs(cellAges) do
      local x, y = key:match("(-?%d+):(-?%d+)")
      x = tonumber(x); y = tonumber(y)
      local dx, dy = x * S, y * S
      ov("rgba " .. colors[idx] .. " 255")
      ov("fill " .. dx .. " " .. dy .. " " .. S .. " " .. S)
    end

    -- Save directly from the buffer (no on-screen update at any point)
    ov("save 0 0 " .. (selwd * S) .. " " .. (selht * S) .. " " .. pngpath)
    ov("delete") -- clean up immediately so nothing can appear later
  else
    -- Normal mode: overlay is already on-screen and up-to-date
    ov("save 0 0 " .. (selwd * S) .. " " .. (selht * S) .. " " .. pngpath)
  end

  g.note("Overlay saved to:\n" .. pngpath)

  -- update default directory
  local pathsep = g.getdir("app"):sub(-1)
  return pngpath:gsub("[^"..pathsep.."]+$","")
end

-- -------- Main loop --------
g.note("Press 's' any time to save the PNG.\nPress 'q' or 'esc' to abort.")

local savedir = g.getdir("data")

while true do
  g.show("Press 's' to save PNG • 'q' or 'esc' to abort")

  local stepped = false

  if rungens > 0 then
    g.step()
    color_step()
    rungens = rungens - 1
    stepped = true
  else
    local event = g.getevent()

    if event:find("key space") then
      g.step()
      color_step()
      g.update()
      stepped = true

    elseif event:find("key s") then
      savedir = save_png(savedir)

    elseif event:find("key q") or event:find("key escape") then
      break
    end
  end

  -- keep loop responsive
  g.sleep(1)
end
