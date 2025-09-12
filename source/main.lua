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
local time = 3000
local spawnTimer

--Wave Management
local currentWaveArray = {}
local initNumEnemies = 4
local waveNum = 0
--local enemyArrayLength

--Background
local backgroundImage = gfx.image.new( "images/background.png" )

-- Player Starting Animation
local playerStart1 <const> = gfx.image.new("images/V-Peace1.png"):scaledImage(7)
local playerStart2 <const> = gfx.image.new("images/V-Peace2.png"):scaledImage(7)
local playerAnimation = gfx.animation.loop.new(1500, {playerStart1, playerStart2})

-- Portal Animation
local frame1 <const> = gfx.image.new("images/portal animation/Portal1.png"):scaledImage(3)
local frame2 <const> = gfx.image.new("images/portal animation/Portal2.png"):scaledImage(3)
local frame3 <const> = gfx.image.new("images/portal animation/Portal3.png"):scaledImage(3)
local frame4 <const> = gfx.image.new("images/portal animation/Portal4.png"):scaledImage(3)
local portalAnimation = gfx.animation.loop.new(1000, {frame1, frame2, frame3, frame4})
local portalSprite = gfx.sprite.new()
portalSprite:setImage(portalAnimation:image())
portalSprite:moveTo(350, 110)
portalSprite:setZIndex(0) -- pick a zIndex relative to other game objects

--TO DO : IMPLEMENT FLYING MONSTERS

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
    energyTimer = 20000,
}
local playerInstance = Player(playerInfo.playerXlocation, playerInfo.playerYlocation, playerInfo.playerHealth, playerInfo.playerMaxHealth, 
                                playerInfo.playerCollisionXLocation, playerInfo.playerCollisionYLocation, playerInfo.playerCollisionXSize, 
                                playerInfo.playerCollisionYSize, playerInfo.playerProjectileSpeed, playerInfo.playerProjectileDamage, playerInfo.playerAttackFrequencyTimer, 
                                playerInfo.energyTimer)

--Enemies: OwlBear
local owlBearInfo = {
    owlBearXlocation = 400,
    owlBearYlocation = 210,
    owlBearHealth = 10,
    owlBearMaxHealth = 10,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 1,
    owlBearDamage = 1,
}


local scooterInfo = {
    scooterXLocation = 30, 
    scooterYLocation = 200, 
    scooterCollesionX = 0, 
    scooterCollesionY = 0, 
    scooterCollesionSizeX = 65, 
    scooterCollisionSizeY = 65,
    scooterDamage = 5,
    scooterSpeed = 10,
    scooterCost = 2,
    scooterKnockBack = 25
}

--list of special abilties and their costs
local specialAbilties = {
    scooter = 2,
}

--Spawn OwlBears and add to OwlBearArray
local function createOwlBears(numOfEnemies)
    local owlBearArray = {}
    for i = 0, numOfEnemies-1 do
        local owlBearInstance = OwlBear(owlBearInfo.owlBearXlocation, owlBearInfo.owlBearYlocation, 
                                owlBearInfo.owlBearHealth, owlBearArray.owlBearMaxHealth, 
                                owlBearInfo.owlCollesionX, owlBearInfo.owlCollesionY, owlBearInfo.owlCollisionSizeX, 
                                owlBearInfo.owlCollisionSizeY, owlBearInfo.owlSpeed, owlBearInfo.owlBearDamage)
        table.insert(owlBearArray, owlBearInstance)
    end
    
    return owlBearArray
end

