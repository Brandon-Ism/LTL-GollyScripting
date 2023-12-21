-- Allows user to draw a rectangle by clicking opposite corners (without cell preview).
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Sept 2023.

local g = golly()  -- Initialize Golly library

-----------------------------------------------------------------------------------------------

-- Function to draw rectangle between two corner points
local function drawRectangle(x1, y1, x2, y2)
    local minx = math.min(x1, x2)
    local maxx = math.max(x1, x2)
    local miny = math.min(y1, y2)
    local maxy = math.max(y1, y2)

    for x = minx, maxx do
        for y = miny, maxy do
            g.setcell(x, y, 1)  -- Set cell state to 1 (alive)
        end
    end
    g.update() -- Update Golly grid
end
-----------------------------------------------------------------------------------------------
-- Main function to handle rectangle drawing
function drawShape()
    local startx, starty, endx, endy 
    local started = false -- Indicate if drawing has been initiated
    while true do 
        local event = g.getevent()
        if event:find("click") == 1 then 
            local parts = {} 
            for part in event:gmatch("%S+") do 
                table.insert(parts, part)
            end
            if #parts >= 5 then 
                local evt, x, y, butt, mods = parts[1], parts[2], parts[3], parts[4], parts[5]
                if not started then 
                    startx, starty = tonumber(x), tonumber(y)
                    started = true
                    g.show("Click to finish the rectangle...")
                else 
                    endx, endy = tonumber(x), tonumber(y) 
                    drawRectangle(startx, starty, endx, endy)
                    g.show("Click to start a new rectangle...")
                    started = false
                end
            end
        else
            if event ~= "" then g.doevent(event) end -- Handle non-click events
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Start script
g.show("Click to start drawing a rectangle...")
drawShape()