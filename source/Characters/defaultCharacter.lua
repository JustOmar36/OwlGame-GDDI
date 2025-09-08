--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

class('DefaultCharacter').extends(gfx.sprite)

function DefaultCharacter:init(x, y, image, health, collesionX, collesionY, collesionSizeX, collisionSizeY, projectileSpeed, projectileDamage, tag)
    self:moveTo(x, y)
    self:setImage(image)
    self:setCollideRect(collesionX, collesionY, collesionSizeX, collisionSizeY)
    self.health = health
    self.projectileSpeed = projectileSpeed
    self.projectileDamage = projectileDamage
    self.tag = tag
end

--Projectile Getters and Setters

function DefaultCharacter:setProjectileSpeed(speed)
    self.projectileSpeed = speed
end

function DefaultCharacter:getProjectSpeed()
    return self.projectileSpeed
end

function DefaultCharacter:SetProjectileDamage(damage)
    self.projectileDamage = damage
end

function DefaultCharacter:getProjectileDamage()
    return self.projectileDamage
end

function DefaultCharacter:update()

    -- Keep player within screen bounds
    local x, y = self:getPosition()
    local width, height = self:getSize()
    x = math.max(width / 2, math.min(pd.display.getWidth() - width / 2, x))
    y = math.max(height / 2, math.min(pd.display.getHeight() - height / 2, y))
    self:moveTo(x, y)

end