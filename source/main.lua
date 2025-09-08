import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/timer"

import "Characters/defaultCharacter"
import "Characters/player"
import "Characters/owlBear"

--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

--Timers
local time <const> = 5000
local timeOffset = 1

-- Starting Animation
local playerStart1 = gfx.image.new("images/V-Peace1.png"):scaledImage(7)
local playerStart2 = gfx.image.new("images/V-Peace2.png"):scaledImage(7)

local playerAnimation = gfx.animation.loop.new(1500, {playerStart1, playerStart2})

--Background
local function drawBackground()

    -- We want an environment displayed behind our sprite.
    -- There are generally two ways to do this:
    -- 1) Use setBackgroundDrawingCallback() to draw a background image. (This is what we're doing below.)
    -- 2) Use a tilemap, assign it to a sprite with sprite:setTilemap(tilemap),
    --       and call :setZIndex() with some low number so the background stays behind
    --       your other sprites.

    local backgroundImage = gfx.image.new( "images/background.png" )

    assert( backgroundImage )

    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw( 0, 0 )
            
        end
    )

end

--Game State
local gameState = "stopped"

--Player Setup
local playerXlocation = 30
local playerYlocation = 200
local playerHealth = 100
local playerCollisionXLocation = 20
local playerCollisionYLocation = 28
local playerCollisionXSize = 20
local playerCollisionYSize = 20
local playerProjectileSpeed = 5
local playerAttackFrequencyTimer = 3000
local energyTimer = 5000
local playerInstance

--Enemies: OwlBear
local owlBearXlocation = 400
local owlBearYlocation = 210
local owlBearHealth = 10
local owlCollesionX = 0
local owlCollesionY = 0
local owlCollisionSizeX = 65
local owlCollisionSizeY = 65
local owlSpeed = 1
local owlBearDamage = 100
local owlBearInstance
local spawnOwlBearTimer
local owlBearArray = {}

--Spawn OwlBears and add to OwlBearArray
local function spawnOwlBear()
    owlBearInstance = OwlBear(owlBearXlocation, owlBearYlocation, owlBearHealth, owlCollesionX, owlCollesionY, owlCollisionSizeX, owlCollisionSizeY, owlSpeed, owlBearDamage)
    owlBearInstance:add()
    table.insert(owlBearArray, owlBearInstance)
end

--Remove Dead OwlBear
local function clearDeadOwlBearArray()
    if(owlBearArray) and (#owlBearArray >= 1) then
        for i = #owlBearArray, 1, -1 do 
            local ob = owlBearArray[i]
            if ob.health <= 0 then
                ob:remove() 
                table.remove(owlBearArray, i)
            end
        end
    end
end

--Clear OwlBearArray
--Reset OwlBear Array
local function ClearOwlBearArray()
    if(owlBearArray) then
        for i = #owlBearArray, 1, -1 do 
            owlBearArray[i]:remove()
        end
        owlBearArray = {}
    end
end

--Play Game
local function playGame()
    gameState = "playing"
    drawBackground()
    playerInstance = Player(playerXlocation, playerYlocation, playerHealth, playerCollisionXLocation, playerCollisionYLocation, playerCollisionXSize, playerCollisionYSize, playerProjectileSpeed, playerAttackFrequencyTimer, energyTimer)
    playerInstance:add()

    -- Then repeat every 3 seconds
    spawnOwlBearTimer = pd.timer.keyRepeatTimerWithDelay(time + (timeOffset * time), time + (timeOffset * time), function() spawnOwlBear() end)
end

--Gamer Over
local function endGame()
    gameState = "stopped"
    playerInstance:remove()
    owlBearInstance:remove()
    playerInstance.handSprite:remove()
    spawnOwlBearTimer:remove()

    --Clear OwlBear Array
    ClearOwlBearArray()
    gfx.clear()
end

--Update
function pd.update()
    gfx.sprite.update()
    if gameState == "stopped" then
        playerAnimation:draw(177, 17)
        gfx.drawText("Owl Invasion", 40, 25)
        gfx.drawText("Press A to Start", 25, 50)

        --Start Game
        if pd.buttonJustPressed(pd.kButtonA) then
            playGame()
            gfx.clear()
        end
    elseif gameState == "playing" then
        --Check if OwlBears are dead in the array and remove them
        clearDeadOwlBearArray()

        gfx.drawText("Energy: " .. playerInstance:getEnergy(), 10, 5)

        --Game Over
        if playerInstance:getHealth() <= 0 then
            endGame()
        end
    end

    pd.timer.updateTimers()
end 