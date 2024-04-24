--[[
    This script assists users in automating the creation of 'initial configurations' on a custom-named Golly grid. These configurations consist of circles and ellipses that represent live and dead cells.

    Steps for the user:
    1. Name the grid: A custom name for the new grid can be entered for identification and reference.
    2. Configuration count and spacing: User specifies the number of configurations and the horizontal center-to-center spacing between them.
    3. Define configurations: For each configuration, the user will:
       - Select a shape (circle or ellipse) for the live cells and provide dimensions (radius for circles, axis lengths for ellipses).
       - Enter a 'Y Setback' value, which determines the vertical offset for the center of dead sites relative to the center of the live sites.
       - Select a shape for the dead sites and provide dimensions, similar to the live sites.

    Purpose:
    This script is designed to streamline the process of generating and testing initial cell arrangements in Golly's environment. 
    It enables users to quickly explore various configurations to discover those that evolve into interesting and potentially stable patterns under the Larger the Life rules, and other rules supported by Golly.

-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2023.

]]
-----------------------------------------------------------------------------------------------

local g = golly() -- Initialize Golly library
-----------------------------------------------------------------------------------------------

-- Prompt user for grid name and clear the grid with the custom name
local grid_name = g.getstring("Enter the desired name for this grid:", "Initial Configurations")
g.new(grid_name)
local grid = g.getlayer()
-----------------------------------------------------------------------------------------------

-- Prompt user for number of configurations to be made and spacing of configurations
local num_configs = tonumber(g.getstring("Enter the number of configurations:", "1"))
local spacing = tonumber(g.getstring("Enter the spacing of the configurations (center to center distance):", "60"))
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

-- Function to handle drawing based on user input
local function handle_shape(config_num, x, y, state, cell_type)
    local prompt_message = "Config. #" .. config_num .. ": Would you like a Circle or Ellipse for the " .. cell_type .. " sites? Enter 'C' or 'E'. :"

    local shape_type = g.getstring(prompt_message, "C")
    shape_type = shape_type:upper() -- Turn all user input letters into captial case

    local size
    if shape_type == "C" then -- Handle Circle
        local radius_prompt = "Config. #" .. config_num .. ": Enter the radius for the " .. cell_type .. " circle:"
        local radius = tonumber(g.getstring(radius_prompt, "20"))
        if radius then -- Check if radius is not nil
            drawFilledCircle(x, y, radius, state)
            size = radius
        end
    elseif shape_type == "E" then -- Handle Ellipse
        local major_axis_prompt = "Config. #" .. config_num .. ": Enter the major axis length for the " .. cell_type .. " ellipse:"
        local minor_axis_prompt = "Config. #" .. config_num .. ": Enter the minor axis length for the " .. cell_type .. " ellipse:"
        local major = tonumber(g.getstring(major_axis_prompt, "25"))
        local minor = tonumber(g.getstring(minor_axis_prompt, "20"))
        if major and minor then -- Check if major and minor are not nil
            drawFilledEllipse(x, y, major, minor, state)
            size = major
        end
    else -- If invalid character entered, circle will be used by default.
        g.warn("Invalid shape type. Circle will be used.")
        local radius = tonumber(g.getstring("Enter the radius for the " .. cell_type .. " circle:", "20"))
        if radius then -- Check if radius is not nil
            drawFilledCircle(x, y, radius, state)
            size = radius
        end
    end
    return size or 0 -- Return 0 if size is nil 
end
-----------------------------------------------------------------------------------------------

-- Loop through each configuration with spacing
local current_x = 0
for i = 1, num_configs do
    -- Live sites
    local live_offset = handle_shape(i, current_x, 0, 1, "live")
    
    -- Dead sites
    local dead_setback_x =  0 -- Prompt for X setback is omitted because it's not currently used for specific configs.
    local dead_setback_y_prompt = "Config. #" .. i .. ": Enter the Y setback for dead sites:"
    local dead_setback_y =  tonumber(g.getstring(dead_setback_y_prompt, "5"))
    handle_shape(i, current_x + dead_setback_x, dead_setback_y, 0, "dead")
    
    -- Update position for next configuration
    current_x = current_x + spacing
end
-----------------------------------------------------------------------------------------------

g.show("Configurations have been successfully placed on the grid.")
g.update()
