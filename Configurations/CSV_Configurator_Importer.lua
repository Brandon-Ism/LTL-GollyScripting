--[[
    This script automates the creation of 'initial configurations' on a custom-named Golly grid, based on data from a CSV file. These configurations comprise circles, ellipses, and rectangles representing live and dead cells.

    Steps for the user:
    1. Name the grid: A custom name for the new grid can be entered for identification and reference.
    2. Configuration count and spacing: The user specifies the desired number of configurations they have entered into the CSV file and the horizontal center-to-center spacing between them.
    3. CSV Input: Instead of manual entry, the script reads configuration details from a CSV file, with each line defining one configuration in the following format:
        - Shape of live cells ('C' for Circle, 'E' for Ellipse, 'R' for Rectangle)
        - Radius for circles, axis lengths for ellipses, or dimensions for rectangles of live cells
        - 'Y Setback' indicating the vertical displacement for the center of the dead cells from the live ones
        - Shape of dead cells ('C' for Circle, 'E' for Ellipse, 'R' for Rectangle)
        - Radius for circles, axis lengths for ellipses, or dimensions for rectangles of dead cells

        The first row of the CSV is assumed to be the header and is ignored.

    CSV File Format Example:
        [shape of live cells] , [radius or axis lengths or dimensions of live shape] , [y setback] , [shape of dead cells] , [radius or axis lengths or dimensions of dead shape]
        example entry: C,23,6,E,9 7 = Circle of live cells with radius 23, y setback of 6, with ellipse of dead cells with major axis = 9, and minor axis = 7.
        

    Purpose:
    This script is designed to streamline the process of generating and testing initial cell arrangements in Golly's environment. 
    By reading configuration data from a CSV file, the script allows for quick adjustments and batch processing of multiple configurations.
    This script enables users to quickly explore various configurations to discover those that evolve into interesting and potentially stable patterns under the Larger the Life rules, and other rules supported by Golly.

    NOTE:
    The user should modify the 'filepath' variable within the script to point to the location of their CSV file before running the script.

-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2023.

]]
-----------------------------------------------------------------------------------------------

local g = golly() -- Initialize Golly library

local filepath = '/dir/.../myfile.csv'
-----------------------------------------------------------------------------------------------

-- Prompt user for grid name and clear the grid with the custom name
local grid_name = g.getstring("Enter the desired name for this grid:", "Initial Configurations")
g.new(grid_name)
local grid = g.getlayer()
-----------------------------------------------------------------------------------------------

-- Prompt user for number of configurations to be made and spacing of configurations
local num_configs = tonumber(g.getstring("Enter the number of configurations:", "50"))
local spacing = tonumber(g.getstring("Enter the spacing of the configurations (center to center distance):", "100"))
local configs_per_row = tonumber(g.getstring("How many configurations per row?", "10"))
-----------------------------------------------------------------------------------------------

-- Function to draw filled circle
local function drawFilledCircle(cx, cy, r, state)
    -- Function to fill cells (live) in quadrants 1-4
    local function fillQuadrants(x, y)
        for dy = 0, y do
            g.setcell(cx + x, cy + dy, state)
            g.setcell(cx - x, cy + dy, state)
            g.setcell(cx + x, cy - dy, state)
            g.setcell(cx - x, cy - dy, state)
        end
        for dx = 0, x do
            g.setcell(cx + dx, cy + y, state)
            g.setcell(cx - dx, cy + y, state)
            g.setcell(cx + dx, cy - y, state)
            g.setcell(cx - dx, cy - y, state)
        end
    end

    local x, y, d = r, 0, 1 - r
    fillQuadrants(r, 0)
    fillQuadrants(0, r)

    while x > y do
        y = y + 1
        if d <= 0 then
            d = d + 2 * y + 1
        else
            x = x - 1
            d = d + 2 * y - 2 * x + 1
        end
        if x < y then break end
        fillQuadrants(x, y)
        fillQuadrants(y, x)
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to draw filled ellipse given center (cx,cy), major axis a, and minor axis b
local function drawFilledEllipse(cx, cy, a, b, state)
    local dx, dy, d1, d2, x, y
    x = 0
    y = b

    -- Initial decision parameter of region 1
    d1 = (b * b) - (a * a * b) + (0.25 * a * a)
    dx = 2 * b * b * x
    dy = 2 * a * a * y

    -- For region 1
    while dx < dy do
        -- Print points based on 4-way symmetry
        for i = -x, x do
            g.setcell(cx + i, cy + y, state)
            g.setcell(cx + i, cy - y, state)
        end

        -- Checking and updating value of decision parameter 
        if d1 < 0 then
            x = x + 1
            dx = dx + (2 * b * b)
            d1 = d1 + dx + (b * b)
        else
            x = x + 1
            y = y - 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d1 = d1 + dx - dy + (b * b)
        end
    end
    -- Decision parameter of region 2
    d2 = ((b * b) * ((x + 0.5) * (x + 0.5))) + ((a * a) * ((y - 1) * (y - 1))) - (a * a * b * b)

     -- Plotting points of region 2
    while y >= 0 do
        for i = -x, x do
            g.setcell(cx + i, cy + y, state)
            g.setcell(cx + i, cy - y, state)
        end
        if d2 > 0 then
            y = y - 1
            dy = dy - (2 * a * a)
            d2 = d2 + (a * a) - dy
        else
            y = y - 1
            x = x + 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d2 = d2 + dx - dy + (a * a)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to draw filled rectangle given center (cx, cy), length l, and width w
