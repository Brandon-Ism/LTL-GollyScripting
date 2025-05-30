-- Allows user to draw an ellipse (dead cells) given options of:
    -- 1) Using cursor to "click and drag" desired ellipse.
    -- 2) Inputting center coordinates and major/minor axes lengths for a filled ellipse.
    -- 3) Using cursor to "click and drag" desired ellipse outline.
    -- 4) Inputting center coordinates and major/minor axes lengths for an unfilled ellipse (ellipse outline).

-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2024.

local g = golly()  -- Initialize Golly library
local gp = require "gplus"  -- Include extended library
-----------------------------------------------------------------------------------------------

local oldCells = {}
local started = false
local startx, starty
-----------------------------------------------------------------------------------------------

-- Function to draw filled ellipse given center (cx,cy), major axis a, and minor axis b
local function drawFilledEllipse(cx, cy, a, b)
    local dx, dy, d1, d2, x, y
    x = 0
    y = b

    -- Initial decision parameter of region 1
    d1 = (b * b) - (a * a * b) + (0.25 * a * a)
    dx = 2 * b * b * x
    dy = 2 * a * a * y

    -- For region 1
    while dx < dy do
        -- Print points based on 4-way symmetry
        for i = -x, x do
            g.setcell(cx + i, cy + y, 0)
            g.setcell(cx + i, cy - y, 0)
        end

        -- Checking and updating value of decision parameter 
        if d1 < 0 then
            x = x + 1
            dx = dx + (2 * b * b)
            d1 = d1 + dx + (b * b)
        else
            x = x + 1
            y = y - 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d1 = d1 + dx - dy + (b * b)
        end
    end

    -- Decision parameter of region 2
    d2 = ((b * b) * ((x + 0.5) * (x + 0.5))) + ((a * a) * ((y - 1) * (y - 1))) - (a * a * b * b)

    -- Plotting points of region 2
    while y >= 0 do
        -- printing points based on 4-way symmetry
        for i = -x, x do
            g.setcell(cx + i, cy + y, 0)
            g.setcell(cx + i, cy - y, 0)
        end

        -- Checking and updating parameter
        if d2 > 0 then
            y = y - 1
            dy = dy - (2 * a * a)
            d2 = d2 + (a * a) - dy
        else
            y = y - 1
            x = x + 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d2 = d2 + dx - dy + (a * a)
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

-- Function to show user live cell preview of ellipse as cursor is moved
-- Allows user to return to 'menu' to switch drawing tools by pressing 'M' key on keyboard.
local function drawLivePreviewEllipse(drawFunc)
    local oldmouse = ""
    while true do
        local event = g.getevent()
        if event:find("key m") then return end  -- 'M' key to go back to the main menu
        
        if event:find("click") == 1 then
            local evt, x, y, butt, mods = gp.split(event)
            if started then 
                started = false
                local a = math.abs(x - startx)
                local b = math.abs(y - starty)
                drawFunc(startx, starty, a, b)
                oldCells = {}  -- Clear old cells after finalizing an ellipse
                g.show("Click to start drawing a new ellipse or press 'M' to return to the main menu...")
            else
                startx, starty = tonumber(x), tonumber(y)
                started = true
                captureOldCells(startx, starty, 0) 
                g.show("Click again to finalize the ellipse or press 'M' to return to the main menu...")
            end
        else
            if event ~= "" then g.doevent(event) end
            local mousepos = g.getxy()
            if started and #mousepos > 0 and mousepos ~= oldmouse then
                local x, y = gp.split(mousepos)
                x, y = tonumber(x), tonumber(y)
                local a = math.abs(x - startx)
                local b = math.abs(y - starty)
                
                restoreOldCells() 
                captureOldCells(startx, starty, math.max(a, b)) -- Capture new cell states with adjustment for ellipse
                drawFunc(startx, starty, a, b)
                
                oldmouse = mousepos
            end
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Function to draw unfilled ellipse given center (cx,cy), major axis a, and minor axis b
local function drawUnfilledEllipse(cx, cy, a, b)
    local dx, dy, d1, d2, x, y
    x = 0
    y = b

    -- Initial decision parameter of region 1
    d1 = (b * b) - (a * a * b) + (0.25 * a * a)
    dx = 2 * b * b * x
    dy = 2 * a * a * y

    -- Function to plot points based on 4-way symmetry for the ellipse border
    local function plotEllipsePoints(cx, cy, x, y)
        g.setcell(cx + x, cy + y, 0)
        g.setcell(cx - x, cy + y, 0)
        g.setcell(cx + x, cy - y, 0)
        g.setcell(cx - x, cy - y, 0)
    end

    -- For region 1
    while dx < dy do
        -- Plot points based on 4-way symmetry
        plotEllipsePoints(cx, cy, x, y)

        -- Checking and updating value of decision parameter
        if d1 < 0 then
            x = x + 1
            dx = dx + (2 * b * b)
            d1 = d1 + dx + (b * b)
        else
            x = x + 1
            y = y - 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d1 = d1 + dx - dy + (b * b)
        end
    end

    -- Decision parameter of region 2
    d2 = ((b * b) * ((x + 0.5) * (x + 0.5))) + ((a * a) * ((y - 1) * (y - 1))) - (a * a * b * b)

    -- Plotting points of region 2
    while y >= 0 do
        -- Plotting points based on 4-way symmetry
        plotEllipsePoints(cx, cy, x, y)

        -- Checking and updating parameter
        if d2 > 0 then
            y = y - 1
            dy = dy - (2 * a * a)
            d2 = d2 + (a * a) - dy
        else
            y = y - 1
            x = x + 1
            dx = dx + (2 * b * b)
            dy = dy - (2 * a * a)
            d2 = d2 + dx - dy + (a * a)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Presents user with the option to choose method of drawing
while true do
    local choice = g.getstring("Choose a method to create an ellipse (dead cells):\n"..
                               "1) Draw filled ellipse with a cell preview.\n"..
                               "2) Input filled ellipse dimensions.\n"..
                               "3) Draw unfilled ellipse with a cell preview.\n"..
                               "4) Input unfilled ellipse dimensions.", "1")

    if choice == "1" then
        drawLivePreviewEllipse(drawFilledEllipse)
    elseif choice == "2" then
        -- Input dimensions to draw filled ellipse
        local center = g.getstring("Enter ellipse center as x,y:", "0,0")
        local axes = g.getstring("Enter major axis,minor axis:", "10,5")
        local x, y = center:match("(%-?%d+),(%-?%d+)")
        local a, b = axes:match("(%-?%d+),(%-?%d+)")
        if x and y and a and b then
            drawFilledEllipse(tonumber(x), tonumber(y), tonumber(a), tonumber(b))
        else
            g.warn("Invalid input. Please enter valid coordinates for the center and valid lengths for the major and minor axes.")
        end
    elseif choice == "3" then
        drawLivePreviewEllipse(drawUnfilledEllipse)
    elseif choice == "4" then
        -- Input dimensions to draw unfilled ellipse
        local center = g.getstring("Enter ellipse center as x,y:", "0,0")
        local axes = g.getstring("Enter major axis,minor axis:", "10,5")
        local x, y = center:match("(%-?%d+),(%-?%d+)")
        local a, b = axes:match("(%-?%d+),(%-?%d+)")
        if x and y and a and b then
            drawUnfilledEllipse(tonumber(x), tonumber(y), tonumber(a), tonumber(b))
        else
            g.warn("Invalid input. Please enter valid coordinates for the center and valid lengths for the major and minor axes.")
        end
    else
        g.warn("Invalid choice. Please enter a valid option.")
    end
end

