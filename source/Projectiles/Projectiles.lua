--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

local collisionXPosition <const>  = 5
local collisionYPosition <const>  = 5

class('Projectiles').extends(gfx.sprite)

function Projectiles:init(image, damage, speed, collisionSizeX, collisionSizeY)
    self:setImage(image)
    self.damage = damage
    self.projectileSpeed = speed
    self.collisionSizeX = collisionSizeX or image:getWidth()
    self.collisionSizeY = collisionSizeY or image:getHeight()
    self:setCollideRect(collisionXPosition, collisionYPosition, self.collisionSizeX, self.collisionSizeY)
    
    self:setZIndex(0) -- Ensure projectiles are drawn behind other sprites

    self.vx = 0
    self.vy = 0
end

function Projectiles:collideWith(target)
    -- Only allow projectiles to collide with the player
    if (target and target.className and target.tag == "Enemy") then
        print("Projectile hit " .. tostring(target.tag))
        if target.health then
            target.health = target.health - self.damage
        end
        
        self:remove()
    end    
end

-- Fire projectile from (x, y) given crank angle
function Projectiles:fire(x, y)
    
    
    -- Get crank angle (0–359)
    local angle = pd.getCrankPosition()

    -- Convert angle to radians
    local rad = math.rad(angle)

    self:moveTo(x + math.cos(rad), y + math.sin(rad))
    
    -- Calculate velocity components
    self.vx = self.projectileSpeed * math.cos(rad)
    self.vy = self.projectileSpeed * math.sin(rad)

    self:add()
end

function Projectiles:collisionResponse(other)
    return "overlap" -- allows overlapping without pushing back
end

function Projectiles:update()
    local x, y = self:getPosition()

    --check for collisions with other sprites
    local actualX, actualY, collisions, numberOfCollisions = self:moveWithCollisions(x + self.vx, y + self.vy)

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