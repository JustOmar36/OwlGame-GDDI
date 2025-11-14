import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/timer"

import "Characters/defaultCharacter"
import "Characters/player"
import "Characters/owlBear"
import "Characters/owlKing"
import "Characters/flyingOwl"
import "Gadgets/scooter"
import "Tower/tower"

--Initializing Playdate SDK
local pd <const> = playdate
local gfx <const> = pd.graphics

--sound
local backgroundMusic = pd.sound.sampleplayer.new("sounds/game.wav")
backgroundMusic:setVolume(0.2)
local mainmenuMusic = pd.sound.sampleplayer.new("sounds/mainmenu.wav")
mainmenuMusic:setVolume(0.2)
local waveCompleteSound = pd.sound.sampleplayer.new("sounds/wavecomplete.wav")
waveCompleteSound:setVolume(0.5)

--Timers
local time = 3000
local spawnTimer

--Wave Management
local currentWaveArray = {}
local initNumEnemies = 4
local waveNum = 1

--Background
local backgroundImage = gfx.image.new( "images/background.png" )

-- Player Starting Animation
local playerStart1 <const> = gfx.image.new("images/V-Peace1.png"):scaledImage(7)
local playerStart2 <const> = gfx.image.new("images/V-Peace2.png"):scaledImage(7)
local playerAnimation = gfx.animation.loop.new(1500, {playerStart1, playerStart2})

-- Portal Animation
local frame1 <const> = gfx.image.new("images/portal animation/Portal1.png"):scaledImage(2.5)
local frame2 <const> = gfx.image.new("images/portal animation/Portal2.png"):scaledImage(2.4)
local frame3 <const> = gfx.image.new("images/portal animation/Portal3.png"):scaledImage(2.3)
local frame4 <const> = gfx.image.new("images/portal animation/Portal4.png"):scaledImage(2.5)
local portalAnimation = gfx.animation.loop.new(1000, {frame1, frame2, frame3, frame4})
local portalSprite = gfx.sprite.new()
portalSprite:setImage(portalAnimation:image())
portalSprite:moveTo(350, 150)
portalSprite:setZIndex(0) -- pick a zIndex relative to other game objects

-- Tower Array
local towers = {}

--Game State
local gameState = "stopped"

--Player Setup
local playerInfo = {
    playerXlocation = 50,
    playerYlocation = 200,
    playerHealth = 100,
    playerMaxHealth = 100,
    playerCollisionXLocation = 20,
    playerCollisionYLocation = 30,
    playerCollisionXSize = 10,
    playerCollisionYSize = 10,
    playerProjectileSpeed = 5,
    playerProjectileDamage = 10,
    playerAttackFrequencyTimer = 3000,
    energyTimer = 15000,
}

local playerInstance = Player(playerInfo.playerXlocation, playerInfo.playerYlocation,
                        playerInfo.playerHealth, playerInfo.playerMaxHealth, 
                        playerInfo.playerCollisionXLocation, playerInfo.playerCollisionYLocation, 
                        playerInfo.playerCollisionXSize, playerInfo.playerCollisionYSize,
                        playerInfo.playerProjectileSpeed, playerInfo.playerProjectileDamage, playerInfo.playerAttackFrequencyTimer)
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
    owlBearDamage = 5,
}

local flyingOwlInfo = {
    flyingOwlXlocation = 400,
    flyingOwlHealth = 10,
    flyingOwlMaxHealth = 10,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 1,
    flyingProjectileSpeed = 5,
    flyingProjectileDamage = 1,
    AttackFrequencyTimer = 5000,
}

local owlKingInfo = {
    owlKingXlocation = 400,
    owlKingYlocation = 210,
    owlKingHealth = 100,
    owlKingMaxHealth = 100,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 1,
    owlKingDamage = 5,
}

