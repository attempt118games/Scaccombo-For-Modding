-- boss_modifiers.lua
local BossModifiers = {}
local pieces = require('pieces')
local KingAbilities = require('kingabilities')
BossModifiers.defs = {}
BossModifiers.active = nil
BossModifiers.seed = os.time()
BossModifiers.prevmods = {}
local bosslength = 0
-- Define a modifier
function primeMods()
    for i, _ in pairs(BossModifiers.defs) do
        BossModifiers.prevmods[i] = false
        bosslength = bosslength + 1
    end
end
function BossModifiers.define(def)
    assert(def.id, "Modifier must have an id")
    def.name = def.name or "Unnamed Modifier"
    def.description = def.description or "No description"
    def.disablePieces = def.disablePieces or {}
    def.turnLimit = def.turnLimit or 30
    def.kingType = def.kingType or pieces.mKing
    def.combineLimit = def.combineLimit
    def.combinesReset = def.combinesReset
    def.minRound = def.minRound or -100
    def.effect = def.effect or function() end
    BossModifiers.defs[def.id] = def
    return def
end
function resetModifiers()
    for i, _ in pairs(pieces) do
        disabledPieceTypes[i] = false
    end
    combineAmount = 1
    combinesResetEveryTurn = true
    _G.currentKingType = pieces.mKing
    if KingAbilities.active['waytoofast'] == true then
        turns = 25
    else
        turns = 30
    end
end
-- Apply modifier
function BossModifiers.apply(modifierId)
    local mod = BossModifiers.defs[modifierId]
    if not mod then return false end
    BossModifiers.active = mod

    -- Disable pieces
    for _, typeName in ipairs(mod.disablePieces) do
        disabledPieceTypes[typeName] = true
    end

    -- Limit combine uses
    combineAmount = mod.combineLimit or 1
    -- King type
    _G.currentKingType = mod.kingType or pieces.mKing

    -- Turn limit
    turns = mod.turnLimit or turns

    -- Combines reset
    if mod.combinesReset ~= nil then
        combinesResetEveryTurn = false
    else
        combinesResetEveryTurn = true
    end

    -- Custom effect
    mod.effect()

    return true
end

-- Choose a random modifier every 5 rounds
function BossModifiers.randomModifier(currentRound, seedb)
    if currentRound % 5 ~= 0 then resetModifiers() return nil end

    local keys = {}
    for k, _ in pairs(BossModifiers.defs) do table.insert(keys, k) end
    local choice = keys[math.random(#keys)]
    BossModifiers.apply(choice)
    return choice
end
local function checkValidity(ID)
    for _, bm in pairs(BossModifiers.defs) do
        if bm.id == ID then return true end
    end
    return false
end
function BossModifiers.getRandomID(roundnum)
    local keys = {}
    for k, _ in pairs(BossModifiers.defs) do
        table.insert(keys, k)
    end

    local didbosses = 0
    for i, _ in pairs(BossModifiers.prevmods) do
        if BossModifiers.prevmods[i] == true then
            didbosses = didbosses + 1
        end
    end

    if didbosses == bosslength then
        BossModifiers.prevmods = {}
        print("That's all, folks! Boss Mods reset")
    end

    local choice
    repeat
        choice = keys[math.random(1, #keys)]
    until checkValidity(choice)  -- use correct round var
       and not BossModifiers.prevmods[choice]

    BossModifiers.prevmods[choice] = true
    return choice
end
function BossModifiers.getBossRounds(id)
    for _, boss in pairs(BossModifiers.defs) do
        if boss.id == id then
            return boss.minRound
        end
    end
end
function BossModifiers.getBossName(id)
    for _, boss in pairs(BossModifiers.defs) do
        if boss.id == id then
            return boss.name
        end
    end
end
-------------------------------------------------
-- Example modifiers
-------------------------------------------------
BossModifiers.define{
    id = "no_pawns",
    name = "High Society",
    description = "Pawns cannot be moved or combined this round.",
    disablePieces = {"Pawn"},
    minRound = 5
}
BossModifiers.define{
    id = "no_lines",
    name = "Line",
    description = "No bishops, rooks, or queens.",
    disablePieces = {"Bishop", "Rook", "Queen"},
    minRound = 5
}
BossModifiers.define{
    id = "no_knights",
    name = "Cavalry",
    description = "Knights cannot be moved or combined this round.",
    disablePieces = {"Knight"},
    minRound = 10
}
BossModifiers.define{
    id = "hmm",
    name = "Tight Timing",
    description = "5 turns this round, 7 combines per move.",
    turnLimit = 5,
    combineLimit = 7
}
BossModifiers.define{
    id = "nope",
    name = "Apprentice",
    description = "5 combines. Combines do not refresh per turn.",
    combinesReset = false,
    combineLimit = 5
}
BossModifiers.define{
    id = "cap",
    name = "10-10",
    description = "10 turns this round, 10 combines. Combines do not refresh per turn.",
    turnLimit = 10,
    combinesReset = false,
    combineLimit = 10
}

BossModifiers.define{
    id = 'classico',
    name = "Classical",
    description = "No non-traditional chess pieces.",
    minRound = 10,
    disablePieces = {'Archer', 'Cannon'}
}

BossModifiers.define{
    id = 'restart',
    name = "Restart",
    description = "All starting pieces are pawns.",
    minRound = 10
}
BossModifiers.define{
    id = 'bonkydonk',
    name = "Bonkers",
    description = "Everything except for pawns is debuffed, 75 turns. No combines.",
    minRound = 25,
    disablePieces = {'Knight', 'Bishop', 'Archer', 'Rook', 'Cannon', 'Queen'},
    turnLimit = 75,
    combineLimit = 0
}
BossModifiers.define{
    id = 'slipking',
    name = "Slippery King",
    description = "Opponent gets 2 moves per turn.",
    minRound = 5
}
BossModifiers.define{
    id = 'soniceconomiccrisis',
    name = "Inflation",
    description = "The 5 shops after this boss have X5 item prices."
}
BossModifiers.define{
    id = 'whatamess',
    name = "Clutter",
    description = "Barriers are randomly scattered throughout the board."
}
BossModifiers.define{
    id = 'nopoliticalimplications',
    name = "Wall",
    description = "All but one random square in row 5 is blocked by Barriers."
}
return BossModifiers