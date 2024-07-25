 --[[
 This script is designed to enhance the visualization of cellular automaton patterns by applying user-defined colors based on the age of each cell. 
    Features:
    - User prompts to define a custom color palette.
    - Optional transformation of selected areas into a torus.
    - Dynamic coloring of cells based on their ages.
    - Overlay creation for enhanced visualization, from the size of user selection.
    - Capability to save the current overlay as a PNG image.

    Instructions:
    1. Before running this script, make a selection in Golly to focus on a specific area of the pattern.
    2. Run the script. You will be prompted to decide if a torus should be created from your selection.
    3. Follow the prompts to input your desired colors and other settings.
    4. The script will then automate the evolution of the pattern, applying colors and presenting the option to save the overlay as an image.

    Note: 
    - Ensure that a selection is made in Golly before running this script. 
    - The script operates on the selected area and requires user input for colors and other options.

Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Jan 2024.
]]

local g = golly()
local ov = g.overlay 
-----------------------------------------------------------------------------------------------

local function make_torus()
-----------------------------------------------------------------------------------------------
-- This is the make-torus.lua script from Golly. 
-- Use the current selection to create a toroidal universe.
-- Author: Andrew Trevorrow (andrew@trevorrow.com), Apr 2016.

local g = golly()

local selrect = g.getselrect()
if #selrect == 0 then g.exit("There is no selection.") end

local x, y, wd, ht = table.unpack(selrect)
local selcells = g.getcells(selrect)

if not g.empty() then
    g.clear(0)
    g.clear(1)
end

-- get current rule, remove any existing suffix, then add new suffix
local rule = g.getrule()
rule = rule:match("^(.+):") or rule
g.setrule(string.format("%s:T%d,%d", rule, wd, ht))

local newx = -math.floor(wd/2)
local newy = -math.floor(ht/2)
selrect[1] = newx
selrect[2] = newy
g.select(selrect)
if #selcells > 0 then g.putcells(selcells, newx - x, newy - y) end
g.fitsel()

-----------------------------------------------------------------------------------------------
end -- end of make_torus()

-----------------------------------------------------------------------------------------------

-- Function to ask the user if they require a torus to be created.
local function ask_user_for_torus()
    while true do
        -- Get user response with a prompt.
        local response = g.getstring("Do you require a torus be created from your selection? (Y/N)", "", "Torus Prompt")
        response = response:upper()  -- Convert response to upper case for consistency

        -- Return true for 'Y' (yes) or false for 'N' (no).
        if response == "Y" then
            return true
        elseif response == "N" then
            return false
        else
            -- Notify the user to enter a valid response if neither Y nor N is entered.
            g.note("Please enter 'Y' for Yes or 'N' for No.")
        end
    end
end

-- Execute the make_torus function if the user confirms.
if ask_user_for_torus() then
    make_torus()
end

-----------------------------------------------------------------------------------------------

-- Function to prompt the user for RGB values.
local function get_rgb(prompt)
    local rgb = g.getstring(prompt, "", "RGB Input")
    local r, g, b = string.match(rgb, "(%d+)%s+(%d+)%s+(%d+)")
    return tonumber(r), tonumber(g), tonumber(b)
end

-----------------------------------------------------------------------------------------------

-- Prompt the user to specify the number of colors they wish to use.
local numcolors = tonumber(g.getstring("Input the number of colors you would like to use. ", "8", "Number of Colors"))
if not numcolors or numcolors < 1 then 
    g.exit("Invalid number of colors.") 
end

-----------------------------------------------------------------------------------------------

-- Collect color values from the user and store them in a table.
local colors = {}
for i = 1, numcolors do
    local r, g, b = get_rgb("Enter RGB values for COLOR # " .. i .. " separated by spaces (e.g., '255 0 0' for red):")
    if not r or not g or not b then 
        g.exit("Invalid RGB values for color " .. i .. ".") 
    end
    colors[i] = r .. " " .. g .. " " .. b
end

-----------------------------------------------------------------------------------------------

-- Prompt for the background color and store it.
local prompt_bg = "Enter RGB values for the BACKGROUND COLOR separated by spaces (e.g., '0 0 0' for black):"
local br, bg, bb = get_rgb(prompt_bg)
if not br or not bg or not bb then 
    g.exit("Invalid RGB values for background color.") 
end
local background_color = {r=br, g=bg, b=bb}

-----------------------------------------------------------------------------------------------

-- Retrieve the current selection rectangle from UI.
local selrect = g.getselrect()
if #selrect == 0 then 
    g.exit("There is no selection.")
end
local selx, sely, selwd, selht = table.unpack(selrect)

-- Create an overlay based on the size of the user's selection.
ov("create " .. selwd .. " " .. selht)
ov("position middle")  -- Position the overlay in the middle of the layer.
ov("blend 1") -- Set opaque blending

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

    -- Fill the overlay with the background color defined by the user.
    ov("position middle")
    ov("blend 1")
    ov("rgba "..background_color.r.." "..background_color.g.." "..background_color.b.." 255")
    ov("fill")

    -- Iterate over each cell in the selection and apply colors based on age.
    for i = 1, #cells, 2 do
        local x, y = cells[i], cells[i + 1]

        -- Adjust cell position based on the selection's coordinates.
        x = x - selx
        y = y - sely

        local key = x .. ":" .. y

        -- Apply color to new or existing cells and update their age.
        if not cellAges[key] then
            ov("rgba " .. colors[colorIndex] .. " 255")
            newCellAges[key] = colorIndex
        else
            ov("rgba " .. colors[cellAges[key]] .. " 255")
            newCellAges[key] = cellAges[key]
        end

        ov("set " .. x .. " " .. y)
    end

    -- Update the cell ages and color index for the next iteration.
    cellAges = newCellAges
    colorIndex = nextColorIndex(colorIndex)

    -- Update the overlay and Golly view to reflect changes.
    ov("update")
    g.update()
end

-----------------------------------------------------------------------------------------------

-- Notify the user about the functionality to save the overlay as an image.
g.note("Press 's' at any time to save the overlay as an image (png).")

-- Main event loop to handle user inputs and automate cellular evolution.
while true do

    -- Keep message displaying to remind user of save/abort functionality while running script.
    g.show("Press 's' at any time to save the overlay as an image (png).\n Press 'q' or 'esc' to abort script.")

    local doStep = false
    local savedir = g.getdir("data")

    -- Run user-specified number of generations.
    if rungens > 0 then
        g.step()
        color_step()
        rungens = rungens - 1
        doStep = true

    -- User leaves number of generations input blank.
    --Allow user to advance generation by pressing their space bar.
    else
        local event = g.getevent()
        if event:find("key space") then
            g.step()
            color_step()
            doStep = true

        -- Handle saving the overlay as a PNG file when 's' is pressed.
        elseif event:find("key s") then

            -- Prompt user for filename and location.
            local pngpath = g.savedialog("Save overlay as PNG file", "PNG (*.png)|*.png",
                                         savedir, "overlay.png")
            if #pngpath > 0 then
                -- Save overlay in given file.
                ov("save 0 0 "..selwd.." "..selht.." "..pngpath)
                g.note("Overlay was saved in "..pngpath)

                -- Update the save directory based on user input.
                local pathsep = g.getdir("app"):sub(-1)
                savedir = pngpath:gsub("[^"..pathsep.."]+$","")
            
            end

        -- If user presses 'q' or 'esc' key, abort script.
        elseif event:find("key q") or event:find("key escape") then
            break
        end
    end

    -- Sleep for a short duration to keep the loop responsive and avoid hogging CPU.
    g.sleep(5)
end



