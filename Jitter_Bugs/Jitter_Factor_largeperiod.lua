--[[ 

The purpose of this script is to facilitate the analysis of cellular automata patterns, 
particularly "jitter bugs" within Golly. 
This script does the following:
    -- Identifies and shifts the selected pattern's centroid to the (0,0) coordinate for a uniform starting position.
    -- Analyzes the pattern over its evolutionary period to calculate its period, displacement, and jitter factor.
    -- Outputs these findings, including the first-cycle trajectory of the pattern's centroid and its displacement from a defined line of movement, into a CSV file.

In addition, each time a jitter factor is computed, the simulation 
is incremented by one generation before the pattern is recentered (recentering ensures 
the pattern remains within Golly's grid limits, even for large periods).

This script was developed as a work-around for the limitation of grid cells within Golly. 
As of Golly version 4.3, there is a limitation of editing cells with coordinated within +/- 1 billion.

Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Feb. 14, 2024.

]]--


local g = golly() -- Initialize Golly library.

-----------------------------------------------------------------------------------------------
-- 1) Get Speed and Period
-----------------------------------------------------------------------------------------------
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
-- 2) Get Max State
-----------------------------------------------------------------------------------------------
local function get_max_state()
    local rule = g.getrule()
    local _, _, state_str = rule:find("C(%d+)")
    local num_states = tonumber(state_str)
    
    -- If the rule contains "C0", the pattern has 2 states (0 and 1), 1 is the maximum state
    if num_states == 0 then
        return 1
    else
        return num_states
    end
end

-----------------------------------------------------------------------------------------------
-- 3) Calculate Centroid
-----------------------------------------------------------------------------------------------
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
-- 4) Calculate a Jitter Factor
-----------------------------------------------------------------------------------------------
local function calculate_jitter_factor(distances, tau)
    local sum = 0
    for _, d in ipairs(distances) do
        sum = sum + math.abs(d)
    end
    return sum / tau
end

-----------------------------------------------------------------------------------------------
-- 5) Distance from a Point to a Line
-----------------------------------------------------------------------------------------------
local function calculate_distance_from_line(cx, cy, initial_cx, initial_cy, final_cx, final_cy)
    if final_cx == initial_cx then -- if the line of displacement is vertical, undefined slope.
        return math.abs(cx - initial_cx)
    else
        local m = (final_cy - initial_cy)/(final_cx - initial_cx)
        local b = initial_cy - (m * initial_cx)
        -- Perpendicular distance formula
        return math.abs(m*cx - cy + b) / math.sqrt(m*m + 1)
    end
end

-----------------------------------------------------------------------------------------------
-- 6) Sum of Distances 
-----------------------------------------------------------------------------------------------
local function calculate_summ_distances(distances)
    local dist_sum = 0
    for _, d in ipairs(distances) do
        dist_sum = dist_sum + d
    end
    return dist_sum
end

-----------------------------------------------------------------------------------------------
-- 7) Calculate line 
-----------------------------------------------------------------------------------------------
local function calculate_line(initial_cx, initial_cy, final_cx, final_cy)
    local slope = (final_cy - initial_cy) / (final_cx - initial_cx)
    local y_intercept = initial_cy - slope * initial_cx
    return slope, y_intercept
end

-----------------------------------------------------------------------------------------------
-- 8) Recenter the Pattern (shift to origin)
-----------------------------------------------------------------------------------------------
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
-- 9) Prompt user for a file location for CSV output
-----------------------------------------------------------------------------------------------
local function prompt_save_location(default_filename)
    local save_path = g.savedialog(
        "Save output as CSV file", 
        "CSV (*.csv)|*.csv", 
        g.getdir("app"), 
        default_filename
    )
    return save_path
end

