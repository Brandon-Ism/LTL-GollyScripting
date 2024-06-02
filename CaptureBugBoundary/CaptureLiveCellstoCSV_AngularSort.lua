-- Allows user to capture coordinates of live (1) cells and write the coordinates x,y onto a CSV file.
    -- User must use selection tool within Golly to select desired area containing live (1) cells.
    -- User can change name of CSV file to be created.
    -- Cells are written to CSV file, after being sorted in a counterclockwise direction based on their angles relative to center.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Mar 2023.

local g = golly() -- Initialize Golly library.

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
        file:write("x,y\n")
        for _, coords in ipairs(data) do
            file:write(coords[1] .. "," .. coords[2] .. "\n")
        end
        file:close()
    else
        g.warn("Unable to open file: " .. filename)
    end
end
-----------------------------------------------------------------------------------------------

-- Function to determine if a cell is an edge cell
local function isEdgeCell(x, y)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                if g.getcell(x + dx, y + dy) == 0 then
                    return true
                end
            end
        end
    end
    return false
end
-----------------------------------------------------------------------------------------------

-- Function to calculate the center of edge cells
local function calculateCenter(edgeCells)
    local sumX, sumY = 0, 0
    for _, point in ipairs(edgeCells) do
        sumX = sumX + point[1]
        sumY = sumY + point[2]
    end
    return sumX / #edgeCells, sumY / #edgeCells
end
-----------------------------------------------------------------------------------------------

-- Capture all live cells and identify edge cells
local edgeCells = {}
for y = y0, y0 + height - 1 do
    for x = x0, x0 + width - 1 do
        if g.getcell(x, y) ~= 0 and isEdgeCell(x, y) then
            table.insert(edgeCells, {x, y})
        end
    end
end
-----------------------------------------------------------------------------------------------

-- atan2 function
local function custom_atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif y >= 0 and x < 0 then
        return math.atan(y / x) + math.pi
    elseif y < 0 and x < 0 then
        return math.atan(y / x) - math.pi
    elseif y > 0 and x == 0 then
        return math.pi / 2
    elseif y < 0 and x == 0 then
        return -math.pi / 2
    end
    -- Undefined if x and y are both 0
    return 0
end
-----------------------------------------------------------------------------------------------

-- Calculate the center of the shape
local centerX, centerY = calculateCenter(edgeCells)

-- Sort edgeCells in a clockwise direction based on angle to center
table.sort(edgeCells, function(a, b)
    return custom_atan2(a[2] - centerY, a[1] - centerX) > custom_atan2(b[2] - centerY, b[1] - centerX)
end)


-- Write to CSV file
    -- User may change filename of CSV file to be created as "my_filename.csv".
--local filename = g.getdir("app") .. "live_cells.csv"
writeCSV("sorted_live_cells.csv", edgeCells)

g.note("Coordinates of edge cells have been written to:\n" .. "sorted_live_cells.csv")
