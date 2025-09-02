-- shop.lua
local recipes = require('recipes')
local Shop = {
    items = {},       -- all shop item definitions
    bought = {},      -- tracks single-buy purchases
    pool = {},        -- items eligible to spawn in shop
}
local KingAbilities = require('kingabilities')
-- Rarity weights (higher number = more likely)
local rarityWeights = {
    [1] = 50, -- common
    [2] = 20, -- uncommon
    [3] = 4, -- rare
    [4] = 1,  -- ultra rare
    [5] = 0.05 -- like, insanely rare
}

-------------------------------------------------
-- Definition
-------------------------------------------------
function Shop.define(def)
    def.id = def.id or error("Shop item missing id")
    def.name = def.name or "Unnamed"
    def.description = def.description or "No description."
    def.cost = def.cost or 1
    def.imagePath = def.imagePath or "assets/idk.png"
    def.rarity = def.rarity or 1
    def.multiBuy = def.multiBuy or false
    def.unlocked = def.unlocked or false
    def.requires = def.requires or nil
    def.effect = def.effect or function() end

    Shop.items[def.id] = def
    table.insert(Shop.pool, def)
end

-------------------------------------------------
-- Weighted random rarity
-------------------------------------------------
function Shop.weightedRandom()
    local total = 0
    for r, w in pairs(rarityWeights) do total = total + w end
    local pick = love.math.random(total)

    local acc = 0
    local chosenRarity = 1
    for r, w in pairs(rarityWeights) do
        acc = acc + w
        if pick <= acc then
            chosenRarity = r
            break
        end
    end

    -- Collect candidates of that rarity
    local candidates = {}
    for _, item in ipairs(Shop.pool) do
        if item.rarity == chosenRarity then
            table.insert(candidates, item)
        end
    end

    if #candidates == 0 then return nil end
    return candidates[love.math.random(#candidates)]
end
function Loadmoddedshopitem(name, def)
    Shop.items[name] = def
    table.insert(Shop.pool, def)
end
-------------------------------------------------
-- Roll shop inventory
-------------------------------------------------
local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function seedStringToNumber(seedStr)
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
function Shop.roll(numItems)
    local rolled = {}
    local attempts = 0

    while #rolled < numItems and attempts < 500 do
        attempts = attempts + 1
        math.randomseed(seedStringToNumber(shopseed))
        local candidate = Shop.weightedRandom()

        if candidate
        and (candidate.unlocked
        or ((not candidate.requires) or Shop.bought[candidate.requires]))
        and (candidate.multiBuy or not Shop.bought[candidate.id])
        then
            -- prevent duplicates in same shop unless multiBuy
            local duplicate = false
            if not candidate.multiBuy then
                for _, r in ipairs(rolled) do
                    if r.id == candidate.id then
                        if candidate.requires then
                            print("Rolled candidate:", candidate.id, "requires", candidate.requires, "bought[requires] =", candidate.requires and Shop.bought[candidate.requires])
                        end
                        duplicate = true
                        break
                    end
                end
            end

            if not duplicate then
                local instance = {}
                for k, v in pairs(candidate) do
                instance[k] = v
                end
                instance._boughtInstance = false
                table.insert(rolled, instance)
            end
        end
    end

    -- if still too few, pad with cheap "filler" items
    while #rolled < numItems do
        table.insert(rolled, {
            id = "filler_" .. #rolled,
            name = "Empty Slot",
            description = "Nothing here...",
            cost = 0,
            imagePath = "assets/idk.png",
            rarity = 1,
            multiBuy = false,
            effect = function() end
        })
    end
    if InTutorial and TutorialState == 4 then
        rolled = {Shop.items['unlockbp_bishop'], Shop.items['unlockrp_knight'], Shop.items['token_small'], Shop.items['token_med'], Shop.items['token_med']}
    end
    for _, k in pairs(rolled) do
        print(k.id)
    end
    return rolled
end


-------------------------------------------------
-- Buy item
-------------------------------------------------
function Shop.buy(item)
    if not item then return false end
    local itemcost = item.cost
    if inflationActive then
        itemcost = itemcost * 5
    end
    if KingAbilities.active['expensve'] == true then
        itemcost = math.floor((itemcost * 1.5) + 0.5)
    end
    if material < itemcost then return false end
    material = material - itemcost
    item.effect()

    if not item.multiBuy then
        Shop.bought[item.id] = true
    end
    return true
end

-------------------------------------------------
-- Reset between runs
-------------------------------------------------
function Shop.reset()
    Shop.bought = {}
end

-------------------------------------------------
-- Shop Items
-------------------------------------------------

Shop.define{
    id = "unlockbp_bishop",
    name = "Bishop Blueprint",
    description = "Unlocks the Bishop blueprint.",
    cost = 10,
    rarity = 1,
    multiBuy = false,
    unlocked = true,
    effect = function()
        Blueprint.unlock("Bishop")
    end,
    imagePath = "assets/bishop.png"
}
Shop.define{
    id = "unlockbp_archer",
    name = "Archer Blueprint",
    description = "Unlocks the Archer blueprint.",
    cost = 15,
    rarity = 2,
    multiBuy = false,
    requires = "unlockbp_bishop",
    effect = function()
        Blueprint.unlock("Archer")
    end,
    imagePath = "assets/bishop.png"
}
Shop.define{
    id = "unlockbp_rook",
    name = "Rook Blueprint",
    description = "Unlocks the Rook blueprint.",
    cost = 20,
    rarity = 2,
    multiBuy = false,
    requires = 'unlockbp_bishop',
    effect = function()
        Blueprint.unlock("Rook")
    end
}
Shop.define{
    id = "unlockbp_cannon",
    name = "Cannon Blueprint",
    description = "Unlocks the Cannon blueprint.",
    cost = 25,
    rarity = 3,
    multiBuy = false,
    requires = 'unlockbp_rook',
    effect = function()
        Blueprint.unlock("Cannon")
    end
}
Shop.define{
    id = "unlockbp_queen",
    name = "Queen Blueprint",
    description = "Unlocks the Queen blueprint.",
    cost = 50,
    rarity = 4,
    multiBuy = false,
    requires = 'unlockbp_rook',
    effect = function()
        Blueprint.unlock("Queen")
    end
}
Shop.define{
    id = "token_small",
    name = "Piece Token",
    description = "Gain a piece token.",
    cost = 5,
    rarity = 2,
    multiBuy = true,
    unlocked = true,
    effect = function() Piecetokens = Piecetokens + 1 end,
    imagePath = "assets/materials.png"
}
Shop.define{
    id = "token_med",
    name = "5 Piece Tokens",
    description = "Gain 5 piece tokens.",
    cost = 25,
    rarity = 3,
    multiBuy = true,
    unlocked = true,
    effect = function() Piecetokens = Piecetokens + 5 end,
    imagePath = "assets/idk.png"
}
Shop.define{
    id = "token_big",
    name = "10 Piece Tokens",
    description = "Gain 10 piece tokens.",
    cost = 50,
    rarity = 4,
    multiBuy = true,
    unlocked = true,
    effect = function() Piecetokens = Piecetokens + 10 end,
    imagePath = "assets/idk.png"
}
Shop.define{
    id = "token_huge",
    name = "50 Piece Tokens",
    description = "Gain 50 piece tokens (half price).",
    cost = 125,
    rarity = 4,
    multiBuy = true,
    unlocked = true,
    effect = function() Piecetokens = Piecetokens + 50 end,
    imagePath = "assets/idk.png"
}
Shop.define{
    id = "unlockrp_knight",
    name = "Knight Recipe",
    description = "Unlocks the Knight recipe.",
    cost = 5,
    rarity = 1,
    multiBuy = false,
    unlocked = true,
    effect = function() Recipes.defs.Knight.unlocked = true end
}
Shop.define{
    id = "unlockrp_bishop",
    name = "Bishop Recipe",
    description = "Unlocks the Bishop recipe.",
    cost = 15,
    rarity = 2,
    multiBuy = false,
    requires = 'unlockbp_bishop',
    effect = function() Recipes.defs.Bishop.unlocked = true end
}
Shop.define{
    id = "unlockrp_archer",
    name = "Archer Recipe",
    description = "Unlocks the Archer recipe.",
    cost = 20,
    rarity = 2,
    multiBuy = false,
    requires = 'unlockbp_archer',
    effect = function() Recipes.defs.Archer.unlocked = true end
}
Shop.define{
    id = "unlockrp_rook",
    name = "Rook Recipe",
    description = "Unlocks the Rook recipe.",
    cost = 30,
    rarity = 3,
    multiBuy = false,
    requires = 'unlockbp_rook',
    effect = function() Recipes.defs.Rook.unlocked = true end
}
Shop.define{
    id = "unlockrp_cannon",
    name = "Cannon Recipe",
    description = "Unlocks the Cannon recipe.",
    cost = 35,
    rarity = 3,
    multiBuy = false,
    requires = 'unlockbp_cannon',
    effect = function() Recipes.defs.Cannon.unlocked = true end
}
Shop.define{
    id = "unlockrp_queen",
    name = "Queen Recipe",
    description = "Unlocks the Queen recipe. (Now the fun begins...)",
    cost = 75,
    rarity = 4,
    multiBuy = false,
    requires = 'unlockbp_queen',
    effect = function() Recipes.defs.Queen.unlocked = true end
}
return Shop
