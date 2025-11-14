
import "defaultCharacter"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("OwlKing").extends("DefaultCharacter")


function OwlKing:init(x, y, health, maxHealth, collesionX, collesionY, collisionSizeX, collisionSizeY, speed, damage)
    self.playerImage = gfx.image.new("./images/OwlKing.png"):scaledImage(4)
    self.health = health
    self.maxHealth = maxHealth
    self.speed = speed
    self.damage = damage
    self:setZIndex(1)

    --enemy tag
    self.tag = "Enemy"
    self.healthtag = "OwlKing"

    OwlKing.super.init(self, x, y, self.playerImage, health, maxHealth, collesionX, collesionY, collisionSizeX, collisionSizeY, 0, 0, self.tag)
end

function OwlKing:collideWith(target)
    -- Only allow projectiles to collide with the player
    if (target and target.className and target.tag == "Player") then
        self:moveTo(self.x + 10, self.y) -- Knockback effects
        print("OwlKing hit " .. target.tag)
        if target.health then
            if target.takeDamage then
                target:takeDamage(self.damage, self)
            else
                target.health = target.health - self.damage
            end
        end
    end
end

function OwlKing:getXLocation() return self.x end
function OwlKing:setXLocation(x) self.x = x end

function OwlKing:getYLocation() return self.y end
function OwlKing:setYLocation(y) self.y = y end

function OwlKing:getSpeed() return self.speed end
function OwlKing:setSpeed(speed) self.speed = speed end

function OwlKing:getDamage() return self.damage end
function OwlKing:setDamage(damage) self.damage = damage end

function OwlKing:getHealthTag() return self.healthtag end

-- allows overlapping without pushing back
function OwlKing:collisionResponse(other) return "overlap" end


function OwlKing:update()
    OwlKing.super.update(self)

    local x, y = self:getPosition()
    local actualX, actualY, collisions, numberOfCollisions = self:moveWithCollisions(x - self.speed, y)

    if numberOfCollisions > 0 then
        for i = 1, numberOfCollisions do
                local collision = collisions[i]
                self:collideWith(collision.other)
        end
    end
    -- Remove if health is 0 or below
    if self.health <= 0 then
        self:remove()
    end

end

