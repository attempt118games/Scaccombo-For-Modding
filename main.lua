
local BlackKing = require("kingai")
local TILE = 64
board = {}  -- global board (x=1..8, y=1..8)
startingboard = {}
local dragging = false
local draggedPiece = nil
local dragStartX, dragStartY = nil, nil
local mouseX, mouseY = 0, 0
local photonegativeShader
ModLoader = require('modloader')
material = 0
TutorialState = 1
GameVolume = 1
function changevolume()
    if GameVolume > 0.75 then
        GameVolume = 0.75
    elseif GameVolume > 0.5 then
        GameVolume = 0.5
    elseif GameVolume > 0.25 then
        GameVolume = 0.25
    elseif GameVolume > 0 then
        GameVolume = 0
    elseif GameVolume < 0.01 then
        GameVolume = 1
    end
end
local BossModifiers
local validMoves = nil
local KingAbilities = require('kingabilities')
local Music = require("music")
local blueprints
local menu = require('menu')
local settings = require('settings')
local settingspage = require('settingspage')
local selectedRecipe = "Pawn"  -- default piece to place
local selectedPieceForDelete = nil
local saveFile = 'settings.lua'
local shaders = {}
local rockhard
local VIRTUAL_WIDTH = 800
local VIRTUAL_HEIGHT = 600
local canvas
local scale, offsetX, offsetY
disabledPieceTypes = {}
pieceCosts = {
    Pawn   = { place = 1,  sell = 1 },
    Knight = { place = 2,  sell = 1 },
    Bishop = { place = 4,  sell = 2 },
    Archer = { place = 4,  sell = 2 },
    Rook   = { place = 8,  sell = 4 },
    Cannon = { place = 8,  sell = 4 },
    Queen  = { place = 16, sell = 8 },
}
-- iterate over all blueprints just like you’d do with pieces
material = 0
Piecetokens = 0
-- Turn system
local currentTurn = "white"
local TutorialText = {
    [1] = "Craft a Knight (move pawns to the Combine slots)",
    [2] = "Checkmate/Stalemate/Capture the Black King",
    [3] = "Collect your materials",
    [4] = "Buy the Knight Recipe, Bishop Blueprint, and Piece Tokens",
    [5] = "Enter the Board Editor",
    [6] = "Sell a Pawn (get 1 token)",
    [7] = 'Select "Knight" in the Palette',
    [8] = "Click on the empty space (place a knight, costs 2 tokens)",
    [9] = "Finish Editing and Begin Round 2",
    [10] = "Create a Bishop (click See Blueprints to look at avaliable blueprints)"
}
-- Combine system (kept as-is, minus small fixes)
local combineSlots = {nil, nil}
local combineButton = {x=600, y=100, w=120, h=40}
-- Converts a number into a human-readable seed string
local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function numberToSeedString(num, length)
    local str = {}
    length = length or 8  -- default seed length
    for i = 1, length do
        local index = (num % #charset) + 1
        str[i] = charset:sub(index, index)
        num = math.floor(num / #charset)
    end
    -- add a dash every 4 chars for readability
    return table.concat(str):gsub("(%w%w%w%w)", "%1-"):gsub("-$", "")
end

-- Converts a string seed back into a number (for math.randomseed)
function seedStringToNumber(seedStr)
    seedStr = seedStr:gsub("-", "") -- remove dashes
    local num = 0
    for i = 1, #seedStr do
        local c = seedStr:sub(i,i)
        local pos = charset:find(c, 1, true)
        if pos then
            num = num * #charset + (pos-1)
        end
    end
    return num
end

-- Example usage:
local function generateSeed(userInput)
    local numSeed
    if userInput and userInput ~= "" then
        -- Use player-provided seed string
        numSeed = seedStringToNumber(userInput)
    else
        -- Use random os.time seed
        numSeed = os.time()
    end
    math.randomseed(numSeed)
    return numberToSeedString(numSeed, 8)
end
-- Map type name -> FEN letter
local fenMap = {
    Pawn   = "P",
    Knight = "N",
    Bishop = "B",
    Rook   = "R",
    Queen  = "Q",
    King   = "K",   -- if you add King to pieces.lua later, this will work automatically
}

-- Preview helper
-- Compute valid moves (respects "fromCombine" one-spot return rule)
local function computeValidMoves(board, piece, sx, sy)
    if piece.fromCombine then
        return {{x=piece.ogX, y=piece.ogY, capture=false}}
    end
    local moves = {}
    for x=1,8 do
        for y=1,8 do
            if not (x==sx and y==sy) then
                local target = board[x][y]
                local isCapture = target~=nil and target.color~=piece.color
                if target==nil or isCapture then
                    if piece.type and piece.type.move then
                        if piece.type.move(piece, sx, sy, x, y, isCapture, board) then
                            table.insert(moves, {x=x,y=y,capture=isCapture})
                        end
                    end
                end
            end
        end
    end
    return moves
end
turns = 30
local unusedCombines = 0
local function resetGame()
    gamestate = 'playinground'
    for y=1,4 do
        for x=1,8 do
            board[x][y] = startingboard[x][y]
        end
    end
    turns = 30
    unusedCombines = 0
    combinedAlready = 0
    currentTurn = 'white'
end

function love.resize(w, h)
    updateScale()
end

function updateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local virtualHeight = VIRTUAL_HEIGHT
    local virtualWidth = VIRTUAL_WIDTH
    local scaleX = windowWidth / virtualHeight
    local scaleY = windowHeight / virtualHeight
    scale = math.min(scaleX, scaleY)

    offsetX = (windowWidth - virtualWidth * scale) / 2
    offsetY = (windowHeight - virtualHeight * scale) / 2
end
local alias
-- Start-up
local settings = require("settings")
local saveFile = "settings.lua"  -- this will be in the save directory
currentShader = settings.shader or 1
-- Save settings as Lua code
function saveSettings()
    local data = "return {\n"
    for k, v in pairs(settings) do
        local value
        if type(v) == "boolean" then
            value = tostring(v) -- "true" or "false"
        elseif type(v) == "number" then
            value = tostring(v) -- numbers as-is
        elseif type(v) == "string" then
            value = string.format("%q", v) -- quoted string with escapes
        else
            -- fallback: serialize with tostring
            value = string.format("%q", tostring(v))
        end

        data = data .. string.format("    %s = %s,\n", k, value)
    end
    data = data .. "}"
    love.filesystem.write(saveFile, data)
end
function swapAA()
    settings.aa = not settings.aa
end
-- Load settings if file exists
local function loadSettings()
    if love.filesystem.getInfo(saveFile) then
        local chunk = love.filesystem.load(saveFile)
        local ok, saved = pcall(chunk)
        if ok and type(saved) == "table" then
            settings = saved
        end
    end
end
local Shop
-- Prices for unlocking rows (2, 3, 4)
local rowUnlockPrices = {
    [2] = 50,   -- price in material to unlock row 2
    [3] = 75,  -- price to unlock row 3
    [4] = 100,  -- price to unlock row 4
}

-- Track how many rows are unlocked
local startingslotsunlocked = 1
-- Editor state
local editingDragging = false
local editingDraggedPiece = nil
local editingDragX, editingDragY = nil, nil
combinesResetEveryTurn = true
gamestate = 'loading'
Currentround = 0
local shopInventory = {}
function waitTime(seconds, callback)
    local timer = {
        t = 0,
        limit = seconds,
        done = false,
        callback = callback
    }

    -- update each frame
    function timer:update(dt)
        if not self.done then
            self.t = self.t + dt
            if self.t >= self.limit then
                self.done = true
                if self.callback then self.callback() end
            end
        end
    end

    return timer
end
local myTimer
function love.load(args)
    loadSettings()
    InTutorial = settings.tutorial ~= nil and settings.tutorial or true
    if settings.tutorial == nil then
        settings.tutorial = true
        saveSettings()
        love.event.quit("restart")
    end
    InTutorial = settings.tutorial
    print(settings.tutorial)
    Music.load()
    pieces = require('pieces')
    loadMods()
    PrimeKingAbilities()
    pieces = require('pieces')
    loadPieceImages()
    BossModifiers = require('boss_modifiers')
    primeMods()
    Shop = require("shop")
    Recipes = require('recipes')
    Blueprint = require('blueprints')
    shouldrerollboss = true
    Currentround = 0
    nextroundBossName = "empty"
    nextroundBossDesc = "nothing here"
    combineAmount = 1
    if args[1] then
        seed = args[1]
        shopseed = args[1] .. 10
    else
        seed = generateSeed()
        shopseed = seed .. 10
    end
    for _, piece in pairs(pieces) do
        disabledPieceTypes[piece.ingame_desc.name] = false
    end
    _G.currentKingType = PieceType.mKing
    print(seed)
    love.graphics.setDefaultFilter("nearest", "nearest")
    local icon = love.image.newImageData('assets/pawn.png')
    love.window.setIcon(icon)
    photonegativeShader = love.graphics.newShader("photonegative_shader.glsl")
    shaders[1] = love.graphics.newShader("blu.glsl")
    shaders[2] = love.graphics.newShader("red.glsl")
    shaders[3] = love.graphics.newShader("grn.glsl")
    shaders[4] = love.graphics.newShader("blk.glsl")
    shaders[5] = love.graphics.newShader("hmm I wonder what this is a reference to.glsl")
    gameover = love.graphics.newShader("error.glsl")
    balafont = love.graphics.newFont("balafont.ttf", 18)
    balabig = love.graphics.newFont("balafont.ttf", 28)
    smallatro = love.graphics.newFont("balafont.ttf", 16)
    rockhard = love.graphics.newShader("stoneboard.glsl")
    alias = love.graphics.newShader("smooth.glsl")
    greyed = love.graphics.newShader("greyed.glsl")
    love.window.setTitle("Scaccombo")
    canvas = love.graphics.newCanvas(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, { format = 'rgba8' })
    canvas:setFilter("linear", "linear")
    scale = 1
    updateScale()
    love.window.setMode(800, 600, {resizable = true, minwidth = 800, minheight = 600})
    -- init empty board
    gamestate = "title"
    for x=1,8 do
        board[x] = {}
        startingboard[x] = {}
        for y=1,8 do
            board[x][y] = nil
            startingboard[x][y] = nil
        end
    end
    cx_title = 400               -- center x in your 800-wide virtual canvas
    cy_title = 200               -- y offset from top

    -- Breathing (scale)
    amplitude_title = 0.02         -- smaller scale change ±2% instead of ±5%
    frequency_breath_title = 0.25  -- slower breathing, 1 full cycle every 4 seconds

-- Rocking (rotation)
    angle_max_title = math.rad(1.5)  -- smaller rotation ±1.5 degrees instead of ±3
    frequency_rock_title = 0.1       -- slower rocking, 1 full cycle every 10 seconds

-- X offset based on rocking
    xoffset_factor_title = 10         -- half the previous shift, softer horizontal sway

-- Load title image safely
    titleImage = love.graphics.newImage("assets/scactitle.png")
    titleImage:setFilter('linear', 'linear')
    width_title = titleImage:getWidth()
    height_title = titleImage:getHeight()
    -- Simple setup so you can test Stockfish-vs-You:
    -- Put a bunch of black pawns in ranks 1..2 like you had
    board[4][8] = {type = PieceType.mKing, color = "black"}
    startingboard[4][8] = {type = PieceType.mKing, color = 'black'}
    startingslotsunlocked = 1
    KingPos = {4, 8}
    for i=1,8 do
        board[i][1] = {type = PieceType.Pawn, color= "white"}
        startingboard[i][1] = {type = PieceType.Pawn, color = "white"}
    end
    -- Give white a few pawns to move (so it's white's turn first)
    for i=1,8 do
        board[i][2] = {type = PieceType.Pawn, color= "white"}
        startingboard[i][2] = {type = PieceType.Pawn, color = "white"}
    end
    for i=1,4 do
        board[i+2][3] = {type = PieceType.Pawn, color= "white"}
        startingboard[i+2][3] = {type = PieceType.Pawn, color = "white"}
    end
    if args[2] then
        debuggame = args[2] == 'debug'
    else
        debuggame = false
    end
    for name, bp in pairs(Blueprint.defs) do
        if type(bp) == "table" and bp.inputs then
            print("Blueprint:", bp.inputs[1], bp.inputs[2], "->", bp.name)
        end
    end
    local kingcheck = findBlackKing()
    if kingcheck == nil then
        error("The board doesn't have a black king!")
    end
    myTimer = waitTime(0.1, function() Music.instaplay("round1") end)
    Shop.reset()
    shopInventory = Shop.roll(5)
end
--gets preview piece from Blueprint
local function yoinkPreviewPiece(pieceA, pieceB)
    if not (pieceA and pieceB) then return false end
    local pa = pieceA.piece
    local pb = pieceB.piece
    if not pa then return nil end
    if not pb then return nil end
    local result = Blueprint.findResult(pieceA.piece, pieceB.piece)
    if result then
        return result
    end
    return nil
end

-- Combine function
local function combinePieces()
    local preview = yoinkPreviewPiece(combineSlots[1], combineSlots[2])
    if preview and combinedAlready > 0 then
        local slot = combineSlots[1]
        combinedAlready = combinedAlready - 1
        -- Spawn result on first piece's original square
        if combineSlots[1].sticker and combineSlots[1].sticker == "Craftsman" then
            combinedAlready = combinedAlready + 1
        end
        if combineSlots[2].sticker and combineSlots[2].sticker == "Craftsman" then
            combinedAlready = combinedAlready + 1
        end
        board[slot.x][slot.y] = {type=preview, color=combineSlots[1].piece.color}
        local pieceA = combineSlots[1].piece
        local pieceB = combineSlots[2].piece
        if preview == PieceType.Knight and InTutorial and TutorialState == 1 then
            TutorialState = 2
        elseif InTutorial and TutorialState == 10 and preview == PieceType.Bishop then
            InTutorial = false
            settings.tutorial = false
            saveSettings()
        end
        -- Remove second piece from its original square
        board[combineSlots[2].x][combineSlots[2].y] = nil
        -- Clear slots
        combineSlots[1], combineSlots[2] = nil, nil
        for name, bp in pairs(Blueprint.defs) do
            if bp.unlocked then
               local inputs = bp.inputs
                if #inputs == 2 then
                    local p1Match = pieceA.type.ingame_desc.name == inputs[1] and pieceB.type.ingame_desc.name == inputs[2]
                    local p2Match = pieceB.type.ingame_desc.name == inputs[1] and pieceA.type.ingame_desc.name == inputs[2]

                    if (p1Match or p2Match) then
                        Blueprint.unlock(bp.name)
                    end
                end
            end
        end
        -- Combining does NOT change turns by design; change this if you want it to be a turn.
    end
    if not preview then print("ERROR: No result!") end
end
local inMenu = false
inSettings = false
local lastBoss = nil

function pickNextBoss()
    local keys = {}
    for _, boss in pairs(BossModifiers.defs) do
        table.insert(keys, boss.id)
    end

    local choice
    repeat
        choice = keys[math.random(1, #keys)]
    until choice ~= lastBoss

    lastBoss = choice
    return choice
end
function bossReroll()
    local bossminrounds = {}
    for _, boss in pairs(BossModifiers.defs) do
        table.insert(bossminrounds, boss.minRounds or 1)
    end
    repeat
        nextroundBoss = BossModifiers.getRandomID(Currentround - 1)
    until BossModifiers.getBossRounds(nextroundBoss) < Currentround - 1
    print(nextroundBoss)
    for _, boss in pairs(BossModifiers.defs) do
        if boss.id == nextroundBoss then
            nextroundBossName = boss.name
            nextroundBossDesc = boss.description
        end
    end
end
nextKingAbility = nil
nextAbilityName = nil
function startround()
    if KingAbilities.active['waytoofast'] == true then
        turns = 25
    else
        turns = 30
    end
    Currentround = Currentround + 1
    print(Currentround % 5)
    print(shouldrerollboss)
    if Currentround % 5 == 0 or Currentround == 1 then
        if nextroundBoss then
            currentBoss = nextroundBoss
            currentBossName = nextroundBossName
            if currentBossName == "Inflation" then
                inflationActive = true
            else
                inflationActive = false
            end
            BossModifiers.apply(currentBoss)
        end
        bossReroll()
    else
        resetModifiers()
    end
    if Currentround % 5 == 4 then
        local primedKingAbility = KingAbilities.randomAbility(Currentround)
        print(primedKingAbility)
        if primedKingAbility ~= nil then
            nextKingAbility = primedKingAbility
            nextAbilityName = KingAbilities.getName(nextKingAbility)
        else
            nextKingAbility = nil
            nextAbilityName = nil
        end
    end
    combinedAlready = combineAmount
    combineSlots[1] = nil
    combineSlots[2] = nil
    local wallrand = math.random(1,8)
    for x=1,8 do
        for y=1,8 do
            if currentBossName == "Wall" then
                if x ~= wallrand and y == 5 then
                    board[x][y] = {type = PieceType.Barrier, color = "barrier"}
                else
                    board[x][y] = nil
                end
            else
                board[x][y] = nil
            end
        end
    end

    for y=1,4 do
        for x=1,8 do
            local piece = board[x][y]
            local startpiece = startingboard[x][y]
            if startpiece and startpiece.type ~= PieceType.Pawn and currentBossName == "Restart" and Currentround % 5 == 0 then
                board[x][y] = {type = PieceType.Pawn, color = startpiece.color}
            elseif startpiece then
                board[x][y] = startpiece
            else
                board[x][y] = nil
            end
        end
    end
    if currentBossName == "Clutter" then
        for x=1,8 do
            for y=1,8 do
                local clutrand = math.random(1,3)
                if clutrand == 1 and board[x][y] == nil then
                    board[x][y] = {type = PieceType.Barrier, color = "barrier"}
                end
            end
        end
    end
    if Currentround % 5 == 0 then
        Music.boss()
    else
        Music.round(Currentround % 5)
    end
    board[4][8] = {type = _G.currentKingType or PieceType.mKing, color = "black"}
    unusedCombines = 0
    currentTurn = "white"
    local kingcheck = findBlackKing()
    if not kingcheck then error("Black king not found") end
    gamestate = "playinground"
end
-- --- INPUT ---
local combineOffset = 64
function calculateinroundpressed(a,b,button)
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    local x = (a - offsetX)/scale
    local y = b/scale
    if x>=combineButton.x - 40 and x<=combineButton.x+128 and y>=404 and y<=444 then
        if not inMenu and not inSettings then inMenu = true else inMenu = false end
    end
    if x>=combineButton.x - 40 and x<=combineButton.x+128 and y>=454 and y<=494 then
        if not inMenu and not inSettings then inSettings = true end
    end
    if inSettings then
        settingspage.mousepressed(x,y,button)
    end
    if not inMenu and not inSettings then
        if button ~= 1 then return end

    -- Combine button click
        if x>=combineButton.x and x<=combineButton.x+combineButton.w+combineOffset and
           y>=0+2*TILE*1.5 and y<=0+2*TILE*1.5+combineButton.h then
            combinePieces()
            return
        end
    -- Don't allow user to move while AI is thinking or if it's not their turn
    --if currentTurn ~= "white" or aiThinking then return end

        local bx = math.floor((math.floor((((a - offsetX)/scale) - 32)/TILE) + 1))
        local by = math.floor((y-32)/TILE)+1
        local piece = nil

    -- From board
        if bx>=1 and bx<=8 and by>=1 and by<=8 then
            piece = board[bx][by]
        if piece and piece.color ~= currentTurn then
            piece = nil -- can't pick up opponent's piece
        end
        end

    -- From combine slots
    -- In love.mousepressed and love.mousereleased
        for i=1,2 do
            local slotSpacing = TILE + 10
            local slotX = combineButton.x + (i-1) * slotSpacing + combineOffset
            local slotY = combineButton.y
            if x >= slotX - combineOffset and x <= slotX + TILE - combineOffset and y >= slotY and y <= slotY + TILE then
                if combineSlots[i] then
                    local p = combineSlots[i].piece
                -- Only allow picking back up your own piece on your turn
                        piece = p
                        dragStartX, dragStartY = combineSlots[i].x, combineSlots[i].y
                        piece.fromCombine = true
                        piece.ogX = dragStartX
                        piece.ogY = dragStartY
                        combineSlots[i] = nil
                end
            end
        end

        if piece and not (disabledPieceTypes[piece.type.ingame_desc.name] == true) then
            dragging = true
            draggedPiece = piece
            if not dragStartX then dragStartX = bx end
            if not dragStartY then dragStartY = by end
            validMoves = computeValidMoves(board, piece, dragStartX, dragStartY)
        end
    end
end
local kingstartupcheck = false
function calculateineditpressed(a,b,button)
    if button ~= 1 then return end
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    local x = (a - offsetX)/scale
    local y = b/scale

    local bx = math.floor(((x - 32)/TILE) + 1)
    local by = math.floor(((y - 32)/TILE) + 1)

    -- Click finish editing
    if x >= 560 and x <= 740 and y >= 450 and y <= 490 and not kingstartupcheck then
        if InTutorial and TutorialState == 9 then
            TutorialState = 10
        elseif InTutorial then
            InTutorial = false
            settings.tutorial = false
            saveSettings()
        end
        startround()
        return
    end

    -- Row unlock buttons
    for row=2,4 do
        if row == startingslotsunlocked+1 then
            local price = rowUnlockPrices[row]
            local btnY = 32 + (row-1)*TILE
            if y >= btnY and y <= btnY+TILE and x >= 32 and x <= 32+8*TILE then
                if material >= price then
                    material = material - price
                    startingslotsunlocked = row
                    return
                end
            end
        end
    end

    -- Piece palette (select recipe)
    local ry = 150
    for name,def in pairs(Recipes.defs) do
        if def.unlocked then
            if x >= 560 and x <= 740 and y >= ry and y <= ry+40 then
                selectedRecipe = name
                if InTutorial and TutorialState == 7 and def.name == "Knight" then
                    TutorialState = 8
                elseif InTutorial then
                    InTutorial = false
                    settings.tutorial = false
                    saveSettings()
                end
                return
            end
            ry = ry + 45
        end
    end

    -- Delete button
    if x >= 560 and x <= 740 and y >= 500 and y <= 540 then
        if selectedPieceForDelete then
            local pieceName = selectedPieceForDelete.type.ingame_desc.name
            if InTutorial and TutorialState == 6 and pieceName == "Pawn" then
                TutorialState = 7
            elseif InTutorial then
                InTutorial = false
                settings.tutorial = false
                saveSettings()
            end
            local refund = Recipes.defs[pieceName].sell or 1
            Piecetokens = Piecetokens + refund
            startingboard[selectedPieceForDelete.x][selectedPieceForDelete.y] = nil
            selectedPieceForDelete = nil
            for xa=1,8 do
                for ya=1,8 do
                    piece = startingboard[xa][ya]
                    if piece and piece.color == 'white' then
                        local cancapture = piece.type.move(piece, xa, ya, 4, 8, true, startingboard)
                        if cancapture then kingstartupcheck = true return end
                    end
                end
            end
            kingstartupcheck = false
        end
        return
    end

    -- Board click
    if bx>=1 and bx<=8 and by>=1 and by<=startingslotsunlocked then
        local piece = startingboard[bx][by]
        if piece then
            selectedPieceForDelete = {type=piece.type, x=bx, y=by}
            -- start dragging
            editingDragging = true
            editingDraggedPiece = piece
            editingDragX, editingDragY = bx, by
            startingboard[bx][by] = nil
        else
            -- Place new piece
            local recipe = Recipes.defs[selectedRecipe]
            if recipe and Piecetokens >= recipe.place then
                local pieceType = pieces[recipe.name]
                if pieceType then
                    Piecetokens = Piecetokens - recipe.place
                    startingboard[bx][by] = {type = pieceType, color="white"}
                    if InTutorial and TutorialState == 8 and pieceType == PieceType.Knight then
                        TutorialState = 9
                    elseif InTutorial then
                        InTutorial = false
                        settings.tutorial = false
                        saveSettings()
                    end
                    if pieceType.move(startingboard[bx][by], bx, by, 4, 8, true, board) then
                        kingstartupcheck = true
                    end
                end
            end
        end
    end
end


function calculateinpayoutpressed(a,b,button)
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    local x = (a - offsetX)/scale
    local y = b/scale
    if button == 1 then
        if x >= 200 and x <= 600 then
            if y >= 450 and y <= 500 then
                material = material + payout
                rerollcost = 4
                if InTutorial and TutorialState == 3 then
                    TutorialState = 4
                    rerollcost = 999
                elseif InTutorial then
                    InTutorial = false
                    settings.tutorial = false
                    saveSettings()
                end
                shopInventory = Shop.roll(5)
                
                gamestate = 'inshop'
                Music.shop(inflationActive)
                currentBossName = nil
            end
        end
    end
end
local buttonHeight = 80
local buttonWidth = 250
local buttonSpacing = 10
local shopY = 100
local selectedMessage = ""
function calculateinshoppressed(mx,my,button)
    if button == 1 then
        for i, item in ipairs(shopInventory) do
            local x = 50
            local y = shopY + (i - 1) * (buttonHeight + buttonSpacing)

            if mx >= x and mx <= x + buttonWidth
            and my >= y and my <= y + buttonHeight then
                local alreadyBought = item._boughtInstance
                if not alreadyBought then
                    local success = Shop.buy(item)
                    if success then
                        selectedMessage = "Bought " .. item.name .. "!"
                        item._boughtInstance = true -- mark this instance as bought
                        if InTutorial and TutorialState == 4 and material == 0 then
                            TutorialState = 5
                        elseif InTutorial and TutorialState ~= 4 then
                            InTutorial = false
                            settings.tutorial = false
                            saveSettings()
                        end
                    else
                        selectedMessage = "Can't buy " .. item.name
                    end
                else
                    selectedMessage = item.name .. " already bought"
                end
                break
            end
        end
        if mx >= 500 and mx <= 700 and my >= 400 and my <= 450 then
            if InTutorial and TutorialState == 5 then
                TutorialState = 6
            elseif InTutorial then
                InTutorial = false
                settings.tutorial = false
                saveSettings()
            end
            gamestate = 'editingboard'
            if Currentround % 5 == 4 then
                Music.editor(true)
            else
                Music.editor(false)
            end
        end
        if mx >= 500 and mx <= 700 and my >= 460 and my <= 510 then
            if material >= rerollcost then
                material = material - rerollcost
                rerollcost = math.floor((rerollcost*1.25)+0.5)
                shopInventory = Shop.roll(5)
            end
        end
    end

end
function love.mousepressed(a,b,button)
    if gamestate == 'playinground' then
        calculateinroundpressed(a,b,button)
    elseif gamestate == 'woncheck' or gamestate == 'wonstale' or gamestate == 'kingcapture' or gamestate == 'devwin' or gamestate == 'wontutorial' then
        calculateinpayoutpressed(a,b,button)
    elseif gamestate == 'inshop' then
        local windoww, windowh = love.graphics.getDimensions()
        offsetX = (windoww - 800*scale)/2
        local x = (a - offsetX)/scale
        local y = b/scale
        calculateinshoppressed(x,y,button)
    elseif gamestate == 'editingboard' then
        calculateineditpressed(a,b,button)
    elseif gamestate == 'title' then
        local windoww, windowh = love.graphics.getDimensions()
        offsetX = (windoww - 800*scale)/2
        local x = (a - offsetX)/scale
        local y = b/scale
        if inSettings then
            settingspage.mousepressed(x,y,button)
        else
            menu.checkClick(x, y)
        end
    end
end
function calculateinroundrelease(a,b,button)
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    local x = (a - offsetX)/scale
    local y = b/scale
    if button ~= 1 then return end
    if not dragging or not draggedPiece then return end

    local bx = math.floor((math.floor((((a - offsetX)/scale) - 32)/TILE) + 1))
    local by = math.floor((y-32)/TILE)+1

    -- Drop on combine slots
    -- In love.mousepressed and love.mousereleased
    for i=1,2 do
        local slotSpacing = TILE + 10
        local slotX = combineButton.x + (i-1) * slotSpacing - 80
        local slotY = combineButton.y
        if x >= (slotX)and x <= (slotX) + TILE + combineOffset and y >= slotY and y <= slotY + TILE + combineOffset and combinedAlready > 0 then
            if combineSlots[i] == nil and not draggedPiece.fromCombine then
                combineSlots[i] = {piece=draggedPiece, x=dragStartX, y=dragStartY}
                board[dragStartX][dragStartY] = nil
            else
                board[dragStartX][dragStartY] = draggedPiece
                print(dragStartX)
                print(dragStartY)
                draggedPiece.fromCombine = false
            end
            draggedPiece.fromCombine = false
            dragging = false
            draggedPiece = nil
            validMoves = nil
            dragStartX, dragStartY = nil,nil
            return
        end
    end
    -- Drop on board
    if draggedPiece.fromCombine then
        -- snap back to original spot only
        board[draggedPiece.ogX][draggedPiece.ogY] = draggedPiece
        draggedPiece.fromCombine = false

        -- (returning from combine does NOT end your turn)
    else
        if bx>=1 and bx<=8 and by>=1 and by<=8 then
            local target = board[bx][by]
            local isCapture = target~=nil and target.color~=draggedPiece.color
            if target==nil or target.color~=draggedPiece.color then
                if draggedPiece.type.move(draggedPiece, dragStartX, dragStartY, bx, by, isCapture, board) then
                    board[bx][by] = draggedPiece
                    board[dragStartX][dragStartY] = nil

                    if currentTurn == "white" then
                        if board[bx][by].sticker and board[bx][by].sticker.name == "Slippery" then
                            board[bx][by].sticker = nil
                        end
                        turns = turns - 1
                        if turns == 0 then gamestate = 'gameover' end
                        if combinedAlready > 0 then unusedCombines = unusedCombines + 1 end
                        currentTurn = "black"
                        if currentBoss == "slipking" then
                            moveBlackKing()
                        end
                        if KingAbilities.active["the_slip"] == true then
                            if currentBoss == "slipking" then
                                kingPlaceTimer = waitTime(0.25, function() moveBlackKing() end)
                            else
                                moveBlackKing()
                            end
                        end
                        myTimer = waitTime(0.25, function() moveBlackKing() currentTurn = "white" end)
                    else
                        currentTurn = "white"
                    end
                    if combinesResetEveryTurn == true then
                        if combinesResetEveryTurn then
                            combinedAlready = combineAmount
                        end
                    end
                else
                    -- invalid -> return to origin
                    board[dragStartX][dragStartY] = draggedPiece
                end
            else
                -- blocked by same color -> return
                board[dragStartX][dragStartY] = draggedPiece
            end
        else
            -- outside board -> return
            board[dragStartX][dragStartY] = draggedPiece
        end
    end

    dragging = false
    draggedPiece = nil
    validMoves = nil
    dragStartX, dragStartY = nil,nil
end
function calculateineditrelease(a,b,button)
    if button ~= 1 then return end
    if not editingDragging or not editingDraggedPiece then return end

    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    local x = (a - offsetX)/scale
    local y = b/scale

    local bx = math.floor(((x - 32)/TILE) + 1)
    local by = math.floor(((y - 32)/TILE) + 1)

    -- Only snap back into unlocked rows
    if bx>=1 and bx<=8 and by>=1 and by<=startingslotsunlocked then
        if not startingboard[bx][by] then
            startingboard[bx][by] = editingDraggedPiece
            if editingDraggedPiece.type.move(editingDraggedPiece, bx, by, 4, 8, true, board) then
                kingstartupcheck = true
            end
        else
            startingboard[editingDragX][editingDragY] = editingDraggedPiece
        end
    else
        startingboard[editingDragX][editingDragY] = editingDraggedPiece
    end
    editingDragging = false
    editingDraggedPiece = nil
    editingDragX, editingDragY = nil, nil
end


function love.mousereleased(a,b,button)
    if gamestate == 'playinground' then
        calculateinroundrelease(a,b,button)
    elseif gamestate == 'editingboard' then
        calculateineditrelease(a,b,button)
    end
end
local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end
function love.mousemoved(mx,my)
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    mouseX = (mx - offsetX) / scale
    mouseY = my/scale
    mouseX = clamp(mouseX, 32, 768)
end
local time = 0

function love.update(dt)
    time = time + dt
    updateScale()
    if myTimer then myTimer:update(dt) end
    if kingPlaceTimer then kingPlaceTimer:update(dt) end
    t_title = love.timer.getTime()
    Music.update(dt)
-- Breathing scale
    scale_title = 1 + amplitude_title * math.sin(2 * math.pi * frequency_breath_title * t_title)
    shadow_scale_title = 1 + (scale_title - 1) * 0.3


-- Rocking rotation
    rotation_title = angle_max_title * math.sin(2 * math.pi * frequency_rock_title * t_title)

-- X offset based on rocking
    xoffset_title = -xoffset_factor_title * math.sin(2 * math.pi * frequency_rock_title * t_title)
    shaders[currentShader]:send("iTime", time)
    shaders[currentShader]:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight()})
    gameover:send("iTime", time)
    gameover:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight()})
    --Stockfish stuff, not implemented yet so ignore this
    if love.keyboard.isDown("1") and not debuggame then
        debuggame = true
    end
    if love.keyboard.isDown("2") and debuggame then
        debuggame = false
    end
    if love.keyboard.isDown("p") and debuggame then
        material = material + 10
        Piecetokens = Piecetokens + 20
    end
    if love.keyboard.isDown("m") and debuggame and gamestate == 'playinground' then
        gamestate = 'woncheck'
    end
    if gamestate == 'gameover' and love.keyboard.isDown('escape') then
        closeGame()
    end
    if gamestate == 'gameover' and love.keyboard.isDown('r') then
        saveSettings()
        love.event.quit('restart')
    end
