--[[
The purpose of this script is to faciliate the analysis of cellular automata patterns, particularly 'jitter bugs' within Golly. 
This script does the following:
    - Identifies and shifts the selected pattern's centroid to the (0,0) coordinate for a uniform starting position.
    - Analyzes the pattern over its evolutionary period to calculate its period, displacement, and jitter factor.
    - Outputs these findings, including the trajectory of the pattern's centroid and its displacement from a defined line of movement, into a CSV file.

With this script, tau jitter factors are calculated, and averaged over the period of a bug.

This script also has the following user-centered features:
    - Prompts user for CSV save location.
    - Checks if the bug might exceed Golly's +/-1,000,000,000 limit by measuring displacement 
      over one period and adding a buffer based on the current bounding box.
    - If no risk or user chooses to continue, it proceeds with the standard jitter factor 
      calculations and saves results to the chosen CSV.

-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Oct 9, 2024; Modified on Feb 19.2025

]]--
-----------------------------------------------------------------------------------------------

local g = golly() -- Initialize Golly library.

-----------------------------------------------------------------------------------------------
-- get_speed_and_period (adapted from oscar.lua)
-----------------------------------------------------------------------------------------------
local function get_speed_and_period()
    local hashlist = {}
    local genlist  = {}
    local poplist  = {}
    local boxlist  = {}
    local r = g.getrule()
    r = string.match(r, "^(.+):") or r

    local function oscillating()
        local pbox = g.getrect()
        if #pbox == 0 then return true, 0, 0, 0 end  -- pattern empty
        local h = g.hash(pbox)
        local pos = 1
        while pos <= #hashlist do
            if h == hashlist[pos] then
                local rect   = boxlist[pos]
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
        table.insert(genlist,  pos, tonumber(g.getgen()))
        table.insert(poplist,  pos, tonumber(g.getpop()))
        table.insert(boxlist,  pos, pbox)
        return false, 0, 0, 0
    end

    while true do
        local osc, period, dx, dy = oscillating()
        if osc then 
            return period, dx, dy 
        end
        g.run(1)
    end
end

-----------------------------------------------------------------------------------------------
-- get_max_state
-----------------------------------------------------------------------------------------------
local function get_max_state()
    local rule = g.getrule()
    local _, _, state_str = rule:find("C(%d+)")
    local num_states = tonumber(state_str)
    
    if num_states == 0 then
        return 1 -- 2-state
    else
        return num_states
    end
end

-----------------------------------------------------------------------------------------------
-- calculate_centroid
-----------------------------------------------------------------------------------------------
local function calculate_centroid()
    local max_state  = get_max_state()
    local live_cells = g.getcells(g.getrect())
    local sum_x, sum_y, count = 0, 0, 0

    if max_state <= 1 then
        for i = 1, #live_cells, 2 do
            sum_x = sum_x + live_cells[i]
            sum_y = sum_y + live_cells[i + 1]
            count = count + 1
        end
    else
        for i = 1, #live_cells - 2, 3 do
            local state = live_cells[i+2]
            if state ~= 0 then
                sum_x = sum_x + live_cells[i]
                sum_y = sum_y + live_cells[i+1]
                count = count + 1
            end
        end
    end

    if count == 0 then return nil, nil end
    return sum_x / count, sum_y / count
end

-----------------------------------------------------------------------------------------------
--  Jitter/distance helper functions
-----------------------------------------------------------------------------------------------
local function calculate_jitter_factor(distances, tau)
    local sum = 0
    for _, d in ipairs(distances) do
        sum = sum + math.abs(d)
    end
    return sum / tau
end

local function calculate_distance_from_line(cx, cy, x1, y1, x2, y2)
    if x2 == x1 then
        return math.abs(cx - x1)
    else
        local m = (y2 - y1)/(x2 - x1)
        local b = y1 - m*x1
        return math.abs(m*cx - cy + b) / math.sqrt(m*m + 1)
    end
end

local function calculate_summ_distances(distances)
    local dist_sum = 0
    for _, d in ipairs(distances) do
        dist_sum = dist_sum + d
    end
    return dist_sum
end

