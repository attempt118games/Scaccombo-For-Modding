-- music.lua
local Music = {}

local tracks = {}
local current, nextTrack
local fadeTime = 0.5
local fadeTimer = 0

function Music.load()
    Titletrack = love.audio.newSource("assets/sounds/title.wav", "stream")
    -- load all round variations
    tracks.round1       = love.audio.newSource("assets/sounds/round1.ogg", "stream")
    tracks.round2       = love.audio.newSource("assets/sounds/round2.ogg", "stream")
    tracks.round3       = love.audio.newSource("assets/sounds/round3.ogg", "stream")
    tracks.round4       = love.audio.newSource("assets/sounds/round4.ogg", "stream")
    tracks.boss         = love.audio.newSource("assets/sounds/boss.ogg", "stream")
    tracks.shop         = love.audio.newSource("assets/sounds/shop.ogg", "stream")
    tracks.shopInflated = love.audio.newSource("assets/sounds/shopInflation.ogg", "stream")
    tracks.editor = love.audio.newSource("assets/sounds/editor.ogg", "stream")
    tracks.editorboss = love.audio.newSource("assets/sounds/prebossEditor.ogg", "stream")
    for _,src in pairs(tracks) do
        src:setLooping(true)
        src:setVolume(0)
        src:play() -- important: ALL tracks play simultaneously
    end
    Titletrack:setLooping(true)
    Titletrack:setVolume(1)
    Titletrack:play()
end

function Music.play(name)
    if current == tracks[name] then return end
    nextTrack = tracks[name]
    fadeTimer = fadeTime
end

function Music.update(dt)
    if fadeTimer > 0 then
        fadeTimer = math.max(0, fadeTimer - dt)
        local t = 1 - (fadeTimer / fadeTime)

        if current then
            current:setVolume(1 - t) -- fade out
        else
            Titletrack:setVolume(1 - t)
        end
        if nextTrack then
            nextTrack:setVolume(t) -- fade in
            if fadeTimer == 0 then
                current = nextTrack
                nextTrack = nil
            end
        end
    end
end
function Music.instaplay(name)
    return
end

-- shortcuts
function Music.round(n)  Music.play("round"..n) end
function Music.boss()    Music.play("boss") end
function Music.editor(n) if n then Music.play("editorboss") else Music.play("editor") end end
function Music.shop(infl)
    if infl then Music.play("shopInflated") else Music.play("shop") end
end

return Music