end
-- --- RENDER ---
local function getBlueprintImage(a, b)
    local function inputsMatch(bpInputs, a, b)
        local n1 = bpInputs[1]
        local n2 = bpInputs[2]
        return (n1 == a and n2 == b) or (n1 == b and n2 == a)
    end

    for name, bp in pairs(Blueprint.defs) do
        if inputsMatch(bp.inputs, a, b) then
            if bp.discovered == true and bp.path then
                local img = love.graphics.newImage(bp.path)
                if img then return img else return love.graphics.newImage('assets/iking.png') end
            elseif bp.unlocked == true then
                return love.graphics.newImage('assets/idk.png')
            else
                return nil
            end
        end
    end

    return nil
end

local menuX, menuY = 50, 50  -- top-left corner of menu
local lineHeight = 40

function getBlueprintData(a, b)
    for name, bp in pairs(Blueprint.defs) do
        -- Draw result image if available
        if not bp.inputs == {a, b} then return false end
        if bp.resultType and bp.resultType.imagePath then
            local ok, img = pcall(love.graphics.newImage, bp.path)
            if ok and bp.path then
                love.graphics.setColor(1, 1, 1, 1)
                if bp.discovered then
                    img = love.graphics.newImage(bp.path)
                    return bp.path
                elseif bp.unlocked then
                    img = love.graphics.newImage('assets/idk.png')
                    return bp.path
                end
                return nil
            end
        end
    end
    return nil
