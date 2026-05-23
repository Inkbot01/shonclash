--!strict
-- Dedupes sibling Instance names in a Roblox .rbxl so Rojo syncback can map
-- the tree onto a filesystem (which can't have two files of the same name in
-- one directory). First occurrence of a name keeps its name; subsequent ones
-- get a `_2`, `_3`, ... suffix. Suffixes that would collide are skipped.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args
local inputPath = args[1] or (process.env.HOME .. "/Documents/shonclash.rbxl")
local outputPath = args[2] or (process.env.HOME .. "/Documents/shonclash-deduped.rbxl")

print(string.format("Reading: %s", inputPath))
local data = fs.readFile(inputPath)
local game = roblox.deserializePlace(data)

local renamed = 0
local sanitized = 0
local visited = 0

-- Filesystem-illegal characters on macOS/Linux/Windows + control chars.
local function sanitizeName(name: string): string
    local cleaned = string.gsub(name, "[/\\:*?\"<>|%c]", "_")
    -- Trim trailing dots/spaces (Windows is strict; harmless elsewhere).
    cleaned = string.gsub(cleaned, "[%.%s]+$", "")
    if cleaned == "" or cleaned == "." or cleaned == ".." then
        cleaned = "_"
    end
    return cleaned
end

local function dedupe(parent: Instance)
    local children = parent:GetChildren()
    -- First: sanitize any filesystem-illegal characters in names.
    for _, child in children do
        local safe = sanitizeName(child.Name)
        if safe ~= child.Name then
            child.Name = safe
            sanitized += 1
        end
    end
    local taken: { [string]: boolean } = {}
    -- Then record existing names (so suffix bumps don't collide).
    for _, child in children do
        taken[child.Name] = true
    end
    -- Second pass: rename anything seen-before within this parent.
    local seen: { [string]: number } = {}
    for _, child in children do
        local name = child.Name
        if seen[name] then
            local base = name
            local n = seen[name] + 1
            local candidate
            repeat
                candidate = string.format("%s_%d", base, n)
                n += 1
            until not taken[candidate]
            child.Name = candidate
            taken[candidate] = true
            seen[base] = n - 1
            seen[candidate] = 1
            renamed += 1
        else
            seen[name] = 1
        end
    end
    for _, child in children do
        visited += 1
        dedupe(child)
    end
end

dedupe(game)

print(string.format("Visited %d instances, sanitized %d names, renamed %d duplicates.", visited, sanitized, renamed))
print(string.format("Writing: %s", outputPath))
fs.writeFile(outputPath, roblox.serializePlace(game))
print("Done.")
