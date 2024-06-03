--[[
    This script automates the creation of 'initial configurations' on a custom-named Golly grid based on user inputs, specifying live and dead cell shapes as circles or ellipses. 
    Each configuration can be precisely placed according to the provided spacing and alignment rules.
    Each configuration is a unique combination made from the user-specified ranges of dimensions.

    Usage Steps:
    1. Name the grid: A custom name for the new grid can be entered for identification and reference.
    2. Shape and Dimensions: Users define whether the live and dead sites on the grid will be circles or ellipses and provide the respective dimensions:
        - If a circle, a radius is required.
        - If an ellipse, major and minor axis lengths are needed.
        - If a rectangle, length and widths are needed. 
    3. Setbacks and Spacing: The user specifies the vertical setback (Y-axis displacement between live and dead cells) and the horizontal spacing between consecutive configurations (center-to-center distance).
    4. Configuration Rows: Users can determine how many configurations should be placed per row on the grid.

    Input Details:
    - Shape of Live Sites: 'C' for Circle, 'E' for Ellipse, or 'R' for Rectangle. Dimensions for circles or ellipses are prompted based on this choice.
    - Setbacks: Defined as a range (min,max), determining the vertical shift for dead sites relative to live ones.
    - Shape of Dead Sites: Similarly, 'C' for Circle, 'E' for Ellipse, or 'R' for Rectangle, with dimensions prompted accordingly.
    - Configurations Per Row: Specifies how many configurations to place per row before moving to a new row, enhancing the visual organization on the grid.

    Example Interaction:
    - Enter grid name: "My Experimental Setup 1, Live Ellipse 25,20"
    - Choose shape for live sites: E (Ellipse)
    - Enter dimensions for ellipse: "25,20" (Major, Minor)
    - Setbacks: "5,15" (from 5 to 15 units)
    - Choose shape for dead sites: C (Circle)
    - Enter radius for dead circle: "10"
    - Configurations per row: "20"

    Purpose:
    - This script is designed to streamline the process of generating and testing initial cell arrangements in Golly's environment. 
    - This script enables users to quickly explore various configurations to discover those that evolve into interesting and potentially stable patterns under the Larger the Life rules, and other rules supported by Golly.
   
    NOTE:
    - Before running the script, ensure that all prompts are answered correctly as they define the grid setup. Incorrect inputs may lead to unexpected behavior or errors.
    - Users should adjust the input dimensions and spacing according to the specific requirements of their cellular automata rules or experiments.

    CSV Output:
    - The script also logs each configuration into a CSV file, documenting the shape and size of live and dead sites, the setbacks, and their arrangement on the grid.

    File Format:
    - Shape of Live Cells,Radius or Axis Lengths of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths of Dead Shape
    - Example entry: E,25 20,7,C,10 (Ellipse of live cells with major axis = 25, minor axis = 20, Y setback of 7, with Circle of dead cells with radius = 10).

-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2023.

]]
-----------------------------------------------------------------------------------------------

local g = golly() -- Initialize Golly library.

-- Ask user for grid name.
local grid_name = g.getstring("Enter the desired name for this grid and CSV file:", "Initial Configurations")
g.new(grid_name) -- Create a new grid with desired name.

-- Get the current rule of the grid.
local current_rule = g.getrule()
-----------------------------------------------------------------------------------------------

-- Assign user parameters as script variables.
local spacing = tonumber(g.getstring("Enter the spacing of the configurations (center to center distance):", "100"))
local shape_live = g.getstring("Would you like a circle, ellipse, or rectangle for the live sites (enter C, E, or R):", "E"):upper()
local dim_live = g.getstring("Enter the dimensions for the live shape (e.g., radius for circle, major,minor for ellipse, or length,width for rectangle):", "25,20")
local range_setback = g.getstring("Enter the bounds of setbacks as min,max (e.g., 5,15):", "5,15")
local shape_dead = g.getstring("Would you like a circle, ellipse, or rectangle for the dead sites (enter C, E, or R):", "C"):upper()
local range_radius_dead = ""
local range_axes_dead = ""
local range_rect_dead = ""
-- If user chooses Circle, prompt for radius.
-- If user chooses Ellipse, prompt for major/minor axes.
-- If user chooses Rectangle, prompt for length and width.
if shape_dead == "C" then
    range_radius_dead = g.getstring("Enter the bounds of radii for the dead circle as min,max (e.g., 5,10):", "5,10")
