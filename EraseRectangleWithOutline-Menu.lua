-- Allows user to "erase" a rectangle  given options of:
    -- 1) Using cursor to "click and drag" desried rectangle.
    -- 2) Inputting vertices/dimensions of desried rectangle.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Sept 2023.

local g = golly() -- Initialize Golly library
local gp = require "gplus" -- Include extended library
-----------------------------------------------------------------------------------------------

local oldCells = {}
local started = false
local startx, starty
-----------------------------------------------------------------------------------------------

-- Function to draw filled (dead) rectangle between two corner points.
local function drawRectangle(x1, y1, x2, y2)
    for x = math.min(x1, x2), math.max(x1, x2) do
        for y = math.min(y1, y2), math.max(y1, y2) do 
            g.setcell(x, y, 0)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to capture/store cells that would be overwritten by a new rectangle.
local function captureOldCells(x1, y1, x2, y2)
    oldCells = {}
    for x = math.min(x1, x2), math.max(x1, x2) do
        for y = math.min(y1, y2), math.max(y1, y2) do
            table.insert(oldCells, {x, y, g.getcell(x, y)})
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Function to restore cells to original state.
local function restoreOldCells()
    for _, cell in ipairs(oldCells) do
        g.setcell(cell[1], cell[2], cell[3])
    end
end
-----------------------------------------------------------------------------------------------

-- Function to draw the outline (dead) of a rectangle between two corner points.
local function drawRectangleOutline(x1, y1, x2, y2)
    local xmin, xmax = math.min(x1, x2), math.max(x1, x2)
    local ymin, ymax = math.min(y1, y2), math.max(y1, y2)
    
    for x = xmin, xmax do
        g.setcell(x, ymin, 0)
        g.setcell(x, ymax, 0)
    end
    
    for y = ymin, ymax do
        g.setcell(xmin, y, 0)
        g.setcell(xmax, y, 0)
    end
    
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to capture/store cells that would be overwritten by a new rectangle outline.
local function captureOldCellsOutline(x1, y1, x2, y2)
    oldCells = {}
    local xmin, xmax = math.min(x1, x2), math.max(x1, x2)
    local ymin, ymax = math.min(y1, y2), math.max(y1, y2)
    
    for x = xmin, xmax do
        table.insert(oldCells, {x, ymin, g.getcell(x, ymin)})
        table.insert(oldCells, {x, ymax, g.getcell(x, ymax)})
    end
    
    for y = ymin, ymax do
        table.insert(oldCells, {xmin, y, g.getcell(xmin, y)})
        table.insert(oldCells, {xmax, y, g.getcell(xmax, y)})
    end
end
-----------------------------------------------------------------------------------------------

-- Function to show user live cell preview of filled rectangle as cursor is moved across grid.
local function drawLivePreviewRectangle()
local oldmouse = ""
    while true do
        local event = g.getevent()
        if event:find("key m") then return end

        if event:find("click") == 1 then
            local evt, x, y, butt, mods = gp.split(event)
            if started then 
                started = false
                drawRectangle(startx, starty, tonumber(x), tonumber(y))
                oldCells = {}  -- Clear the old cells after finalizing a rectangle
                g.show("Click to start drawing new rectangle or press 'M' to return to the main menu...")
            else
                startx, starty = tonumber(x), tonumber(y)
                started = true
                captureOldCells(startx, starty, startx, starty)
                g.show("Click again to finalize rectangle or press 'M' to return to the main menu...")
            end
        else
            if event ~= "" then g.doevent(event) end
            local mousepos = g.getxy()
            if started and #mousepos > 0 and mousepos ~= oldmouse then
                local x, y = gp.split(mousepos)
                x, y = tonumber(x), tonumber(y)
                restoreOldCells()
                captureOldCells(startx, starty, x, y)
                drawRectangle(startx, starty, x, y)
                oldmouse = mousepos
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Function to show user live cell preview of rectangle outline as cursor is moved across grid.
local function drawLivePreviewRectangleOutline()
    local oldmouse = ""
    while true do
        local event = g.getevent()
        if event:find("key m") then return end

        if event:find("click") == 1 then
            local evt, x, y, butt, mods = gp.split(event)
            if started then 
                started = false
                drawRectangleOutline(startx, starty, tonumber(x), tonumber(y))
                oldCells = {}
                g.show("Click to start drawing new rectangle outline or press 'M' to return to the main menu...")
            else
                startx, starty = tonumber(x), tonumber(y)
                started = true
                captureOldCellsOutline(startx, starty, startx, starty)
                g.show("Click again to finalize rectangle outline or press 'M' to return to the main menu...")
            end
        else
            if event ~= "" then g.doevent(event) end
            local mousepos = g.getxy()
            if started and #mousepos > 0 and mousepos ~= oldmouse then
                local x, y = gp.split(mousepos)
                x, y = tonumber(x), tonumber(y)
                restoreOldCells()
                captureOldCellsOutline(startx, starty, x, y)
                drawRectangleOutline(startx, starty, x, y)
                oldmouse = mousepos
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Function to allow user to input either opposite corners of a rectangle (x1,y1 x2,y2), or input top-left/bottom-right corner corrdinates, then input dimensions as (width, height).
local function getInputRectangle()
    local option = g.getstring("Choose a method:\n"..
                               "a) Enter coordinates of opposite corners.\n"..
                               "b) Enter top-left corner coordinates and dimensions.\n"..
                               "c) Enter bottom-right corner coordinates and dimensions.", "a")
    if option == "a" then
        local coords = g.getstring("Enter opposite corners as x1,y1 x2,y2:", "0,0 10,10")
        local x1, y1, x2, y2 = coords:match("(%-?%d+)%s*,%s*(%-?%d+)%s*(%-?%d+)%s*,%s*(%-?%d+)")
        if x1 and y1 and x2 and y2 then
            drawRectangle(tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2))
        else
            g.warn("Invalid coordinates; Please use the format x1,y1 x2,y2.")
        end
    elseif option == "b" then
        local topLeft = g.getstring("Enter top-left corner as x,y:", "0,0")
        local dimensions = g.getstring("Enter dimensions as width,height:", "10,10")
        local x, y = topLeft:match("(%-?%d+),(%-?%d+)")
        local w, h = dimensions:match("(%-?%d+),(%-?%d+)")
        drawRectangle(tonumber(x), tonumber(y), tonumber(x)+tonumber(w)-1, tonumber(y)+tonumber(h)-1)
    elseif option == "c" then
        local bottomRight = g.getstring("Enter bottom-right corner as x,y:", "0,0")
        local dimensions = g.getstring("Enter dimensions as width,height:", "10,10")
        local x, y = bottomRight:match("(%-?%d+),(%-?%d+)")
        local w, h = dimensions:match("(%-?%d+),(%-?%d+)")
        drawRectangle(tonumber(x)-tonumber(w)+1, tonumber(y)-tonumber(h)+1, tonumber(x), tonumber(y))
    end