end
function drawBlueprintMenu()
    local y = menuY
    love.graphics.setColor(0, 0, 0, 0.7)
    local linesamt = 40 + lineHeight * 2
    for name, bp in pairs(Blueprint.defs) do
        if bp.unlocked then linesamt = linesamt + lineHeight end
    end
    love.graphics.setFont(balafont)
    love.graphics.rectangle("fill", 40, 40, 500, linesamt, 8, 8)
    love.graphics.setColor(1, 1, 1, 1) -- reset draw color
    love.graphics.print("Unlocked Blueprints:", menuX, y)
    y = y + lineHeight

    for name, bp in pairs(Blueprint.defs) do
        -- Skip locked ones
            if bp.unlocked then
                inputStr = table.concat(bp.inputs, " + ")
                if bp.discovered then
                    resultName = bp.resultType.ingame_desc.name or bp.resultName or "???"
                else
                    resultName = "UNDISCOVERED (Discover this piece first!)"
                end
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(inputStr .. " = " .. resultName, menuX + lineHeight + 10, y + 20)
            end
            -- Text fallback

            -- Draw result image if available
            if bp.resultType and bp.resultType.imagePath then
                local img = bp.resultType.imagePath
                local img = love.graphics.newImage(img)
                if img then
                    love.graphics.setColor(1, 1, 1, 1)
                    if img and bp.discovered then
                        love.graphics.draw(img, menuX, y + lineHeight-40, 0, 0.4, 0.4) -- scale down a bit
                    elseif img and bp.unlocked then
                        img = love.graphics.newImage('assets/idk.png')
                        love.graphics.draw(img, menuX, y + lineHeight-40, 0, 0.4, 0.4) -- scale down a bit
                    end
                end
            else
                if bp.unlocked then
                    local img = love.graphics.newImage('assets/idk.png')
                    love.graphics.draw(img, menuX, y + lineHeight-40, 0, 0.4, 0.4)
                end
            end
            if bp.unlocked then
                y = y + lineHeight
            end
    end
