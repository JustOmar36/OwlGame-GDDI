
import "defaultCharacter"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("OwlBear").extends("DefaultCharacter")

function OwlBear:init(x, y, health, collesionX, collesionY, collisionSizeX, collisionSizeY, speed, damage)
    self.playerImage = gfx.image.new("./images/OwlBear.png"):scaledImage(2)
    self.speed = speed
    self.damage = damage
    OwlBear.super.init(self, x, y, self.playerImage, health, collesionX, collesionY, collisionSizeX, collisionSizeY)
end

function OwlBear:collideWith(target)
    -- Only allow projectiles to collide with the player
    if (target and target.className and target.className == "Player") then
        self:moveTo(self.x + 10, self.y) -- Knockback effects
        print("OwlBear hit Player")
        if target.health then
            target.health = target.health - self.damage
        end
    end
    
end

function OwlBear:collisionResponse(other)
    return "overlap" -- allows overlapping without pushing back
end


function OwlBear:update()
    OwlBear.super.update(self)

    -- Move left across the screen
    local x, y = self:getPosition()
    self:moveWithCollisions(x - self.speed, y)

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

