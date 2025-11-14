import "defaultCharacter"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Disable some diagnostics for this file because we use dynamic fields
-- (e.g. injecting `tag`, `vx`, `vy`) and Playdate collision responses
---@diagnostic disable: undefined-field, inject-field, return-type-mismatch
class("FlyingOwl").extends("DefaultCharacter")


function FlyingOwl:init(x, y, health, maxHealth, collesionX, collesionY, collisionSizeX, collisionSizeY, speed, projectileSpeed, projectileDamage, attackFrquencyTimer)
    self.playerImage = gfx.image.new("./images/Barn Owl.png"):scaledImage(2)
    self.health = health
    self.maxHealth = maxHealth
    self.speed = speed
    self.projectileSpeed = projectileSpeed
    self.damage = projectileDamage
    self.attackFrequencyTimer = attackFrquencyTimer
    self:setZIndex(1)

    self.playerYlocation = 0

    self.randomLocation = math.random(200, 360)

    --timers
    self.lastShotTimeOwl = pd.getCurrentTimeMilliseconds()

    --enemy tag
    self.tag = "Enemy"
    self.healthtag = "FlyingOwl"

    FlyingOwl.super.init(self, x, y, self.playerImage, health, maxHealth, collesionX, collesionY, collisionSizeX, collisionSizeY, projectileSpeed, projectileDamage, self.tag)
end

function FlyingOwl:fire(startX, startY, targetX, targetY)
    
    local projectileImage = gfx.image.new("./images/Fireball.png"):scaledImage(0.7)
    local projectilesprite = gfx.sprite.new(projectileImage)
    projectilesprite:setZIndex(1)
    projectilesprite:setCollideRect(0, 0, 10, 10)
    -- mark this sprite as a projectile so we can special-case projectile-vs-projectile collisions
---@diagnostic disable-next-line: inject-field
    projectilesprite.tag = "Projectile"

    -- Ensure projectile vs projectile interactions are non-physical (overlap)
    -- so projectiles don't block or push each other. We still receive collision
    -- callbacks so hitting the player can be handled elsewhere.
---@diagnostic disable-next-line: inject-field
    projectilesprite.collisionResponse = function(self, other)
        -- suppress undefined-field diagnostics for `other.tag` since many sprites
        -- in this project use a `tag` field dynamically.
        ---@diagnostic disable-next-line: undefined-field
        if other and other.tag == "Projectile" then
            return "overlap"
        end

        return "overlap"
    end

    local dx = targetX - startX
    local dy = targetY - startY
    
    local distance = math.sqrt(dx*dx + dy*dy)

    local normX = dx / distance
    local normY = dy / distance

    local vx = normX * self.projectileSpeed
    local vy = normY * self.projectileSpeed

    -- capture owner so the projectile can call back for collision handling
    local owner = self

    -- attach velocity to the sprite so it can move every frame
---@diagnostic disable-next-line: inject-field
    projectilesprite.vx = vx

---@diagnostic disable-next-line: inject-field
    projectilesprite.vy = vy

    -- closure captures the FlyingOwl instance (owner) so collision handling can
    -- call back into the owl to apply damage when hitting the player.
    projectilesprite.update = function()
        local px, py = projectilesprite:getPosition()
        local newX, newY, pCollisions, pNumberOfCollisions = projectilesprite:moveWithCollisions(px + projectilesprite.vx, py + projectilesprite.vy)
        -- call owl's collision handler to apply damage to player if hit
        if owner and owner.collisionCheck then
            owner:collisionCheck(projectilesprite, pNumberOfCollisions, pCollisions)
        end
    end

    projectilesprite:add()
    projectilesprite:moveTo(startX, startY)

    return projectilesprite
end

function FlyingOwl:collisionCheck(projectile, numberOfCollisions, collisions)

    for i = 1, numberOfCollisions do
        local collision = collisions[i]
        local other = collision.other
        if other and other.className and other.tag == "Player" then
            print("Owl projectile hit the player!")
            if other.health then
                if other.takeDamage then
                    other:takeDamage(self.damage, self)
                else
                    other.health = other.health - self.damage
                end
            end
            projectile:remove()
        end
    end
end

function FlyingOwl:getXLocation() return self.x end
function FlyingOwl:setXLocation(x) self.x = x end

function FlyingOwl:getYLocation() return self.y end
function FlyingOwl:setYLocation(y) self.y = y end

function FlyingOwl:getHealthTag() return self.healthtag end

-- allows overlapping without pushing back
function FlyingOwl:collisionResponse(other) return "overlap" end

function FlyingOwl:SetPlayerYLocation(y) self.playerYlocation = y end
function FlyingOwl:GetPlayerYLocation() return self.playerYlocation end


function FlyingOwl:update()
    FlyingOwl.super.update(self)
    local projectile, dx, dy

    --timer as the game runs
    local timeNow = pd.getCurrentTimeMilliseconds()

    -- Move left across the screen
    local x, y = self:getPosition()

    -- Move left across the screen and stop at the randomLocation without overshooting
    if x > self.randomLocation then
        local nextX = x - self.speed
        if nextX < self.randomLocation then
            x = self.randomLocation
        else
            x = nextX
        end
    end

    self:moveTo(x, y)

    if timeNow - self.lastShotTimeOwl >= self.attackFrequencyTimer then
        self:fire(x, y, 20, self:GetPlayerYLocation())
        self.lastShotTimeOwl = timeNow
    end

    -- Remove if health is 0 or below
    if self.health <= 0 then
        self:remove()
    end

end