end
function switchShader()
    currentShader = currentShader + 1
    if currentShader > #shaders then
        currentShader = 1
    end
    settings.shader = currentShader
end
function closeGame()
    saveSettings()
    love.event.quit()
end

local function boardDraw()
    love.graphics.setFont(balafont)
    love.graphics.setShader()
    local slotSpacing = TILE + 10
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", TILE * 8.7, 32, 200, 500, 8, 8)
    -- Draw board
    for x=1,8 do
        for y=1,8 do
            if (x+y)%2==0 then
                local color = isWhite and {1, 0.95, 0.9} or {0.3, 0.25, 0.2}
                rockhard:send("baseColor", color)
                love.graphics.setColor(1,0.95,0.9)
            else
                love.graphics.setColor(0.3,0.25,0.2)
            end
            love.graphics.rectangle("fill", (x-1)*TILE + 32, (y-1)*TILE + 32, TILE, TILE)
            love.graphics.setColor(0,0,0,0.5)
            love.graphics.rectangle('line', (x-1)*TILE + 32 + 1, (y-1)*TILE + 32 + 1, TILE - 2, TILE - 2)
            love.graphics.setColor(1,1,1,1)
        end
    end
    love.graphics.setShader()
    -- Draw combine slots (keep your style; fixed pos was in your code so I’ll keep it)
    local slotSpacing = TILE + 10 -- 10px gap between slots

