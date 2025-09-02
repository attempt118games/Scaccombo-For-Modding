StickerType = {}

local function loadImage(sticker)
    local path = sticker.imagePath or "assets/idk.png"
    local img = love.graphics.newImage(path)

    -- Scale stickers to exactly 24x24 regardless of source resolution
    local iw, ih = img:getWidth(), img:getHeight()
    local canvas = love.graphics.newCanvas(24, 24)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(img, 0, 0, 0, 24/iw, 24/ih)
    love.graphics.setCanvas()
    sticker.image = canvas
end

StickerType.Slippery = {
    id = "Slippery",
    name = "Slippery Sticker",
    desc = {"This piece can be moved twice per round."},
    amount = 0,
    returnOnSell = true,
    selfDestruct = false
}

StickerType.Craftsman = {
    id = "Craftsman",
    name = "Craftsman Sticker",
    desc = {"When this piece combines, gain a free combine immediately."},
    amount = 0,
    returnOnSell = true,
    selfDestruct = false
}

StickerType.Value = {
    id = "Value",
    name = "Value Sticker",
    desc = {"When sold, piece gives 3x sell value."},
    amount = 0,
    returnOnSell = false, -- consumed on sell
    selfDestruct = false
}

StickerType.Debuff = {
    id = "Debuff",
    name = "Debuff Sticker",
    desc = {"When this piece captures, the boss is disabled."},
    amount = 0,
    returnOnSell = true,
    selfDestruct = true
}

-- Load all sticker images (scaled to 24x24)
for _, sticker in pairs(StickerType) do
    loadImage(sticker)
end

return StickerType
