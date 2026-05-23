--!strict
-- Adds/merges `ignoreUnknownInstances: true` into:
--   - <dir>/init.meta.json for every directory under src/
--   - <basename>.meta.json next to every .luau/.lua (except init.*)
-- Existing meta.json files are preserved (other keys kept, the flag is merged in).

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function mergeMeta(metaPath: string)
    local content: { [string]: any }
    if fs.isFile(metaPath) then
        content = serde.decode("json", fs.readFile(metaPath))
    else
        content = {}
    end
    content.ignoreUnknownInstances = true
    fs.writeFile(metaPath, serde.encode("json", content, true))
end

local function scriptBaseName(filename: string): string?
    local b = string.match(filename, "^(.+)%.server%.luau?$")
    if b then return b end
    b = string.match(filename, "^(.+)%.client%.luau?$")
    if b then return b end
    return string.match(filename, "^(.+)%.luau?$")
end

local dirsTouched, scriptMetas = 0, 0

local function walk(dir: string)
    mergeMeta(dir .. "/init.meta.json")
    dirsTouched += 1
    for _, entry in fs.readDir(dir) do
        local full = dir .. "/" .. entry
        if fs.isDir(full) then
            walk(full)
        elseif fs.isFile(full) and not string.match(entry, "^init%.") then
            local base = scriptBaseName(entry)
            if base then
                mergeMeta(dir .. "/" .. base .. ".meta.json")
                scriptMetas += 1
            end
        end
    end
end

walk("src")
print(string.format("Touched %d dirs (init.meta.json) and %d script meta files", dirsTouched, scriptMetas))
