import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/animation"

import "Characters/defaultCharacter"
import "Characters/player"

--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

-- Starting Animation
local playerStart1 = gfx.image.new("images/V-Peace1.png")
local playerStart2 = gfx.image.new("images/V-Peace2.png")

local playerStart1Scaled = playerStart1 and playerStart1:scaledImage(7) or nil
local playerStart2Scaled = playerStart2 and playerStart2:scaledImage(7) or nil

local playerAnimation = gfx.animation.loop.new(1500, {playerStart1Scaled, playerStart2Scaled})



--Game State
local gameState = "stopped"

--Player Setup
local playerInstance = Player(200, 120, 100)



--Update
function pd.update()
    gfx.clear()
    gfx.sprite.update()
    if gameState == "stopped" then
        playerAnimation:draw(177, 17)
        gfx.drawText("Owl Invasion", 40, 25)
        gfx.drawText("Press A to Start", 25, 50)
        if pd.buttonJustPressed(pd.kButtonA) then
            gameState = "playing"
            playerInstance:add()
            gfx.sprite.update()

        end
    end
end 