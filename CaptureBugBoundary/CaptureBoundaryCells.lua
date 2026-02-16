-- Capture and classify inner vs outer boundaries.
-- Finds which dead cells are "outside" with a flood fill, then scans the selection
-- for live cells and marks edge cells as outer (touching background) or inner (touching holes).
-- Sorts by angle and writes to CSV.

local g = golly()

-- need a selection to work with
local selrect = g.getselrect()
if #selrect == 0 then
    g.exit("No selection found. Please select an area first.")
end

local x0, y0, width, height = table.unpack(selrect)

-----------------------------------------------------------------------------------------------
-- flood fill to find which dead cells are "outside"
-----------------------------------------------------------------------------------------------

local external_mask = {}  -- "x,y" -> true for dead cells that are external

local function coordsToKey(x, y)
    return x .. "," .. y
end

-- scan a bit outside the selection so the fill can wrap around the shape
local pad = 1
local minX, minY = x0 - pad, y0 - pad
local maxX, maxY = x0 + width + pad - 1, y0 + height + pad - 1

local stack = {}

-- start from the padded box perimeter (we treat that as "outside")
for x = minX, maxX do
    table.insert(stack, {x, minY})
    table.insert(stack, {x, maxY})
end
for y = minY + 1, maxY - 1 do
    table.insert(stack, {minX, y})
    table.insert(stack, {maxX, y})
end

while #stack > 0 do
    local p = table.remove(stack)
    local px, py = p[1], p[2]
    local key = coordsToKey(px, py)

    if not external_mask[key] then
        -- getcell: 0 = dead, 1 = live; we only spread through dead cells
        if g.getcell(px, py) == 0 then
            external_mask[key] = true
            
            -- 4-connected neighbors so we don't leak through diagonal gaps
            local neighbors = {
                {px + 1, py}, {px - 1, py}, {px, py + 1}, {px, py - 1}
            }
            
            for _, n in ipairs(neighbors) do
                local nx, ny = n[1], n[2]
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
-- classify live edge cells as outer (touching outside) or inner (touching a hole)
-----------------------------------------------------------------------------------------------

local outerEdges = {}
local innerEdges = {}

for y = y0, y0 + height - 1 do
    for x = x0, x0 + width - 1 do
        if g.getcell(x, y) ~= 0 then
            
            local isOuter = false
            local isInner = false
            
            -- look at all 8 neighbors; if it touches a dead cell, that side is outer or inner
            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        local nx, ny = x + dx, y + dy
                        if g.getcell(nx, ny) == 0 then
                            if external_mask[coordsToKey(nx, ny)] then
                                isOuter = true
                            else
                                isInner = true
                            end
                        end
                    end
                end
            end
            
            -- a cell can be both if the wall is one pixel thick
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
-- sort helpers (angle around center)
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
    return 0
end

local function sortRadially(cellList)
    if #cellList == 0 then return end
    local cx, cy = calculateCenter(cellList)
    table.sort(cellList, function(a, b)
        return custom_atan2(a[2] - cy, a[1] - cx) > custom_atan2(b[2] - cy, b[1] - cx)
    end)
end

-----------------------------------------------------------------------------------------------
-- recenter all boundary coords about the origin (round to integers)
-----------------------------------------------------------------------------------------------

local function recenter_coords()
    local n = #outerEdges + #innerEdges
    if n == 0 then return end
    local sumX, sumY = 0, 0
    for _, p in ipairs(outerEdges) do
        sumX = sumX + p[1]
        sumY = sumY + p[2]
    end
    for _, p in ipairs(innerEdges) do
        sumX = sumX + p[1]
        sumY = sumY + p[2]
    end
    local cx, cy = sumX / n, sumY / n
    local function shift(p)
        p[1] = math.floor(p[1] - cx + 0.5)
        p[2] = math.floor(p[2] - cy + 0.5)
    end
    for _, p in ipairs(outerEdges) do shift(p) end
    for _, p in ipairs(innerEdges) do shift(p) end
end

-----------------------------------------------------------------------------------------------
-- sort and write CSV
-----------------------------------------------------------------------------------------------

recenter_coords()
sortRadially(outerEdges)
sortRadially(innerEdges)

-- build filename from current layer/pattern name (safe for filesystem)
local function safe_pattern_name()
    local name = g.getname()
    if name == "" then name = "untitled" end
    -- allow only alphanumeric, underscore, hyphen; replace rest with underscore
    name = name:gsub("[%s%p]", "_"):gsub("_+", "_"):gsub("^_", ""):gsub("_$", "")
    if name == "" then name = "pattern" end
    return name
end

local filename = "boundary_cells_" .. safe_pattern_name() .. ".csv"
local file = io.open(filename, "w")

if file then
    file:write("x,y,boundary_type\n")
    
    for _, coords in ipairs(outerEdges) do
        file:write(coords[1] .. "," .. coords[2] .. "," .. coords[3] .. "\n")
    end
    
    for _, coords in ipairs(innerEdges) do
        file:write(coords[1] .. "," .. coords[2] .. "," .. coords[3] .. "\n")
    end
    
    file:close()
    g.note("Success! Processed " .. #outerEdges .. " outer cells and " .. #innerEdges .. " inner cells.\nWritten to: " .. filename)
else
    g.warn("Unable to open file: " .. filename)
end