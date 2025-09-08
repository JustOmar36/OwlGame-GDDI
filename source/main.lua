import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/timer"

import "Characters/defaultCharacter"
import "Characters/player"
import "Characters/owlBear"
import "Gadgets/scooter"

--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

--Timers
local time = 10000

--Background
local backgroundImage = gfx.image.new( "images/background.png" )

-- Starting Animation
local playerStart1 = gfx.image.new("images/V-Peace1.png"):scaledImage(7)
local playerStart2 = gfx.image.new("images/V-Peace2.png"):scaledImage(7)
local playerAnimation = gfx.animation.loop.new(1500, {playerStart1, playerStart2})

--Game State
local gameState = "stopped"

--Player Setup
local playerInfo = {
    playerXlocation = 30,
    playerYlocation = 200,
    playerHealth = 100,
    playerMaxHealth = 100,
    playerCollisionXLocation = 20,
    playerCollisionYLocation = 28,
    playerCollisionXSize = 20,
    playerCollisionYSize = 20,
    playerProjectileSpeed = 5,
    playerProjectileDamage = 10,
    playerAttackFrequencyTimer = 3000,
    energyTimer = 5000,
}

local playerInstance

--Enemies: OwlBear
local owlBearInfo ={
    owlBearXlocation = 400,
    owlBearYlocation = 210,
    owlBearHealth = 10,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 1,
    owlBearDamage = 1,
}

local spawnOwlBearTimer
local owlBearArray = {}

local scooterInfo = {
    scooterXLocation = 30, 
    scooterYLocation = 200, 
    scooterCollesionX = 0, 
    scooterCollesionY = 0, 
    scooterCollesionSizeX = 65, 
    scooterCollisionSizeY = 65,
    scooterDamage = 1,
    scooterSpeed = 5,
    scooterCost = 2,
    scooterKnockBack = 5
}

--list of special abilties and their costs
local specialAbilties = {
    scooter = 2,
}


--Spawn OwlBears and add to OwlBearArray
local function spawnOwlBear()
    local owlBearInstance = OwlBear(owlBearInfo.owlBearXlocation, owlBearInfo.owlBearYlocation, owlBearInfo.owlBearHealth, owlBearInfo.owlCollesionX, owlBearInfo.owlCollesionY, owlBearInfo.owlCollisionSizeX, owlBearInfo.owlCollisionSizeY, owlBearInfo.owlSpeed, owlBearInfo.owlBearDamage)
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

--Clear OwlBearArray & Reset OwlBear Array
local function ClearOwlBearArray()
    if(owlBearArray) then
        for i = #owlBearArray, 1, -1 do 
            owlBearArray[i]:remove()
        end
        owlBearArray = {}
    end
end

--Background Draw
local function drawBackground()
    assert( backgroundImage )
    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            backgroundImage:draw( 0, 0 )
        end
    )
end

--remove background
local function clearBackground()
    gfx.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
        gfx.clear(gfx.kColorWhite)
    end)
end

local function spawnScooter()
    if(playerInstance:getEnergy() >= specialAbilties[playerInstance:getSpecialAbility()]) then
        local scooterInstance = Scooter(scooterInfo.scooterXLocation, scooterInfo.scooterYLocation, scooterInfo.scooterDamage, 
        scooterInfo.scooterCollesionX, scooterInfo.scooterCollesionY, scooterInfo.scooterCollesionSizeX, 
        scooterInfo.scooterCollisionSizeY, scooterInfo.scooterSpeed, scooterInfo.scooterCost, scooterInfo.scooterKnockBack)

        scooterInstance:add()
        playerInstance:setEnergy(-(scooterInstance:getCost()))
    end
    
end

--Play Game
local function playGame()
    gameState = "playing"
    drawBackground()
    playerInstance = Player(playerInfo.playerXlocation, playerInfo.playerYlocation, playerInfo.playerHealth, 
                                playerInfo.playerCollisionXLocation, playerInfo.playerCollisionYLocation, playerInfo.playerCollisionXSize, 
                                playerInfo.playerCollisionYSize, playerInfo.playerProjectileSpeed, playerInfo.playerProjectileDamage, playerInfo.playerAttackFrequencyTimer, 
                                playerInfo.energyTimer, playerInfo.playerMaxHealth)
    playerInstance:add()
    playerInstance:setSepecialAbility("scooter")

    print(tostring(playerInstance:getSpecialAbility()))

    -- Then repeat every 3 seconds
    spawnOwlBearTimer = pd.timer.keyRepeatTimerWithDelay(time, time, function() spawnOwlBear() end)
end

--Gamer Over
local function endGame()
    gameState = "stopped"
    playerInstance:remove()
    playerInstance.handSprite:remove()
    spawnOwlBearTimer:remove()

    --Remove background
    clearBackground()
    
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
        if pd.buttonJustPressed(pd.kButtonB) then
            if (playerInstance:getSpecialAbility() == "scooter") then spawnScooter() end
            
        end
        gfx.drawText("Health: " .. playerInstance:getHealth() .. "/" .. playerInstance:getMaxHealth(), 10, 5)
        gfx.drawText("Energy: " .. playerInstance:getEnergy(), 150, 5)

        --Game Over
        if playerInstance:getHealth() <= 0 then
            endGame()
        end
    end

    pd.timer.updateTimers()
end 