--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics
import "CoreLibs/timer"

class('DefaultCharacter').extends(gfx.sprite)

function DefaultCharacter:init(x, y, image, health, maxHealth, collesionX, collesionY, collesionSizeX, collisionSizeY, projectileSpeed, projectileDamage, tag)
    self:moveTo(x, y)
    self:setImage(image)
    self:setCollideRect(collesionX, collesionY, collesionSizeX, collisionSizeY)
    -- Ensure sensible defaults so health bar drawing works even if callers omit values
    self.health = (health ~= nil) and health or 1
    self.maxHealth = (maxHealth ~= nil) and maxHealth or self.health
    self.projectileSpeed = projectileSpeed
    self.projectileDamage = projectileDamage
    self.originalX = x
    -- Ensure sprite draws above background by default (subclasses can override)
    if not self:getZIndex() then
        self:setZIndex(10)
    end
    self.tag = tag
    -- damage / invincibility state
    self.invincible = false
    -- duration in milliseconds to be invincible after taking damage
    self.invincibleDuration = 500
    -- blink interval in milliseconds while invincible
    self._damageBlinkInterval = 100

    self.damageSound = pd.sound.sampleplayer.new("./sounds/hit.wav")

    self.healthbarBackground = nil
    self.healthbarForeground = nil

end

-- Apply damage to this character. Handles invincibility window and simple blink feedback.
function DefaultCharacter:takeDamage(amount, source)
    if not amount then return end
    if self.invincible then
        return
    end

    -- subtract health
    self.health = (self.health or 0) - amount

    -- play hit sound if available
    if self.damageSound then
        self.damageSound:play()
    end

    -- set invincible state
    self.invincible = true

    -- apply knockback if source provides one
    local kb = 0
    if source then
        if source.getKnockback then
            kb = source:getKnockback() or 0
        elseif source.knockback then
            kb = source.knockback or 0
        end
    end

    if kb and kb > 0 then
        -- get positions to compute direction (push away from source)
        local sx, sy = nil, nil
        if source and source.getPosition then
            sx, sy = source:getPosition()
        elseif source and source.x and source.y then
            sx, sy = source.x, source.y
        end

        local tx, ty = self:getPosition()
        local dir = 1
        if sx and tx then
            if (tx - sx) < 0 then dir = -1 end
        end

        -- Smooth knockback: move in small steps over the invincibility duration
        local duration = math.min(self.invincibleDuration or 500, 600)
        local steps = 8
        local stepDelay = math.floor(duration / steps)
        local stepAmount = (dir * kb) / steps
        for i = 1, steps do
            pd.timer.performAfterDelay(i * stepDelay, function()
                if self.isRemoved and self:isRemoved() then return end
                local curX, curY = self:getPosition()
                self:moveTo(curX + stepAmount, curY)
            end)
        end
    end

    local duration = self.invincibleDuration or 500
    local interval = self._damageBlinkInterval or 100
    local iterations = math.floor(duration / interval)

    -- schedule blink toggles
    for i = 0, iterations do
        pd.timer.performAfterDelay(i * interval, function()
            -- If sprite was removed, nothing to do
            if not self then return end
            -- toggle visibility for simple visual feedback
            if self.isRemoved and self:isRemoved() then return end
            self:setVisible(not self:isVisible())
        end)
    end

    -- ensure visible and clear invincibility at the end
    pd.timer.performAfterDelay(duration + 10, function()
        if not self then return end
        if not (self.isRemoved and self:isRemoved()) then
            self:setVisible(true)
        end
        self.invincible = false
    end)
end

function DefaultCharacter:drawHealthBar(width, height, offset)
    -- Defensive checks
    if not self then return end
    if not self.health or not self.maxHealth or self.maxHealth == 0 then return end

    local x, y = self:getPosition()
    x -= width / 2
    y -= height / 2 + offset
    local healthPercent = math.max(0, math.min(1, (self.health or 0) / (self.maxHealth or 1)))
    local barWidth = math.floor(width * healthPercent)

    -- Draw background bar (black)
    gfx.setColor(gfx.kColorBlack)
    local b = gfx.fillRoundRect(x, y, width, height, 1)

    -- Draw health bar (white)
    gfx.setColor(gfx.kColorWhite)
    local h = gfx.fillRoundRect(x+1, y+1, barWidth-2, height-2, 2)

    self.healthbarBackground = b
    self.healthbarForeground = h

end

function DefaultCharacter:removeHealthBar()
    if self.healthbarBackground then
        self.healthbarBackground = nil
    end
    if self.healthbarForeground then
        self.healthbarForeground = nil
    end
end

--Check if collision box is set
function DefaultCharacter:isCollisionBoxSet()
    local rect = self:getCollideRect()
    if rect then
        return true
    else
        return false
    end
end

--Max Health Getter and Setter
function DefaultCharacter:getMaxHealth() return self.maxHealth end
function DefaultCharacter:setMaxHealth(maxHealth) self.maxHealth = maxHealth end

--Health Getter and Setter
function DefaultCharacter:getHealth() return self.health end
function DefaultCharacter:setHealth(health) self.health = health end

--Projectile Getters and Setters
function DefaultCharacter:setProjectileSpeed(speed) self.projectileSpeed = speed end
function DefaultCharacter:getProjectSpeed() return self.projectileSpeed end

function DefaultCharacter:SetProjectileDamage(damage) self.projectileDamage = damage end
function DefaultCharacter:getProjectileDamage() return self.projectileDamage end

function DefaultCharacter:getOriginalXLocation() return self.originalX end
function DefaultCharacter:getXLocation() return self.x end
function DefaultCharacter:setXLocation(x) self.x = x end

function DefaultCharacter:setYLocation(y) self.y = y end
function DefaultCharacter:getYLocation() return self.y end

function DefaultCharacter:update()
    --Keep characters in screen bounds
    local x, y = self:getPosition()
    local screenWidth, screenHeight = pd.display.getSize()
    x = math.max(25, math.min(screenWidth, x))
    y = math.max(0, math.min(screenHeight, y))
    self:moveTo(x, y)
end