-- Draw combine slots
    for i=1,2 do
        local slotSpacing = TILE + 10
        local slot = combineSlots[i]
        local slotX = combineButton.x + (i-1) * slotSpacing
        local slotY = combineButton.y
        if i == 1 then
            love.graphics.setColor(1, 0.95, 0.9)
        else
            love.graphics.setColor(0.3, 0.25, 0.2)
        end
        love.graphics.rectangle("fill", (slotX + combineOffset - 80), slotY, TILE, TILE)
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("line", (slotX + combineOffset - 80)+1, slotY+1, TILE-2, TILE-2)
        love.graphics.setColor(1,1,1,1)
        if slot then
            local img = slot.piece.type.image
            local scaleX = TILE / img:getWidth()
            local scaleY = TILE / img:getHeight()
            if slot.piece.color=="black" then
                love.graphics.setShader(photonegativeShader)
            else
                if disabledPieceTypes[slot.piece.type.ingame_desc.name] == true then
                    love.graphics.setShader(greyed)
                else
                    love.graphics.setShader()
                end
            end
            love.graphics.draw(img, (slotX + combineOffset - 80), slotY, 0, scaleX, scaleY)
            love.graphics.setShader()
        end
    end

    -- Draw combine previe
    Img = nil
    local p1 = combineSlots[1]
    local p2 = combineSlots[2]
    if p1 and p2 then
        if yoinkPreviewPiece(p1, p2) then
            Img = getBlueprintImage(p1.piece.type.ingame_desc.name, p2.piece.type.ingame_desc.name)
        end
    end
    if Img ~= nil then
        local img = Img
        local previewX = combineButton.x + combineOffset - 35
        local previewY = 0 + 2*TILE*1.5 + combineButton.h + 10
        if img then
            local scaleX = TILE / img:getWidth()
            local scaleY = TILE / img:getHeight()
            love.graphics.setColor(0,1,0,0.8)
            love.graphics.rectangle("line", previewX, previewY, TILE, TILE, 8, 8)
            -- color: use slot[1] piece color if present
            if combineSlots[1] and combineSlots[1].piece and combineSlots[1].piece.color == "black" then
                love.graphics.setShader(photonegativeShader)
            else
                love.graphics.setShader()
            end
            love.graphics.setColor(1,1,1)
            love.graphics.draw(img, previewX, previewY, 0, scaleX, scaleY)
            love.graphics.setShader()
            Img = nil
        end
    end

    -- Draw pieces (hide ones in combine slots; hide dragged piece on its square)
    for x=1,8 do
        for y=1,8 do
            local piece = board[x][y]
            if piece then
                local inCombine = false
                for _,slot in ipairs(combineSlots) do
                    if slot and slot.piece==piece then inCombine=true end
                end
                if not inCombine and not (dragging and piece==draggedPiece) then
                    local img = piece.type.image
                    local scaleX = TILE / img:getWidth()
                    local scaleY = TILE / img:getHeight()
                    if piece.color=="black" then
                        love.graphics.setShader(photonegativeShader)
                    else
                        if disabledPieceTypes[piece.type.ingame_desc.name] == true then
                            love.graphics.setShader(greyed)
                        else
                            love.graphics.setShader()
                        end
                    end
                    love.graphics.setColor(1,1,1)
                    love.graphics.draw(img, (x-1)*TILE + 32, (y-1)*TILE + 32, 0, scaleX, scaleY)
                end
            end
        end
    end
    love.graphics.setShader()

    -- Draw valid moves (and the special green circle if fromCombine)
    if dragging and draggedPiece and validMoves then
        for _, m in ipairs(validMoves) do
            local cx = (m.x-0.5)*TILE
            local cy = (m.y-0.5)*TILE
            if draggedPiece.fromCombine then
                love.graphics.setColor(0,1,0,0.35)
                love.graphics.circle("fill", cx+32, cy+32, TILE*0.22)
                love.graphics.setLineWidth(2)
                love.graphics.setColor(0,0.6,0,0.9)
                love.graphics.circle("line", cx+32, cy+32, TILE*0.22)
            else
                if m.capture then
                    love.graphics.setColor(1,0,0,0.35)
                    love.graphics.circle("fill", cx+32, cy+32, TILE*0.22)
                    love.graphics.setLineWidth(2)
                    love.graphics.setColor(0.7,0,0,0.9)
                    love.graphics.circle("line", cx+32, cy+32, TILE*0.22)
                else
                    love.graphics.setColor(0,1,0,0.35)
                    love.graphics.circle("fill", cx+32, cy+32, TILE*0.22)
                    love.graphics.setLineWidth(2)
                    love.graphics.setColor(0,0.6,0,0.9)
                    love.graphics.circle("line", cx+32, cy+32, TILE*0.22)
                end
            end
        end
    end


    -- Draw combine button
    if yoinkPreviewPiece(combineSlots[1], combineSlots[2]) and combinedAlready > 0 then
        love.graphics.setColor(0,1,0)
    else
        love.graphics.setColor(0.5,0.5,0.5)
    end
    love.graphics.rectangle("fill", combineButton.x+combineOffset-40, 00 + 2*TILE*1.5, 64, 40, 8, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Combine", combineButton.x+combineOffset-35, 00 + 2*TILE*1.5 + 10)
    if combinedAlready == 0 then
        love.graphics.printf("(out of combines)", combineButton.x+combineOffset-100, 50 + 2*TILE*1.5 + 10, 200, "center")
    elseif combinedAlready > 1 then
        if combinesResetEveryTurn and (currentBoss == nil or currentBoss.combinesRefresh ~= false) then
            love.graphics.printf("(" .. combinedAlready .. " Combines left this turn)", combineButton.x+combineOffset-150, 300 + 2*TILE*1.5 + 10, 300, "center")
        else
            love.graphics.printf("(" .. combinedAlready .. " Combines left this round)", combineButton.x+combineOffset-150, 300 + 2*TILE*1.5 + 10, 300, "center")
        end
    else
        if combinesResetEveryTurn and (currentBoss == nil or currentBoss.combinesRefresh ~= false) then
            love.graphics.printf("(1 Combine left this turn)", combineButton.x+combineOffset-150, 300 + 2*TILE*1.5 + 10, 300, "center")
        else
            love.graphics.printf("(1 Combine left this round)", combineButton.x+combineOffset-150, 300 + 2*TILE*1.5 + 10, 300, "center")
        end
    end
    love.graphics.setColor(0,0,1)
    love.graphics.rectangle("fill", combineButton.x+combineOffset-64, 200 + 2*TILE*1.5, 128, 40, 8, 8)
    love.graphics.setColor(1,1,1)
    if inMenu then
        love.graphics.printf("Close Blueprints", combineButton.x+combineOffset-64, 200 + 2*TILE*1.5 + 10, 128, 'center')
    else
        love.graphics.printf("See Blueprints", combineButton.x+combineOffset-64, 200 + 2*TILE*1.5 + 10, 128, 'center')
    end
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", combineButton.x+combineOffset-64, 250 + 2*TILE*1.5, 128, 40, 8, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Open Settings", combineButton.x+combineOffset-64, 250 + 2*TILE*1.5 + 10, 128, 'center')
    -- turn text
    love.graphics.setColor(1,1,1,1)
    local turnText = ((currentTurn:sub(1,1):upper() .. currentTurn:sub(2) .. "'s Turn"))
    love.graphics.printf(turnText, 250, 50, 800, 'center')
    love.graphics.printf('Turns Left:', 250, 325, 800, 'center')
    love.graphics.printf(turns, 250, 350, 800, 'center')
    local hx = math.floor((mouseX - 32) / TILE) + 1
    local hy = math.floor((mouseY - 32) / TILE) + 1
        -- Draw dragged piece
    if dragging and draggedPiece then
        local img = draggedPiece.type.image
        local scaleX = TILE / img:getWidth()
        local scaleY = TILE / img:getHeight()
        if draggedPiece.color=="black" then
            love.graphics.setShader(photonegativeShader)
        else
            love.graphics.setShader()
        end
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img, mouseX - TILE/2, mouseY - TILE/2, 0, scaleX, scaleY)
        love.graphics.setShader()
    end
    --hover info for combine slots
    if combineSlots[1] and combineSlots[2] then
        local p1 = combineSlots[1].piece
        local p2 = combineSlots[2].piece
        local p1t = combineSlots[1]
        local p2t = combineSlots[2]
        if p1 and p2 and p1.color == p2.color and Blueprint.findResult(p1, p2) then
            local key = p1.type.ingame_desc.name .. "+" .. p2.type.ingame_desc.name
            local newType = Blueprint.findResult(p1, p2, true)
            local img = getBlueprintImage(p1.type.ingame_desc.name, p2.type.ingame_desc.name)
            if img ~= nil and p1 and p2 then
                local scaleX = TILE / img:getWidth()
                local scaleY = TILE / img:getHeight()
                local previewX = combineButton.x+combineOffset-35
                local previewY = 0 + 2*TILE*1.5 + combineButton.h + 10
                local newType = Blueprint.findResult(p1, p2)
                if mouseX >= previewX and mouseX <= previewX + TILE and
                   mouseY >= previewY and mouseY <= previewY + TILE then
                    local offsetX, offsetY = 20, 20
                    love.graphics.setColor(0,0,0,0.8)
                    local width = 10
                    local padding = 5
                    local height = 10
                    width = math.max(width, love.graphics.getFont():getWidth(newType.ingame_desc.name))
                    local nameWidth = love.graphics.getFont():getWidth(newType.ingame_desc.name)
                    local nameHeight = love.graphics.getFont():getHeight()
                    local desc = newType.ingame_desc.desc
                    local descWidth, descHeight = 0, 0
                    for _, line in ipairs(desc) do
                        local w = love.graphics.getFont():getWidth(line)
                        descWidth = math.max(descWidth, w)
                        descHeight = descHeight + love.graphics.getFont():getHeight() + 2
                    end
                    local rectWidth = math.max(nameWidth, descWidth) + padding*2
                    local rectHeight = nameHeight + descHeight + padding*2
                    love.graphics.setColor(0, 0, 0, 0.7)
                    love.graphics.rectangle("fill", mouseX + offsetX - rectWidth -15, mouseY + offsetY, rectWidth, rectHeight)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print(newType.ingame_desc.name, mouseX + offsetX - padding - rectWidth, mouseY + offsetY + padding)
                    for i, line in ipairs(newType.ingame_desc.desc) do
                        love.graphics.print(line, mouseX + offsetX - rectWidth - padding, mouseY + offsetY + padding + nameHeight + (i-1)*love.graphics.getFont():getHeight())
                    end
                end
            end
        end
    end
    --hover info for board
    if hx >= 1 and hx <= 8 and hy >= 1 and hy <= 8 then
        local hoverPiece = board[hx][hy]
        if hoverPiece then
            local offsetX, offsetY = 15, 15
            local padding = 5
            local nameText = "Name: " .. hoverPiece.type.ingame_desc.name
            local nameWidth = love.graphics.getFont():getWidth(nameText)
            local nameHeight = love.graphics.getFont():getHeight()
            local desc = hoverPiece.type.ingame_desc.desc
            local descWidth, descHeight = 0, 0
            for _, line in ipairs(desc) do
                local w = love.graphics.getFont():getWidth(line)
                descWidth = math.max(descWidth, w)
                descHeight = descHeight + love.graphics.getFont():getHeight()
            end
            local rectWidth = math.max(nameWidth, descWidth) + padding*2
            local rectHeight = nameHeight + descHeight + padding*2
            if VIRTUAL_WIDTH*scale >= mouseX+offsetX+rectWidth then
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", mouseX + offsetX, mouseY + offsetY, rectWidth, rectHeight)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(nameText, mouseX + offsetX + padding, mouseY + offsetY + padding)
                for i, line in ipairs(desc) do
                    love.graphics.print(line, mouseX + offsetX + padding, mouseY + offsetY + padding + nameHeight + (i-1)*love.graphics.getFont():getHeight())
                end
            else
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", (mouseX - offsetX) - rectWidth, mouseY + offsetY, rectWidth, rectHeight)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(nameText, (mouseX - offsetX) - rectWidth, mouseY + offsetY + padding)
                for i, line in ipairs(desc) do
                    love.graphics.print(line, (mouseX - offsetX) - rectWidth, mouseY + offsetY + padding + nameHeight + (i-1)*love.graphics.getFont():getHeight())
                end
            end
        end
    end
    if Currentround % 5 == 0 and Currentround > 1 then
        love.graphics.setFont(balabig)
        love.graphics.setColor(1,0.2,0,1)
        love.graphics.printf("Boss Active: " .. currentBossName, 32, 4, 512, "center")
        love.graphics.setFont(balafont)
        love.graphics.printf(currentBossDesc, 0, 560, 800, "center")
    end
    -- Turn text
    love.graphics.setColor(1, 1, 1, 1)
    if inMenu then drawBlueprintMenu() end
    if inSettings then settingspage.draw() end
