-- FOR MODDERS: Custom pieces start at line 237
PieceType = {}

local function loadImage(piece)
    if piece.imagePath then
        piece.image = love.graphics.newImage(piece.imagePath)
    else
        piece.image = love.graphics.newImage('assets/pawn.png')
    end
end

-- Pawn
PieceType.Pawn = {
    ingame_desc = {
        name = 'Pawn',
        desc = {
            'Move forward 1',
            'Capture diagonally'
        }
    },
    pieceval = 1,
    imagePath = 'assets/pawn.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        local direction = piece.color == "white" and 1 or -1
        if desty == selfy + direction and destx == selfx and not capturing then
            return true
        elseif capturing then
            if (destx == selfx + 1 or destx == selfx - 1) and desty == selfy + direction then
                return true
            end
        end
        return false
    end
}

-- Rook
PieceType.Rook = {
    ingame_desc = {
        name = 'Rook',
        desc = {'Move vertically or horizontally'}
    },
    imagePath = 'assets/rook.png',
    pieceval = 8,
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        if selfx == destx then
            local step = desty > selfy and 1 or -1
            for y = selfy + step, desty - step, step do
                if boarda[selfx][y] then return false end
            end
            return true
        elseif selfy == desty then
            local step = destx > selfx and 1 or -1
            for x = selfx + step, destx - step, step do
                if boarda[x][selfy] then return false end
            end
            return true
        end
        return false
    end
}

-- Bishop
PieceType.Bishop = {
    ingame_desc = {
        name = 'Bishop',
        desc = {'Move diagonally'}
    },
    pieceval = 4,
    imagePath = "assets/bishop.png",
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if math.abs(destx - selfx) ~= math.abs(desty - selfy) then return false end
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        local stepX = destx > selfx and 1 or -1
        local stepY = desty > selfy and 1 or -1
        local x, y = selfx + stepX, selfy + stepY
        while x ~= destx and y ~= desty do
            if board[x][y] then return false end
            x = x + stepX
            y = y + stepY
        end
        return true
    end
}

PieceType.Archer = {
    ingame_desc = {
        name = "Archer",
        desc = {
            "Move diagonally,",
            "can jump over pieces"
        }
    },
    pieceval = 5,
    imagePath = 'assets/archer.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        if math.abs(destx-selfx) == math.abs(desty-selfy) then
            return true
        end
    end
}
-- Knight
PieceType.Knight = {
    ingame_desc = {
        name = 'Knight',
        desc = {'Move in an L shape: 2 in one', 'direction then 1 perpendicular'}
    },
    pieceval = 2,
    imagePath = 'assets/knight.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        local dx = math.abs(destx - selfx)
        local dy = math.abs(desty - selfy)
        return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)
    end
}

-- Queen
PieceType.Queen = {
    ingame_desc = {
        name = 'Queen',
        desc = {'Move horizontally, vertically,', 'and diagonally'}
    },
    pieceval = 16,
    imagePath = 'assets/queen.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        -- Diagonal
        if math.abs(destx - selfx) == math.abs(desty - selfy) then
            local stepX = destx > selfx and 1 or -1
            local stepY = desty > selfy and 1 or -1
            local x, y = selfx + stepX, selfy + stepY
            while x ~= destx and y ~= desty do
                if boarda[x][y] then return false end
                x = x + stepX
                y = y + stepY
            end
            return true
        -- Horizontal or vertical
        elseif selfx == destx then
            local step = desty > selfy and 1 or -1
            for y = selfy + step, desty - step, step do
                if boarda[selfx][y] then return false end
            end
            return true
        elseif selfy == desty then
            local step = destx > selfx and 1 or -1
            for x = selfx + step, destx - step, step do
                if boarda[x][selfy] then return false end
            end
            return true
        end
        return false
    end
}
PieceType.Pope = {
    ingame_desc = {
        name = "Pope",
        desc = {
            "Moves diagonally and",
            "vertically, can jump over",
            "pieces diagonally"
        }
    },
    move = function(piece, selfx, selfy, destx, desty, capturing, board)
        if capturing and board[destx][desty] and board[destx][desty].color == 'barrier' then return false end
        if selfx == destx then
            local step = desty > selfy and 1 or -1
            for y = selfy + step, desty - step, step do
                if board[selfx][y] then return false end
            end
            return true
        elseif math.abs(destx - selfx) == math.abs(desty - selfy) then
            return true
        end
        return false
    end
}
PieceType.Cannon = {
    ingame_desc = {
        name = "Cannon",
        desc = {
            "Can move anywhere 3",
            "pieces away, can jump"
        }
    },
    pieceval = 12,
    imagePath = 'assets/cannon.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if capturing and boarda[destx][desty] and boarda[destx][desty].color == 'barrier' then return false end
        if math.abs(destx - selfx) == 3 or math.abs(desty - selfy) == 3 then
            if math.abs(destx - selfx) < 4 and math.abs(desty - selfy) < 4 then
                if not capturing and not boarda[destx][desty] then return true end
                if capturing then return true end
            end
        end
        return false
    end
}
PieceType.iKing = {
    ingame_desc = { name = "Immobile King", desc = {'Cannot be moved.'} },
    imagePath = 'assets/immobileking.png',
    move = function() return false end -- optional; only used by your own move validation
}

PieceType.mKing = {
    ingame_desc = { name = "King", desc = {'Can move 1 space in any direction'}},
    imagePath = 'assets/king.png',
    move = function(piece, selfx, selfy, destx, desty, capturing, boarda)
        if destx <= selfx + 1 and destx >= selfx - 1 then
            if desty <= selfy + 1 and desty >= selfy - 1 then
                if (not capturing) or (boarda[destx][desty] and boarda[destx][desty].color ~= piece.color) then
                   return true 
                end
            end
        end
        return false
    end
}
PieceType.Catalyst = {
    ingame_desc = { name = "Catalyst", desc = {'Can be combined to make a', 'Legendary piece'}},
    imagePath = 'assets/catalyst.png',
    move = function()
        return false
    end
}
PieceType.Barrier = {
    ingame_desc = { name = 'Barrier', desc = {'Cannot be moved or captured'}},
    imagePath = 'assets/idk.png',
    move = function()
        return false
    end
}
--DO NOT EDIT ANYTHING ABOVE THIS LINE

--Example Piece
PieceType.Epic = {
    ingame_desc = {
        name = "Epic Piece",
        desc = {
            "Is epic, can move anywhere"
        }
    },
    move = function() return true end
}






--DO NOT EDIT ANYTHING BELOW THIS LINE
function loadPieceImages()
    for _, piece in pairs(PieceType) do
        loadImage(piece)
    end
end

return PieceType
