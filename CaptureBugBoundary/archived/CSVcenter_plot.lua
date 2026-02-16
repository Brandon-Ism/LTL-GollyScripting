-- Plots x,y coordinates from desried CSV file, onto Golly grid, calulating the centroid and centering them about (0,0).
    -- CSV filepath must be written to script (using forward slashes only */* )
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Dec 2023.

local g = golly() -- Initialize Golly library.


-- Filepath for the CSV file containing coordinates to be written in this line.
    -- Filepath must be contained in single quote characters.
local file_path = 'your_filepath/../../boundary_points.csv'
-----------------------------------------------------------------------------------------------

-- Function to split x,y coordinates from CSV format.
local function split(str, delimiter)
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
-----------------------------------------------------------------------------------------------

-- Function to calculate the centroid of the coordinates.
local function calculate_centroid(coords)
    local min_x, max_x = coords[1][1], coords[1][1]
    local min_y, max_y = coords[1][2], coords[1][2]

    for _, coord in ipairs(coords) do
        local x, y = coord[1], coord[2]
        min_x = math.min(min_x, x)
        max_x = math.max(max_x, x)
        min_y = math.min(min_y, y)
        max_y = math.max(max_y, y)
    end

    local centroid_x = math.floor((min_x + max_x) / 2)
    local centroid_y = math.floor((min_y + max_y) / 2)
    return centroid_x, centroid_y
end
-----------------------------------------------------------------------------------------------

-- Read coordinates from CSV file and calculate centroid.
local coords = {}
local file = io.open(file_path, "r")
if file then
    for line in file:lines() do
        local split_coords = split(line, ',')
        local x = tonumber(split_coords[1])
        local y = tonumber(split_coords[2])
        if x and y then
            table.insert(coords, {x, y})
        end
    end
    file:close()
else
    g.warn("Unable to open file: " .. file_path)
    return
end
-----------------------------------------------------------------------------------------------

-- Calculate the centroid of all coordinates
local centroid_x, centroid_y = calculate_centroid(coords)

-- Shift coordinates and plot them onto the Golly grid
    -- The '+0' is a placeholder for potential future adjustments to the x and y coordinates.   
    -- To shift the center point, replace '+0' with the desired x and y offsets.
for _, coord in ipairs(coords) do
    local x, y = coord[1] - centroid_x + 0, coord[2] - centroid_y + 0
    g.setcell(x, y, 1)
end
-----------------------------------------------------------------------------------------------

g.update()
g.show("Boundary points have been centered around (0,0) and plotted onto the grid.")