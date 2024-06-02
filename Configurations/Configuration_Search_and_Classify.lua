--[[

    This script automates the creation, simulation, and sorting of 'initial configurations' on a custom-named Golly grid based on user inputs. 
    Users specify live and dead cell shapes as circles or ellipses, along with their dimensions. 
    Each configuration is analyzed for survival and categorized based on its behavior over a user-specified number of time steps. 
    The script handles configurations that exceed a user-defined maximum number of iterations by logging them separately.

    Usage Steps:
    1. Name the grid and CSV files: 
        - Enter a custom name for the new grid and CSV file prefixes for reference.
    2. Set Simulation Parameters:
        - Time steps: Specify the number of time steps to simulate each configuration, before classifying the pattern.
        - Rule: Enter the desired rule for the simulation, or leave rule as is or blank.
        - Maximum timeout iterations: Set a limit on the number of iterations for pattern to be classified as timeout, if no other classification occurs.
    3. Define Shapes and Dimensions of Live Sites:
        - Shape of Live Sites: 'C' for Circle or 'E' for Ellipse.
        - Dimensions: If a circle, provide the radius. If an ellipse, provide major and minor axis lengths.
    4. Setbacks:
        - Setbacks: Define the vertical shift (Y-axis displacement) for dead sites relative to the center of live sites, as bounds (min, max).
    5. Define Shapes and Dimensions of Dead Sites:
        - Shape of Dead Sites: 'C' for Circle or 'E' for Ellipse.
        - Dimensions: If a circle, provide the radius. If an ellipse, provide major and minor axis lengths.

    Purpose:
    - This script streamlines the process of generating, simulating, and analyzing initial cell configurations in Golly.
    - It helps users quickly explore various configurations to discover those that evolve into interesting and potentially stable patterns under different cellular automata rules.

    CSV Output:
    - The script logs each configuration into multiple CSV files, documenting the shape and size of live and dead sites, setbacks, and their arrangement on the grid.
        - 'filename_all.csv'
            - Contains parameters of every initial configuration that was created.
        - 'filename_survive.csv'
            - Contains parameters of initial configurations that were detected as 'stable' after being run, the user-defined number of time steps.
            - Contains period, vertical displacement, population, and dimensions of the minimal bounding box of the pattern.
        - 'filename_not_survive.csv'
            - Contains parameters of every intital configuration that resulted in zero live cells on the grid, after being run, the user-defined number of time steps.
        - 'filename_still.csv'
            - Contains parameters of every initial configuration that resulted in a patternn that was detected as 'stable', with no vertical displacement, after being run, the user-defined number of time steps.
        - 'filename_timeout.csv'
            - Contains parameters of every inital configuration that could not be detected as 'stable' or dead, after attemping to be classified after being run, the user-defined number of time steps for a runtime error. 

    File Format:
    - Shape of Live Cells, Radius or Axis Lengths of Live Shape, Y Setback, Shape of Dead Cells, Radius or Axis Lengths of Dead Shape
    - Example entry: E,25 20,7,C,10 (Ellipse of live cells with major axis = 25, minor axis = 20, Y setback of 7, with Circle of dead cells with radius = 10).

    -- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2023.
]]


local g = golly() -- Initialize Golly library.
local gp = require "gplus" -- Import gplus module.

-----------------------------------------------------------------------------------------------
-- Handle initial user parameters for CSV naming, time steps, rule, and timeout limit. 

-- User enters CSV filename prefixes. 
local grid_name = g.getstring("Enter the desired name convention for CSV files:", "InitialConfigurations")
g.new(grid_name) -- Create a new grid with desired name.

-- User enters number of time steps for each pattern to be run before determining survival.
local time_steps = tonumber(g.getstring("Enter the number of time steps to simulate before categorizing pattern:", "30"))

-- Get the current rule of the grid.
local current_rule = g.getrule()

-- User decides if they want to change the rule of the current grid, displaying the current rule by default.
local new_rule = g.getstring("Would you like to change the rule of the current grid? If yes, please enter new rule. \nIf not, leave blank, or leave current rule:", current_rule)

-- Check if the user enters new rule, set new rule.
if new_rule ~= "" and new_rule ~= current_rule then
    g.setrule(new_rule) -- Set the new rule for the grid.
end

-- Ask user for maximum number of iterations until speed search is determined inconclusive.
local max_iterations_input = g.getstring("In case of runtime error, enter the maximum number of iterations for pattern search:", "10000")
local max_iterations = tonumber(max_iterations_input)

