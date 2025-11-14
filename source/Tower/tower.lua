local pd <const> = playdate
local gfx <const> = pd.graphics

class('Tower').extends(gfx.sprite)

function Tower:init(x, y, image, health, maxHealth, collesionX, collesionY, collesionSizeX, collisionSizeY, level, cost)
    self:moveTo(x, y)
    self:setImage(image)
    self:setCollideRect(collesionX, collesionY, collesionSizeX, collisionSizeY)
    self.health = health
    self.maxHealth = maxHealth
    self.level = level
    self.cost = cost
    self.tag = "Player"

    self.invincible = false
    -- duration in milliseconds to be invincible after taking damage
    self.invincibleDuration = 500
    -- blink interval in milliseconds while invincible
    self._damageBlinkInterval = 100

    --Healthbar
    self.healthBarBackground = nil
    self.healthBar = nil

    self:setZIndex(0)
end

-- Apply damage to this character. Handles invincibility window and simple blink feedback.
function Tower:takeDamage(amount, source)
    if not amount then return end
    if self.invincible then
        return
    end

    -- subtract health
    self.health = (self.health or 0) - amount

    -- set invincible state
    self.invincible = true

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

function Tower:spawnTower(player)
    local playerX = player:getXLocation()
    local playerY = player:getYLocation()
    local towerImage = gfx.image.new("./images/TowerTiles/Level1.png"):scaledImage(0.2)
    local tower = Tower(playerX, playerY, towerImage, 100, 100,  0, 0, 40, 40, 1, 3)
    if(player:getCoins() < tower:getCost()) then
        print("Not enough MO to build tower!")
        return nil
    end
    player:setCoins(player:getCoins() - tower:getCost())
    tower:add()
    return tower
end

function Tower:draweHealthBar(width, height)
    -- Draw current health (green)
    local healthPercent = math.max(0, math.min(1, (self.health or 0) / (self.maxHealth or 1)))
    local barWidth = math.floor(width * healthPercent)

    -- Draw health bar above the tower
    local x, y = self:getPosition()
    x -= width / 2
    y -= height / 2

    -- Draw background (black)
    gfx.setColor(gfx.kColorBlack)
    self.healthBarBackground = gfx.sprite.new(gfx.fillRoundRect(x, y, width, height, 2))

    -- Draw health bar (white)
    gfx.setColor(gfx.kColorWhite)
    self.healthBar = gfx.sprite.new(gfx.fillRoundRect(x+1, y+1, barWidth-2, height-2, 2))

end

function Tower:getLevel() return self.level end
function Tower:setLevel(level) self.level = level end

function Tower:getHealth() return self.health end
function Tower:setHealth(health) self.health = health end

function Tower:getMaxHealth() return self.maxHealth end
function Tower:setMaxHealth(maxHealth) self.maxHealth = maxHealth end

function Tower:getXLocation() return self.x end
function Tower:setXLocation(x) self.x = x end

function Tower:getYLocation() return self.y end
function Tower:setYLocation(y) self.y = y end

function Tower:getCost() return self.cost end
function Tower:setCost(cost) self.cost = cost end

function Tower:update()
    if self.health <= 0 then
        print("Tower has been destroyed!")
        self:remove()
    else 
        self:draweHealthBar(25, 8)
    end
end