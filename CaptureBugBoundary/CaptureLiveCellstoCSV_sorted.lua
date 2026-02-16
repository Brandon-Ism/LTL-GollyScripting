-- Golly Script: Capture and Classify Inner vs Outer Boundaries
-- 1. Identifies "External Background" using a Flood Fill algorithm.
-- 2. Scans selected area for live cells.
-- 3. Classifies edge cells as "outer" (touching background) or "inner" (touching holes).
-- 4. Sorts them angularly and exports to CSV.

local g = golly()

-- Check for a selection
local selrect = g.getselrect()
if #selrect == 0 then
    g.exit("No selection found. Please select an area first.")
end

local x0, y0, width, height = table.unpack(selrect)

-----------------------------------------------------------------------------------------------
-- STEP 1: FLOOD FILL BACKGROUND
-- We map which dead cells belong to the "outside" world.
-----------------------------------------------------------------------------------------------

local external_mask = {} -- Stores "x,y" of external dead cells

-- Helper to create a key string for coordinates
local function coordsToKey(x, y)
    return x .. "," .. y
end

-- We scan a slightly larger area than the selection to allow the flood 
-- to wrap around the shape.
local pad = 1
local minX, minY = x0 - pad, y0 - pad
local maxX, maxY = x0 + width + pad - 1, y0 + height + pad - 1

local stack = {}

-- Initialize stack with the perimeter of our padded bounding box
-- We assume the boundary of the selection box is surrounded by dead cells (or we treat it as "outside")
for x = minX, maxX do
    table.insert(stack, {x, minY}) -- Top edge
    table.insert(stack, {x, maxY}) -- Bottom edge
end
for y = minY + 1, maxY - 1 do
    table.insert(stack, {minX, y}) -- Left edge
    table.insert(stack, {maxX, y}) -- Right edge
end

-- Perform the Flood Fill
while #stack > 0 do
    local p = table.remove(stack)
    local px, py = p[1], p[2]
    local key = coordsToKey(px, py)

    -- If we haven't visited this cell yet
    if not external_mask[key] then
        -- In Golly, getcell returns 0 for dead, 1 for live.
        -- We only flood through dead cells (0).
        if g.getcell(px, py) == 0 then
            external_mask[key] = true
            
            -- Check 4-connected neighbors (Up, Down, Left, Right)
            -- We use 4-way fill to ensure we don't "leak" through diagonal cracks of live cells.
            local neighbors = {
                {px + 1, py}, {px - 1, py}, {px, py + 1}, {px, py - 1}
            }
            
            for _, n in ipairs(neighbors) do
                local nx, ny = n[1], n[2]
                -- Ensure we stay within our scan bounds
                if nx >= minX and nx <= maxX and ny >= minY and ny <= maxY then
                    if not external_mask[coordsToKey(nx, ny)] then
                        table.insert(stack, {nx, ny})
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- STEP 2: CLASSIFY CELLS
-----------------------------------------------------------------------------------------------

local outerEdges = {}
local innerEdges = {}

for y = y0, y0 + height - 1 do
    for x = x0, x0 + width - 1 do
        if g.getcell(x, y) ~= 0 then -- It is a live cell
            
            local isOuter = false
            local isInner = false
            
            -- Check all 8 neighbors (Moore Neighborhood)
            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        local nx, ny = x + dx, y + dy
                        if g.getcell(nx, ny) == 0 then -- It's touching a dead cell
                            if external_mask[coordsToKey(nx, ny)] then
                                isOuter = true
                            else
                                isInner = true
                            end
                        end
                    end
                end
            end
            
            -- Add to respective lists
            -- Note: A single cell can be BOTH inner and outer if the wall is 1 pixel thick.
            if isOuter then
                table.insert(outerEdges, {x, y, "outer"})
            end
            if isInner then
                table.insert(innerEdges, {x, y, "inner"})
            end
        end
    end
end

-----------------------------------------------------------------------------------------------
-- STEP 3: SORTING HELPERS
-----------------------------------------------------------------------------------------------

local function calculateCenter(cells)
    if #cells == 0 then return 0, 0 end
    local sumX, sumY = 0, 0
    for _, point in ipairs(cells) do
        sumX = sumX + point[1]
        sumY = sumY + point[2]
    end
    return sumX / #cells, sumY / #cells
end

-- Lua 5.1 has no math.atan2; Golly uses Lua 5.1.
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
    return 0
end

-- Sort function wrapper
local function sortRadially(cellList)
    if #cellList == 0 then return end
    local cx, cy = calculateCenter(cellList)
    table.sort(cellList, function(a, b)
        return custom_atan2(a[2] - cy, a[1] - cx) > custom_atan2(b[2] - cy, b[1] - cx)
    end)
end

-----------------------------------------------------------------------------------------------
-- STEP 4: PROCESS AND WRITE
-----------------------------------------------------------------------------------------------

-- Sort the lists individually for better results
sortRadially(outerEdges)
sortRadially(innerEdges)

local filename = "classified_boundaries.csv"
local file = io.open(filename, "w")

if file then
    file:write("x,y,boundary_type\n")
    
    -- Write Outer Edges
    for _, coords in ipairs(outerEdges) do
        file:write(coords[1] .. "," .. coords[2] .. "," .. coords[3] .. "\n")
    end
    
    -- Write Inner Edges
    for _, coords in ipairs(innerEdges) do
        file:write(coords[1] .. "," .. coords[2] .. "," .. coords[3] .. "\n")
    end
    
    file:close()
    g.note("Success! Processed " .. #outerEdges .. " outer cells and " .. #innerEdges .. " inner cells.\nWritten to: " .. filename)
else
    g.warn("Unable to open file: " .. filename)
end