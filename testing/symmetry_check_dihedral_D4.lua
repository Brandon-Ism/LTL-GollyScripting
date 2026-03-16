local g = golly() -- Initialize Golly library.

-- =========================================================
-- Matrix helpers
-- =========================================================

local function get_matrix_from_selection(min_x, min_y, width, height)
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

local function find_live_bounds(mat, w, h)
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

local function crop_matrix_to_live_bounds(mat, w, h)
    local min_x, min_y, max_x, max_y = find_live_bounds(mat, w, h)

    -- No live cells at all
    if not min_x then
        return {}, 0, 0, nil, nil, nil, nil
    end

    local crop_w = max_x - min_x + 1
    local crop_h = max_y - min_y + 1
    local cropped = {}

    for y = 1, crop_h do
        cropped[y] = {}
        for x = 1, crop_w do
            cropped[y][x] = mat[min_y + y - 1][min_x + x - 1]
        end
    end

    return cropped, crop_w, crop_h, min_x, min_y, max_x, max_y
end

local function write_matrix_to_file(f, mat, w, h)
    for y = 1, h do
        local row = {}
        for x = 1, w do
            row[#row + 1] = tostring(mat[y][x])
        end
        f:write(table.concat(row, " ") .. "\n")
    end
end

-- =========================================================
-- D4 symmetry checks
-- All checks assume mat is already the matrix being classified.
-- =========================================================

-- R90 (Rotate 90° clockwise)
local function check_R90(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - x + 1][y] then
                return false
            end
        end
    end
    return true
end

-- R180 (Rotate 180°)
local function check_R180(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - y + 1][w - x + 1] then
                return false
            end
        end
    end
    return true
end

-- R270 (Rotate 270° clockwise)
local function check_R270(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[x][w - y + 1] then
                return false
            end
        end
    end
    return true
end

-- SH (Horizontal reflection: top <-> bottom)
local function check_SH(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[h - y + 1][x] then
                return false
            end
        end
    end
    return true
end

-- SV (Vertical reflection: left <-> right)
local function check_SV(mat, w, h)
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[y][w - x + 1] then
                return false
            end
        end
    end
    return true
end

-- SD1 (Main diagonal reflection: top-left to bottom-right)
local function check_SD1(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[x][y] then
                return false
            end
        end
    end
    return true
end

-- SD2 (Anti-diagonal reflection: top-right to bottom-left)
local function check_SD2(mat, w, h)
    if w ~= h then return false end
    for y = 1, h do
        for x = 1, w do
            if mat[y][x] ~= mat[w - x + 1][h - y + 1] then
                return false
            end
        end
    end
    return true
end

-- =========================================================
-- Symmetry classification
-- =========================================================

local function classify_symmetry(mat, w, h)
    if w == 0 or h == 0 then
        return "Empty pattern (no live cells)", {}
    end

    local has_R90 = check_R90(mat, w, h)
    local has_R180 = check_R180(mat, w, h)
    local has_R270 = check_R270(mat, w, h)
    local has_SH = check_SH(mat, w, h)
    local has_SV = check_SV(mat, w, h)
    local has_SD1 = check_SD1(mat, w, h)
    local has_SD2 = check_SD2(mat, w, h)

    local symmetries = {"Identity (R0)"}
    if has_R90 then table.insert(symmetries, "Rotate 90° (R90)") end
    if has_R180 then table.insert(symmetries, "Rotate 180° (R180)") end
    if has_R270 then table.insert(symmetries, "Rotate 270° (R270)") end
    if has_SH then table.insert(symmetries, "Horizontal Reflection (SH)") end
    if has_SV then table.insert(symmetries, "Vertical Reflection (SV)") end
    if has_SD1 then table.insert(symmetries, "Main Diagonal Reflection (SD1)") end
    if has_SD2 then table.insert(symmetries, "Anti-Diagonal Reflection (SD2)") end

    local class_name = "Asymmetric"

    -- Full square symmetry
    if #symmetries == 8 then
        class_name = "D4 (Full Square Symmetry)"

    -- 4 total symmetries = identity + 3 others
    elseif #symmetries == 4 then
        if has_R90 and has_R180 and has_R270 then
            class_name = "C4 (90° Rotational Symmetry)"
        elseif has_R180 and has_SH and has_SV then
            class_name = "D2_hv (Horizontal and Vertical Reflection)"
        elseif has_R180 and has_SD1 and has_SD2 then
            class_name = "D2_diag (Diagonal Reflections)"
        end

    -- 2 total symmetries = identity + 1 other
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

-- =========================================================
-- Main
-- =========================================================

local function select_to_matrix()
    local selrect = g.getselrect()
    if #selrect == 0 then
        g.warn("Please make a selection.")
        return
    end

    local min_x = selrect[1]
    local min_y = selrect[2]
    local width = selrect[3]
    local height = selrect[4]

    -- Determine the directory of this script
    local script_dir = ""
    local info = debug.getinfo(1, "S")
    if info and info.source and info.source:sub(1,1) == "@" then
        script_dir = info.source:sub(2):match("(.*[/\\])") or ""
    end

    -- Fallback if script path cannot be determined dynamically
    if script_dir == "" then
        script_dir = "/Users/brandon/Documents/ltl/golly-4.3-mac/MyScripting/LTL-GollyScripting/testing/"
    end

    local patt_name = g.getname()
    if patt_name == "" or patt_name == "untitled" then
        patt_name = "pattern"
    else
        patt_name = patt_name
            :gsub("%.rle$", "")
            :gsub("%.mc$", "")
            :gsub("%.rpo$", "")
            :gsub("%.mcx$", "")
            :gsub("%.lif$", "")
    end

    local out_filename = script_dir .. "matrix_" .. patt_name .. ".txt"
    local f = io.open(out_filename, "w")
    if not f then
        g.warn("Could not open file for writing: " .. out_filename)
        return
    end

    -- Full selected matrix
    local mat = get_matrix_from_selection(min_x, min_y, width, height)

    -- Tight bounding box of live cells INSIDE the selection
    local cropped, crop_w, crop_h, live_min_x, live_min_y, live_max_x, live_max_y =
        crop_matrix_to_live_bounds(mat, width, height)

    -- Write original selected matrix
    f:write("--- Selected Matrix (" .. width .. " x " .. height .. ") ---\n")
    write_matrix_to_file(f, mat, width, height)

    f:write("\n--- Symmetry Analysis Uses Tight Live-Cell Bounding Box ---\n")

    if crop_w == 0 or crop_h == 0 then
        f:write("No live cells found in selection.\n")
        f:write("Classification: Empty pattern (no live cells)\n")
        f:close()
        g.show("No live cells found. Matrix saved to: " .. out_filename)
        return
    end

    local abs_min_x = min_x + live_min_x - 1
    local abs_min_y = min_y + live_min_y - 1
    local abs_max_x = min_x + live_max_x - 1
    local abs_max_y = min_y + live_max_y - 1

    f:write("Selection-relative bounds: x=[" .. live_min_x .. "," .. live_max_x ..
            "], y=[" .. live_min_y .. "," .. live_max_y .. "]\n")
    f:write("Absolute bounds: x=[" .. abs_min_x .. "," .. abs_max_x ..
            "], y=[" .. abs_min_y .. "," .. abs_max_y .. "]\n")
    f:write("Cropped Matrix (" .. crop_w .. " x " .. crop_h .. "):\n")
    write_matrix_to_file(f, cropped, crop_w, crop_h)

    -- Classify using the cropped matrix only
    local class_name, valid_syms = classify_symmetry(cropped, crop_w, crop_h)

    f:write("\n--- Symmetry Classification ---\n")
    f:write("Classification: " .. class_name .. "\n")
    f:write("Valid Symmetries: " .. table.concat(valid_syms, ", ") .. "\n")
    f:close()

    g.show("Symmetry: " .. class_name .. ". Matrix saved to: " .. out_filename)
end

select_to_matrix()