local function drawFilledRectangle(cx, cy, l, w, state)
    for dx = -math.floor(l / 2), math.ceil(l / 2) - 1 do
        for dy = -math.floor(w / 2), math.ceil(w / 2) - 1 do
            g.setcell(cx + dx, cy + dy, state)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to split csv name string by a delimiter
local function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
-----------------------------------------------------------------------------------------------

-- Function to handle drawing based on configuration in CSV file
local function handle_shape(config, x, y, state)
    local shape_live = config[1]
    local size_live = config[2]
    local y_setback = tonumber(config[3])
    local shape_dead = config[4]
    local size_dead = config[5]

    if y_setback == nil then
        g.warn("Invalid y_setback value in configuration. Please ensure proper header in CSV file... " .. table.concat(config, ", "))
        return
    end

    -- Draw the live shape
    if shape_live:upper() == "C" then -- Handle Circle
        drawFilledCircle(x, y, tonumber(size_live), state)
    elseif shape_live:upper() == "E" then -- Handle Ellipse
        local sizes = split_string(size_live, " ")
        drawFilledEllipse(x, y, tonumber(sizes[1]), tonumber(sizes[2]), state)
    elseif shape_live:upper() == "R" then -- Handle Rectangle
        local sizes = split_string(size_live, " ")
        drawFilledRectangle(x, y, tonumber(sizes[1]), tonumber(sizes[2]), state)
    end

    -- Draw the dead shape
    local dead_y = y + y_setback
    if shape_dead:upper() == "C" then -- Circle
        drawFilledCircle(x, dead_y, tonumber(size_dead), 0)
    elseif shape_dead:upper() == "E" then -- Ellipse
        local sizes = split_string(size_dead, " ") -- Split major and minor axis by identifying blank space
        drawFilledEllipse(x, dead_y, tonumber(sizes[1]), tonumber(sizes[2]), 0)
    elseif shape_dead:upper() == "R" then -- Rectangle
        local sizes = split_string(size_dead, " ")
        drawFilledRectangle(x, dead_y, tonumber(sizes[1]), tonumber(sizes[2]), 0)
    end
end
-----------------------------------------------------------------------------------------------

-- Read configurations from a CSV file
local file = io.open(filepath, "r")
if not file then
    g.warn("Could not open file: " .. filepath)
    return
end

-- Skip the header line
file:read()
-----------------------------------------------------------------------------------------------

-- Loop through each configuration line in the CSV file
local current_x, current_y = 0, 0
local config_count = 0
for line in file:lines() do
    local config = split_string(line, ",")
    if #config >= 5 then
        -- Draw the live shape
        handle_shape(config, current_x, current_y, 1)
        
        -- Update position for next configuration
        config_count = config_count + 1
        if config_count % configs_per_row == 0 then
            current_x = 0
            current_y = current_y + spacing
        else
            current_x = current_x + spacing
        end

        -- Stop if script has created the user-specified number of configurations
        if config_count >= num_configs then break end
    else
        g.warn("Invalid configuration format in CSV line: " .. line)
        break
    end
end

file:close() -- Close CSV file reading within script.

g.note("Configurations have been successfully placed on the grid.")
g.update()
