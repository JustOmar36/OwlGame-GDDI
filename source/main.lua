import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/animation"

--Initializing Playdate SDK
local pd = playdate
local gfx = pd.graphics

-- Starting Animation
local playerStart1 = gfx.image.new("images/V-Peace1.png")
local playerStart2 = gfx.image.new("images/V-Peace2.png")

local playerStart1Scaled = playerStart1 and playerStart1:scaledImage(7) or nil
local playerStart2Scaled = playerStart2 and playerStart2:scaledImage(7) or nil

local playerAnimation = gfx.animation.loop.new(1500, {playerStart1Scaled, playerStart2Scaled})



--Game State
local gameState = "stopped"

--Update
function pd.update()
    gfx.clear()
    gfx.sprite.update()
    if gameState == "stopped" then
        playerAnimation:draw(177, 17)
        gfx.drawText("Press A to Start", 50, 50)
        if pd.buttonJustPressed(pd.kButtonA) then
            gameState = "playing"
        end
    end
end 