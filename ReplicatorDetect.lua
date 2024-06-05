-- Detect a single replicator on the grid
-- Utilizing clusters with hashing to detect the copy of a pattern seen at some previous time step

local g = golly()

-- A function to find clusters of connected cells
local function find_clusters()
    local all_cells = g.getcells(g.getrect())
    local clusters = {}
    local visited = {}

    -- Helper function to check if a cell is live
    local function is_live(x, y)
        for i = 1, #all_cells, 2 do
            if all_cells[i] == x and all_cells[i + 1] == y then
                return true
            end
        end
        return false
    end

    -- Depth-first search to find connected component
    local function dfs(x, y, cluster)
        local stack = {{x, y}}
        while #stack > 0 do
            local pos = table.remove(stack)
            local cx, cy = pos[1], pos[2]
            local key = cx .. "," .. cy
            if not visited[key] and is_live(cx, cy) then
                visited[key] = true
                table.insert(cluster, cx)
                table.insert(cluster, cy)

                -- Push neighboring cells to stack
                stack[#stack + 1] = {cx + 1, cy}
                stack[#stack + 1] = {cx - 1, cy}
                stack[#stack + 1] = {cx, cy + 1}
                stack[#stack + 1] = {cx, cy - 1}
            end
        end
    end

    -- Find all clusters on grid
    for i = 1, #all_cells, 2 do
        local x, y = all_cells[i], all_cells[i + 1]
        if not visited[x .. "," .. y] and is_live(x, y) then
            local new_cluster = {}
            dfs(x, y, new_cluster)
            if #new_cluster > 0 then
                clusters[#clusters + 1] = new_cluster
            end
        end
    end
    return clusters
end



-- Track configurations and detect replicators
local function detect_replicators()
    local clusters = find_clusters()
    local hashes = {}


    for i, cluster in ipairs(clusters) do
        local rect = g.getrect(cluster)
        local hash_val = g.hash(rect)
        if hashes[hash_val] then
            g.show("Possible replicator detected!")
            return true
        end
        hashes[hash_val] = true
    end

    return false
end


-- Main simulation loop for 'gen' generations
for gen = 1, 100 do
    g.run(1)  -- Advance one generation
    if detect_replicators() then break end
end

g.show("Simulation complete - No replicator detected within 100 generations.")