-----------------------------------------------------------------------------------------------
-- 10) Main Execution
-----------------------------------------------------------------------------------------------
local function main()

    -- Prompt user for save location and file name
    local csv_path = prompt_save_location("jitter_bug_data.csv")
    if csv_path == nil or csv_path == "" then
        g.note("File save operation was cancelled.")
        return
    end

    g.show("CALCULATING SPEED AND PERIOD & CENTRALIZING PATTERN...")

    -- Get the period, delta x, and delta y from the adapted oscar.lua logic.
    local tau, deltax, deltay = get_speed_and_period()

    cycles = 1
    --[[
    -- Ask the user for the number of cycles to output
    local cycles = tonumber(g.getstring("Enter the number of cycles to output:", "1", "Number of cycles"))
    if cycles == nil or cycles < 1 then
        g.note("Invalid number of cycles. Please enter a positive integer.")
        return
    end ]]--

    -- Calculate initial centroid and ensure a pattern is on the Golly grid.
    g.setgen("0")  -- Ensure the pattern is at its initial state, time = 0.
    local init_cx, init_cy = calculate_centroid()
    if not init_cx or not init_cy then
        g.note("Pattern is empty or centroid calculation failed.")
        return
    end

    -- Recenter to start
    shift_pattern_to_origin(init_cx, init_cy)
    g.setgen("0")
    local initial_cx, initial_cy = calculate_centroid() -- Recalculate after centralizing

    -- Data table for CSV output
    local data_table = {}
    local distances = {}

    local tau_cx, tau_cy

    -- Timer: Start
    local start_time = os.time()

    ------------------------------------------------------------------------------
    -- Gather single-cycle data
    ------------------------------------------------------------------------------
    g.setgen("0") -- Reset to initial state for accurate measurement

    for t = 0, tau * cycles - 1 do
        local cx, cy = calculate_centroid()
        if not cx or not cy then
            g.note("Pattern became empty or centroid calculation failed at time step " .. t)
            return
        end

        -- if we're within the first tau steps, track the distance for the original jitter factor approach
        if t < tau then
            local distance = calculate_distance_from_line(
                cx, cy, 
                initial_cx, initial_cy, 
                initial_cx + deltax, initial_cy + deltay
            )
            table.insert(distances, distance)
        else

            local distance = calculate_distance_from_line(
                cx, cy,
                initial_cx + (deltax * ((t // tau) % cycles)),
                initial_cy + (deltay * ((t // tau) % cycles)),
                initial_cx + deltax + (deltax * ((t // tau) % cycles)),
                initial_cy + deltay + (deltay * ((t // tau) % cycles))
            )
        end

        if t == tau - 1 then
            tau_cx, tau_cy = cx, cy  -- define the final centroid after one full period
        end

        local distance_for_output = calculate_distance_from_line(
            cx, cy,
            initial_cx + (deltax * ((t // tau) % cycles)),
            initial_cy + (deltay * ((t // tau) % cycles)),
            initial_cx + deltax + (deltax * ((t // tau) % cycles)),
            initial_cy + deltay + (deltay * ((t // tau) % cycles))
        )
        table.insert(data_table, {t, cx, cy, distance_for_output, ""})

        g.run(1)
    end

    local jitter_factor = calculate_jitter_factor(distances, tau)
    local summ_distances = calculate_summ_distances(distances)

    local line_of_displacement = "(" .. initial_cx .. ", " .. initial_cy .. ") to (" .. tau_cx .. ", " .. tau_cy .. ")" 
    local m = (tau_cy - initial_cy) / (tau_cx - initial_cx)
    local b = initial_cy - (m * initial_cx)
    local line_equation = string.format("y = %.2fx + %.2f", m, b)

    ------------------------------------------------------------------------------
    -- Calculate tau separate jitter factors for averaging
    ------------------------------------------------------------------------------
    local factors_for_avg = {}  -- This will store tau jitter factors for averaging

    --   - run the pattern for a full period (tau steps),
    --   - compute that period's jitter factor,
    --   - THEN increment by 1 generation,
    --   - THEN recenter,
    --   - proceed to next.

    g.setgen("0") 
    for factor_i = 0, tau - 1 do

        g.show("Calculating jitter factor: " .. factor_i + 1 .. " of " .. tau)

        local temp_distances = {}  -- Collect all distances for this jitter factor
        local initial_cx_i, initial_cy_i = calculate_centroid()
        if not initial_cx_i or not initial_cy_i then
            g.note("Pattern is empty or centroid calculation failed before factor " .. factor_i)
            return
        end

        -- For each jitter factor, run the pattern for tau steps, collecting distances
        for time_step = 0, tau - 1 do
            local cx_i, cy_i = calculate_centroid()
            if not cx_i or not cy_i then
                g.note("Centroid calculation failed at time step " .. time_step)
                return
            end

            local distance_i = calculate_distance_from_line(
                cx_i, cy_i, 
                initial_cx_i, initial_cy_i, 
                initial_cx_i + deltax, initial_cy_i + deltay
            )
            table.insert(temp_distances, distance_i)
            g.run(1)
        end

        -- Calculate the jitter factor for this cycle of tau steps
        local jitter_factor_i = calculate_jitter_factor(temp_distances, tau)
        table.insert(factors_for_avg, jitter_factor_i)

        -- If there's a row in data_table that corresponds to factor_i + 1, fill that cell:
        if data_table[factor_i + 1] then
            data_table[factor_i + 1][5] = jitter_factor_i
        end


        g.run(1)

        local new_cx, new_cy = calculate_centroid()
        if new_cx and new_cy then
            shift_pattern_to_origin(new_cx, new_cy)
        end
        g.setgen("0")
    end

    local sum_factors = 0
    for _, factor in ipairs(factors_for_avg) do
        sum_factors = sum_factors + factor
    end
    local average_jitter_factor = sum_factors / #factors_for_avg

    local end_time = os.time()
    local elapsed_time = os.difftime(end_time, start_time)

    ------------------------------------------------------------------------------
    -- Display final metrics
    ------------------------------------------------------------------------------
    g.note("Period: " .. tau ..
           "\nDelta X: " .. math.abs(deltax) ..
           "\nDelta Y: " .. math.abs(deltay) ..
           "\nJitter Factor (first cycle): " .. jitter_factor ..
           "\nAverage Jitter Factor over " .. #factors_for_avg .. " cycles: " .. average_jitter_factor ..
           "\nRuntime: " .. elapsed_time .. " seconds")

    local file, err = io.open(csv_path, "w")
    if not file then
        g.note("ERROR opening file for writing: " .. err)
        return
    end

    -- Escape any double quotes in the rule
    local escaped_rule = g.getrule():gsub('"', '""')

    -- CSV Header
    file:write("Time,Centroid X,Centroid Y,Distance from Line,Tau Jitter Factors\n")
    file:write(',,,,,"Rule: "' .. escaped_rule .. '"\n')
    file:write(",,,,,Total Runtime (s): " .. elapsed_time .. "\n")
    file:write(",,,,,First-Cycle Jitter Factor: " .. jitter_factor .. "\n")
    file:write(",,,,,Average Jitter Factor over Period: " .. average_jitter_factor .. "\n")
    file:write(',,,,,"Line of Displacement: ' .. line_of_displacement .. '"\n')
    file:write(",,,,,Equation of Line: " .. line_equation .. "\n")
    file:write(",,,,,Sum of Distances (first cycle): " .. summ_distances .. "\n")
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
-- Run Main
-----------------------------------------------------------------------------------------------
main()