if max_iterations == nil or max_iterations <= 0 then
    g.warn("Invalid input for maximum iterations. Using default value of 10000.")
    max_iterations = 10000
end

local spacing = 0
local configs_per_row = 1 
-----------------------------------------------------------------------------------------------

-- User parameters for live sites.
local shape_live
local range_radius_live = ""
local range_axes_live = ""
local range_rect_live = ""
local valid_input0 = false

-- Determine live cell configuration based on shape input.
while not valid_input0 do
    shape_live = g.getstring("Would you like a circle, ellipse, or rectangle for the live sites (enter C, E, or R):", "E"):upper()

    if shape_live == "C" then
        range_radius_live = g.getstring("Enter the bounds of radii for the live circle as min,max (e.g., 20,25):", "20,25")
        valid_input0 = true
    elseif shape_live == "E" then
        range_axes_live = g.getstring("Enter the bounds of major/minor axes for the live ellipse, major_range,minor_range (e.g., 20,25 20,25):", "20,25 20,25")
        valid_input0 = true
    elseif shape_live == "R" then
        range_rect_live = g.getstring("Enter the bounds of length/width for the live rectangle, length_range,width_range (e.g., 20,25 10,15):", "20,25 10,15")
        valid_input0 = true
    else
        g.warn("Invalid shape input. Please enter 'C' for circle, 'E' for ellipse, or 'R' for rectangle.")
    end
end
-----------------------------------------------------------------------------------------------

-- User parameters for bound of Y setbacks. 
local range_setback = g.getstring("Enter the bounds of Y setbacks as min,max (e.g., 5,15):", "5,15")
-----------------------------------------------------------------------------------------------

-- User parameters for dead sites. 
local shape_dead
local range_radius_dead = ""
local range_axes_dead = ""
local range_rect_dead = ""
local valid_input1 = false

-- Determine dead cell configuration based on shape input.
while not valid_input1 do
    shape_dead = g.getstring("Would you like a circle, ellipse, or rectangle for the dead sites (enter C, E, or R):", "C"):upper()

    if shape_dead == "C" then
        range_radius_dead = g.getstring("Enter the bounds of radii for the dead circle as min,max (e.g., 5,10):", "5,10")
        valid_input1 = true
    elseif shape_dead == "E" then
        range_axes_dead = g.getstring("Enter the bounds of major/minor axes for the dead ellipse, major_bounds,minor_bounds (e.g., 5,20 5,20):", "5,20 5,20")
        valid_input1 = true
    elseif shape_dead == "R" then
        range_rect_dead = g.getstring("Enter the bounds of length/width for the dead rectangle, length_bounds,width_bounds (e.g., 10,15 5,10):", "10,15 5,10")
        valid_input1 = true
    else
        g.warn("Invalid shape input. Please enter 'C' for circle, 'E' for ellipse, or 'R' for rectangle.")
    end
end 
-----------------------------------------------------------------------------------------------

-- Process user inputs as valid Lua variables. 

-- Function to split strings based on a delimiter
local function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"  -- Use space as default separator 
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end


-- Parse ranges from input, into Lua variables
local function parse_range(input)
    local min_val, max_val = input:match("(%d+),(%d+)")
    min_val, max_val = tonumber(min_val), tonumber(max_val)
    if not min_val or not max_val or min_val > max_val then
        g.warn("Invalid range. Please enter a valid range (e.g., 5,15).")
    end
    return min_val, max_val
end


local radius_live_min, radius_live_max = 0,0
local axes_live_min, axes_live_max = {}, {}
local rect_live_min, rect_live_max = {}, {}
local setback_min, setback_max = parse_range(range_setback)
local radius_dead_min, radius_dead_max = 0, 0
local axes_dead_min, axes_dead_max = {}, {}
local rect_dead_min, rect_dead_max = {}, {}

if shape_live == "C" then
    radius_live_min, radius_live_max = parse_range(range_radius_live)
elseif shape_live == "E" then
    local j = 1
    for axis_range0 in range_axes_live:gmatch("(%d+,%d+)") do
        local min_ax0, max_ax0 = parse_range(axis_range0)
        axes_live_min[j], axes_live_max[j] = min_ax0, max_ax0 
        j = j + 1
    end
elseif shape_live == "R" then
    local parts = split_string(range_rect_live, " ")
    rect_live_min[1], rect_live_max[1] = parse_range(parts[1])
    rect_live_min[2], rect_live_max[2] = parse_range(parts[2])
end