--Remove Dead OwlBear
-- local function clearDeadEnemyArray(enemyArray)
--     if(enemyArray) and (#enemyArray >= 1) then
--         for i = #enemyArray, 1, -1 do 
--             local ob = enemyArray[i]
--             if ob.health <= 0 then
--                 ob:remove() 
--                 table.remove(enemyArray, i)
--             end
--         end
--     end
-- end

--Clear OwlBearArray & Reset OwlBear Array
local function ClearOwlBearArray(enemyArray)
    if(enemyArray)then
        for i = #enemyArray, 1, -1 do 
            enemyArray[i]:remove()
            table.remove(enemyArray, i)
        end
    end
end

local function startNextWave()
    
    currentWaveArray = createOwlBears(initNumEnemies)
    --enemyArrayLength = #currentWaveArray

    -- Kill old timer if it exists
    if spawnTimer then
        spawnTimer:remove()
    end

    spawnTimer = pd.timer.keyRepeatTimerWithDelay(time, time, function()
        local enemy = table.remove(currentWaveArray, 1)
        if enemy then
            enemy:add()
        else
            spawnTimer:remove()
            spawnTimer = nil
            -- Wave is done → stop timer and auto-start next wave
            spawnTimer = pd.timer.performAfterDelay(3000, function() 
                currentWaveArray = {}
                --enemyArrayLength = 0
                spawnTimer:remove()
                spawnTimer = nil
                waveNum += 1
                initNumEnemies += 1
                startNextWave()
                owlBearInfo.owlSpeed += 0.1
                owlBearInfo.owlBearDamage += 0.5
                owlBearInfo.owlBearMaxHealth += 0.5
                owlBearInfo.owlBearHealth = owlBearInfo.owlBearMaxHealth
                playerInstance:setProjectileSpeed(playerInstance:getProjectSpeed() + 0.2)
                playerInstance:setProjectileDamage(playerInstance:getProjectileDamage() + 0.5)
                if not (playerInstance:getAttackFrequencyTimer() <= 1000) then
                    playerInstance:setAttackFrequencyTimer(playerInstance:getAttackFrequencyTimer() - 250)
                end
                if (waveNum % 5 == 0) then 
                    playerInstance:setMaxHealth(playerInstance:getMaxHealth() + 10)
                    playerInstance:healPlayer()
                end

                if(waveNum == 15) then
                    gameState = "won"
                end

                if(time ~= 1) then 
                    time -= time*0.005 
                end --Speed up game
            end)
        end
    end)
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
    playerInstance:add()
    playerInstance:setSepecialAbility("scooter")
    portalSprite:add()
    print(tostring(playerInstance:getSpecialAbility()))
    startNextWave()
end

--Gamer Over
local function endGame()
    gameState = "stopped"
    playerInstance:remove()
    playerInstance.handSprite:remove()
    spawnTimer:remove()
    ClearOwlBearArray(currentWaveArray)
    waveNum = 0
    initNumEnemies = 4
    currentWaveArray = {}
    --Remove background
    clearBackground()
    gfx.clear()
end

local function drawInstructions()
    gfx.clear(gfx.kColorWhite)
    gfx.setFont(gfx.getSystemFont())
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Title
    gfx.drawTextAligned("How to Play", 200, 20, kTextAlignment.center)

    -- Instruction lines (reworded for clarity)
    local instructions = {
        "Turn the crank to aim your shots",
        "Shoot Owl Bears to stay alive",
        "Each wave grows faster and tougher",
        "Gain 10 extra health points every 5 waves",
        "Press B to unleash Scooter Power", 
        "(Requires 2 Energy):",
        "  - Deals heavy damage",
        "  - Knocks enemies back",
        "Reach Wave 15 to Win!",
        "",
        "Press B again to return to Main Menu"
    }

    -- Center block of text vertically
    local startY = 35
    local lineSpacing = 18
    for i, line in ipairs(instructions) do
        gfx.drawText(line, 30, startY + (i - 1) * lineSpacing)
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        gfx.clear()
        gameState = "stopped"
    end
end

local function drawWinScreen()
    gfx.clear(gfx.kColorWhite)
    gfx.setFont(gfx.getSystemFont())
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Big centered title
    gfx.drawTextAligned("You Survived!", 200, 80, kTextAlignment.center)

    -- Subtext
    gfx.drawTextAligned("The Owl Bears are defeated...", 200, 120, kTextAlignment.center)
    gfx.drawTextAligned("But new challenges await.", 200, 140, kTextAlignment.center)

    -- Instructions
    gfx.drawTextAligned("Press B to return to Main Menu", 200, 210, kTextAlignment.center)

end

--Update
function pd.update()
    gfx.sprite.update()
    if gameState == "stopped" then
        playerAnimation:draw(177, 17)
        gfx.drawText("Owl Invasion", 40, 25)
        gfx.drawText("Press A to Start", 25, 50)
        gfx.drawText("Press B for Instructions", 25, 75)

        --Start Game
        if pd.buttonJustPressed(pd.kButtonA) then
            gfx.clear()
            playGame()
        end

        if pd.buttonJustPressed(pd.kButtonB) then
            gfx.clear()
            gameState = "instructions"
        end

    elseif gameState == "playing" then
        --Check if OwlBears are dead in the array and remove them
        --clearDeadEnemyArray(currentWaveArray)

        gfx.drawText("Health: " .. playerInstance:getHealth() .. "/" .. playerInstance:getMaxHealth(), 5, 5)
        gfx.drawText("Energy: " .. playerInstance:getEnergy(), 5, 25)
        gfx.drawText("Wave: " .. waveNum, 5, 45)

        if pd.buttonJustPressed(pd.kButtonB) then
            if (playerInstance:getSpecialAbility() == "scooter") then spawnScooter() end 
        end
        
        --Game Over
        if playerInstance:getHealth() <= 0 then
            endGame()
        end
        
        portalSprite:setImage(portalAnimation:image())
    
    elseif gameState == "instructions" then
        drawInstructions()
    
    elseif gameState == "won" then
        drawWinScreen()
        if playdate.buttonJustPressed(playdate.kButtonB) then
            endGame()
        end
    end
    pd.timer.updateTimers()
end