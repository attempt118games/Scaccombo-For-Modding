-- menu.lua



local menu = {}

menu.buttons = {
    {text = "Start Game", x = 400, y = 450, w = 300, h = 40, color = {0, 1, 0}, action = function() startround() end},
    {text = "Options", x = 400, y = 500, w = 300, h = 40, color = {0, 0.35, 1}, action = function() inSettings = true end},
    {text = "Exit", x = 400, y = 550, w = 300, h = 40, color = {1, 0, 0}, action = function() love.event.quit() end}
}

function menu.draw(canvasWidth, canvasHeight)
    for _, btn in ipairs(menu.buttons) do
        local bx, by, bw, bh = btn.x, btn.y, btn.w, btn.h

        -- Button background
        love.graphics.setColor(btn.color)
        love.graphics.rectangle("fill", bx - bw/2, by - bh/2, bw, bh, 10, 10)

        -- Button text
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(balafont)
        local textW = balafont:getWidth(btn.text)
        local textH = balafont:getHeight(btn.text)
        love.graphics.print(btn.text, bx - textW/2, by - textH/2)
    end
    local img = titleImage
    local scaleX = 500 / img:getWidth()
    local scaleY = 250 / img:getHeight()
    -- Draw title image centered with breathing and rocking
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.draw(
        titleImage,
        cx_title + (xoffset_title/2), cy_title,  -- apply x offset
        rotation_title,                       -- rotate
        shadow_scale_title/1.75, shadow_scale_title/1.75,             -- scale X/Y
        width_title/2, height_title/2         -- origin at image center
    )
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(
        titleImage,
        cx_title + xoffset_title, cy_title,  -- apply x offset
        rotation_title,                       -- rotate
        scale_title/1.5, scale_title/1.5,             -- scale X/Y
        width_title/2, height_title/2         -- origin at image center
    )
    love.graphics.setColor(1,1,1,0.7)
    love.graphics.setFont(smallatro)
    love.graphics.printf("Seed: " .. seed, 300, 410, 200, "center")
    if debuggame then
        love.graphics.setColor(1,0.4,0,1)
        love.graphics.setFont(smallatro)
        love.graphics.printf("very cool mode enabled", 300, 390, 200, "center")
    end
end

function menu.checkClick(mx, my)
    for _, btn in ipairs(menu.buttons) do
        local bx, by, bw, bh = btn.x, btn.y, btn.w, btn.h
        if mx > bx - bw/2 and mx < bx + bw/2 and my > by - bh/2 and my < by + bh/2 then
            if btn.action then btn.action() end
        end
    end
end
return menu