-- settingspage.lua
local settingspage = {}
local settings = require('settings')
-- button definitions
local fullscreen = false
settingspage.buttons = {
    {
        text = "Toggle Smooth Image",
        x = 100, y = 100,
        w = 200, h = 50,
        color = {0.8, 0.3, 0.3},
        onClick = function()
            -- flip antialias boolean and save
            swapAA()
            saveSettings()
        end
    },
    {
        text = "Back",
        x = 100, y = 200,
        w = 200, h = 50,
        color = {0.3, 0.8, 0.3},
        onClick = function()
            inSettings = false
        end
    },
    {
        text = "Toggle Fullscreen",
        x = 500, y = 100,
        w = 200, h = 50,
        color = {0.3, 0.3, 0.8},
        onClick = function()
            if fullscreen == false then
                love.window.setMode(0, 0, {
                    fullscreen = true,
                    fullscreentype = "desktop",
                    resizable = true
                })
                fullscreen = true
            else
                love.window.setMode(1280, 720, {resizable = true, minwidth = 400, minheight = 300})
                fullscreen = false
            end
        end
    },
    {
        text = "Change BG color",
        x = 500, y = 200,
        w = 200, h = 50,
        color = {0.8, 0.3, 0.8},
        onClick = function()
            switchShader()
        end
    },
    {
        text = 'Close Game',
        x = 500, y = 300,
        w = 200, h = 50,
        color = {1, 0, 0},
        onClick = function()
            closeGame()
        end
    },
    {
        text = 'Restart Game',
        x = 100, y = 300,
        w = 200, h = 50,
        color = {0, 0.5, 1},
        onClick = function()
            saveSettings()
            love.event.quit("restart")
        end
    }
}

-- draw buttons
function settingspage.draw()
    local outlinesize = 2
    local windowWidth, windowHeight = love.graphics.getDimensions()
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", 20, 20, 760, 560, 8, 8)
    love.graphics.setColor(1,1,1)
    local bigfont = love.graphics.newFont('balafont.ttf', 32)
    love.graphics.setFont(bigfont)
    love.graphics.printf("Settings", 0, 40, 800, "center")
    love.graphics.setFont(balafont)
    for _, btn in ipairs(settingspage.buttons) do
        love.graphics.setColor(btn.color)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(outlinesize)
        love.graphics.rectangle('line', btn.x+(outlinesize/2), btn.y+(outlinesize/2), btn.w-outlinesize, btn.h-outlinesize, 4, 4)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(btn.text, btn.x, btn.y + btn.h/4, btn.w, "center")
    end
    love.graphics.setColor(1,1,1,0.7)
    love.graphics.printf("Seed: " .. seed, 0, 400, 800, "center")
    love.graphics.setColor(1,1,1,1)
end

-- handle clicks
function settingspage.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(settingspage.buttons) do
            if x >= btn.x and x <= btn.x+btn.w and y >= btn.y and y <= btn.y+btn.h then
                btn.onClick()
            end
        end
    end
end

return settingspage
