-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Sept 2023.

local g = golly()  -- Initialize Golly library
local gp = require "gplus"  -- Include extended library
-----------------------------------------------------------------------------------------------

local oldCells = {}
local started = false 
local startx, starty 
-----------------------------------------------------------------------------------------------

-- Function to draw filled circle given center (x,y) and radius using Bresenham's circle drawing algorithm
local function drawFilledCircle(cx, cy, r)
    -- Function to fill cells (live) in quadrants 1-4
    local function fillQuadrants(x, y)
        for dy = 0, y do -- vertical
            g.setcell(cx + x, cy + dy, 1)
            g.setcell(cx - x, cy + dy, 1)
            g.setcell(cx + x, cy - dy, 1)
            g.setcell(cx - x, cy - dy, 1) 
        end
        for dx = 0, x do -- horizontal
            g.setcell(cx + dx, cy + y, 1)
            g.setcell(cx - dx, cy + y, 1)
            g.setcell(cx + dx, cy - y, 1)
            g.setcell(cx - dx, cy - y, 1)
        end
    end

    -- Bresenham's algo
    local x, y, d
    x, y = r, 0 -- x to rad, y to 0
    d = 1 - r -- decision param.

    fillQuadrants(r, 0) -- fill for init x,y
    fillQuadrants(0, r) -- fill for swapped x,y for symm.

    while x > y do
        y = y + 1 
        if d <= 0 then -- moving directly up
            d = d + 2 * y + 1
        else -- moving up and left
            x = x - 1
            d = d + 2 * y - 2 * x + 1
        end
        if x < y then -- region complete
            break
        end
        fillQuadrants(x, y)
        fillQuadrants(y, x)
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to draw ring given center (x,y) and radius using Bresenham's circle drawing algorithm
local function drawUnfilledCircle(cx, cy, r)
    local x, y, d
    x, y = r, 0
    d = 1 - r

    -- Set init points on perimeter
    g.setcell(cx + r, cy, 1)
    g.setcell(cx - r, cy, 1)
    g.setcell(cx, cy + r, 1)
    g.setcell(cx, cy - r, 1)
    
    while x > y do
        y = y + 1
        if d <= 0 then
            d = d + 2 * y + 1
        else
            x = x - 1
            d = d + 2 * y - 2 * x + 1
        end
        if x < y then
            break
        end
        g.setcell(cx + x, cy + y, 1)
        g.setcell(cx - x, cy + y, 1)
        g.setcell(cx + x, cy - y, 1)
        g.setcell(cx - x, cy - y, 1)

        if x ~= y then -- keep symm.
            g.setcell(cx + y, cy + x, 1)
            g.setcell(cx - y, cy + x, 1)
            g.setcell(cx + y, cy - x, 1)
            g.setcell(cx - y, cy - x, 1)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to capture/store cells that would be overwritten
local function captureOldCells(cx, cy, r)
    oldCells = {}
    for x = cx - r, cx + r do
        for y = cy - r, cy + r do
            table.insert(oldCells, {x, y, g.getcell(x, y)})
        end
    end
end

-- Function to restore cells to orignial state.
local function restoreOldCells()
    for _, cell in ipairs(oldCells) do
        g.setcell(cell[1], cell[2], cell[3])
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to show user live cell preview of circle as cursor is moved across grid to radius length.
-- Allows user to return to 'menu' to switch drawing tools by pressing 'M' key on keyboard.
local function drawLivePreviewCircle(drawFunc)
    local oldmouse = ""
    while true do
        local event = g.getevent()
        if event:find("key m") then return end  -- 'M' key to go back to the main menu
        
        if event:find("click") == 1 then
            local evt, x, y, butt, mods = gp.split(event)
            if started then 
                started = false
                drawFunc(startx, starty, math.floor(math.sqrt((x - startx)^2 + (y - starty)^2)))
                oldCells = {}  -- Clear old cells after finalizing a circle
                g.show("Click to start drawing a new circle or press 'M' to return to the main menu...")
            else
                startx, starty = tonumber(x), tonumber(y)
                started = true
                captureOldCells(startx, starty, 0)
                g.show("Click again to finalize the circle or press 'M' to return to the main menu...")
            end
        else
            if event ~= "" then g.doevent(event) end
            local mousepos = g.getxy()
            if started and #mousepos > 0 and mousepos ~= oldmouse then
                local x, y = gp.split(mousepos)
                x, y = tonumber(x), tonumber(y)
                local radius = math.floor(math.sqrt((x - startx)^2 + (y - starty)^2))
                
                restoreOldCells() 
                captureOldCells(startx, starty, radius) -- Capture new cell states
                drawFunc(startx, starty, radius) 
                
                oldmouse = mousepos
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Presents user with the option to choose method of drawing
while true do
    local choice = g.getstring("Choose a method to create a circle:\n"..
                               "1) Draw filled circle with a cell preview.\n"..
                               "2) Input filled circle dimensions.\n"..
                               "3) Draw unfilled circle with a cell preview.\n"..
                               "4) Input unfilled circle dimensions.", "1")
    
    if choice == "1" then
        drawLivePreviewCircle(drawFilledCircle)
    elseif choice == "3" then
        drawLivePreviewCircle(drawUnfilledCircle)
    elseif choice == "2" or choice == "4" then
        -- Input dimensions to draw circles
        local center = g.getstring("Enter circle center as x,y:", "0,0")
        local radius = g.getstring("Enter circle radius:", "10")
        local x, y = center:match("(%-?%d+),(%-?%d+)")
        if x and y and tonumber(radius) then
            if choice == "2" then
                drawFilledCircle(tonumber(x), tonumber(y), tonumber(radius))
            else
                drawUnfilledCircle(tonumber(x), tonumber(y), tonumber(radius))
            end
        else
            g.warn("Invalid input. Please enter valid coordinates for the center and a valid radius.")
        end
    else
        g.warn("Invalid choice. Please enter a valid option.")
    end
end
