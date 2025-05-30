--[[ 
    This script allows the user to make a selection of live cells, or a pattern. and output the selection into a single PNG type image file at the current time step.
    All live cells are captures as a single RGB value. 
    A seleciton on the Golly grid must be made first.
    Once the script is run, the user is prompted to name the file and choose a location for the file to be saved. 

    Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Jul. 2024.

 ]]--

local g = golly()
local ov = g.overlay

-- Function to parse RGB input and return default if input is empty
local function get_rgb_input(prompt, default)
    local input = g.getstring(prompt, default)
    if input == "" then
        return default
    end
    local r, g, b = input:match("(%d+),(%d+),(%d+)")
    return tonumber(r), tonumber(g), tonumber(b)
end

-- Get RGB values for live cells
local live_r, live_g, live_b = get_rgb_input("Enter RGB values for live cells (e.g., 0,0,0 for black):", "0,0,0")
local dead_r, dead_g, dead_b = get_rgb_input("Enter RGB values for dead cells (e.g., 255,255,255 for white):", "255,255,255")

-- Retrieve the current selection rectangle from UI
local selrect = g.getselrect()
if #selrect == 0 then 
    g.exit("There is no selection.")
end
local selx, sely, selwd, selht = table.unpack(selrect)

-- Create an overlay based on the size of the user's selection
ov("create " .. selwd .. " " .. selht)

-- Set the RGBA value to the user-defined color for dead cells
ov("rgba " .. dead_r .. " " .. dead_g .. " " .. dead_b .. " 255")
ov("fill 0 0 " .. selwd .. " " .. selht)

-- Set the RGBA value to the user-defined color for live cells
ov("rgba " .. live_r .. " " .. live_g .. " " .. live_b .. " 255")

-- Get the cells in the selection and draw live cells with the specified color
local cells = g.getcells(selrect)
for i = 1, #cells, 2 do
    local x = cells[i] - selx
    local y = cells[i + 1] - sely
    ov("set " .. x .. " " .. y)
end

-- Prompt user for filename and location
local savedir = g.getdir("data")
local pngpath = g.savedialog("Save overlay as PNG file", "PNG (*.png)|*.png", savedir, "exp1_image1a.png")
if #pngpath > 0 then
    -- Save overlay in given file
    ov("save 0 0 " .. selwd .. " " .. selht .. " " .. pngpath)
    g.note("Overlay was saved in " .. pngpath)

    -- Clear the overlay after saving
    ov("delete")
end
