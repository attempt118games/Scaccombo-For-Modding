--------DO NOT EDIT THESE LINES--------
local BossModifiers = require "boss_modifiers"
----Lines below this  can be edited----

--Example Shop Items
Mods.ShopDefine{
    id = "thatsalotoftoken",
    name = "Like, a lot of piece tokens",
    description = "Gives 1,000 Piece Tokens.",
    cost = 1,
    rarity = 1,
    multiBuy = true,
    unlocked = true,
    effect = function()
        Piecetokens = Piecetokens + 1000
    end
}
Mods.ShopDefine{
    id = "waytoooverpowered",
    name = "Very Swag Blueprint",
    description = "Gives a very swag blueprint",
    cost = 5,
    rarity = 1,
    multiBuy = false,
    unlocked = true,
    effect = function()
        Blueprint.unlock("Very cool piece")
    end
}

--Example Blueprint (Put piece definitions in pieces.lua)
Blueprint.Type{
    name = "Very cool piece",
    inputs = {'Pawn', 'Knight'},
    result = PieceType.Epic,
    resultType = PieceType.Epic
}

--Example Boss
BossModifiers.define{
    id = "very-bonklers",
    name = "lol",
    description = "Screw early game all my homies [Unlock Row 4 (100 Mat.)]",
    disablePieces = {"Pawn", "Knight", "Bishop"},
}