elseif shape_dead == "E" then
    range_axes_dead = g.getstring("Enter the bounds of major/minor axes for the dead ellipse, major_bounds,minor_bounds (e.g., 5,20 5,20):", "5,20 5,20")
elseif shape_dead == "R" then
    range_rect_dead = g.getstring("Enter the bounds of length/width for the dead rectangle, length_bounds,width_bounds (e.g., 10,15 5,10):", "10,15 5,10")
else
    g.warn("Invalid shape input. Please enter 'C' for circle, 'E' for ellipse, or 'R' for rectangle.")
end
local configs_per_row = tonumber(g.getstring("Enter the number of configurations placed per row:", "20"))
-----------------------------------------------------------------------------------------------

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
-----------------------------------------------------------------------------------------------

-- Parse ranges from input, into Lua variables
local function parse_range(input)
    local min_val, max_val = input:match("(%d+),(%d+)")
    min_val, max_val = tonumber(min_val), tonumber(max_val)
    if not min_val or not max_val or min_val > max_val then
        g.warn("Invalid range. Please enter a valid range (e.g., 5,15).")
    end
    return min_val, max_val
end
-----------------------------------------------------------------------------------------------
-- Assign range values by parsing user input. 
local setback_min, setback_max = parse_range(range_setback)
local radius_dead_min, radius_dead_max = 0, 0
local axes_dead_min, axes_dead_max = {}, {}
local rect_dead_min, rect_dead_max = {}, {}
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

-- CSV file setup
local filepath = g.getdir("app") .. grid_name .. ".csv" -- Save as user provided grid name, to the directory in which Golly is in.
local file = io.open(filepath, "w")
-- Format of CSV file
file:write('"' .. g.getrule() .. '"',"\nShape of Live Cells,Radius or Axis Lengths or Dimensions of Live Shape,Y Setback,Shape of Dead Cells,Radius or Axis Lengths or Dimensions of Dead Shape\n")
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

-- Generate and place configurations
local current_x, current_y, count = 0, 0, 0

for setback = setback_min, setback_max do -- Iterate through setback range.
    for radius_dead = radius_dead_min, radius_dead_max do -- Iterate through radii range.
        for major = (axes_dead_min[1] or 0), (axes_dead_max[1] or 0) do -- Iterate through major axes range.
            for minor = (axes_dead_min[2] or 0), (axes_dead_max[2] or 0) do -- Iterate through minor axes range.
                for length = (rect_dead_min[1] or 0), (rect_dead_max[1] or 0) do -- Iterate through length range.
                    for width = (rect_dead_min[2] or 0), (rect_dead_max[2] or 0) do -- Iterate through width range.

                        local live_shape_size, dead_shape_size

                        if shape_live == "C" then -- Live shape is a circle.
                            live_shape_size = tostring(dim_live)
                            drawFilledCircle(current_x, current_y, tonumber(dim_live), 1)
                        elseif shape_live == "E" then -- Live shape is an ellipse.
                            local live_dims = split_string(dim_live, ",")
                            live_shape_size = table.concat(live_dims, " ")  -- Concatenate major and minor dimensions with a space
                            drawFilledEllipse(current_x, current_y, tonumber(live_dims[0]), tonumber(live_dims[1]), 1)
                        elseif shape_live == "R" then -- Live shape is a rectangle.
                            local live_dims = split_string(dim_live, ",")
                            live_shape_size = table.concat(live_dims, " ")  -- Concatenate length and width with a space
                            drawFilledRectangle(current_x, current_y, tonumber(live_dims[1]), tonumber(live_dims[2]), 1)
                        end

                        if shape_dead == 'C' then
                            dead_shape_size = tostring(radius_dead)
                            drawFilledCircle(current_x, current_y + setback, radius_dead, 0)
                        elseif shape_dead == "E" then -- Dead shape is an ellipse.
                            dead_shape_size = major .. " " .. minor
                            drawFilledEllipse(current_x, current_y + setback, major, minor, 0)
                        elseif shape_dead == "R" then -- Dead shape is a rectangle.
                            dead_shape_size = length .. " " .. width
                            drawFilledRectangle(current_x, current_y + setback, length, width, 0)
                        end

                        -- Write to CSV, ensuring dimensions are in a single cell
                        file:write(shape_live, ",", live_shape_size, ",", setback, ",", shape_dead, ",", dead_shape_size, "\n")

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
-----------------------------------------------------------------------------------------------

file:close() -- Writing to CSV file complete.
-----------------------------------------------------------------------------------------------

-- Notify user of completion.
g.note("Configurations have been successfully placed on the grid.")
g.update()