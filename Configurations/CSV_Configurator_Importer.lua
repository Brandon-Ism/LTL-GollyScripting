--[[
    This script automates the creation of 'initial configurations' on a custom-named Golly grid, based on data from a CSV file. These configurations comprise circles, ellipses, and rectangles representing live and dead cells.

    Steps for the user:
    1. Name the grid: A custom name for the new grid can be entered for identification and reference.
    2. Configuration count and spacing: The user specifies the desired number of configurations they have entered into the CSV file and the horizontal center-to-center spacing between them.
    3. CSV Input: Instead of manual entry, the script reads configuration details from a CSV file, with each line defining one configuration in the following format:
        - Shape of live cells ('C' for Circle, 'E' for Ellipse, 'R' for Rectangle)
        - Radius for circles, axis lengths for ellipses, or dimensions for rectangles of live cells
        - 'Y Setback' indicating the vertical displacement for the center of the dead cells from the live ones
        - Shape of dead cells ('C' for Circle, 'E' for Ellipse, 'R' for Rectangle)
        - Radius for circles, axis lengths for ellipses, or dimensions for rectangles of dead cells
        - Rule string (column F, header row only) — applied automatically to the grid

        The first row of the CSV is assumed to be the header and is ignored for configurations.
        Row numbers in prompts use Excel/LibreOffice numbering (header = row 1, first config = row 2).

    CSV File Format Example:
        [shape of live cells] , [radius or axis lengths or dimensions of live shape] , [y setback] , [shape of dead cells] , [radius or axis lengths or dimensions of dead shape]
        example entry: C,23,6,E,9 7 = Circle of live cells with radius 23, y setback of 6, with ellipse of dead cells with major axis = 9, and minor axis = 7.
        example entry: R,27 29,5,C,10 = Rectangle of live cells length 27, width 29. y setback of 5. Circle of dead cells with radius = 10.


    Purpose:
    This script is designed to streamline the process of generating and testing initial cell arrangements in Golly's environment.
    By reading configuration data from a CSV file, the script allows for quick adjustments and batch processing of multiple configurations.
    This script enables users to quickly explore various configurations to discover those that evolve into interesting and potentially stable patterns under the Larger the Life rules, and other rules supported by Golly.


-- Author: Brandon Ismalej (brandon.ismalej.671@my.csun.edu), Apr 2024.; Updated: Aug. 2024

]]
-----------------------------------------------------------------------------------------------

local g = golly() -- Initialize Golly library
-----------------------------------------------------------------------------------------------

