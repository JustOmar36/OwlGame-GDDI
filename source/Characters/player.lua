import "CoreLibs/timer"
import "defaultCharacter"
import "../Projectiles/Projectiles"

local pd <const> = playdate
local gfx <const> = pd.graphics
local offset <const> = 10

class("Player").extends("DefaultCharacter")

function Player:init(x, y, health, collesionX, collesionY, 
    collisionSizeX, collisionSizeY, projectileSpeed, projectileDamage, 
    attackFrquencyTimer, playerEnergyTimer, maxHealth)

    self.playerImage = gfx.image.new("./images/V-Char-sideways.png"):scaledImage(2)
    self.handImage = gfx.image.new("./images/hand.png")
    self.handSprite = gfx.sprite.new(self.handImage)

    self.attackFrequencyTimer = attackFrquencyTimer
    self.projectileSpeed = projectileSpeed
    self.projectileDamage = projectileDamage
    self.playerEnergyTimer = playerEnergyTimer

    self.handSprite:setZIndex(1)

    --player energy
    self.energy = 0

    --Player Max Health
    self.maxHealth = maxHealth

    --player tag
    self.tag = "Player"

    --projectile damage
    self.projectileDamage = 5

    --currentSpecialAbility
    self.currentSpecialAbility = ""

    --timers
    self.lastShotTime = pd.getCurrentTimeMilliseconds()
    self.energyTime = pd.getCurrentTimeMilliseconds()

    Player.super.init(self, x, y, self.playerImage, health, collesionX, collesionY, collisionSizeX, collisionSizeY, projectileSpeed, projectileDamage, self.tag)
end

--Max Health Getter and Setter
function Player:getMaxHealth()
    return self.maxHealth
end

function Player:setMaxHealth(maxHealth)
    self.maxHealth = maxHealth
end

--Health Getter and Setter
function Player:getHealth()
    return self.health
end

function Player:setHealth(health)
    self.health = health
end

--Energy Getter and Setter
function Player:getEnergy()
    return self.energy
end

function Player:setEnergy(energy)
    self.energy += energy
end

--Special Ability Getter and Setter
function Player:getSpecialAbility()
    return self.currentSpecialAbility
end

function Player:setSepecialAbility(ability)
    self.currentSpecialAbility = ability
end

--Heal Player
function Player:healPlayer()
    self.health = self.maxHealth
end

--Shoot projectile from current hand location
function Player:fireProjectile(handX, handY)
    local projectileImage = gfx.image.new("./images/Fireball.png"):scaledImage(0.7)
    local projectile = Projectiles(projectileImage, self.projectileDamage, self.projectileSpeed, 10, 10)
    projectile:fire(handX, handY)

end

--Controls for hand rotation
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

--Spawns in the handsprite connected to player location (offset based on character size)
function Player:spawnHand(x, y)
    if self.handSprite then
        self.handSprite:moveTo(x - 5 , y + 8) -- Position the hand
        self.handSprite:add()
    end
end


function Player:update()

    --timer as the game runs
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

    --Increase energy on a timer
    if timeNow - self.energyTime >= self.playerEnergyTimer then
        self:setEnergy(1)
        self.energyTime = timeNow
    end

    --remove player on death
    if self.health <= 0 then
        self.remove()
        self.handSprite:remove()
    end

end