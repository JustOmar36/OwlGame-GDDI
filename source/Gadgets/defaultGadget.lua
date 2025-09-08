--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

class('DefaultGadget').extends(gfx.sprite)

function DefaultGadget:init(x, y, image, damage, collesionX, collesionY, collesionSizeX, collisionSizeY, speed, cost)
    self:moveTo(x, y)
    self:setImage(image)
    self:setCollideRect(collesionX, collesionY, collesionSizeX, collisionSizeY)
    self.damage = damage
    self.speed = speed
    self.cost = cost
end

function DefaultGadget:update()
    local x, y = self:getPosition()
    if x < 0 or x > pd.display.getWidth() or y < 0 or y > pd.display.getHeight() then
        self:remove()
    end
end