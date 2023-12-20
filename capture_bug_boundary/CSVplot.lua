-- Plots x,y coordinates from desried CSV file, onto Golly grid.
    -- CSV filepath must be written to script (using forward slashes only */* )
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Nov 2023.

local g = golly() -- Intialize Golly library.


-- Filepath for the CSV file containing coordinates to be written in this line.
    -- Filepath must be contained in single quote characters. '../../my_CSVfile.csv'.
local file_path = 'your_filepath/../../boundary_points.csv'
-----------------------------------------------------------------------------------------------

-- Function to spilt x,y coordinates from CSV format. 
local function split(str, delimiter)
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
-----------------------------------------------------------------------------------------------

-- Function to read coordinates from CSV file, and plot them onto Golly grid as live (1) cells. 
local file = io.open(file_path, "r")
if file then
    for line in file:lines() do
        local coords = split(line, ',')
        local x = tonumber(coords[1])
        local y = tonumber(coords[2])
        if x and y then
            g.setcell(x, y, 1) 
        end
    end
    file:close()
else
    g.warn("Unable to open file: " .. file_path)
end
-----------------------------------------------------------------------------------------------

g.update()
g.show("Boundary points have been plotted onto grid.")