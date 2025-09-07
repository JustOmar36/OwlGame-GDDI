import "CoreLibs/timer"
import "defaultCharacter"
import "../Projectiles/Projectiles"

local pd <const> = playdate
local gfx <const> = pd.graphics
local offset <const> = 10

class("Player").extends("DefaultCharacter")

function Player:init(x, y, health, collesionX, collesionY, collisionSizeX, collisionSizeY, projectileSpeed, attackFrquencyTimer)
    self.playerImage = gfx.image.new("./images/V-Char-sideways.png"):scaledImage(2)

    self.handImage = gfx.image.new("./images/hand.png")
    self.handSprite = gfx.sprite.new(self.handImage)
    self.attackFrequencyTimer = attackFrquencyTimer
    self.projectileSpeed = projectileSpeed

    self.handSprite:setZIndex(1)
    self.lastShotTime = playdate.getCurrentTimeMilliseconds()

    Player.super.init(self, x, y, self.playerImage, health, collesionX, collesionY, collisionSizeX, collisionSizeY, projectileSpeed)
end

function Player:fireProjectile(handX, handY)
    local projectileImage = gfx.image.new("./images/Fireball.png"):scaledImage(0.4)
    local projectile = Projectiles(projectileImage, 5, self.projectileSpeed, 5, 5)
    projectile:fire(handX, handY)

end

function Player:updateHand()
    -- Rotate around the far left edge of the hand sprite
    local baseX, baseY = self.handSprite.x, self.handSprite.y
 
    local crankPosition = playdate.getCrankPosition()
    local angleRad = math.rad(self.handSprite:getRotation())

    -- Offset from center to far right (positive half width, 0)
    local offsetX = self.handImage.width / 2
    local offsetY = 0

    -- Rotate the offset
    local rotatedOffsetX = offsetX * math.cos(angleRad) - offsetY * math.sin(angleRad)
    local rotatedOffsetY = offsetX * math.sin(angleRad) + offsetY * math.cos(angleRad)

    self.handSprite:moveTo(baseX + rotatedOffsetX, baseY + rotatedOffsetY)
    self.handSprite:setRotation(crankPosition)
    
end

function Player:getHealth()
    return self.health
end

function Player:spawnHand(x, y)
    if self.handSprite then
        self.handSprite:moveTo(x - 5 , y + 8) -- Position the hand
        self.handSprite:add()
    end
end

function Player:update()

    local timeNow = playdate.getCurrentTimeMilliseconds()

    -- Keep player within screen bounds
    local x, y = self:getPosition()

    self:moveTo(x, y)
    self:spawnHand(x, y)
    self:updateHand()

    --Fire every 2 seconds
    if timeNow - self.lastShotTime >= self.attackFrequencyTimer then
        self:fireProjectile(self.handSprite.x, self.handSprite.y)
        self.lastShotTime = timeNow
    end

    if self.health <= 0 then
        self.handSprite:remove()
    end

end