if shape_dead == "C" then
    radius_dead_min, radius_dead_max = parse_range(range_radius_dead)
elseif shape_dead == "E" then
    local i = 1
    for axis_range in range_axes_dead:gmatch("(%d+,%d+)") do
        local min_ax, max_ax = parse_range(axis_range)
        axes_dead_min[i], axes_dead_max[i] = min_ax, max_ax
        i = i + 1
    end
elseif shape_dead == "R" then
    local parts = split_string(range_rect_dead, " ")
    rect_dead_min[1], rect_dead_max[1] = parse_range(parts[1])
    rect_dead_min[2], rect_dead_max[2] = parse_range(parts[2])
end

-----------------------------------------------------------------------------------------------
-- Initialize all CSV files. 
local filepath_all = g.getdir("app") .. grid_name .. "_all.csv"
local file_all = io.open(filepath_all, "w")
local filepath_survive = g.getdir("app") .. grid_name .. "_survive.csv"
local file_survive = io.open(filepath_survive, "w")
local filepath_not_survive = g.getdir("app") .. grid_name .. "_not_survive.csv"
local file_not_survive = io.open(filepath_not_survive, "w")
local filepath_still = g.getdir("app") .. grid_name .. "_still.csv"
local file_still = io.open(filepath_still, "w")
local filepath_timeout = g.getdir("app") .. grid_name .. "_timeout.csv"
local file_timeout = io.open(filepath_timeout, "w")

-- Write headers to CSV files. 
file_all:write('"' .. g.getrule() .. '"',"\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape\n")
file_survive:write('"' .. g.getrule() .. '"',"\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape,Period,dy,Population, Bound Box Wd, Bound Box Ht, Hash Value\n")
file_not_survive:write('"' .. g.getrule() .. '"',"\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape\n")
file_still:write('"' .. g.getrule() .. '"',"\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape,Period,dy,Hash Value\n")
file_timeout: write('"' .. g.getrule() .. '"', "\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape\n")
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

-- Function to check survival of configurations after user entered time steps.
local function check_survival()
    return tonumber( g.getpop() ) > 0  -- Returns true if any cells are alive
end
-----------------------------------------------------------------------------------------------

--This function is adapted from oscar.lua-[Author: Andrew Trevorrow (andrew@trevorrow.com), Mar 2016.]
-- Function to determine speed and period directly from the pattern's behavior
local function get_speed_and_period(max_iterations)
    local hashlist = {}
    local genlist = {}
    local poplist = {}
    local boxlist = {}
    local iterations = 0 -- Counter   
    local r = g.getrule()
    r = string.match(r, "^(.+):") or r
    local hasB0notS8 = r:find("B0") == 1 and r:find("/") > 1 and r:sub(-1) ~= "8"

    local function oscillating()

        -- Runtime error check, returns nil if time steps of search for speed and period is longer than user entered 'max_iterations'. 
        iterations = iterations + 1  -- Update the iteration counter each time the function is called
        if iterations > max_iterations then
            return nil, nil, nil, nil  -- Indicate the process took too long
        end

        local pbox = g.getrect()
        if #pbox == 0 then return true, 0, 0, 0 end  -- pattern is empty
        
        local h = g.hash(pbox)
        local pos = 1
        while pos <= #hashlist do

            iterations = iterations + 1  -- Increment counter at each comparison
            if iterations > max_iterations then
                return nil, nil, nil, nil  -- Exit if the iteration limit is exceeded
            end

            if h == hashlist[pos] then
                local rect = boxlist[pos]
                local period = tonumber(g.getgen()) - genlist[pos]
                local deltax = rect[1] - pbox[1]
                local deltay = rect[2] - pbox[2]
                return true, period, deltax, deltay
            elseif h < hashlist[pos] then
                break
            end
            pos = pos + 1
        end

        table.insert(hashlist, pos, h)
        table.insert(genlist, pos, tonumber(g.getgen()))
        table.insert(poplist, pos, tonumber(g.getpop()))
        table.insert(boxlist, pos, pbox)

        return false, 0, 0, 0
    end


    while true do
        local osc, period, dx, dy = oscillating()
        if osc == nil then return nil end
        if osc then return period, dx, dy end
        g.run(1)
    end
end
-----------------------------------------------------------------------------------------------

-- Function to return the height and width of a minimal bounding box of pattern.
local function get_bounding_box(cells, dim)
    local min_box = gp.getminbox(cells)
    if dim == "ht" then
        return min_box.ht
    else
        return min_box.wd
    end
