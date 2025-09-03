-- recipes.lua
local Recipes = {}
function Loadmoddedrecipe(defname, def)
    Recipes.defs[defname] = def
end
-- Define recipes (pieces player can place in editor)
Recipes.defs = {
    Pawn = {
        name = "Pawn",
        place = 1,
        sell = 1,
        unlocked = true,  -- always available
        desc = {"The humble pawn.", "Cheap and refundable."},
        image = "assets/pawn.png",
    },
    Knight = {
        name = "Knight",
        place = 2,
        sell = 1,
        unlocked = false, -- unlock when its recipe is discovered
        desc = {"Moves in L shapes.", "Costs 2 to place."},
        image = "assets/knight.png",
    },
    Bishop = {
        name = "Bishop",
        place = 4,
        sell = 3,
        unlocked = false,
        desc = {"Moves diagonally.", "Costs 4 to place."},
        image = "assets/bishop.png",
    },
    Archer = {
        name = "Archer",
        place = 4,
        sell = 3,
        unlocked = false,
        desc = {"Custom ranged unit.", "Costs 4 to place."},
        image = "assets/archer.png",
    },
    Rook = {
        name = "Rook",
        place = 8,
        sell = 7,
        unlocked = false,
        desc = {"Moves straight.", "Costs 8 to place."},
        image = "assets/rook.png",
    },
    Cannon = {
        name = "Cannon",
        place = 8,
        sell = 7,
        unlocked = false,
        desc = {"Special attack unit.", "Costs 8 to place."},
        image = "assets/cannon.png",
    },
    Queen = {
        name = "Queen",
        place = 16,
        sell = 15,
        unlocked = false,
        desc = {"The strongest piece.", "Costs 16 to place."},
        image = "assets/queen.png",
    },
    -- START MODDED RECIPES







    --END MODDED RECIPES
}

return Recipes
