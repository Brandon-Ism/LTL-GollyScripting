
--[[

 - Draws a “ghost-trail” overlay of past generations for a selected region, alternating two colors to visualize all live cells (treats any non-zero state as live).
 - Prompts for scale factor, trail interval, and run-length (auto or manual stepping).
 - Controls: Space to step/draw, “s” to save the overlay as PNG, “q”/Esc to exit.
 - Fully supports both 2-state and multi-state rules without additional changes.


 Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), May 2025.

]]--

local g = golly()
local ov = g.overlay


--------------------------------------------------------------------------------

-- Ensure there is a selection
local selrect = g.getselrect()
if #selrect == 0 then
    g.exit("There is no selection. Please select an area before running the script.")
end
local selx, sely, selwd, selht = table.unpack(selrect)


-- Prompt for scale factor
local S = tonumber(
    g.getstring(
      "Enter integer scale factor (e.g. 4,8,16):",
      "8",
      "Scale Factor"
    )
)
if not S or S < 1 then
    g.exit("Invalid scale factor.")
end



-- Clone current layer and tile it
local cloneindex = g.clone()
g.setoption("tilelayers", 1)

-- Create overlay, fill it white once
ov("create " .. (selwd * S) .. " " .. (selht * S))
ov("position middle")
ov("blend 1")
ov("rgba 255 255 255 255")
ov("fill")
ov("update")

-- Prompt for trail interval (nth step to plot)
local interval = tonumber(
    g.getstring(
      "Enter trail interval (1 = every step, 2 = every other step, ...):",
      "1",
      "Trail Interval"
    )
)

if not interval or interval < 1 then
    g.exit("Invalid interval.")
end


-- Prompt for run-length (blank = manual stepping)
local rungens = tonumber(
    g.getstring(
      "Enter number of generations to run\nOR\nLeave blank for manual stepping:",
      "",
      "Run Generations"
    )
)
if not rungens then rungens = 0 end

-- returns 1 for 2-state rules, or the C-parameter otherwise
local function get_max_state()
  local rule = g.getrule()
  local _,_,state_str = rule:find("C(%d+)")
  local num = tonumber(state_str)
  return (num == 0) and 1 or num
end


-- draws every non-zero cell as an S×S block,
-- handling both 2-state and multi-state rules
local function draw_live_cells(cells)
    local max_state = get_max_state()
    if max_state <= 1 then
        -- two-state: {x,y, x,y, …}
        for i = 1, #cells, 2 do
            local x = (cells[i]   - selx) * S
            local y = (cells[i+1] - sely) * S
            ov("fill " .. x .. " " .. y .. " " .. S .. " " .. S)
        end
    else
        -- multi-state: {x,y,state,  x,y,state, …}
        for i = 1, #cells-2, 3 do
            if cells[i+2] ~= 0 then
                local x = (cells[i]   - selx) * S
                local y = (cells[i+1] - sely) * S
                ov("fill " .. x .. " " .. y .. " " .. S .. " " .. S)
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Main loop: step + draw ghosts
local gencount  = 0  -- how many steps taken
local plotCount = 0  -- how many times we’ve drawn

while true do
    if rungens > 0 then
        ------------------------------------------------------------------------
        -- Automatic stepping
        if (gencount % interval) == 0 then
            local cells = g.getcells(selrect)
            ov("position middle")
            -- choose color: black or dark grey
            if (plotCount % 2) == 0 then
                ov("rgba 0 0 0 255")
            else
                ov("rgba 128 128 128 255")
            end
            -- draw live cells (handles 2-state and multi-state)
            draw_live_cells(cells)
            ov("update")
            plotCount = plotCount + 1
        end

        -- advance one generation
        g.step()
        g.update()
        gencount = gencount + 1
        rungens = rungens - 1

        -- throttle to ~20 updates/sec
        g.sleep(50)

    else
        ------------------------------------------------------------------------
        -- Manual stepping (blocks on getevent)
        local event = g.getevent()

        if event:find("key space") then
            if (gencount % interval) == 0 then
                local cells = g.getcells(selrect)
                ov("position middle")
                -- choose color: black or dark grey
                if (plotCount % 2) == 0 then
                    ov("rgba 0 0 0 255")
                else
                    ov("rgba 128 128 128 255")
                end
                -- draw live cells (handles 2-state and multi-state)
                draw_live_cells(cells)
                ov("update")
                plotCount = plotCount + 1
            end

            g.step()
            g.update()
            gencount = gencount + 1

        elseif event:find("key s") then
            ----------------------------------------------------------------
            -- Save overlay as PNG with scaled dimensions
            local savedir = g.getdir("data")
            local pngpath = g.savedialog(
                "Save overlay as PNG file",
                "PNG (*.png)|*.png",
                savedir,
                "overlay.png"
            )
            if #pngpath > 0 then
                ov("save 0 0 " .. (selwd * S) .. " " .. (selht * S) .. " " .. pngpath)
                g.note("Overlay saved to " .. pngpath)
            end

        elseif event:find("key escape") or event:find("key q") then
            break
        end
    end
end
