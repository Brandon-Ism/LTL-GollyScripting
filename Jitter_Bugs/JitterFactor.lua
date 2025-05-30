-- The purpose of this script is to faciliate the analysis of cellular automata patterns, particularly 'jitter bugs' within Golly. 
-- This script does the following:
    -- Identifies and shifts the selected pattern's centroid to the (0,0) coordinate for a uniform starting position.
    -- Analyzes the pattern over its evolutionary period to calculate its period, displacement, and jitter factor.
    -- Outputs these findings, including the trajectory of the pattern's centroid and its displacement from a defined line of movement, into a CSV file.
-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Feb 2024.

local g = golly() -- Initialize Golly library.

-----------------------------------------------------------------------------------------------

--This function is adapted from oscar.lua-[Author: Andrew Trevorrow (andrew@trevorrow.com), Mar 2016.]
-- Function to determine speed and period directly from the pattern's behavior
local function get_speed_and_period()
    local hashlist = {}
    local genlist = {}
    local poplist = {}
    local boxlist = {}
    local r = g.getrule()
    r = string.match(r, "^(.+):") or r
    local hasB0notS8 = r:find("B0") == 1 and r:find("/") > 1 and r:sub(-1) ~= "8"

    local function oscillating()
        local pbox = g.getrect()
        if #pbox == 0 then return true, 0, 0, 0 end  -- pattern is empty
        
        local h = g.hash(pbox)
        local pos = 1
        while pos <= #hashlist do
            if h == hashlist[pos] then
                local rect = boxlist[pos]
                local period = tonumber(g.getgen()) - genlist[pos]
                local deltax = rect[1] - pbox[1]
                local deltay = rect[2] - pbox[2]
                return true, period, deltax, deltay
            elseif h < hashlist[pos] then
                break
            end
            pos = pos + 1
        end

        table.insert(hashlist, pos, h)
        table.insert(genlist, pos, tonumber(g.getgen()))
        table.insert(poplist, pos, tonumber(g.getpop()))
        table.insert(boxlist, pos, pbox)

        return false, 0, 0, 0
    end

    while true do
        local osc, period, dx, dy = oscillating()
        if osc then return period, dx, dy end
        g.run(1)
    end
end
-----------------------------------------------------------------------------------------------

-- Function to get the maximum state in the current pattern. 
local function get_max_state()
    local rule = g.getrule()
    local _, _, state_str = rule:find("C(%d+)")
    local num_states = tonumber(state_str)
    
    -- If the rule contains "C0", the pattern has 2 states (0 and 1), 1 is the maximum state
    if num_states == 0 then
        return 1
    else
        -- Otherwise, the integer following "C" is the maximum state
        return num_states
    end
end
-----------------------------------------------------------------------------------------------

-- Function to calculate the centroid of the pattern.
-- This function computes the centroid by averaging the x and y coords of all live cells of the pattern.
local function calculate_centroid()
    local max_state = get_max_state()
    local live_cells = g.getcells(g.getrect())
    local sum_x, sum_y, count = 0, 0, 0

    if max_state <= 1 then
        -- Handle 2-state pattern
        for i = 1, #live_cells, 2 do
            sum_x = sum_x + live_cells[i]
            sum_y = sum_y + live_cells[i + 1]
            count = count + 1
        end

    else
        -- Handle patterns with more than 2 states
        for i = 1, #live_cells - 2, 3 do
            local state = live_cells[i+2]
            if state ~= 0 then  -- Consider any non-zero state as "live"
                sum_x = sum_x + live_cells[i]
                sum_y = sum_y + live_cells[i + 1]
                count = count + 1
            end
        end
    end        

    if count == 0 then return nil, nil end  -- Pattern is empty

    return sum_x / count, sum_y / count
end
-----------------------------------------------------------------------------------------------

-- Function to calculate the jitter factor.
local function calculate_jitter_factor(distances, tau)
    local sum = 0
    for _, d in ipairs(distances) do
        sum = sum + math.abs(d)
    end
    return sum / tau
end
-----------------------------------------------------------------------------------------------

-- Function to calculate distance from a point to the line.
local function calculate_distance_from_line(cx, cy, initial_cx, initial_cy, final_cx, final_cy)

    if final_cx == initial_cx then -- if the line of displacement is vertical, undefined slope.
        return math.abs(cx - initial_cx)

    else
    m = (final_cy - initial_cy)/(final_cx - initial_cx)
    b = initial_cy - (m * initial_cx)
    return math.sqrt((((m*(cy-b))-(m^2*cx))^2) / (m^2+1) + (((m*cx)+b-cy)^2) / (m^2+1))

    end
end
-----------------------------------------------------------------------------------------------

-- Function to calculate sum of all distances for every time step, from the centroid to the line of displacement.
local function calculate_summ_distances(distances)
    local dist_sum = 0
    for _, d in ipairs(distances) do
        dist_sum = dist_sum + d
    end
    return dist_sum
end
-----------------------------------------------------------------------------------------------

-- Function to calculate the slope (m) and y-intercept (b) of the line
local function calculate_line(initial_cx, initial_cy, final_cx, final_cy)
    local slope = (final_cy - initial_cy) / (final_cx - initial_cx)
    local y_intercept = initial_cy - slope * initial_cx
    return slope, y_intercept
