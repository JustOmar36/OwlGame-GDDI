import "defaultCharacter"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("Player").extends("DefaultCharacter")

function Player:init(x, y, health)
    self.playerImage = gfx.image.new("./images/V-Char-sideways.png"):scaledImage(3)
    self.handImage = gfx.image.new("./images/hand.png"):scaledImage(1.5)
    self.handSprite = gfx.sprite.new(self.handImage)

    -- self.ProjectileImage = gfx.image.new("./images/projectile.png"):scaledImage(1)


    Player.super.init(self, x, y, self.playerImage, health)
end

function Player:updateHand()
    -- Rotate around the far left edge of the hand sprite
    local baseX, baseY = self.handSprite.x, self.handSprite.y

    local crank = playdate.getCrankPosition()
    local crankDirection, acceleratedChange = playdate.getCrankChange()

    if crankDirection ~= 0 then
            local newRotation = 0
            
        if crankDirection > 0 then
            newRotation = self.handSprite:getRotation() + crankDirection
            if newRotation >= 45 and newRotation <= 250 then
                self.handSprite:setRotation(45)
            else
                self.handSprite:setRotation(newRotation)
            end
        else
            newRotation = self.handSprite:getRotation() + crankDirection
            if newRotation <= 250 and newRotation >= 45 then
                self.handSprite:setRotation(250)
            else
                self.handSprite:setRotation(newRotation)
            end
        end
        
    end
    

    local angleRad = math.rad(self.handSprite:getRotation())


    -- Offset from center to far right (positive half width, 0)
    local offsetX = self.handImage.width / 2
    local offsetY = 0

    -- Rotate the offset
    local rotatedOffsetX = offsetX * math.cos(angleRad) - offsetY * math.sin(angleRad)
    local rotatedOffsetY = offsetX * math.sin(angleRad) + offsetY * math.cos(angleRad)

    self.handSprite:moveTo(baseX + rotatedOffsetX, baseY + rotatedOffsetY)

end

-- To shoot a projectile from the hand's tip
-- function Player:shootProjectile()
--     if not self.handSprite then return end
--     local handLength = 20 -- distance from hand base to tip
--     local angleRad = math.rad(self.handSprite:getRotation())
--     local hx, hy = self.handSprite:getPosition()
--     local tipX = hx + math.cos(angleRad) * handLength
--     local tipY = hy + math.sin(angleRad) * handLength

--     local projectile = gfx.sprite.new(self.projectileImage)
--     projectile:moveTo(tipX, tipY)
--     projectile:setRotation(self.handSprite:getRotation())
--     projectile:add()

--     -- Set projectile velocity in the direction of the hand
--     local speed = 5
--     projectile.dx = math.cos(angleRad) * speed
--     projectile.dy = math.sin(angleRad) * speed

--     function projectile:update()
--         self:moveBy(self.dx, self.dy)
--         -- Add collision or off-screen logic here
--     end
-- end

function Player:spawnHand(x, y)
    if self.handSprite then
        self.handSprite:moveTo(x + 17 - self.handImage.width / 2, y + 15) -- Position the hand
        self.handSprite:add()
    end
end

function Player:update()

    -- Keep player within screen bounds
    local x, y = self:getPosition()
    local width, height = self:getSize()
    x = math.max(width / 2, math.min(pd.display.getWidth() - width / 2, x))
    y = math.max(height / 2, math.min(pd.display.getHeight() - height / 2, y))
    self:moveTo(x, y)
    self:spawnHand(x, y)
    self:updateHand()


end