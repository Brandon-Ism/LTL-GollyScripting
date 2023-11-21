-- Allows user to capture coordinates of live (1) cells and write the coordinates x,y onto a CSV file.
    -- User must use selection tool within Golly to select desired area containing live (1) cells.
    -- User can change name of CSV file to be created.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Nov 2023.

local g = golly() -- Intitialie Golly library.

-- Check for a selection
local selrect = g.getselrect()
if #selrect == 0 then
    g.exit("No selection found. Please select an area first.")
end
-----------------------------------------------------------------------------------------------

local x0, y0, width, height = table.unpack(selrect)

-- Function to write coordinates to CSV file.
local function writeCSV(filename, data)
    local file = io.open(filename, "w")
    if file then
        for _, coords in ipairs(data) do
            file:write(coords[1] .. "," .. coords[2] .. "\n")
        end
        file:close()
    else
        g.warn("Unable to open file: " .. filename)
    end
end
-----------------------------------------------------------------------------------------------

-- Function to capture live cell coordinates to a table.
local liveCells = {}
for y = y0, y0 + height - 1 do
    for x = x0, x0 + width - 1 do
        if g.getcell(x, y) ~= 0 then
            table.insert(liveCells, {x, y})
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Write to CSV file
    -- User may change filename of CSV file to be created as "my_filename.csv".
local filename = g.getdir("app") .. "live_cells.csv"
writeCSV(filename, liveCells)

g.note("Coordinates of live cells have been written to:\n" .. filename)
