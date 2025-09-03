local ModLoader = {}
local Shop = require('shop')
local Blueprints = require('blueprints')
local BossModifiers = require('boss_modifiers')
local Recipes = require('recipes')
-- Create the Mods table that mod authors will use
-- These are just arrays that will hold the raw definitions
Mods = {
    Piece = {},
    Blueprint = {},
    ShopItem = {},
    BossType = {},
    Recipe = {}
}
function Mods.ShopDefine(def)
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

    Mods.ShopItem[def.id] = def
end
function Mods.BlueprintDefine(def)
    assert(def.name, "Blueprint must have a name")
    assert(def.inputs, "Blueprint must have input pieces")
    assert(type(def.result) == "table" and def.result, "Invalid PieceType")
    def.name = def.name or "error"
    def.unlocked = def.unlocked_default or false
    def.discovered = false
    def.unlocks = def.unlocks or {}
    def.path = def.path or 'assets/idk.png'
    Mods.Blueprint[def.name] = def
    return def
end
function Mods.BossType.define(def)
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
    Mods.BossType[def.id] = def
    return def
end
-- Load and execute mod.lua if it exists
function loadMods()
    local modFile = "mod.lua"
    local fileInfo = love.filesystem.getInfo(modFile)
    
    if fileInfo then
        print("Loading mods from " .. modFile)
        
        -- Execute the mod file - this will populate the Mods tables
        local success, errorMsg = pcall(function()
            love.filesystem.load(modFile)()
        end)
        if not success then
            print("Error loading mod file: " .. errorMsg)
            return false
        end
        
        integrateMods()
        return true
    else
        print("No mod file found, running vanilla game")
        return false
    end
end
function integrateMods()
    for pieceName, pieceDef in pairs(Mods.Piece) do
        Loadmoddedpiece(pieceName, pieceDef)
        pieces[pieceName] = pieceDef
    end
    for recipeDef in ipairs(Mods.Recipe) do
        Loadmoddedrecipe(recipeDef.name, recipeDef)
    end
    for bossDef in ipairs(Mods.BossType) do
        Loadmoddedboss(bossDef)
    end
    for shopName, shopDef in pairs(Mods.ShopItem) do
        Loadmoddedshopitem(shopDef.id, shopDef)
    end
end