local bossInstance = OwlKing(owlKingInfo.owlKingXlocation, owlKingInfo.owlKingYlocation, 
                            owlKingInfo.owlKingHealth, owlKingInfo.owlKingMaxHealth, 
                            owlKingInfo.owlCollesionX, owlKingInfo.owlCollesionY, owlKingInfo.owlCollisionSizeX, 
                            owlKingInfo.owlCollisionSizeY, owlKingInfo.owlSpeed, owlKingInfo.owlKingDamage)


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
local function createEnemies(numOfEnemies)
    local enemyArray = {}
    for i = 0, numOfEnemies-1 do
        local owlBearInstance = OwlBear(owlBearInfo.owlBearXlocation, owlBearInfo.owlBearYlocation, 
                                owlBearInfo.owlBearHealth, owlBearInfo.owlBearMaxHealth, 
                                owlBearInfo.owlCollesionX, owlBearInfo.owlCollesionY, owlBearInfo.owlCollisionSizeX, 
                                owlBearInfo.owlCollisionSizeY, owlBearInfo.owlSpeed, owlBearInfo.owlBearDamage)
        table.insert(enemyArray, owlBearInstance)

        if waveNum >= 6 then
            local randomYAxis = math.random(90, 110)
            local flyingOwlInstance = FlyingOwl(flyingOwlInfo.flyingOwlXlocation, randomYAxis, 
                                    flyingOwlInfo.flyingOwlHealth, enemyArray.flyingOwlMaxHealth,
                                    flyingOwlInfo.owlCollesionX, flyingOwlInfo.owlCollesionY,
                                    flyingOwlInfo.owlCollisionSizeX, flyingOwlInfo.owlCollisionSizeY,
                                    flyingOwlInfo.owlSpeed, flyingOwlInfo.flyingProjectileSpeed,
                                    flyingOwlInfo.flyingProjectileDamage, flyingOwlInfo.AttackFrequencyTimer)
            table.insert(enemyArray, flyingOwlInstance)
        end
    end

    return enemyArray
end

local function drawEnemyHealthBars()
    if currentWaveArray then
        for i = 1, #currentWaveArray do
            if (currentWaveArray[i]:getOriginalXLocation() ~= currentWaveArray[i]:getXLocation()) and (currentWaveArray[i]:getHealth() > 0) then
                if currentWaveArray[i]:getHeatlhTag() == "OwlBear" then
                    currentWaveArray[i]:drawHealthBar(40, 5, 40)
                elseif currentWaveArray[i]:getHeatlhTag() == "FlyingOwl" then
                    currentWaveArray[i]:drawHealthBar(30, 4, 20)
                elseif currentWaveArray[i]:getHeatlhTag() == "OwlKing" then
                    currentWaveArray[i]:drawHealthBar(60, 8, 60)
                end
            end
        end
    end
end

local function ClearOwlBearArray(enemyArray)
    for i = #enemyArray, 1, -1 do
        enemyArray[i]:remove()
        table.remove(enemyArray, i)
    end
end

