local Sounds = {
    place = love.audio.newSource("assets/sounds/sfx/place.ogg", "static"),
    cash = love.audio.newSource("assets/sounds/sfx/money.ogg", "static")
}

function PlaySFX(name)
    if Sounds[name] then
        local clone = Sounds[name]:clone()
        clone:play()
        clone = nil
    end
end