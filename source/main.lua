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

--Menu Sprites
local playGameImage = gfx.image.new("/images/Menu/Play.png"):scaledImage(0.65)
local instructionsImage = gfx.image.new("/images/Menu/Instructions.png"):scaledImage(0.65)
local shopImage = gfx.image.new("/images/Menu/Shop.png"):scaledImage(0.65)

--Menu Index
local rotateMenu = 0

--Icons
local featherIcon = gfx.image.new("images/Icons/FeatherIcon.png"):scaledImage(0.075)
local moIcon = gfx.image.new("images/Icons/MOIcon.png"):scaledImage(0.5)

assert( playGameImage )
assert( instructionsImage )
assert( shopImage )
assert( featherIcon )
assert( moIcon )

--sound
local backgroundMusic = pd.sound.sampleplayer.new("sounds/game.wav")
backgroundMusic:setVolume(0.2)
local mainmenuMusic = pd.sound.sampleplayer.new("sounds/mainmenu.wav")
mainmenuMusic:setVolume(0.2)
local waveCompleteSound = pd.sound.sampleplayer.new("sounds/wavecomplete.wav")
waveCompleteSound:setVolume(0.5)

--Fonts
local newFont = gfx.font.new("Fonts/ammolite_10")
gfx.setFont(newFont)

--Timers
local time = 3000
local spawnTimer