-- Function to correct file path slashes for Windows
local function correct_file_path(filepath)

    -- Remove any leading or trailing double or single quotes
    filepath = filepath:gsub([["]], ""):gsub([['']], "")

    -- Replace both single and double backslashes with a single forward slash
    filepath = filepath:gsub("\\+", "/")
    return filepath
end
-----------------------------------------------------------------------------------------------

-- Function to prompt the user for a file path and validate it
local function get_valid_file_path()
    while true do
        local input_path = g.getstring("Enter the file path for the CSV file:", "")
        local corrected_path = correct_file_path(input_path)

        g.show("Corrected file path: " .. corrected_path)
        local file = io.open(corrected_path, "r")

        if file then
            file:close()
            return corrected_path
        else
            g.warn("Invalid file path. Please try again.")
        end
    end
end
-----------------------------------------------------------------------------------------------

-- Parses a single CSV line, respecting double-quoted fields (which may contain commas).
local function parse_csv_line(line)
    local fields = {}
    local i = 1
    local len = #line
    while i <= len do
        if line:sub(i, i) == '"' then
            -- quoted field: collect until closing quote
            local j = i + 1
            local field = ""
            while j <= len do
                if line:sub(j, j) == '"' then
                    if line:sub(j + 1, j + 1) == '"' then
                        field = field .. '"'  -- escaped double-quote
                        j = j + 2
                    else
                        j = j + 1
                        break
                    end
                else
                    field = field .. line:sub(j, j)
                    j = j + 1
                end
            end
            table.insert(fields, field)
            i = j
            if i <= len and line:sub(i, i) == ',' then i = i + 1 end
        else
            local j = line:find(',', i, true)
            if j then
                table.insert(fields, line:sub(i, j - 1))
                i = j + 1
            else
                table.insert(fields, line:sub(i))
                break
            end
        end
    end
    return fields
end
-----------------------------------------------------------------------------------------------

-- Reads the header row to extract the rule string (column F) and counts data rows.
local function read_csv_header(filepath)
    local file = io.open(filepath, "r")
    if not file then
        g.warn("Could not open file: " .. filepath)
        return "", 0
    end

    local header_line = file:read()
    local count = 0
    for line in file:lines() do
        if line:match("%S") then
            count = count + 1
        end
    end
    file:close()

    local fields = parse_csv_line(header_line or "")
    local rule = fields[6] or ""
    rule = rule:match("^%s*(.-)%s*$")  -- trim any surrounding whitespace
    return rule, count
end
-----------------------------------------------------------------------------------------------

-- Prompts the user to select a range of configurations using Excel row numbers.
-- Excel row 1 = header, Excel row 2 = first config (config index 1), etc.
local function get_range_selection(total_configs)
    local last_excel_row = total_configs + 1  -- last data row in Excel numbering

    local choice = g.getstring(
        "Total configurations found: " .. total_configs ..
        " (Excel rows 2–" .. last_excel_row .. ").\n" ..
        "Plot all configurations? (y/n)", "y")

    if choice:lower() == "y" then
        return 1, total_configs
    end

    local input = g.getstring(
        "Enter row range using Excel row numbers\n" ..
        "(e.g. '35-50' for a range, '42' for a single row):",
        "2-" .. last_excel_row)

    input = input:match("^%s*(.-)%s*$")  -- trim whitespace

    local start_excel, end_excel
    local a, b = input:match("^(%d+)%s*-%s*(%d+)$")
    if a and b then
        start_excel = tonumber(a)
        end_excel   = tonumber(b)
    else
        local single = input:match("^(%d+)$")
        if single then
            start_excel = tonumber(single)
            end_excel   = start_excel
        else
            g.warn("Invalid input. Plotting all configurations.")
            return 1, total_configs
        end
    end

    -- Convert from Excel row numbers to 1-based config indices (offset of -1)
    local start_config = start_excel - 1
    local end_config   = end_excel   - 1

    -- Clamp to valid range
    start_config = math.max(1, start_config)
    end_config   = math.min(total_configs, end_config)

    if start_config > end_config then
        g.warn("Invalid range. Plotting all configurations.")
        return 1, total_configs
    end

    return start_config, end_config
end
-----------------------------------------------------------------------------------------------

-- Prompt for and validate the file path
local filepath = get_valid_file_path()

-- Read rule from header (column F) and count total configurations
local rule, total_configs = read_csv_header(filepath)
g.show("Number of configurations found: " .. total_configs)

-- Prompt the user for the range of configurations to plot
local start_config, end_config = get_range_selection(total_configs)
-----------------------------------------------------------------------------------------------

-- Prompt user for grid name and create the grid
local grid_name = g.getstring("Enter the desired name for this grid:", "Initial Configurations")
g.new(grid_name)
local grid = g.getlayer()

-- Apply the rule from the CSV header if one was found
if rule ~= "" then
    g.setrule(rule)
    g.show("Rule set to: " .. rule)
end
-----------------------------------------------------------------------------------------------

-- Prompt user for spacing and layout
local spacing = tonumber(g.getstring("Enter the spacing of the configurations (center to center distance):", "100"))
local configs_per_row = tonumber(g.getstring("How many configurations per row?", "10"))
-----------------------------------------------------------------------------------------------

-- Function to draw filled circle
local function drawFilledCircle(cx, cy, r, state)
    -- Function to fill cells (live) in quadrants 1-4
    local function fillQuadrants(x, y)
        for dy = 0, y do
            g.setcell(cx + x, cy + dy, state)
            g.setcell(cx - x, cy + dy, state)
            g.setcell(cx + x, cy - dy, state)
            g.setcell(cx - x, cy - dy, state)
        end
        for dx = 0, x do
            g.setcell(cx + dx, cy + y, state)
            g.setcell(cx - dx, cy + y, state)
            g.setcell(cx + dx, cy - y, state)
            g.setcell(cx - dx, cy - y, state)
        end
    end

    local x, y, d = r, 0, 1 - r
    fillQuadrants(r, 0)
    fillQuadrants(0, r)

    while x > y do
        y = y + 1
        if d <= 0 then
            d = d + 2 * y + 1
        else
            x = x - 1
            d = d + 2 * y - 2 * x + 1
        end
        if x < y then break end
        fillQuadrants(x, y)
        fillQuadrants(y, x)
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to draw filled ellipse given center (cx,cy), major axis a, and minor axis b
local function drawFilledEllipse(cx, cy, a, b, state)
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
            g.setcell(cx + i, cy + y, state)
            g.setcell(cx + i, cy - y, state)
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
        for i = -x, x do
            g.setcell(cx + i, cy + y, state)
            g.setcell(cx + i, cy - y, state)
        end
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

-- Function to draw filled rectangle given center (cx, cy), length l, and width w
local function drawFilledRectangle(cx, cy, l, w, state)
    for dx = -math.floor(l / 2), math.ceil(l / 2) - 1 do
        for dy = -math.floor(w / 2), math.ceil(w / 2) - 1 do
            g.setcell(cx + dx, cy + dy, state)
        end
    end
    g.update()
end
-----------------------------------------------------------------------------------------------

-- Function to split a string by a delimiter
local function split_string(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
-----------------------------------------------------------------------------------------------

-- Function to handle drawing based on configuration in CSV file
local function handle_shape(config, x, y, state)
    local shape_live = config[1]
    local size_live = config[2]
    local y_setback = tonumber(config[3])
    local shape_dead = config[4]
    local size_dead = config[5]

    if y_setback == nil then
        g.warn("Invalid y_setback value in configuration. Please ensure proper header in CSV file... " .. table.concat(config, ", "))
        return
    end

    -- Draw the live shape
    if shape_live:upper() == "C" then -- Handle Circle
        drawFilledCircle(x, y, tonumber(size_live), state)
    elseif shape_live:upper() == "E" then -- Handle Ellipse
        local sizes = split_string(size_live, " ")
        drawFilledEllipse(x, y, tonumber(sizes[1]), tonumber(sizes[2]), state)
    elseif shape_live:upper() == "R" then -- Handle Rectangle
        local sizes = split_string(size_live, " ")
        drawFilledRectangle(x, y, tonumber(sizes[1]), tonumber(sizes[2]), state)
    end

    -- Draw the dead shape
    local dead_y = y + y_setback
    if shape_dead:upper() == "C" then -- Circle
        drawFilledCircle(x, dead_y, tonumber(size_dead), 0)
    elseif shape_dead:upper() == "E" then -- Ellipse
        local sizes = split_string(size_dead, " ") -- Split major and minor axis by identifying blank space
        drawFilledEllipse(x, dead_y, tonumber(sizes[1]), tonumber(sizes[2]), 0)
    elseif shape_dead:upper() == "R" then -- Rectangle
        local sizes = split_string(size_dead, " ")
        drawFilledRectangle(x, dead_y, tonumber(sizes[1]), tonumber(sizes[2]), 0)
    end
end
-----------------------------------------------------------------------------------------------

-- Loop through each configuration line in the CSV file
-- config_idx tracks the 1-based index of the current data row (header already excluded)
local current_x, current_y = 0, 0
local plot_count = 0   -- how many configs have been drawn so far (for layout)
local config_idx = 0   -- 1-based index into data rows

for line in io.lines(filepath) do
    if config_idx == 0 then
        config_idx = 1  -- first iteration is the header row; skip it
    else
        if config_idx >= start_config and config_idx <= end_config then
            local config = split_string(line, ",")
            if #config >= 5 then
                handle_shape(config, current_x, current_y, 1)

                -- Advance grid position based on how many have been plotted
                plot_count = plot_count + 1
                if plot_count % configs_per_row == 0 then
                    current_x = 0
                    current_y = current_y + spacing
                else
                    current_x = current_x + spacing
                end
            else
                g.warn("Invalid configuration format in CSV line: " .. line)
                break
            end
        end

        if config_idx >= end_config then break end
        config_idx = config_idx + 1
    end
end

g.note("Configurations have been successfully placed on the grid.")
g.update()
