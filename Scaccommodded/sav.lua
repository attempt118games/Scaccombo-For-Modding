-- sav.lua
-- Save / Load system for game state

GameState = {
    currentRound = 1,
    board = {},
    turnsLeft = 0,
    unlockedBlueprints = {},
    unlockedRecipes = {},
    startingBoard = {},
    boughtSingleItems = {},
    materials = 0,
    tokens = 0,
}

-- Simple table serializer
local function tableToString(tbl, indent)
    indent = indent or ""
    local str = "{\n"
    local nextIndent = indent .. "  "
    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q] = ", k)
        else
            key = string.format("[%d] = ", k)
        end

        if type(v) == "table" then
            str = str .. nextIndent .. key .. tableToString(v, nextIndent) .. ",\n"
        elseif type(v) == "string" then
            str = str .. nextIndent .. key .. string.format("%q", v) .. ",\n"
        else
            str = str .. nextIndent .. key .. tostring(v) .. ",\n"
        end
    end
    str = str .. indent .. "}"
    return str
end

-- Save current GameState to save.lua
function saveGame()
    local data = "return " .. tableToString(GameState)
    love.filesystem.write("save.lua", data)
end

-- Load save.lua if it exists
function loadGame()
    if love.filesystem.getInfo("save.lua") then
        local chunk = love.filesystem.load("save.lua")
        if chunk then
            GameState = chunk()
        end
    end
end

-- Utility: add blueprint only if not already unlocked
function saveunlockBlueprint(name)
    for _, bp in ipairs(GameState.unlockedBlueprints) do
        if bp == name then
            return false -- already unlocked
        end
    end
    table.insert(GameState.unlockedBlueprints, name)
    return true
end
