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
    playerHealth = 120,
    playerMaxHealth = 120,
    playerCollisionXLocation = 10,
    playerCollisionYLocation = 0,
    playerCollisionXSize = 20,
    playerCollisionYSize = 40,
    playerProjectileSpeed = 5,
    playerProjectileDamage = 6,
    playerAttackFrequencyTimer = 2400,
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
    owlBearHealth = 8,
    owlBearMaxHealth = 8,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 0.9,
    owlBearDamage = 8,
}

local flyingOwlInfo = {
    flyingOwlXlocation = 400,
    flyingOwlHealth = 6,
    flyingOwlMaxHealth = 6,
    owlCollesionX = 0,
    owlCollesionY = 0,
    owlCollisionSizeX = 65,
    owlCollisionSizeY = 65,
    owlSpeed = 1.2,
    flyingProjectileSpeed = 5,
    flyingProjectileDamage = 2,
    AttackFrequencyTimer = 4200,
}

local owlKingInfo = {
    owlKingXlocation = 400,
    owlKingYlocation = 150,
    owlKingHealth = 80,
    owlKingMaxHealth = 80,
    owlCollesionX = 10,
    owlCollesionY = 0,
    owlCollisionSizeX = 120,
    owlCollisionSizeY = 120,
    owlSpeed = 0.9,
    owlKingDamage = 12,
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
local function createEnemies(numOfEnemies, difficulty)
    local enemyArray = {}
    difficulty = difficulty or 1

    -- reduce number of melee enemies on later waves to mix variety
    if waveNum >= 6 then
        numOfEnemies = math.max(1, math.floor(numOfEnemies / 2))
    end

    for i = 0, numOfEnemies-1 do
        local scaledHealth = math.max(1, math.floor(owlBearInfo.owlBearMaxHealth * difficulty + 0.5))
        local scaledDamage = math.max(1, math.floor(owlBearInfo.owlBearDamage * difficulty + 0.5))
        local scaledSpeed = owlBearInfo.owlSpeed * (1 + (difficulty - 1) * 0.3)

        local owlBearInstance = OwlBear(
            owlBearInfo.owlBearXlocation,
            owlBearInfo.owlBearYlocation,
            scaledHealth,
            scaledHealth,
            owlBearInfo.owlCollesionX,
            owlBearInfo.owlCollesionY,
            owlBearInfo.owlCollisionSizeX,
            owlBearInfo.owlCollisionSizeY,
            scaledSpeed,
            scaledDamage
        )
        table.insert(enemyArray, owlBearInstance)

        -- On hard waves, add a flying owl per melee enemy for variety
        if waveNum >= 6 then
            local randomYAxis = math.random(90, 110)
            local fScaledHealth = math.max(1, math.floor(flyingOwlInfo.flyingOwlMaxHealth * difficulty + 0.5))
            local fScaledDamage = math.max(1, math.floor(flyingOwlInfo.flyingProjectileDamage * difficulty + 0.5))
            local fScaledSpeed = flyingOwlInfo.owlSpeed * (1 + (difficulty - 1) * 0.25)

            local flyingOwlInstance = FlyingOwl(
                flyingOwlInfo.flyingOwlXlocation,
                randomYAxis,
                fScaledHealth,
                fScaledHealth,
                flyingOwlInfo.owlCollesionX,
                flyingOwlInfo.owlCollesionY,
                flyingOwlInfo.owlCollisionSizeX,
                flyingOwlInfo.owlCollisionSizeY,
                fScaledSpeed,
                flyingOwlInfo.flyingProjectileSpeed,
                fScaledDamage,
                flyingOwlInfo.AttackFrequencyTimer
            )
            table.insert(enemyArray, flyingOwlInstance)
        end
    end

    return enemyArray
end

-- Small helper to show temporary text popups (no-fade simple implementation)
-- Popup manager for simple temporary text above player or at arbitrary coords.
local activePlayerPopups = {}
local function repositionPlayerPopups()
    -- Display active player popups in the middle of the screen stacked vertically
    local screenW, screenH = pd.display.getWidth(), pd.display.getHeight()
    local centerX, centerY = screenW / 2, screenH / 2
    for i, p in ipairs(activePlayerPopups) do
        if p then
            local removed = (p.isRemoved and p:isRemoved()) or false
            if not removed then
                -- Stack them centered: first slightly above center, subsequent below
                local offsetY = -10 + ((i - 1) * 22)
                p:moveTo(centerX, centerY + offsetY)
            end
        end
    end
end

local function showPopup(text, x, y, duration, anchor)
    duration = duration or 3000
    anchor = anchor or "none"

    local w, h = 180, 25
    local img = gfx.image.new(w, h)

    gfx.pushContext(img)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, w, h)
    gfx.setColor(gfx.kColorBlack)
    gfx.setFont(newFont)
    gfx.drawTextAligned(text, w / 2, h / 2  , kTextAlignment.center)
    gfx.popContext()

    local popup = gfx.sprite.new(img)
    popup:setZIndex(1)

    if anchor == "player" and playerInstance then
        -- place above the player and push into active list
        table.insert(activePlayerPopups, popup)
        repositionPlayerPopups()
    else
        popup:moveTo(x or (pd.display.getWidth() - 80), y or 24)
    end

    popup:add()

    local stepDelay = 60 -- ms per step
    local steps = math.max(1, math.floor(duration / stepDelay))

    for i = 1, steps do
        local t = i * stepDelay
        pd.timer.performAfterDelay(t, function()
            if not popup then return end
            local removed = (not popup) or false
            if removed then return end

            -- near the end, do a simple blink to mimic fade on monochrome screen
            if i >= steps - 4 then
                -- toggle visibility on last two frames
                popup:setVisible((i % 2) == 0)
            end

            -- final step: cleanup
            if i == steps then
                if anchor == "player" then
                    for j = #activePlayerPopups, 1, -1 do
                        if activePlayerPopups[j] == popup then
                            table.remove(activePlayerPopups, j)
                        end
                    end
                    repositionPlayerPopups()
                end
                if ((popup)) then
                    popup:remove()
                end
            end
        end)
    end
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
    -- Difficulty multiplier grows slowly with waves; cap it so game stays winnable
    local difficulty = 1 + math.min((waveNum - 1) * 0.05, 3) -- +5% per wave, max +300%

    -- Prepare wave enemies (boss every 5th)
    if waveNum % 5 == 0 then
        -- create scaled boss for the wave
        if not bossInstance or bossInstance:getHealth() <= 0 then
            local scaledBossHealth = math.max(10, math.floor(owlKingInfo.owlKingMaxHealth * difficulty + 0.5))
            local scaledBossDamage = math.max(1, math.floor(owlKingInfo.owlKingDamage * difficulty + 0.5))
            local scaledBossSpeed = owlKingInfo.owlSpeed * (1 + (difficulty - 1) * 0.2)
            bossInstance = OwlKing(
                owlKingInfo.owlKingXlocation,
                owlKingInfo.owlKingYlocation,
                scaledBossHealth,
                scaledBossHealth,
                owlKingInfo.owlCollesionX,
                owlKingInfo.owlCollesionY,
                owlKingInfo.owlCollisionSizeX,
                owlKingInfo.owlCollisionSizeY,
                scaledBossSpeed,
                scaledBossDamage
            )
        end

        currentWaveArray = { bossInstance }
    else
        currentWaveArray = createEnemies(initNumEnemies, difficulty)
    end

    local enemyArrayLength = #currentWaveArray

    if spawnTimer then
        spawnTimer:remove()
        spawnTimer = nil
    end

    spawnTimer = pd.timer.keyRepeatTimerWithDelay(time, time, function()
        local enemy = currentWaveArray[enemyArrayLength]

        if enemy then
            if enemy:getHealthTag() == "FlyingOwl" and playerInstance then
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

                    -- Reward: permanently increase player's max health by 2 and heal to full
                    local newMax = playerInstance:getMaxHealth() + 5
                    playerInstance:setMaxHealth(newMax)
                    if playerInstance.healPlayer then
                        playerInstance:healPlayer()
                    else
                        playerInstance:setHealth(playerInstance:getMaxHealth())
                    end

                    -- Buff scooter damage after boss defeat (cap to avoid runaway)
                    scooterInfo.scooterDamage = math.min(50, (scooterInfo.scooterDamage or 0) + 3)

                    -- Show feedback popups anchored to player and stacked; longer duration
                    if showPopup then
                        showPopup("+5 Health", nil, nil, 2500, "player")
                        showPopup("+3 Scooter Damage", nil, nil, 2500, "player")
                    end
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
            spawnTimer = pd.timer.performAfterDelay(1200, function()
                currentWaveArray = {}
                if spawnTimer then
                    spawnTimer:remove()
                    spawnTimer = nil
                end

                -- progress wave and gently increase enemy count (cap max)
                waveNum += 1
                initNumEnemies = math.min(12, initNumEnemies + 1)
                waveCompleteSound:play()

                -- Tweak global pacing: slightly speed up spawn rhythm but never too fast
                time = math.max(400, math.floor(time * 0.97))

                -- Remove automatic player stat inflation; keep player's growth tied to items
                -- but allow small auto-adjustments with caps to keep pace with enemies
                local pProjSpeed = math.min(12, playerInstance:getProjectSpeed() + 0.05)
                playerInstance:setProjectileSpeed(pProjSpeed)
                local pProjDamage = math.min(20, playerInstance:getProjectileDamage() + 0.1)
                playerInstance:setProjectileDamage(pProjDamage)
                if playerInstance:getAttackFrequencyTimer() > 900 then
                    playerInstance:setAttackFrequencyTimer(math.max(900, playerInstance:getAttackFrequencyTimer() - 100))
                end

                startNextWave()
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

    -- Feather Icon (row 1)
    featherIcon:draw(20, 27.5)
    gfx.drawText("Collect feathers by defeating enemies", 60, 42.5)

    -- MO Icon (row 2)
    moIcon:draw(20, 70)
    gfx.drawText("Collect Mantled Owls (MO)\nby defeating bosses", 60, 85)

    -- Scooter Icon (row 3)
    local scooterIcon = gfx.image.new("images/V-Scooter.png"):scaledImage(1)
    scooterIcon:draw(20, 112.5)
    gfx.drawText("Scooter Ability Requires 2x", 60, 127.5)
    featherIcon:draw(290, 112.5)

    -- Tower Tile Icon (row 4) — moved up to avoid overlapping bottom buttons
    local towerTileIcon = gfx.image.new("images/TowerTiles/Level1.png"):scaledImage(0.125)
    towerTileIcon:draw(20, 155)
    gfx.drawText("Each Tower Costs 3x", 60, 170)
    featherIcon:draw(225, 155)

    --Draw Back Button (bottom)
    local bIcon = gfx.image.new("images/Icons/BButtonIcon.png"):scaledImage(2)
    bIcon:draw(10, 200)
    gfx.drawText("Main Menu", 50, 212)

    local leftIcon = gfx.image.new("images/Icons/LeftButtonIcon.png"):scaledImage(2)
    leftIcon:draw(350, 200)
    gfx.drawText("Back", 310, 212)
    if pd.buttonJustPressed(pd.kButtonB) then
        gfx.clear()
        gameState = "stopped"
    end

    if pd.buttonJustPressed(pd.kButtonLeft) then
        gfx.clear()
        gameState = "instructions"
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