local function startNextWave()
    if waveNum % 5 == 0 then
        table.insert(currentWaveArray, bossInstance)
    else
        currentWaveArray = createEnemies(initNumEnemies)
    end

    local enemyArrayLength = #currentWaveArray

    if spawnTimer then
        spawnTimer:remove()
    end

    spawnTimer = pd.timer.keyRepeatTimerWithDelay(time, time, function()
        local enemy = currentWaveArray[enemyArrayLength]
    
        if enemy then
            enemy:add()
            enemyArrayLength -= 1
        end

        for i = #currentWaveArray, 1, -1 do
            if currentWaveArray[i]:getHealth() <= 0 then
                table.remove(currentWaveArray, i)
                if currentWaveArray[i]:getHeatlhTag() == "OwlKing" then
                    playerInstance:setMO(playerInstance:getMO() + 1)
                else
                    playerInstance:setCoins(playerInstance:getCoins() + 1)
                end
            end 
        end

        if #currentWaveArray == 0 then
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
                waveCompleteSound:play()
                
                startNextWave()

                -- Increase difficulty each wave
                owlBearInfo.owlSpeed += 0.1
                owlBearInfo.owlBearDamage += 0.5
                owlBearInfo.owlBearMaxHealth += 0.5
                owlBearInfo.owlBearHealth = owlBearInfo.owlBearMaxHealth
                playerInstance:setProjectileSpeed(playerInstance:getProjectSpeed() + 0.2)
                playerInstance:setProjectileDamage(playerInstance:getProjectileDamage() + 0.5)
                if not (playerInstance:getAttackFrequencyTimer() <= 1000) then
                    playerInstance:setAttackFrequencyTimer(playerInstance:getAttackFrequencyTimer() - 250)
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
    if(playerInstance:getCoins() >= specialAbilties[playerInstance:getSpecialAbility()]) then
        local scooterInstance = Scooter(scooterInfo.scooterXLocation, scooterInfo.scooterYLocation, scooterInfo.scooterDamage, 
        scooterInfo.scooterCollesionX, scooterInfo.scooterCollesionY, scooterInfo.scooterCollesionSizeX, 
        scooterInfo.scooterCollisionSizeY, scooterInfo.scooterSpeed, scooterInfo.scooterCost, scooterInfo.scooterKnockBack)

        scooterInstance:add()
        playerInstance:setCoins(playerInstance:getCoins()-(scooterInstance:getCost()))
    end
    
end

local function clearTowers()
    for i = 0, 2 do
        if towers[i] then
            towers[i]:remove()
            towers[i] = nil
        end
    end
end

local function handleTowerDestruction()
    if towers[0] and towers[0]:getHealth() <= 0 then
        towers[0]:remove()
        towers[0] = nil

        if not towers[1] and not towers[2] then
            playerInstance:setYLocation(200)
            playerInstance:moveTo(playerInstance:getXLocation(), playerInstance:getYLocation())
        end
    end

    if towers[1] and towers[1]:getHealth() > 0 and not towers[0] then
        if towers[2] and towers[2]:getHealth() > 0 then
            towers[0] = towers[1]
            towers[0]:moveTo(towers[0]:getXLocation(), towers[0]:getYLocation()+50)
            playerInstance:setYLocation(playerInstance:getYLocation() + 25)
            playerInstance:moveTo(playerInstance:getXLocation(), playerInstance:getYLocation())
            towers[1] = nil
        else
            towers[0] = towers[1]
            towers[0]:moveTo(towers[0]:getXLocation(), towers[0]:getYLocation()+50)
            playerInstance:setYLocation(playerInstance:getYLocation() + 50)
            playerInstance:moveTo(playerInstance:getXLocation(), playerInstance:getYLocation())
            towers[1] = nil
        end
    end

    if towers[2] and towers[2]:getHealth() > 0 and not towers[1] then
        if not towers[1] then
            towers[1] = towers[2]
            towers[1]:moveTo(towers[1]:getXLocation(), towers[1]:getYLocation()+50)
            playerInstance:setYLocation(playerInstance:getYLocation() + 20)
            playerInstance:moveTo(playerInstance:getXLocation(), playerInstance:getYLocation())
            towers[2] = nil
        end
    end

end

--Play Game
local function playGame()
    gameState = "playing"
    if mainmenuMusic:isPlaying() then
        mainmenuMusic:stop()
        backgroundMusic:play(0,1)
    end

    drawBackground()
    playerInstance:add()
    playerInstance:setHealth(playerInfo.playerHealth)
    playerInstance:setSepecialAbility("scooter")
    portalSprite:add()
    startNextWave()
end

--Gamer Over
local function endGame()
    playerInstance:remove()
    playerInstance.handSprite:remove()
    playerInstance:setCoins(0)
    spawnTimer:remove()
    ClearOwlBearArray(currentWaveArray)
    clearTowers()
    waveNum = 1
    initNumEnemies = 4
    currentWaveArray = {}
    --Remove background
    clearBackground()
    gfx.clear()

    if backgroundMusic:isPlaying() then
        backgroundMusic:stop()
    end

    --clear all sprites
    gfx.sprite.removeAll()
    --Reset Game State
    gameState = "stopped"
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

--Update
function pd.update()
    gfx.sprite.update()
    if gameState == "stopped" then
        
        if not mainmenuMusic:isPlaying() then
            mainmenuMusic:play(0,1)
        end

        gfx.clear(gfx.kColorWhite)
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
        gfx.drawText(tostring(waveNum), 195, 5)
        gfx.drawText("Feathers: " .. playerInstance:getCoins(), 300, 3)
        gfx.drawText("MO: " .. playerInstance:getMO(), 347, 20)
    
        if pd.buttonJustPressed(pd.kButtonB) then
            if (playerInstance:getSpecialAbility() == "scooter") then spawnScooter() end
        end

        if pd.buttonIsPressed(pd.kButtonUp) then
            for i = 0, 2 do
                if towers[i] == nil then
                    towers[i] = Tower:spawnTower(playerInstance)
                    playerInstance:setYLocation(playerInstance:getYLocation() - 50)
                    playerInstance:moveTo(playerInstance:getXLocation(), playerInstance:getYLocation())
                    break
                end
            end
        end

        if towers[0] and towers[0]:getHealth() > 0 then 
            towers[0]:update() 
        else 
            handleTowerDestruction()
        end
        if towers[1] and towers[1]:getHealth() > 0 
        then 
            towers[1]:update() 
         end
        if towers[2] and towers[2]:getHealth() > 0 
        then 
            towers[2]:update() 
         end

        --Draw enemy healthbars
        drawEnemyHealthBars()
        
        --Game Over
        if playerInstance:getHealth() <= 0 then
            endGame()
        else
            --Draw Player Healthbar
             playerInstance:drawHealthBar(50, 6, 40)
        end
        
        portalSprite:setImage(portalAnimation:image())
    
    elseif gameState == "instructions" then
        drawInstructions()
    end

    pd.timer.updateTimers()
end