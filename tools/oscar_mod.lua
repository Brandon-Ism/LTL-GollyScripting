
-- Oscar is an OSCillation AnalyzeR for use with Golly.
-- Author: Andrew Trevorrow (andrew@trevorrow.com), Mar 2016.
--
-- Modified to provide bounding box dimensions and population for "bugs".
-- Modified by: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2025.
-- Added D4 symmetry classification at test time and average population over period.

local g = golly()

--------------------------------------------------------------------------------
-- D4 Symmetry helpers (ported from symmetry_check_dihedral_D4.lua)
--------------------------------------------------------------------------------

local function get_matrix_from_rect(rect)
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

local function find_live_bounds_sym(mat, w, h)
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
    return min_x, min_y, max_x, max_y
end

local function crop_to_live(mat, w, h)
    local min_x, min_y, max_x, max_y = find_live_bounds_sym(mat, w, h)
    if not min_x then return {}, 0, 0 end
    local crop_w = max_x - min_x + 1
    local crop_h = max_y - min_y + 1
    local cropped = {}
    for y = 1, crop_h do
        cropped[y] = {}
        for x = 1, crop_w do
            cropped[y][x] = mat[min_y + y - 1][min_x + x - 1]
        end
    end
    return cropped, crop_w, crop_h
end

local function check_R90(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - x + 1][y] then return false end
        end
    end
    return true
end

local function check_R180(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - y + 1][w - x + 1] then return false end
        end
    end
    return true
end

