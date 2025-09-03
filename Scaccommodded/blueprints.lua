Blueprint = { defs = {} }
local pieces = require('pieces')
function Blueprint.Type(def)
    assert(def.name, "Blueprint must have a name")
    assert(def.inputs, "Blueprint must have input pieces")
    assert(type(def.result) == "table" and def.result, "Invalid PieceType")
    def.name = def.name or "error"
    def.unlocked = def.unlocked_default or false
    def.discovered = false
    def.unlocks = def.unlocks or {}
    def.path = def.path or 'assets/idk.png'
    Blueprint.defs[def.name] = def
    return def
end
Blueprint.Type{
    name = "Knight",
    inputs = { "Pawn", "Pawn" },
    result = pieces.Knight,
    path = 'assets/knight.png',
    resultType = PieceType.Knight,
    unlocked_default = true,
}
Blueprint.Type{
    name = "Bishop",
    inputs = { "Knight", "Knight" },
    result = pieces.Bishop,
    resultType = PieceType.Bishop,
    path = 'assets/bishop.png',
}
Blueprint.Type{
    name = "Archer",
    inputs = { "Bishop", "Pawn" },
    result = pieces.Archer,
    resultType = PieceType.Archer,
    path = 'assets/archer.png',
}
Blueprint.Type{
    name = "Rook",
    inputs = { "Bishop", "Bishop" },
    result = pieces.Rook,
    path = 'assets/rook.png',
    resultType = PieceType.Rook,
}
Blueprint.Type{
    name = "Cannon",
    inputs = { "Rook", "Bishop" },
    result = pieces.Cannon,
    path = 'assets/cannon.png',
    resultType = PieceType.Cannon,
}
Blueprint.Type{
    name = "Queen",
    inputs = { "Rook", "Rook" },
    result = pieces.Queen,
    path = 'assets/queen.png',
    resultType = PieceType.Queen
}

function Blueprint.findResult(pieceA, pieceB)
    for name, bp in pairs(Blueprint.defs) do
        -- skip locked blueprints if requested
        if bp.unlocked then
            local inputs = bp.inputs
            if #inputs == 2 then
                local p1Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]
                local p2Match = pieceB.type.ingame_desc.name == inputs[1] and pieceA.type.ingame_desc.name == inputs[2]

                if p1Match or p2Match then
                    return bp.result
                end
            end
        end
        ::continue::
    end
    return nil
end
function Blueprint.unlock(nameunlock)
    for nameb, bp in pairs(Blueprint.defs) do
        if bp.name == nameunlock then
            bp.unlocked = true
            bp.discovered = true
        end
    end
end

function Blueprint.findType(pieceA, pieceB, onlyUnlocked)
    if not pieceA or not pieceB then return nil end
    for name, bp in pairs(Blueprint.defs) do
        -- skip locked blueprints if requested
        if bp.unlocked then
            local inputs = bp.inputs
            if #inputs == 2 then
                local p1Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]
                local p2Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]

                if p1Match or p2Match then
                    if bp.unlocked then
                        return bp.path
                    end
                end
            end
        end

        ::continue::
    end
    return nil
end
function Blueprint.findImage(pieceA, pieceB)
    for name, bp in pairs(Blueprint.defs) do
        local inputs = bp.inputs
        if #inputs == 2 then
            local p1Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]
            local p2Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]

            if p1Match or p2Match then
                img = bp.path
                if bp.discovered then
                    return love.graphics.newImage(img)
                end
            end
        end
    end
end
return Blueprint