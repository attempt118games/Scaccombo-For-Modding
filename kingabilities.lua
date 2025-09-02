local KingAbilities = {}
KingAbilities.defs = {}
KingAbilities.active = {}
KingAbilities.seed = os.time()
--Loads abilities
function PrimeKingAbilities()
    for i, _ in pairs(KingAbilities.defs) do
        KingAbilities.active[i] = false
    end
end
--Definition for King Abilities
function KingAbilities.define(def)
    assert(def.id, "Ability must have an ID!")
    def.name = def.name or "ERROR. KING ABILITY HAS NO NAME."
    def.requires = def.requires or {}
    def.minround = def.minround or 0
    KingAbilities.defs[def.id] = def
    return def
end
--Checks if all abilities are already active
local function areThereMore()
    local active = 0
    for i, _ in pairs(KingAbilities.active) do
        if KingAbilities.active[i] == true then
            active = active + 1
        end
    end
    if active == #KingAbilities.defs then
        return false
    end
    return false
end
--Checks if an ID's requires are all active
local function checkValid(id)
    for _, ka in pairs(KingAbilities.defs) do
        if ka.id == id then
            if ka.requires then
                local required = 0
                for i in pairs(ka.requires) do
                    if KingAbilities.active[i] then
                        required = required + 1
                    end
                end
                if required == #ka.requires then
                    return true
                end
            else
                return true
            end
        end
    end
    return false
end
--Looks for a random inactive ability
function KingAbilities.randomAbility(currentround)
    if currentround % 5 ~= 4 then return end
    if not areThereMore() then
        local keys = {}
        for k, _ in pairs(KingAbilities.defs) do table.insert(keys, k) end
        local choice
        repeat
            choice = keys[math.random(#keys)]
        until checkValid(choice) and KingAbilities.active[choice] ~= true
        KingAbilities.active[choice] = true
        return choice
    end
    return
end
--Finds the name of the specified ID
function KingAbilities.getName(id)
    for _, k in pairs(KingAbilities.defs) do
        if k.id == id then
            return k.name
        end
    end
end
----  --  --  --  --  --  ----
-- King Ability Definitions --
--  --  --  --  --  --  --  --
KingAbilities.define{
    id = "the_original",
    name = "King can now capture"
}
KingAbilities.define{
    id = "the_slip",
    name = "King moves an additional time per turn"
}
KingAbilities.define{
    id = "waytoofast",
    name = "Permanent -5 Turns for non-boss rounds"
}
KingAbilities.define{
    id = "expensve",
    name = "Shop items are X1.5 more expensive (permanent)"
}
KingAbilities.define{
    id = 'payout',
    name = "Bosses no longer give defeat payout"
}
KingAbilities.define{
    id = 'idk',
    name = "Rounds no longer give defeat payout",
    requires = {'payout'}
}

return KingAbilities