local function check_R270(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[x][w - y + 1] then return false end
        end
    end
    return true
end

local function check_SH(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - y + 1][x] then return false end
        end
    end
    return true
end

local function check_SV(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[y][w - x + 1] then return false end
        end
    end
    return true
end

local function check_SD1(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[x][y] then return false end
        end
    end
    return true
end

local function check_SD2(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[w - x + 1][h - y + 1] then return false end
        end
    end
    return true
end

local function classify_symmetry(mat, w, h)
    if w == 0 or h == 0 then return "Empty", {} end

    local has_R90  = check_R90(mat, w, h)
    local has_R180 = check_R180(mat, w, h)
    local has_R270 = check_R270(mat, w, h)
    local has_SH   = check_SH(mat, w, h)
    local has_SV   = check_SV(mat, w, h)
    local has_SD1  = check_SD1(mat, w, h)
    local has_SD2  = check_SD2(mat, w, h)

    local symmetries = {"Identity (R0)"}
    if has_R90  then table.insert(symmetries, "R90")  end
    if has_R180 then table.insert(symmetries, "R180") end
    if has_R270 then table.insert(symmetries, "R270") end
    if has_SH   then table.insert(symmetries, "SH")   end
    if has_SV   then table.insert(symmetries, "SV")   end
    if has_SD1  then table.insert(symmetries, "SD1")  end
    if has_SD2  then table.insert(symmetries, "SD2")  end

    local class_name = "Asymmetric"
    if #symmetries == 8 then
        class_name = "D4 (Full Square Symmetry)"
    elseif #symmetries == 4 then
        if has_R90 and has_R180 and has_R270 then
            class_name = "C4 (90° Rotational Symmetry)"
        elseif has_R180 and has_SH and has_SV then
            class_name = "D2_hv (Horizontal and Vertical Reflection)"
        elseif has_R180 and has_SD1 and has_SD2 then
            class_name = "D2_diag (Diagonal Reflections)"
        end
    elseif #symmetries == 2 then
        if has_R180 then
            class_name = "C2 (180° Rotational Symmetry)"
        elseif has_SH then
            class_name = "D1_h (Horizontal Reflection)"
        elseif has_SV then
            class_name = "D1_v (Vertical Reflection)"
        elseif has_SD1 then
            class_name = "D1_d1 (Main Diagonal Reflection)"
        elseif has_SD2 then
            class_name = "D1_d2 (Anti-Diagonal Reflection)"
        end
    end

    return class_name, symmetries
end

-- Returns a formatted symmetry note line for the current pattern state.
local function get_symmetry_note()
    local rect = g.getrect()
    if #rect == 0 then return "Symmetric (at test time): N/A (empty)" end

    local mat = get_matrix_from_rect(rect)
    local cropped, cw, ch = crop_to_live(mat, rect[3], rect[4])
    local class_name, symmetries = classify_symmetry(cropped, cw, ch)

    if class_name == "Asymmetric" then
        return "Symmetric (at test time): No (Asymmetric)"
    else
        local display = {}
        for _, s in ipairs(symmetries) do
            if s ~= "Identity (R0)" then table.insert(display, s) end
        end
        local detail = #display > 0 and ("\n  Symmetries: " .. table.concat(display, ", ")) or ""
        return "Symmetric (at test time): Yes — " .. class_name .. detail
    end
end

-- Runs forward one full period sampling population at each step, then restores
-- the pattern to its state at the time of the call.  Returns avg pop as string.
local function compute_period_avg_pop(period)
    local saved_rect = g.getrect()
    local saved_cells = {}
    if #saved_rect > 0 then
        saved_cells = g.getcells(saved_rect)
    end

    local total = tonumber(g.getpop())
    for i = 1, period - 1 do
        g.run(1)
        total = total + tonumber(g.getpop())
    end

    -- Restore cells to detection state (generation counter resets, which is fine
    -- because the main loop will restore p0cells immediately after).
    g.new("")
    if #saved_rect > 0 then
        g.putcells(saved_cells)
    end

    local avg = total / period
    if avg == math.floor(avg) then
        return tostring(math.floor(avg))
    else
        return string.format("%.1f", avg)
    end
end

--------------------------------------------------------------------------------
-- Global data structures used by Andrew Trevorrow's "keep minima" algorithm:
--------------------------------------------------------------------------------
local hashlist = {}     -- pattern hash values
local genlist  = {}     -- corresponding generation counts
local poplist  = {}     -- corresponding population counts
local boxlist  = {}     -- corresponding bounding boxes

--------------------------------------------------------------------------------
-- Check if current rule might cause false positives with certain patterns:
--------------------------------------------------------------------------------
local r = g.getrule()
r = string.match(r, "^(.+):") or r
local hasB0notS8 = r:find("B0") == 1 and r:find("/") > 1 and r:sub(-1,-1) ~= "8"

--------------------------------------------------------------------------------
-- Function to do BFS removal of outer-connected live cells after inverting:
--------------------------------------------------------------------------------
local function get_stomach_via_inversion_and_bfs()
    local rect = g.getrect()
    if #rect == 0 then return {0, 0} end

    -- Save current pattern so we can restore it later
    local saved_cells = g.getcells(rect)

    -- Outer bounding box
    local x0, y0, w, h = table.unpack(rect)
    local x1 = x0 + w - 1
    local y1 = y0 + h - 1

    local maxstate = g.numstates() - 1

    -- INVERT all cells in bounding box
    g.select(rect)
    for row = y0, y1 do
        for col = x0, x1 do
            local oldstate = g.getcell(col, row)
            g.setcell(col, row, maxstate - oldstate)
        end
    end

    -- Remove all live cells connected to edges via BFS
    local visited = {}
    local function key(xx, yy) return xx.."_"..yy end

    local function remove_connected_live(sx, sy)
        local stack = {{sx, sy}}
        while #stack > 0 do
            local cx, cy = table.unpack(table.remove(stack))
            local k = key(cx, cy)
            if not visited[k] then
                visited[k] = true
                if g.getcell(cx, cy) ~= 0 then
                    -- Kill the cell
                    g.setcell(cx, cy, 0)
                    -- Push neighbors
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            if dx ~= 0 or dy ~= 0 then
                                local nx, ny = cx + dx, cy + dy
                                if nx >= x0 and nx <= x1 and
                                   ny >= y0 and ny <= y1 then
                                    table.insert(stack, {nx, ny})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- BFS from perimeter cells
    for col = x0, x1 do
        remove_connected_live(col, y0)      -- top edge
        remove_connected_live(col, y1)      -- bottom edge
    end
    for row = y0, y1 do
        remove_connected_live(x0, row)      -- left edge
        remove_connected_live(x1, row)      -- right edge
    end

    -- Get bounding box of what's left in bounding box (the “stomach”)
    local leftover_rect = g.getrect()
    if #leftover_rect == 0 then
        -- No enclosed region
        g.new("")
        g.putcells(saved_cells)
        return {0, 0}
    end

    local leftover_w, leftover_h = leftover_rect[3], leftover_rect[4]

    -- Restore original pattern
    g.new("")
    g.putcells(saved_cells)

    -- Return the “stomach” size
    return {leftover_w, leftover_h}
end

--------------------------------------------------------------------------------
-- We'll store the t=0 bounding boxes in these variables:
--------------------------------------------------------------------------------
local initialOuterW, initialOuterH = 0, 0
local initialInnerW, initialInnerH = 0, 0
local population_t0 = 0

--------------------------------------------------------------------------------
-- Save the pattern at t=0, record outer & inner bounding boxes, then restore
--------------------------------------------------------------------------------
local p0rect = g.getrect()
local p0cells = {}
if #p0rect > 0 then
    -- Save entire pattern
    p0cells = g.getcells(p0rect)

    -- Population at t=0 (store as a printable string with separators)
    population_t0 = g.getpop(',')
    
    -- Outer bounding box at t=0
    initialOuterW = p0rect[3]
    initialOuterH = p0rect[4]

    -- Get inner bounding box at t=0 (using BFS/inversion trick)
    local innerBox = get_stomach_via_inversion_and_bfs()
    initialInnerW, initialInnerH = innerBox[1], innerBox[2]

    -- Restore the original pattern at t=0
    g.new("")
    g.putcells(p0cells)
end

--------------------------------------------------------------------------------
-- We now run Andrew's detection code.  But for any spaceship,
-- we display the outer/inner box sizes from t=0.
--------------------------------------------------------------------------------
local function show_spaceship_speed(period, deltax, deltay)
    -- we found a moving oscillator
    if deltax == deltay or deltax == 0 or deltay == 0 then

        local speed = ""
        if deltax == 0 or deltay == 0 then
            -- orthogonal spaceship
            if deltax > 1 or deltay > 1 then
                speed = speed..(deltax + deltay)
            end
        else
            -- diagonal spaceship (deltax == deltay)
            if deltax > 1 then
                speed = speed..deltax
            end
        end

        local avg_pop = compute_period_avg_pop(period)
        local sym_note = get_symmetry_note()

        if period == 1 then
            g.note(
                "Spaceship detected (speed = "..speed.."c)\n"..
                "W x H (Outer Bounding Box, t=0): "..initialOuterW.." x "..initialOuterH.."\n"..
                "w x h (Inner Bounding Box, t=0): "..initialInnerW.." x "..initialInnerH.."\n"..
                "Population, t=0: "..population_t0.."\n"..
                sym_note.."\n"..
                "Avg Population over Period: "..avg_pop
            )
        else
            g.note(
                "Spaceship detected (speed = "..speed.."c/"..period..")\n"..
                "W x H (Outer Bounding Box, script start): "..initialOuterW.." x "..initialOuterH.."\n"..
                "w x h (Inner Bounding Box, script start): "..initialInnerW.." x "..initialInnerH.."\n"..
                "Population, script start: "..population_t0.."\n"..
                sym_note.."\n"..
                "Avg Population over Period: "..avg_pop
            )
        end
    else
        -- deltax != deltay and both > 0 => knightship
        local speed = deltay..","..deltax
        local avg_pop = compute_period_avg_pop(period)
        local sym_note = get_symmetry_note()
        if period == 1 then
            g.note(
                "Knightship detected (speed = "..speed.."c)\n"..
                sym_note.."\n"..
                "Avg Population over Period: "..avg_pop
            )
        else
            g.note(
                "Knightship detected (speed = "..speed.."c/"..period..")\n"..
                sym_note.."\n"..
                "Avg Population over Period: "..avg_pop
            )
        end
    end
end

--------------------------------------------------------------------------------
-- The main "keep minima" algorithm for detecting oscillation/spaceships
--------------------------------------------------------------------------------
local function oscillating()
    -- return true if the pattern is empty, stable or oscillating
    local pbox = g.getrect()
    if #pbox == 0 then
        g.show("The pattern is empty.")
        return true
    end

    local h = g.hash(pbox)

    -- Insert or compare hash with existing minima
    local pos = 1
    local listlen = #hashlist
    while pos <= listlen do
        if h > hashlist[pos] then
            pos = pos + 1
        elseif h < hashlist[pos] then
            -- shorten lists from pos to end
            for i = 1, listlen - pos + 1 do
                table.remove(hashlist)
                table.remove(genlist)
                table.remove(poplist)
                table.remove(boxlist)
            end
            break
        else
            -- h == hashlist[pos]
            local rect = boxlist[pos]
            if tonumber(g.getpop()) == poplist[pos] and
               pbox[3] == rect[3] and pbox[4] == rect[4] then

                local period = tonumber(g.getgen()) - genlist[pos]

                if hasB0notS8 and (period % 2) > 0 and
                   pbox[1] == rect[1] and pbox[2] == rect[2] and
                   pbox[3] == rect[3] and pbox[4] == rect[4] then
                    -- ignore this hash due to B0 rule issues
                    return false
                end

                -- pattern matched => stable or oscillator
                if pbox[1] == rect[1] and pbox[2] == rect[2] and
                   pbox[3] == rect[3] and pbox[4] == rect[4] then
                    -- pattern hasn't moved
                    if period == 1 then
                        local sym_note = get_symmetry_note()
                        local pop = g.getpop(',')
                        g.note(
                            "The pattern is stable.\n" ..
                            sym_note .. "\n" ..
                            "Population: " .. pop
                        )
                    else
                        local avg_pop = compute_period_avg_pop(period)
                        local sym_note = get_symmetry_note()
                        g.note(
                            "Oscillator detected (period = "..period..")\n" ..
                            sym_note .. "\n" ..
                            "Avg Population over Period: " .. avg_pop
                        )
                    end
                else
                    -- pattern moved => spaceship or knightship
                    local deltax = math.abs(rect[1] - pbox[1])
                    local deltay = math.abs(rect[2] - pbox[2])
                    show_spaceship_speed(period, deltax, deltay)
                end
                return true
            else
                -- look at next matching hash value
                pos = pos + 1
            end
        end
    end

    -- not found => insert new minima
    table.insert(hashlist, pos, h)
    table.insert(genlist, pos, tonumber(g.getgen()))
    table.insert(poplist, pos, tonumber(g.getpop()))
    table.insert(boxlist, pos, pbox)

    return false
end

--------------------------------------------------------------------------------
-- Keep stepping until pattern is empty, stable, or we find an oscillator/spaceship
--------------------------------------------------------------------------------
g.show("Checking for oscillation... (hit escape to abort)")
local oldsecs = os.clock()
while not oscillating() do
    g.run(1)
    local newsecs = os.clock()
    if newsecs - oldsecs >= 1.0 then
        oldsecs = newsecs
        local r = g.getrect()
        if #r > 0 and not g.visrect(r) then g.fit() end
        g.update()
    end
end

-- after detection is complete, restore the original t=0 pattern
if #p0rect > 0 then
    g.new("")
    g.putcells(p0cells)
    local rr = g.getrect()
    if #rr > 0 and not g.visrect(rr) then g.fit() end
end

g.show("Done.")