end
function editDraw()
    love.graphics.setFont(balafont)
    love.graphics.setShader()

    -- Draw board squares
    for x=1,8 do
        for y=1,8 do
            if (x+y)%2==0 then
                love.graphics.setColor(1, 0.95, 0.9)
            else
                love.graphics.setColor(0.3, 0.25, 0.2)
            end
            love.graphics.rectangle("fill", (x-1)*TILE + 32, (y-1)*TILE + 32, TILE, TILE)
            love.graphics.setColor(0,0,0,0.5)
            love.graphics.rectangle('line', (x-1)*TILE + 32+1, (y-1)*TILE + 32+1, TILE-2, TILE-2)
        end
    end

    -- Darken entire board then reveal unlocked rows
    love.graphics.setColor(1,1,1,1)
    if selectedPieceForDelete then
        local gx = (selectedPieceForDelete.x-1)*TILE + 32
        local gy = (selectedPieceForDelete.y-1)*TILE + 32
        love.graphics.setColor(0,1,0,0.4)
        love.graphics.rectangle("fill", gx, gy, TILE, TILE)
        love.graphics.setColor(1,1,1,1)
    end
    -- Draw pieces
    for x=1,8 do
        for y=1,8 do
            local piece = startingboard[x][y]
            if piece and not (editingDragging and editingDraggedPiece == piece) then
                local img = piece.type.image
                local scaleX = TILE / img:getWidth()
                local scaleY = TILE / img:getHeight()
                if piece.color == "black" then
                    love.graphics.setShader(photonegativeShader)
                else
                    love.graphics.setShader()
                end
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(img, (x-1)*TILE + 32, (y-1)*TILE + 32, 0, scaleX, scaleY)
            end
        end
    end
    love.graphics.setShader()
    for y=startingslotsunlocked+1,8 do
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", 32, 32+(y-1)*TILE, TILE*8, TILE)
    end
    -- Highlight selected square

    -- Sidebar
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", 550, 50, 220, 500, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print("Board Editor", 560, 60)
    love.graphics.print("Tokens: " .. Piecetokens, 560, 90)
    love.graphics.print("Material: " .. material, 560, 110)

    -- Piece palette
    local y = 150
    for name,def in pairs(Recipes.defs) do
        if def.unlocked then
            if name == selectedRecipe then
                love.graphics.setColor(0,1,0,0.5)
                love.graphics.rectangle("fill", 560, y, 180, 40, 8, 8)
            end
            love.graphics.setFont(smallatro)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(name .. " (Place: "..def.place.."Tk, Sell: "..def.sell.."Tk)", 560, y+10, 180, "center")
            y = y + 45
        end
    end
    love.graphics.setFont(balafont)
    -- Delete button
    love.graphics.setColor(1,0,0,1)
    love.graphics.rectangle("fill", 560, 500, 180, 40, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Sell Selected", 560, 510, 180, "center")

    -- Finish Editing button
    if kingstartupcheck then
        love.graphics.setColor(0.5,0.5,0.5)
    else
        love.graphics.setColor(0,0.7,0.1)
    end
    love.graphics.rectangle("fill", 560, 450, 180, 40, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Finish Editing", 560, 460, 180, "center")

    -- Locked row text
    love.graphics.setFont(balabig)
    love.graphics.setColor(1,1,1,1)
    for row=startingslotsunlocked+1,4 do
        if row == startingslotsunlocked+1 then
            local price = rowUnlockPrices[row]
            local rowY = 32 + (row-1)*TILE + TILE/2 - 12
            love.graphics.printf("Unlock Row "..row.." ("..price.." Mat.)", 32, rowY, TILE*8, "center")
        end
    end
    love.graphics.setFont(balafont)

    -- Dragged piece (on top of menus)
    if editingDragging and editingDraggedPiece then
        local img = editingDraggedPiece.type.image
        local scaleX = TILE / img:getWidth()
        local scaleY = TILE / img:getHeight()
        if editingDraggedPiece.color=="black" then
            love.graphics.setShader(photonegativeShader)
        else
            love.graphics.setShader()
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(img, mouseX - TILE/2, mouseY - TILE/2, 0, scaleX, scaleY)
        love.graphics.setShader()
    end

    -- Hover description (copied from boardDraw, same format)
    local hx = math.floor((mouseX - 32) / TILE) + 1
    local hy = math.floor((mouseY - 32) / TILE) + 1
    if hx >= 1 and hx <= 8 and hy >= 1 and hy <= startingslotsunlocked then
        local hoverPiece = startingboard[hx][hy]
        if hoverPiece then
            local offsetX, offsetY = 15, 15
            local padding = 5
            local nameText = "Name: " .. hoverPiece.type.ingame_desc.name
            local nameWidth = love.graphics.getFont():getWidth(nameText)
            local nameHeight = love.graphics.getFont():getHeight()
            local desc = hoverPiece.type.ingame_desc.desc
            local descWidth, descHeight = 0, 0
            for _, line in ipairs(desc) do
                local w = love.graphics.getFont():getWidth(line)
                descWidth = math.max(descWidth, w)
                descHeight = descHeight + love.graphics.getFont():getHeight()
            end
            local rectWidth = math.max(nameWidth, descWidth) + padding*2
            local rectHeight = nameHeight + descHeight + padding*2
            if VIRTUAL_WIDTH*scale >= mouseX+offsetX+rectWidth then
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", mouseX + offsetX, mouseY + offsetY, rectWidth, rectHeight)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(nameText, mouseX + offsetX + padding, mouseY + offsetY + padding)
                for i, line in ipairs(desc) do
                    love.graphics.print(line, mouseX + offsetX + padding, mouseY + offsetY + padding + nameHeight + (i-1)*love.graphics.getFont():getHeight())
                end
            else
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", (mouseX - offsetX) - rectWidth, mouseY + offsetY, rectWidth, rectHeight)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(nameText, (mouseX - offsetX) - rectWidth, mouseY + offsetY + padding)
                for i, line in ipairs(desc) do
                    love.graphics.print(line, (mouseX - offsetX) - rectWidth, mouseY + offsetY + padding + nameHeight + (i-1)*love.graphics.getFont():getHeight())
                end
            end
        end
    end
end



function endofroundDraw()
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle('fill', 50, 50, 700, 500, 8, 8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(balabig)
    if gamestate == 'woncheck' then
        --payout calculations
        local roundpayout = turns
        local combinepayout = unusedCombines * 2
        local bosspayout
        if KingAbilities.active['payout'] == false and Currentround % 5 == 0 then
            bosspayout = 20
        elseif Currentround % 5 ~= 0 and KingAbilities.active['idk'] == false then
            bosspayout = Currentround % 5 < 4 and (((Currentround + 1) % 5) * 2) or 10
        else
            bosspayout = 0
        end
        payout = roundpayout + combinepayout + bosspayout
        --screen title
        love.graphics.printf("Round Won (Checkmate)!", 0, 75, 800, 'center')
        -- payout text
        love.graphics.setFont(balafont)
        love.graphics.print("Remaining Turns: ".. roundpayout .. ' Mat.', 100, 150)
        love.graphics.print("Unused Combines (2 Mat per combine): ".. combinepayout .. ' Mat.', 100, 170)
        if Currentround % 5 == 4 and nextAbilityName ~= nil then
            love.graphics.print("New Modifier: " .. nextAbilityName, 100, 190)
        end
        if KingAbilities.active['idk'] == false then
            if Currentround % 5 == 0 and bosspayout > 0 then
                love.graphics.print("Boss Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 4 then
                love.graphics.print("4th Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 3 then
                love.graphics.print("3rd Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 2 then
                love.graphics.print("2nd Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 1 then
                love.graphics.print("1st Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            end
        end
        --payout button
        love.graphics.setColor(1, 0.7, 0, 1)
        love.graphics.rectangle("fill", 200, 450, 400, 50, 8, 8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(balabig)
        love.graphics.printf("Give me my " .. payout .. " Materials!", 0, 462, 800, 'center')
    elseif gamestate == 'wonstale' then
        --payout calculations
        local roundpayout = math.floor((turns/2) + 0.5)
        local combinepayout = unusedCombines
        local bosspayout
        if KingAbilities.active['payout'] == false and Currentround % 5 == 0 then
            bosspayout = 10
        elseif Currentround % 5 < 5 and KingAbilities.active['idk'] == false then
            bosspayout = Currentround % 5 < 4 and (Currentround % 5) + 1 or 5
        else
            bosspayout = 0
        end
        payout = roundpayout + combinepayout + bosspayout
        love.graphics.printf("Round Beaten (Stalemate).", 0, 75, 800, 'center')
        --payout text
        love.graphics.setFont(balafont)
        love.graphics.print("Remaining Turns (1 Mat. per 2 turns): ".. roundpayout .. ' Mat.', 100, 150)
        love.graphics.print("Unused Combines: ".. combinepayout .. ' Mat.', 100, 170)
        if Currentround % 5 == 4 and nextAbilityName ~= nil then
            love.graphics.print("New Modifier: " .. nextAbilityName, 100, 190)
        end
        if KingAbilities.active['idk'] == false then
            if Currentround % 5 == 0 and bosspayout > 0 then
                love.graphics.print("Boss Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 4 then
                love.graphics.print("4th Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 3 then
                love.graphics.print("3rd Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 2 then
                love.graphics.print("2nd Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            elseif Currentround % 5 == 1 then
                love.graphics.print("1st Round Defeated: " .. bosspayout .. " Mat", 100, 210)
            end
        end
        --payout button
        love.graphics.setColor(1, 0.7, 0, 1)
        love.graphics.rectangle("fill", 200, 450, 400, 50, 8, 8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(balabig)
        love.graphics.printf("Give me my " .. payout .. " Materials!", 0, 462, 800, 'center')
    elseif gamestate == 'kingcapture' then
        --payout calculations
        payout = 2
        --screen title
        love.graphics.printf("Round Won (King Captured)!", 0, 75, 800, 'center')
        -- payout text
        love.graphics.setFont(balafont)
        love.graphics.print("Capture Payout: 2 Mat", 100, 150)
        if Currentround % 5 == 4 and nextAbilityName ~= nil then
            love.graphics.print("New Modifier: " .. nextAbilityName, 100, 190)
        end
        --payout button
        love.graphics.setColor(1, 0.7, 0, 1)
        love.graphics.rectangle("fill", 200, 450, 400, 50, 8, 8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(balabig)
        love.graphics.printf("Give me my 2 Materials!", 0, 462, 800, 'center')
    elseif gamestate == 'devwin' then
        local roundpayout = 15
        local combinepayout = 60
        payout = roundpayout + combinepayout
        love.graphics.printf("SUPER COOL DEV SECRET", 0, 75, 800, 'center')
        --payout text
        love.graphics.setFont(balafont)
        love.graphics.print("Remaining Rounds (1 Mat. per 2 rounds): ".. roundpayout .. ' Mat.', 100, 150)
        love.graphics.print("Unused Combines: ".. combinepayout .. ' Mat.', 100, 170)
        if Currentround == 4 then
            love.graphics.print("King Gained Ability: Capturing (youre cooked)", 100, 190)
        end
        --payout button
        love.graphics.setColor(1, 0.7, 0, 1)
        love.graphics.rectangle("fill", 200, 450, 400, 50, 8, 8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(balabig)
        love.graphics.printf("Give me my " .. payout .. " Materials! (in a cool way)", 0, 462, 800, 'center')
    elseif gamestate == 'wontutorial' then
        payout = 20
        love.graphics.printf("Round Won! (Tutorial)", 0, 75, 800, 'center')
        --payout text
        love.graphics.setFont(balafont)
        love.graphics.print("Payout: 20 Mat", 100, 150)
        --payout button
        love.graphics.setColor(1, 0.7, 0, 1)
        love.graphics.rectangle("fill", 200, 450, 400, 50, 8, 8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(balabig)
        love.graphics.printf("Give me my " .. payout .. " Materials!", 0, 462, 800, 'center')
    end
end

function shopDraw()
    love.graphics.setFont(smallatro)
    love.graphics.setColor(1, 1, 1)
    local toNextMultipleOf5 = 5 - (Currentround % 5)
    love.graphics.print("Materials: " .. material, 50, 20)
    love.graphics.print("Tokens: " .. Piecetokens, 50, 40)
    love.graphics.setFont(balabig)
    love.graphics.printf("Shop", 0, 32, 800, "center")
    if inflationActive then
        love.graphics.setFont(balafont)
        love.graphics.setColor(1,0,0)
        love.graphics.printf("Inflation Active (X5 Prices)", 0, 60, 800, "center")
        love.graphics.setFont(smallatro)
        love.graphics.setColor(1,0.5,0.5)
        love.graphics.printf("(Disables in " .. toNextMultipleOf5 .. " rounds)", 0, 75, 800, "center")
    end
    -- Draw shop items
    for i, item in ipairs(shopInventory) do
        love.graphics.setFont(smallatro)
        local x = 50
        local y = shopY + (i - 1) * (buttonHeight + buttonSpacing)
        local itemprice
    -- Background box
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 8, 8)
        itemprice = item.cost
        if inflationActive then
            itemprice = itemprice * 5
        end
        if KingAbilities.active["expensve"] == true then
            itemprice = math.floor((itemprice * 1.5) + 0.5)
        end
        
    -- Name + cost
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(item.name .. " - Cost: " .. itemprice, x + 10, y + 10, buttonWidth - 20, "left")

    -- Description
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(item.description, x + 10, y + 30, buttonWidth - 20, "left")

    -- Disabled overlay
        local disabled = (material < itemprice) or (not item.multiBuy and Shop.bought[item.id]) or item._boughtInstance
        if disabled then
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 8, 8)
            if (not item.multiBuy and Shop.bought[item.id]) or item._boughtInstance then
                love.graphics.setColor(1, 0, 0)
                love.graphics.setFont(balabig)
                love.graphics.printf("BOUGHT", x, y + buttonHeight/2 - 8, buttonWidth, "center")
            end
        end
    end
    love.graphics.setColor(0, 1, 0.25)
    love.graphics.rectangle("fill", 500, 400, 200, 50, 8, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(balafont)
    love.graphics.printf("To Board Editor", 500, 413, 200, "center")
    love.graphics.setColor(0, 0.25, 1)
    love.graphics.rectangle("fill", 500, 460, 200, 50, 8, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(balafont)
    love.graphics.printf("Reroll (" .. rerollcost .. " Mat)", 500, 473, 200, "center")
    if material < rerollcost then
        love.graphics.setColor(0,0,0,0.5)
        love.graphics.rectangle("fill", 500, 460, 200, 50, 8, 8)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(balabig)
    love.graphics.printf("Upcoming Boss:", 500, 170, 200, "center")
    love.graphics.printf(nextroundBossName, 500, 200, 200, "center")
    love.graphics.setFont(smallatro)
    love.graphics.printf(nextroundBossDesc, 500, 250, 200, "center")
    if toNextMultipleOf5 > 1 then
        love.graphics.printf("(In " .. toNextMultipleOf5 .. " rounds)", 500, 350, 200, "center")
    else
        love.graphics.printf("(This round)", 500, 350, 200, "center")
    end
end
function gameoverDraw()
        love.graphics.setFont(balabig)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Game Over :(", 200, 24, 400, "center")
        love.graphics.setFont(balafont)
        love.graphics.printf("You ran out of moves.", 50, 70, 300, "left")
        love.graphics.setColor(1,1,1,0.6)
        love.graphics.printf("Seed: " .. seed, 0, 400, 800, "center")
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("[ESC] Quit Game | [R] New Run", 0, 560, 800, "center")
end
function love.draw()
    if settings.aa then
        canvas:setFilter("linear", "linear")
    else
        canvas:setFilter("nearest", "nearest")
    end
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    --begin drawing stuff to canvas
    if gamestate == 'playinground' then
        boardDraw()
    elseif gamestate == 'woncheck' or gamestate == 'wonstale' or gamestate == 'kingcapture' or gamestate == 'devwin' or gamestate == 'wontutorial' then
        endofroundDraw()
    elseif gamestate == 'inshop' then
        shopDraw()
    elseif gamestate == 'editingboard' then
        editDraw()
    elseif gamestate == 'gameover' then
        gameoverDraw()
    elseif gamestate == 'title' then
        menu.draw(800, 600)
        if inSettings then
            settingspage.draw()
        end
    end
    if InTutorial and gamestate ~= 'title' then
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", 250, 500, 300, 75, 8, 8)
        love.graphics.setFont(balafont)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("Tutorial (" .. TutorialState .. "/10)", 0, 510, 800, "center")
        love.graphics.setFont(smallatro)
        love.graphics.printf(TutorialText[TutorialState], 270, 530, 270, "left")
    end
    --end drawing stuff to canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader(shaders[currentShader])
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    if settings.aa then
        love.graphics.setShader(alias)
    else
        love.graphics.setShader()
    end
    alias:send("texSize", { canvas:getWidth(), canvas:getHeight() })
    local windoww, windowh = love.graphics.getDimensions()
    offsetX = (windoww - 800*scale)/2
    love.graphics.draw(canvas, offsetX, 0, 0, scale)
    love.graphics.setShader()
    Img = nil
end
local function cleanErrorMessage(msg)
    -- Removes "filename:line: " at the start
    return msg:gsub("^[^:]+:%d+: ", "")
end
function love.keypressed(key, _, isrepeat)
    if key == "r" and debuggame and not isrepeat then
        bossReroll()
    end
end
function love.errorhandler(msg)
    msg = tostring(msg)
    msg = cleanErrorMessage(msg)
    local trace = debug.traceback("", 2)  -- skip errorhandler itself
    local lines = {}

    for line in (trace .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line)
    end

    -- Make sure graphics + events exist
    if not love.graphics or not love.event then
        return
    end

    -- Reset graphics state
    love.graphics.reset()

    -- Custom font
    local font = love.graphics.newFont("balafont.ttf", 22)
    local bigfont = love.graphics.newFont("balafont.ttf", 36)
    love.graphics.setFont(font)

    -- Setup shader (time-based shifting gradient)
    local shader = love.graphics.newShader('error.glsl')

    local timer = 0
    local width, height = love.graphics.getDimensions()
    local draw = function()
        local dt = love.timer.step()
        timer = timer + dt
        local width = love.graphics.getWidth()
        local height = love.graphics.getHeight()

        shader:send("iTime", timer)
        shader:send("iResolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        love.graphics.setShader(shader)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setShader()
        love.graphics.setFont(bigfont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Whuh-oh! The game crashed.", 50, 24, width - 100, "center")
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(font)
        love.graphics.printf(msg, 50, 70, width - 100, "left")
        love.graphics.printf("Here's the code (ignore this):", 50, 118, width - 100, "left")
        for i, line in ipairs(lines) do
            love.graphics.printf(line, 50, 132 + (24*i), width - 100, "left")
        end
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("[ESC] Quit Game", 0, height - 60, width, "center")

        love.graphics.present()
    end
    return function()
        love.window.setTitle("Scaccombo: ERROR")
        love.event.pump()
        -- Handle events
        for n, a, b, c in love.event.poll() do
            if n == "quit" then
                return 1
            elseif n == "keypressed" then
                if love.keyboard.isDown('escape') then
                    return 1
                end
            end
        end
        draw()
    end
end
