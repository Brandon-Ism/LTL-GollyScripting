-- Allows user to capture coordinates of boundary cell of a bug.
    -- User must use selection tool within Golly to select desired bug.
    -- Script writes boundary cell coordinates to CSV file as x,y.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Nov 2023.

local g = golly() -- Initialize Golly library.

local boundary_points = {}
-----------------------------------------------------------------------------------------------

local function isAlive(x, y)
    return g.getcell(x, y) == 1
end
-----------------------------------------------------------------------------------------------

-- Function to determine if cell is at an edge of the selected area.
local function isAtSelectionEdge(x, y, selrect)
    return x == selrect[1] or x == selrect[1] + selrect[3] - 1 or y == selrect[2] or y == selrect[2] + selrect[4] - 1
end
-----------------------------------------------------------------------------------------------

-- Function to determine if cell is a boundary, determines if it is alive and had at least one dead adj. cell.
local function isBoundary(x, y)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and not isAlive(x + dx, y + dy) then
                return true
            end
        end
    end
    return false
end
-----------------------------------------------------------------------------------------------

-- Gets the selected rectangular area from user.
local selrect = g.getselrect()
if #selrect == 0 then g.alert("No selection.") return end
-----------------------------------------------------------------------------------------------

-- Iterate over each cell in the user selection to classify boundary cells.
    -- 1 is top-left corner x-coordinate
    -- 2 is top-left corner y-coordinate
    -- 3 is width    
    -- 4 is height

for y = selrect[2], selrect[2] + selrect[4] - 1 do 
    for x = selrect[1], selrect[1] + selrect[3] - 1 do
        if isAlive(x, y) and isBoundary(x, y) then

             -- If cell is at edge of selection, is a boudary
                table.insert(boundary_points, {x, y})
            end
        end
    end
-----------------------------------------------------------------------------------------------

-- Function to write points to a CSV file as x,y.
local function writeCSV(filename, points)
    local file = io.open(filename, "w")
    if not file then g.alert("Could not open file: " .. filename) return end
    
    file:write("x,y\n")
    for i, pt in ipairs(points) do
        file:write(pt[1] .. "," .. pt[2] .. "\n")
    end
    
    file:close()
end
-----------------------------------------------------------------------------------------------

-- Write boundary points to CSV files.
    -- User may change filename of CSV file as "my_filename.csv".
writeCSV("boundary_points.csv", boundary_points)
g.show("Boundary points have been written to CSV files.")