-----------------------------------------------------------------------------------------------
-- D4 Symmetry helpers (ported from symmetry_check_dihedral_D4.lua)
-----------------------------------------------------------------------------------------------
local function sym_get_matrix(rect)
    local min_x, min_y, width, height = rect[1], rect[2], rect[3], rect[4]
    local mat = {}
    for y = 0, height - 1 do
        mat[y + 1] = {}
        for x = 0, width - 1 do
            local state = g.getcell(min_x + x, min_y + y)
            mat[y + 1][x + 1] = (state > 0) and 1 or 0
        end
    end
    return mat
end

local function sym_crop_to_live(mat, w, h)
    local min_x, min_y, max_x, max_y = nil, nil, nil, nil
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] == 1 then
                if not min_x or x < min_x then min_x = x end
                if not max_x or x > max_x then max_x = x end
                if not min_y or y < min_y then min_y = y end
                if not max_y or y > max_y then max_y = y end
            end
        end
    end
    if not min_x then return {}, 0, 0 end
    local cw = max_x - min_x + 1
    local ch = max_y - min_y + 1
    local cropped = {}
    for y = 1, ch do
        cropped[y] = {}
        for x = 1, cw do
            cropped[y][x] = mat[min_y + y - 1][min_x + x - 1]
        end
    end
    return cropped, cw, ch
end

