-- Allows user to draw a rectangle by clicking opposite corners, with a live cell preview. 
    --Note: The live preview will overwrite existing live cells.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Sept 2023.

local g = golly() -- Initialize Golly library
local gp = require "gplus" -- Include extended library

local oldRectangle = {} 
local started = false 
local startx, starty 
-----------------------------------------------------------------------------------------------

-- Function to draw rectangle between two corner points
local function drawRectangle(x1, y1, x2, y2)
    for x = math.min(x1, x2), math.max(x1, x2) do
        for y = math.min(y1, y2), math.max(y1, y2) do 
            g.setcell(x, y, 1)  -- Set cell state to 1 (alive)
        end
    end
    g.update() -- Update Golly grid
end
-----------------------------------------------------------------------------------------------
-- For live cell preview; to erase cells to enable live view while moving mouse
local function eraseRectangle(x1, y1, x2, y2)
    for x = math.min(x1, x2), math.max(x1, x2) do
        for y = math.min(y1, y2), math.max(y1, y2) do
            g.setcell(x, y, 0)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------
-- Main function to handle rectangle drawing
function drawRectangles()
    local oldmouse = "" -- Previous mouse position
    while true do
        local event = g.getevent()
        if event:find("click") == 1 then
            local evt, x, y, butt, mods = gp.split(event)
            oldmouse = x .. ' ' .. y -- Update user mouse position
            if started then 
                started = false
                g.show("Click to start drawing a new rectangle...")
            else --start drawing
                startx, starty = tonumber(x), tonumber(y)
                started = true
                oldRectangle = {startx, starty, startx, starty}
                g.show("Click to finish drawing the rectangle...")
            end
        else
            if event ~= "" then g.doevent(event) end -- Handle non-click events
            local mousepos = g.getxy() 
            if started and #mousepos == 0 then -- If mouse leaves grid, erase preview
                if oldRectangle then
                    eraseRectangle(table.unpack(oldRectangle)) 
                    oldRectangle = nil
                end
            elseif started and #mousepos > 0 and mousepos ~= oldmouse then -- Update preview for mouse position changes
                local x, y = gp.split(mousepos)
                x, y = tonumber(x), tonumber(y)
                if oldRectangle then
                    eraseRectangle(table.unpack(oldRectangle)) 
                end
                drawRectangle(startx, starty, x, y)
                oldRectangle = {startx, starty, x, y}
                oldmouse = mousepos
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Start script
g.show("Click to start drawing a rectangle...")
drawRectangles()