--Wave Management
local currentWaveArray = {}
local initNumEnemies = 2
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
portalSprite:setZIndex(0)

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
    playerCollisionXLocation = 10,
    playerCollisionYLocation = 0,
    playerCollisionXSize = 20,
    playerCollisionYSize = 40,
    playerProjectileSpeed = 5,
    playerProjectileDamage = 5,
    playerAttackFrequencyTimer = 3000,
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
    owlBearDamage = 25,
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
    owlKingYlocation = 150,
    owlKingHealth = 50,
    owlKingMaxHealth = 50,
    owlCollesionX = 10,
    owlCollesionY = 0,
    owlCollisionSizeX = 120,
    owlCollisionSizeY = 120,
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
    if waveNum >= 6 then
        numOfEnemies = math.floor(numOfEnemies / 2)
    end
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
                if currentWaveArray[i]:getHealthTag() == "OwlBear" then
                    currentWaveArray[i]:drawHealthBar(40, 5, 40)
                elseif currentWaveArray[i]:getHealthTag() == "FlyingOwl" then
                    currentWaveArray[i]:drawHealthBar(30, 4, 20)
                elseif currentWaveArray[i]:getHealthTag() == "OwlKing" then
                    currentWaveArray[i]:drawHealthBar(60, 8, 70)
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
        if not bossInstance or bossInstance:getHealth() <= 0 then
            bossInstance = OwlKing(owlKingInfo.owlKingXlocation, owlKingInfo.owlKingYlocation, 
                            owlKingInfo.owlKingHealth, owlKingInfo.owlKingMaxHealth, 
                            owlKingInfo.owlCollesionX, owlKingInfo.owlCollesionY, owlKingInfo.owlCollisionSizeX, 
                            owlKingInfo.owlCollisionSizeY, owlKingInfo.owlSpeed, owlKingInfo.owlKingDamage)
        end

        table.insert(currentWaveArray, bossInstance)
    else
        currentWaveArray = createEnemies(initNumEnemies)
    end

    local enemyArrayLength = #currentWaveArray


    if spawnTimer then
        spawnTimer:remove()
        spawnTimer = nil
    end

    spawnTimer = pd.timer.keyRepeatTimerWithDelay(time, time, function()
        local enemy = currentWaveArray[enemyArrayLength]
    
        if enemy then
            if enemy:getHealthTag() == "FlyingOwl" then
                enemy:SetPlayerYLocation(playerInstance:getYLocation())
            end

            enemy:add()
            enemyArrayLength -= 1
        end

        for i = #currentWaveArray, 1, -1 do
            if currentWaveArray[i]:getHealth() <= 0 then
                local defeatedEnemy = currentWaveArray[i]
                table.remove(currentWaveArray, i)
                if defeatedEnemy:getHealthTag() == "OwlKing" then
                    playerInstance:setMO(playerInstance:getMO() + 1)
                    bossInstance = nil
                else
                    playerInstance:setCoins(playerInstance:getCoins() + 1)
                end
            end 
        end

        if #currentWaveArray == 0 then
            if spawnTimer then
                spawnTimer:remove()
                spawnTimer = nil
            end
            -- Wave is done → stop timer and auto-start next wave
            spawnTimer = pd.timer.performAfterDelay(3000, function() 
                currentWaveArray = {}
                --enemyArrayLength = 0
                if spawnTimer then
                    spawnTimer:remove()
                    spawnTimer = nil
                end
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

    rotateMenu = 0

    if backgroundMusic:isPlaying() then
        backgroundMusic:stop()
    end

    --clear all sprites
    gfx.sprite.removeAll()
    --Reset Game State
    gameState = "stopped"
end

local function drawInstructions()
    rotateMenu = 0
    gfx.clear(gfx.kColorWhite)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local gameCrankIcon = gfx.image.new("images/Icons/CrankIcon.png"):scaledImage(2)
    local bIcon = gfx.image.new("images/Icons/BButtonIcon.png"):scaledImage(2)
    local upIcon = gfx.image.new("images/Icons/UpButtonIcon.png"):scaledImage(2)
    local rightIcon = gfx.image.new("images/Icons/RightButtonIcon.png"):scaledImage(2)

    -- Title
    gfx.drawTextAligned("INSTRUCTIONS", 200, 10, kTextAlignment.center)

    -- Crank Icon
    gameCrankIcon:draw(20, 40)
    gfx.drawText("Use the crank to aim your projectiles", 60, 52.5)

    -- B Button Icon
    bIcon:draw(20, 100)
    gfx.drawText("Press B to spawn your special ability", 60, 112.5)

    --UpButtonIcon
    upIcon:draw(20, 160)
    gfx.drawText("Press Up to build a tower (max 3)", 60, 172.5)

    --RightButtonIcon
    rightIcon:draw(350, 200)
    gfx.drawText("Next", 310, 212)

    --Draw Back Button
    bIcon:draw(10, 200)
    gfx.drawText("Main Menu", 50, 212)
    if pd.buttonJustPressed(pd.kButtonB) then
        gfx.clear()
        gameState = "stopped"
    end

    if pd.buttonJustPressed(pd.kButtonRight) then
        gfx.clear()
        gameState = "instructions2"
    end
end

local function drawInstructions2()
    gfx.clear(gfx.kColorWhite)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    -- Title
    gfx.drawTextAligned("INSTRUCTIONS", 200, 10, kTextAlignment.center)

    -- Feather Icon
    featherIcon:draw(20, 37.5)
    gfx.drawText("Collect feathers by defeating enemies", 60, 52.5)

    -- MO Icon
    moIcon:draw(20, 100)
    gfx.drawText("Collect Mantled Owls (MO) by defeating \nbosses", 60, 106)

    --Draw Back Button
    local bIcon = gfx.image.new("images/Icons/BButtonIcon.png"):scaledImage(2)
    bIcon:draw(10, 200)
    gfx.drawText("Main Menu", 50, 212)

    if pd.buttonJustPressed(pd.kButtonB) then
        gfx.clear()
        gameState = "stopped"
    end
end

local function drawShop()
    rotateMenu = 0
    gfx.clear(gfx.kColorWhite)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("Coming Soon", 200, 20, kTextAlignment.center)
    gfx.drawTextAligned("Press B to return to Main Menu", 200, 200, kTextAlignment.center)

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
        gfx.drawText("Owl Invasion", 48, 25)
        
        if rotateMenu == 0 then
            playGameImage:setInverted(true)
            instructionsImage:setInverted(false)
            shopImage:setInverted(false)
        elseif rotateMenu == 1 then
            playGameImage:setInverted(false)
            instructionsImage:setInverted(true)
            shopImage:setInverted(false)
        elseif rotateMenu == 2 then
            playGameImage:setInverted(false)
            instructionsImage:setInverted(false)
            shopImage:setInverted(true)
        end
            
        playGameImage:draw(10, 50)
        instructionsImage:draw(10, 100)
        shopImage:draw(10, 150)

        if pd.buttonJustPressed(pd.kButtonDown) then
            rotateMenu += 1
            if rotateMenu > 2 then
                rotateMenu = 0
            end
        elseif pd.buttonJustPressed(pd.kButtonUp) then
            rotateMenu -= 1
            if rotateMenu < 0 then
                rotateMenu = 2
            end
        end

        --Start Game
        if pd.buttonJustPressed(pd.kButtonA) then
            gfx.clear()
            if rotateMenu == 0 then
                playGame()
            elseif rotateMenu == 1 then
                gameState = "instructions"
            elseif rotateMenu == 2 then
                gameState = "shop"
            end
        end

    elseif gameState == "playing" then
        gfx.drawText(tostring(waveNum), 195, 5)
        local featherGameIcon = gfx.image.new("images/Icons/FeatherIcon.png"):scaledImage(0.045)
        featherGameIcon:draw(340, 1)
        gfx.drawText(": " .. playerInstance:getCoins(), 370, 5)

        local moIcon = gfx.image.new("images/Icons/MOIcon.png"):scaledImage(0.35)
        moIcon:draw(337, 20)
        gfx.drawText(": " .. playerInstance:getMO(), 370, 26)
    
        if pd.buttonJustPressed(pd.kButtonB) then
            if (playerInstance:getSpecialAbility() == "scooter") then spawnScooter() end
        end
        if pd.buttonIsPressed(pd.kButtonUp) then
            for i = 0, 2 do
                if towers[i] == nil then
                    towers[i] = Tower:spawnTower(playerInstance)
                    if( not towers[i] ) then
                        break
                    end

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

    elseif gameState == "instructions2" then
        drawInstructions2()

    elseif gameState == "shop" then
        drawShop()
    end

    pd.timer.updateTimers()
end