local function sym_check_R90(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[h - x + 1][y] then return false end
    end end
    return true
end
local function sym_check_R180(mat, w, h)
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[h - y + 1][w - x + 1] then return false end
    end end
    return true
end
local function sym_check_R270(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[x][w - y + 1] then return false end
    end end
    return true
end
local function sym_check_SH(mat, w, h)
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[h - y + 1][x] then return false end
    end end
    return true
end
local function sym_check_SV(mat, w, h)
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[y][w - x + 1] then return false end
    end end
    return true
end
local function sym_check_SD1(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[x][y] then return false end
    end end
    return true
end
local function sym_check_SD2(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do for x = 1, w do
        if mat[y][x] ~= mat[w - x + 1][h - y + 1] then return false end
    end end
    return true
end

-- Returns 1 if any non-trivial D4 symmetry is present, 0 otherwise.
local function check_any_symmetry()
    local rect = g.getrect()
    if #rect == 0 then return 0 end
    local mat = sym_get_matrix(rect)
    local cropped, cw, ch = sym_crop_to_live(mat, rect[3], rect[4])
    if cw == 0 or ch == 0 then return 0 end
    if sym_check_R90 (cropped, cw, ch) or sym_check_R180(cropped, cw, ch) or
       sym_check_R270(cropped, cw, ch) or sym_check_SH  (cropped, cw, ch) or
       sym_check_SV  (cropped, cw, ch) or sym_check_SD1 (cropped, cw, ch) or
       sym_check_SD2 (cropped, cw, ch) then
        return 1
    end
    return 0
end

-----------------------------------------------------------------------------------------------
-- shift_pattern_to_origin
-----------------------------------------------------------------------------------------------
local function shift_pattern_to_origin(cx, cy)
    local max_state = get_max_state()
    local cells     = g.getcells(g.getrect())

    local dx = -math.floor(cx + 0.5)
    local dy = -math.floor(cy + 0.5)

    if max_state <= 1 then
        for i = 1, #cells, 2 do
            cells[i]   = cells[i] + dx
            cells[i+1] = cells[i+1] + dy
        end
    else
        for i = 1, #cells-2, 3 do
            cells[i]   = cells[i] + dx
            cells[i+1] = cells[i+1] + dy
        end
    end

    g.new("Centralized Pattern")
    g.putcells(cells)
end

-----------------------------------------------------------------------------------------------
-- Prompt user for a file location and name to save
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
-- Main Execution
-----------------------------------------------------------------------------------------------
local function main()

    -- Prompt user for save location and file name
    local csv_path = prompt_save_location("jitter_bug_data.csv")
    if csv_path == nil or csv_path == "" then
        g.note("File save operation was cancelled.")
        return
    end

    g.show("CALCULATING SPEED AND PERIOD & CENTRALIZING PATTERN...")

    -- Get the period, delta x, and delta y
    local tau, deltax, deltay = get_speed_and_period()

    -- Ask user for the number of cycles
    local cycles = tonumber(g.getstring("Enter the number of cycles to output:", "1", "Number of cycles"))
    if cycles == nil or cycles < 1 then
        g.note("Invalid number of cycles. Please enter a positive integer.")
        return
    end

    -- Center the pattern at generation 0
    g.setgen("0")
    local init_cx, init_cy = calculate_centroid()
    if not init_cx or not init_cy then
        g.note("Pattern is empty or centroid calculation failed.")
        return
    end
    shift_pattern_to_origin(init_cx, init_cy)
    g.setgen("0")

    -------------------------------------------------------------------------------------------
    -- Overflow Check: run pattern for 1 period, measure net displacement, add bounding box
    -------------------------------------------------------------------------------------------
    local rect = g.getrect() -- bounding box after recenter
    if #rect < 4 then
        g.note("No pattern after recentering?! Aborting.")
        return
    end

    local w0 = rect[3]
    local h0 = rect[4]
    local buffer_x = w0 / 2
    local buffer_y = h0 / 2

    -- Save the current pattern so we can restore it
    local saved_cells = g.getcells(rect)
    local saved_rule  = g.getrule()

    -- measure centroid at t=0
    local cx0, cy0 = calculate_centroid()

    -- run forward 1 period
    for _ = 1, tau do
        g.run(1)
    end

    -- measure centroid at t=tau
    local cx_tau, cy_tau = calculate_centroid()
    if not cx_tau or not cy_tau then
        g.note("Pattern empty during the test run for 1 period.")
        return
    end

    -- net displacement for 1 period
    local dx_period = cx_tau - cx0
    local dy_period = cy_tau - cy0

    -- restore the pattern at t=0
    g.new("Centralized Pattern")
    g.setrule(saved_rule)
    g.putcells(saved_cells)
    g.setgen("0")

    -- Decide how many total periods we might run
    -- By default, we do tau*cycles steps in the first pass (which is cycles periods)
    -- plus a second pass of tau steps for the "tau factor" loop => total = cycles + tau.
    local n_periods = cycles + tau

    local limit = 1e9
    local final_x = math.abs(n_periods * dx_period) + buffer_x
    local final_y = math.abs(n_periods * dy_period) + buffer_y

    if final_x >= limit or final_y >= limit then
        local warn_msg = string.format([[
WARNING:
Based on displacement over 1 period (tau=%d):
  dx = %.6f
  dy = %.6f

...and a bounding box half-size of (%.0fx%.0f),
we estimate up to %.1f in X or %.1f in Y after %d periods.
This may exceed Golly's +/-1,000,000,000 coordinate cell limit!

We recommend using the `Jitter_Factor_largeperiod.lua`
Type "yes" to proceed anyway, or "no" to terminate script:
]], tau, dx_period, dy_period, w0, h0, final_x, final_y, n_periods)

        local ans = g.getstring(warn_msg, "no", "Potential overflow!")
        if not ans or ans:lower() ~= "yes" then
            g.note("Exiting script to avoid coordinate overflow risk.")
            return
        end
    end

    -------------------------------------------------------------------------------------------
    -- Proceed with the original logic if user continues or no overflow risk
    -------------------------------------------------------------------------------------------
    local initial_cx, initial_cy = calculate_centroid()
    local data_table = {}
    local distances = {}
    local tau_cx, tau_cy

    -- Timer: Start
    local start_time = os.time()

    -- Single-cycle path data
    g.setgen("0")
    for t = 0, tau * cycles - 1 do
        local cx, cy = calculate_centroid()
        if not cx or not cy then
            g.note("Pattern became empty or centroid calculation failed at time step " .. t)
            return
        end

        if t == tau - 1 then
            tau_cx, tau_cy = cx, cy
        end

        local distance
        if t < tau then
            distance = calculate_distance_from_line(cx, cy, initial_cx, initial_cy,
                                                    initial_cx + deltax, initial_cy + deltay)
            table.insert(distances, distance)
        else
            distance = calculate_distance_from_line(cx, cy,
                                                    initial_cx + (deltax * ((t // tau) % cycles)),
                                                    initial_cy + (deltay * ((t // tau) % cycles)),
                                                    initial_cx + deltax + (deltax * ((t // tau) % cycles)),
                                                    initial_cy + deltay + (deltay * ((t // tau) % cycles)))
        end
        local sym_flag = check_any_symmetry()
        -- columns: t, cx, cy, distance, tau_jitter_factor (filled later), symmetry_flag
        table.insert(data_table, {t, cx, cy, distance, nil, sym_flag})

        g.run(1)
    end

    local jitter_factor  = calculate_jitter_factor(distances, tau)
    local summ_distances = calculate_summ_distances(distances)

    local line_of_displacement = "(" .. initial_cx .. ", " .. initial_cy 
                                 .. ") to (" .. tau_cx .. ", " .. tau_cy .. ")" 
    local m = (tau_cy - initial_cy) / (tau_cx - initial_cx)
    local b = initial_cy - (m * initial_cx)
    local line_equation = string.format("y = %.2fx + %.2f", m, b)

    -- Multiple jitter factors for averaging
    local factors_for_avg = {}
    for factor_i = 0, tau - 1 do
        local temp_distances = {}
        local initial_cx_i, initial_cy_i = calculate_centroid()

        for time_step = 0, tau - 1 do
            local cx_i, cy_i = calculate_centroid()
            if not cx_i or not cy_i then
                g.note("Centroid calculation failed at time step " .. time_step)
                return
            end

            local distance_i = calculate_distance_from_line(cx_i, cy_i,
                                                            initial_cx_i, initial_cy_i,
                                                            initial_cx_i + deltax, initial_cy_i + deltay)
            table.insert(temp_distances, distance_i)
            g.run(1)
        end

        local jitter_factor_i = calculate_jitter_factor(temp_distances, tau)
        table.insert(factors_for_avg, jitter_factor_i)

        -- Fill the 5th column in the first tau rows
        if data_table[factor_i + 1] then
            data_table[factor_i + 1][5] = jitter_factor_i
        end

        g.run(1)
    end

    -- Compute average of the tau jitter factors
    local sum_factors = 0
    for _, factor in ipairs(factors_for_avg) do
        sum_factors = sum_factors + factor
    end
    local average_jitter_factor = sum_factors / #factors_for_avg

    local end_time = os.time()
    local elapsed_time = os.difftime(end_time, start_time)

    -- Final note
    g.note("Period: " .. tau ..
           "\nDelta X: " .. math.abs(deltax) ..
           "\nDelta Y: " .. math.abs(deltay) ..
           "\nJitter Factor: " .. jitter_factor ..
           "\nAverage Jitter Factor over Period: " .. average_jitter_factor ..
           "\nRuntime: " .. elapsed_time .. " seconds")

    -------------------------------------------------------------------------------------------
    -- Save data to the chosen CSV file
    -------------------------------------------------------------------------------------------
    local file, err = io.open(csv_path, "w")
    if not file then
        g.note("ERROR opening file for writing: " .. err)
        return
    end

    -- Escape double quotes in the rule
    local escaped_rule = g.getrule():gsub('"', '""')

    file:write("Time,Centroid X,Centroid Y,Distance from Line,Tau Jitter Factors,Symmetry Detected (0/1)\n")
    file:write(',,,,,"Rule: "' .. escaped_rule .. '"\n')
    file:write(",,,,,Total Runtime (s): " .. elapsed_time .. "\n")
    file:write(",,,,,Jitter Factor: " .. jitter_factor .. "\n")
    file:write(",,,,,Average Jitter Factor over Period: " .. average_jitter_factor .. "\n")
    file:write(',,,,,"Line of Displacement: ' .. line_of_displacement .. '"\n')
    file:write(",,,,,Equation of Line: " .. line_equation .. "\n")
    file:write(",,,,,Sum of Distances: " .. summ_distances .. "\n")
    file:write(",,,,,Period: " .. tau .."\n")
    file:write(",,,,,Delta X: " .. math.abs(deltax) .. "\n")
    file:write(",,,,,Delta Y: " .. math.abs(deltay) .. "\n")

    for _, row in ipairs(data_table) do
        -- row: {t, cx, cy, distance, jitter_factor_or_nil, sym_flag}
        file:write(tostring(row[1]) .. "," ..
                   tostring(row[2]) .. "," ..
                   tostring(row[3]) .. "," ..
                   tostring(row[4]) .. "," ..
                   (row[5] ~= nil and tostring(row[5]) or "") .. "," ..
                   tostring(row[6]) .. "\n")
    end

    file:close()
    g.show("Data saved to: " .. csv_path)
end

-----------------------------------------------------------------------------------------------
main()
