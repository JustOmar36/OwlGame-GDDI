import "defaultGadget"

--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

class("Scooter").extends("DefaultGadget")

function Scooter:init(x, y, damage, collesionX, collesionY, collesionSizeX, collisionSizeY, speed, cost, knockback)
    self:moveTo(x, y)
    self.image = gfx.image.new("./images/V-Scooter.png"):scaledImage(2)
    self:setCollideRect(collesionX, collesionY, collesionSizeX, collisionSizeY)
    self.damage  = damage
    self.speed = speed
    self.cost = cost
    self.knockback = knockback
    self:setZIndex(1)

    self.collidedEnemies = {}

    Scooter.super.init(self, x, y, self.image, damage, collesionX, collesionY, collesionSizeX, collisionSizeY, speed, cost)
end

function Scooter:getKnockback()
    return self.knockback
end

function Scooter:setKnockback(knockback)
    self.knockback = knockback
end

function Scooter:collideWith(target)
    -- Only allow projectiles to collide with the player
    if (target and target.className and target.tag == "Enemy") then
        if (not self.collidedEnemies[target]) then
            print("Scooter hit " .. tostring(target.tag))
            if target.health then
                target.health = target.health - self.damage
                for i = 1, self:getKnockback() do
                    target:moveTo((target.x + i), target.y)
                end
                self.collidedEnemies[target] = true
            end
        end
    end    
end

function Scooter:getCost()
    return self.cost
end

function Scooter:collisionResponse(other)
    return "overlap" -- allows overlapping without pushing back
end

function Scooter:update()
    local x, y = self:getPosition()

    local actualX, actualY, collisions, numberOfCollisions = self:moveWithCollisions(x + self.speed, y)

    if numberOfCollisions > 0 then
        for i = 1, numberOfCollisions do
                local collision = collisions[i]
                self:collideWith(collision.other)
        end
    end

    -- Remove projectile if it goes off-screen
    if x < 0 or x > pd.display.getWidth() or y < 0 or y > pd.display.getHeight() then
        self:remove()
    end

end