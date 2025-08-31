import "defaultCharacter"

local pd <const> = playdate
local gfx <const> = pd.graphics

class("Player").extends("DefaultCharacter")

function Player:init(x, y, health)
    local playerImage = gfx.image.new("./images/V-Char-sideways.png"):scaledImage(3)
    Player.super.init(self, x, y, playerImage, health)

end

function Player:update()

    -- Movement
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self:moveBy(-2, 0)
    end
    if pd.buttonIsPressed(pd.kButtonRight) then
        self:moveBy(2, 0)
    end
    if pd.buttonIsPressed(pd.kButtonUp) then
        self:moveBy(0, -2)
    end
    if pd.buttonIsPressed(pd.kButtonDown) then
        self:moveBy(0, 2)
    end

    -- Keep player within screen bounds
    local x, y = self:getPosition()
    local width, height = self:getSize()
    x = math.max(width / 2, math.min(pd.display.getWidth() - width / 2, x))
    y = math.max(height / 2, math.min(pd.display.getHeight() - height / 2, y))
    self:moveTo(x, y)
end