end
-----------------------------------------------------------------------------------------------

-- Function to allow user to input either opposite corners of a rectangle outline or input dimensions.
local function getInputRectangleOutline()
    local option = g.getstring("Choose a method:\n"..
                               "a) Enter coordinates of opposite corners.\n"..
                               "b) Enter top-left corner coordinates and dimensions.\n"..
                               "c) Enter bottom-right corner coordinates and dimensions.", "a")
    if option == "a" then
        local coords = g.getstring("Enter opposite corners as x1,y1 x2,y2:", "0,0 10,10")
        local x1, y1, x2, y2 = coords:match("(%-?%d+)%s*,%s*(%-?%d+)%s*(%-?%d+)%s*,%s*(%-?%d+)")
        if x1 and y1 and x2 and y2 then
            drawRectangleOutline(tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2))
        else
            g.warn("Invalid coordinates; Please use the format x1,y1 x2,y2.")
        end
    elseif option == "b" then
        local topLeft = g.getstring("Enter top-left corner as x,y:", "0,0")
        local dimensions = g.getstring("Enter dimensions as width,height:", "10,10")
        local x, y = topLeft:match("(%-?%d+),(%-?%d+)")
        local w, h = dimensions:match("(%-?%d+),(%-?%d+)")
        drawRectangleOutline(tonumber(x), tonumber(y), tonumber(x)+tonumber(w)-1, tonumber(y)+tonumber(h)-1)
    elseif option == "c" then
        local bottomRight = g.getstring("Enter bottom-right corner as x,y:", "0,0")
        local dimensions = g.getstring("Enter dimensions as width,height:", "10,10")
        local x, y = bottomRight:match("(%-?%d+),(%-?%d+)")
        local w, h = dimensions:match("(%-?%d+),(%-?%d+)")
        drawRectangleOutline(tonumber(x)-tonumber(w)+1, tonumber(y)-tonumber(h)+1, tonumber(x), tonumber(y))
    end
end

-- Presents user with the option to choose method of drawing rectangle or rectangle outline.
while true do
    local choice = g.getstring("Choose a method to create a rectangle or rectangle outline (dead cells):\n"..
                               "1) Draw filled rectangle with cell preview.\n"..
                               "2) Input dimensions/vertices for filled rectangle.\n"..
                               "3) Draw rectangle outline with cell preview.\n"..
                               "4) Input dimensions/vertices for rectangle outline.", "1")
    if choice == "1" then
        g.show("Click to start drawing a filled rectangle...")
        drawLivePreviewRectangle()
    elseif choice == "2" then
        getInputRectangle()
    elseif choice == "3" then
        g.show("Click to start drawing a rectangle outline...")
        drawLivePreviewRectangleOutline()
    elseif choice == "4" then
        getInputRectangleOutline()
    end
end
