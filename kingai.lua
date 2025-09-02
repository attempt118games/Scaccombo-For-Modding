-- blackking.lua
local pieces = require('pieces')
local BlackKing = {}
-- Directions a king can move
local directions = {
    {-1, -1}, {-1, 0}, {-1, 1},
    {0, -1},          {0, 1},
    {1, -1},  {1, 0}, {1, 1}
}
local KingAbilities = require('kingabilities')
-- Find the black king on the board
-- Find the black king on the board
-- Find the black king on the board
-- Find the black king
function findBlackKing()
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = board[row][col]
            if piece and piece.color == "black" and piece.type == _G.currentKingType then
                return row, col, piece
            end
        end
    end
    return nil
end
local function isSquareAttacked(a, b, col)
    for x=1,8 do
        for y=1,8 do
            if board[x][y] and board[x][y].color == col then
                local piece = board[x][y]
                if piece.type.move(piece, x, y, a, b, true, board) then
                    print('Error! Square is attacked by ' .. piece.type.ingame_desc.name)
                    return true
                end
            end
        end
    end
    return false
end
local function evalKingMoves(king, row, col)
    local moves = {}
    for x=1,8 do
        for y=1,8 do
            if king.type.move(king, row, col, x, y, false, board) then
                if not king.type.move(king, row, col, x, y, true, board) then
                    table.insert(moves, {x, y})
                end
            elseif king.type.move(king, row, col, x, y, true, board) then
                if KingAbilities.active['the_original'] == true then
                    table.insert(moves, {x, y})
                    print("piece at " .. x .. ", " .. y .. " can be captured")
                end
            end
        end
    end
    return moves
end
-- Generate all legal moves for black king
local function getLegalKingMoves(x, y, king)
    local moves = {}
    local candidateMoves = evalKingMoves(king, x, y)
    if not candidateMoves then return moves end

    print("Candidate moves for king at", x, y)

    for _, move in ipairs(candidateMoves) do
        local tx, ty = move[1], move[2]

        if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
            local target = board[tx][ty]
            if not target or target.color ~= king.color then
                -- temporarily remove king
                local saved = board[x][y]
                board[x][y] = nil

                local attacked = isSquareAttacked(tx, ty, "white")

                board[x][y] = saved -- restore king

                if not attacked then
                    table.insert(moves, {tx, ty})
                end
            end
        end
    end
    return moves
end



-- Actually move the king
function moveBlackKing()
    local row, col, king = findBlackKing()
    if not king then
        if InTutorial and TutorialState == 2 then
            TutorialState = 3
            gamestate = 'wontutorial'
        else
            gamestate = 'kingcapture'
        end
        return
    end
    local legalMoves = getLegalKingMoves(row, col, king)

    if #legalMoves > 0 then
        local choice = legalMoves[math.random(1, #legalMoves)]

        -- move piece
        board[choice[1]][choice[2]] = king
        board[row][col] = nil

        print("Black king moved to", choice[1], choice[2])
    else
        print("Black king has no legal moves!")
        if isSquareAttacked(row, col, 'white') then
            if InTutorial and TutorialState == 2 then
                TutorialState = 3
                gamestate = 'wontutorial'
            else
                gamestate = 'woncheck'
            end
        else
            if InTutorial and TutorialState == 2 then
                TutorialState = 3
                gamestate = 'wontutorial'
            else
                gamestate = 'wonstale'
            end
        end
    end
end




return BlackKing