--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

class('DefaultCharacter').extends(gfx.sprite)

function DefaultCharacter:init(x, y, image, health, collesionX, collesionY, collesionSizeX, collisionSizeY, projectileSpeed)
    self:moveTo(x, y)
    self:setImage(image)
    self:setCollideRect(collesionX, collesionY, collesionSizeX or image:getWidth(), collisionSizeY or image:getHeight())
    self.health = health
    self.projectileSpeed = projectileSpeed
end

function DefaultCharacter:update()

    -- Keep player within screen bounds
    local x, y = self:getPosition()
    local width, height = self:getSize()
    x = math.max(width / 2, math.min(pd.display.getWidth() - width / 2, x))
    y = math.max(height / 2, math.min(pd.display.getHeight() - height / 2, y))
    self:moveTo(x, y)

end