end
-----------------------------------------------------------------------------------------------

-- Function to shift the pattern so its centroid is at (0,0).
local function shift_pattern_to_origin(cx, cy)
    local max_state = get_max_state()
    local cells = g.getcells(g.getrect())

    -- Use rounding (+0.5) and floor func, to determine best shift to move the centroid to (0,0).
    local dx, dy = -math.floor(cx + 0.5), -math.floor(cy + 0.5)

    if max_state <= 1 then
        for i = 1, #cells, 2 do
            cells[i] = cells[i] + dx
            cells[i+1] = cells[i+1] + dy
        end

    else
        for i = 1, #cells-2, 3 do
            cells[i] = cells[i] + dx
            cells[i+1] = cells[i+1] + dy
        end
    end    

    g.new("Centralized Pattern")  --Creates a new layer with the shifted pattern centered about (0,0).
    g.putcells(cells)
end
-----------------------------------------------------------------------------------------------

-- Main execution function
local function main()

    g.show("CALCULATING SPEED AND PERIOD & CENTRALIZING PATTERN...")

    -- Get the period, delta x, and delta y from the adapted oscar.lua logic.
    local tau, deltax, deltay = get_speed_and_period()

    -- Ask the user for the number of cycles to output
    local cycles = tonumber(g.getstring("Enter the number of cycles to output:", "1", "Number of cycles"))
    if cycles == nil or cycles < 1 then
        g.note("Invalid number of cycles. Please enter a positive integer.")
        return
    end

    -- Calculate initial centroid and ensure a pattern is on the Golly grid.
    g.setgen("0")  -- Ensure the pattern is at its initial state, time = 0.
    local init_cx, init_cy = calculate_centroid()
    if not init_cx then
        g.note("Pattern is empty.")
        return
    end

    shift_pattern_to_origin(init_cx, init_cy) -- Shift pattern to be centered about (0,0).
    g.setgen("0")
    initial_cx, initial_cy = calculate_centroid() --Recalculate intitial x,y from centralized pattern.

    -- Data table for CSV output
    local data_table = {}
    local distances = {}

    local tau_cx, tau_cy

    -- Iterate through each generation up to tau to calculate centroids and distances
    g.setgen("0") -- Reset to initial state for accurate measurement
    for t = 0, tau * cycles - 1 do

        if t == tau-1 then
            tau_cx, tau_cy = calculate_centroid()
        end

        g.show(" JITTER FACTOR IS BEING CALCULATED...\n")
        local cx, cy = calculate_centroid()
        local distance
        if t < tau then  -- Only calculate distance for the first cycle for jitter factor
            distance = calculate_distance_from_line(cx, cy, initial_cx, initial_cy, initial_cx+deltax, initial_cy+deltay)
            table.insert(distances, distance)
        else
            -- For additional cycles, calculate distance but do not add to distances for jitter factor calculation
            distance = calculate_distance_from_line(cx, cy, initial_cx + (deltax * ((t // tau) % cycles)), initial_cy + (deltay * ((t // tau) % cycles)), initial_cx + deltax + (deltax * ((t // tau) % cycles)), initial_cy + deltay + (deltay * ((t // tau) % cycles)))
        end
        table.insert(data_table, {t, cx, cy, distance})
        g.run(1)
    end

    local jitter_factor = calculate_jitter_factor(distances, tau)
    local summ_distances = calculate_summ_distances(distances)
    
    local line_of_displacement = "(" .. initial_cx .. ", " .. initial_cy .. ") to (" .. tau_cx .. ", " .. tau_cy .. ")" 
    m = (tau_cy - initial_cy)/(tau_cx - initial_cx)
    b = initial_cy - (m * initial_cx)
    line_equation = string.format("y = %.2fx + %.2f", m, b)

    -- Display metrics with a g.note
    g.note("Period: " .. tau ..
           "\nDelta X: " .. math.abs(deltax) ..
           "\nDelta Y: " .. math.abs(deltay) ..
           "\nJitter Factor: " .. jitter_factor)


    -- Save to CSV file titled 'jitter_bug_data.csv'
    local csv_path = g.getdir("app") .. "jitter_bug_data.csv"
    local file, err = io.open(csv_path, "w")
    if not file then
        g.note("ERROR opening file for writing (ensure any CSV files generated from this script are not in use...): " .. err)
        return
    end

    -- Write header with line of displacement and jitter factor
    file:write("Time,Centroid X,Centroid Y,Distance from Line\n")
    file:write(",,,,,Jitter Factor: " .. jitter_factor .. "\n")
    file:write(',,,,,"Line of Displacement: ' .. line_of_displacement .. '"\n')
    file:write(",,,,,Equation of Line: " .. line_equation .. "\n")
    file:write(",,,,,Sum of Distances: " .. summ_distances .. "\n")
    file:write(",,,,,Period: " .. tau .."\n")
    file:write(",,,,,Delta X: " .. math.abs(deltax) .. "\n")
    file:write(",,,,,Delta Y: " .. math.abs(deltay) .. "\n")

    for _, row in ipairs(data_table) do
        file:write(table.concat(row, ",") .. "\n")
    end

    file:close()
    g.show("Data saved to: " .. csv_path)

end
-----------------------------------------------------------------------------------------------

main()