end
-----------------------------------------------------------------------------------------------

-- Generate and place configurations.

local current_x, current_y, count = 0, 0, 0

-- Iterate through combinations of user entered dimension bounds.

for radius_live = radius_live_min, radius_live_max do
    for major0 = (axes_live_min[1] or 0), (axes_live_max[1] or 0) do
        for minor0 = (axes_live_min[2] or 0), (axes_live_max[2] or 0) do
            for length0 = (rect_live_min[1] or 0), (rect_live_max[1] or 0) do
                for width0 = (rect_live_min[2] or 0), (rect_live_max[2] or 0) do
                    for setback = setback_min, setback_max do
                        for radius_dead = radius_dead_min, radius_dead_max do
                            for major = (axes_dead_min[1] or 0), (axes_dead_max[1] or 0) do
                                for minor = (axes_dead_min[2] or 0), (axes_dead_max[2] or 0) do
                                    for length = (rect_dead_min[1] or 0), (rect_dead_max[1] or 0) do
                                        for width = (rect_dead_min[2] or 0), (rect_dead_max[2] or 0) do

                                            local live_shape_size, dead_shape_size

                                            -- Circle live sites.  
                                            if shape_live == "C" then
                                                live_shape_size = tostring(radius_live)
                                                drawFilledCircle(current_x, current_y, radius_live, 1)
                                            elseif shape_live == "E" then
                                                live_shape_size = major0 .. " " .. minor0
                                                drawFilledEllipse(current_x, current_y, major0, minor0, 1)
                                            elseif shape_live == "R" then
                                                live_shape_size = length0 .. " " .. width0
                                                drawFilledRectangle(current_x, current_y, length0, width0, 1)
                                            end

                                            -- Dead sites. 
                                            if shape_dead == 'C' then
                                                dead_shape_size = tostring(radius_dead)
                                                drawFilledCircle(current_x, current_y + setback, radius_dead, 0)
                                            elseif shape_dead == "E" then
                                                dead_shape_size = major .. " " .. minor
                                                drawFilledEllipse(current_x, current_y + setback, major, minor, 0)
                                            elseif shape_dead == "R" then
                                                dead_shape_size = length .. " " .. width
                                                drawFilledRectangle(current_x, current_y + setback, length, width, 0)
                                            end

                                            -- Write to CSV, all configurations to be simulated.
                                            file_all:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, "\n")

                                            -- Run each pattern simulation for the specified number of steps
                                            g.run(time_steps)

                                            -- If configuration 'survives' after time steps run, get speed and period. 
                                            if check_survival() then 
                                                local period, dx, dy = get_speed_and_period(max_iterations)

                                                -- Runtime error, greater than max_iterations. 
                                                if period == nil then
                                                    -- Write initial configuration data to '_timeout' CSV file for user reference.
                                                    file_timeout:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, "\n")

                                                else
                                                    -- Speed and period were successfully determined
                                                    local pop = tonumber( g.getpop() ) -- Get current cell population.

                                                    -- Get dimensions of minimal bounding box. 
                                                    local bound_box_wd = get_bounding_box(g.getcells( g.getrect()), "wd")
                                                    local bound_box_ht = get_bounding_box(g.getcells( g.getrect()), "ht")
                                                    local hash_val = g.hash(g.getrect())

                                                    if dy == 0 then -- Pattern determined to be still, has no vertical displacement over time, write to '_still' CSV file. 
                                                        file_still:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, ",", period, ",", dy, ",", hash_val, "\n")

                                                    else
                                                        -- Pattern has survived, and has a period with vertical displacement, successful search for potential spaceship or bug. 
                                                        file_survive:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, ",", period, ",", -dy, ",", pop,",", bound_box_wd, ",", bound_box_ht, ",", hash_val, "\n")
                                                    end
                                                end
                                            else
                                                -- Initial configuration has not survived after timesteps run. 
                                                file_not_survive:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, "\n")
                                            end

                                            -- Clear the grid and update positions for the next configuration
                                            g.new(grid_name)
                                            current_x = current_x + spacing
                                            count = count + 1
                                            if count % configs_per_row == 0 then
                                                current_x = 0
                                                current_y = current_y + spacing
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Close all CSV files
file_all:close()
file_survive:close()
file_not_survive:close()
file_still:close()
file_timeout:close()
-----------------------------------------------------------------------------------------------

-- Notify user of completion.
g.note("Configuration simulation complete. Data has been written to CSV files.")
g.update()
