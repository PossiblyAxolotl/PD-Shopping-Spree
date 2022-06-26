-- PossiblyAxolotl
-- June 24th, 2022 to June 27th, 2022
-- Shopping spree

-- I am well aware that if you are touching an enemy and item at the same time no collision is counted 
-- I am simply lazy and there's not enough jam time left to fix it

-- IMPORTS
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/math"
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

-- sprites
local tSquare = gfx.imagetable.new("gfx/square")
local tPlayer = gfx.imagetable.new("gfx/player")
local tEnemy = gfx.imagetable.new("gfx/enemy")
local tButton = gfx.imagetable.new("gfx/button")
local imgCart = gfx.image.new("gfx/cart")
local imgLogo = gfx.image.new("gfx/logo")
local imgTile = gfx.image.new("gfx/floor")
local imgSecurity = gfx.image.new("gfx/security")
local imgComic = gfx.image.new("gfx/comic")
assert(tSquare)
assert(tPlayer)
assert(tEnemy)
assert(tButton)
assert(imgCart)
assert(imgLogo)
assert(imgTile)
assert(imgSecurity)
assert(imgComic)

local animPlayer = gfx.animation.loop.new(150,tPlayer)
local animEnemy = gfx.animation.loop.new(200,tEnemy)
local animButton = gfx.animation.loop.new(300,tButton)

local sprSquare = gfx.sprite.new(tSquare[1])
local sprPlayer = gfx.sprite.new()
local sprEnemies = gfx.sprite.new()
sprSquare:setCollideRect(0,0,18,18)
sprPlayer:setCollideRect(6,2,22,34)
sprPlayer:setZIndex(2)
sprEnemies:setCollideRect(11,18,10,10)
sprSquare:add()
sprSquare:moveTo(50,50)
sprPlayer:add()
sprEnemies:add()

-- sfx
local sfxCollect = playdate.sound.sampleplayer.new("sfx/collect")
local sfxLose = playdate.sound.sampleplayer.new("sfx/lose")
local sfxPlay = playdate.sound.sampleplayer.new("sfx/play")

local mus = playdate.sound.fileplayer.new("sfx/tree")

mus:play(0)

-- enemy vars
local enemies = {}
local rechargeTime = 80
local recharge = 80
local enemySpeed = 1
local enemyAmount = 1

-- title vars
local titleY = 400 -- -100
local titleLerpY = 0

-- other vars
local mode = "comic"

local yOffset = 240

local score = 0

local particles = {}
local shake = 0

local font = gfx.font.new("gfx/font")

-- OTHER STUFF
gfx.setLineWidth(2)
gfx.setFont(font)

--[[
playdate.graphics.sprite.setBackgroundDrawingCallback(function() 
    gfx.setDrawOffset(math.random(-1,1) * shake, math.random(-1,1) * shake + yOffset)
    imgTile:drawTiled(0,0,400,240) 
end)
]]
local menu = playdate.getSystemMenu()
menu:addMenuItem("restart", function() die() end)
menu:addCheckmarkMenuItem("night mode", function(value) playdate.display.setInverted(value) end)

math.randomseed(playdate.getSecondsSinceEpoch())

playdate.ui.crankIndicator:start()

--local cubePos = math.rad(math.random(1,359))
local cubePos = math.pi
local cubeCirc = 0

function playdate.update()
    gfx.setDrawOffset(0,0)
    if mode == "game" then
        updateGame()
    elseif mode == "comic" then -- too lazy to move to a different function. screw you.
        titleY = playdate.math.lerp(titleY,titleLerpY,0.1)
        imgComic:draw(0,titleY)

        local change = playdate.getCrankChange()
        titleLerpY -= change
        if titleLerpY > 0 then titleLerpY = 0 end
        if titleLerpY < -453 then titleLerpY = -453 end

        if playdate.buttonJustPressed(playdate.kButtonA) then
            titleLerpY = 0
            titleY = -100
            mode = "title"
            sfxCollect:play()
        end
    elseif mode == "title" then
        updateTitle()
    end

    processParticles()

    if playdate.isCrankDocked() then
        playdate.ui.crankIndicator:update()
    end
end

function collectCube(pos)
    shake = 5
    sfxCollect:play()

    sprSquare:setImage(tSquare[math.random(1,#tSquare)])

    spawnParts(sprSquare.x,sprSquare.y)
    
    score += 1

    local option = score % 3
    if option == 0 and rechargeTime > 20 then
        rechargeTime -= .5
    elseif option == 1 and enemySpeed < 10 then
        enemySpeed += .3
    elseif option == 2 and enemyAmount < 6 then
        enemyAmount += .3
    end

    cubeCirc = 0
    cubePos = pos + math.rad(math.random(-45,45) + 180)
end

function updateTitle()
    gfx.clear()
    imgLogo:draw(31,imgLogo.height/2+titleY - 40)
    titleY = playdate.math.lerp(titleY,titleLerpY,0.1)

    if titleLerpY+1 >= titleY then
        if titleLerpY == -170 then
            mode = "game"
        else
            animButton:draw(143, 200)

            if playdate.buttonJustPressed(playdate.kButtonA) then
                titleLerpY = -170
                rechargeTime = 80
                recharge = 80
                enemySpeed = 1
                enemyAmount = 1

                sfxPlay:play()
                
                cubePos = math.rad(playdate.getCrankPosition() + 180)
                
                spawnParts(143 + 57,210)
            end
        end
    end
end

function updateGame()
    -- UPDATE

    -- set important vars
    local pos = playdate.getCrankPosition()
    local change = playdate.getCrankChange()
    pos = math.rad(pos)

    -- if player is overlapping a square, move it
    if #sprSquare:overlappingSprites() > 0 then
        local spr = sprSquare:overlappingSprites()[1]
        if spr.width == 34 and spr.height == 38 then
            collectCube(pos)
        end
    end

    -- set shake var. yeah
    if shake > 0 then shake -= .2 elseif shake < 0 then shake = 0 end
    
    -- spawn enemies
    recharge -= 1

    if recharge <= 0 then
        for amnt = 1, math.floor(enemyAmount), 1 do
            local enemy = {
                x=180,
                y=100,
                dir = math.random(0,359),
                speed = enemySpeed
            }
            enemies[#enemies+1] = enemy
        end

        recharge = rechargeTime
    end

    -- DRAW
    gfx.clear()

    -- smooth transition in + drawing with shake
    yOffset = playdate.math.lerp(yOffset,0,0.1)

    gfx.setDrawOffset(math.random(-1,1) * shake, math.random(-1,1) * shake + yOffset)

    -- animate
    if change == 0 then
        animPlayer.frame = 0
    end
    
    sprPlayer:setImage(animPlayer:image())

    -- move sprites
    local nX, nY = 200 + (math.sin(pos) * 120), 120 - (math.cos(pos) * 70)
    sprPlayer:moveTo(nX, nY)
    
    sprSquare:moveTo(200 + (math.sin(cubePos) * 120), 120 - (math.cos(cubePos) * 70))

    -- yeah
    gfx.sprite.update()

    -- enemy processing and drawing
    for enemyNo = 1, #enemies, 1 do
        local enemy = enemies[enemyNo]
        enemy.x += math.sin(enemy.dir) * enemy.speed
        enemy.y -= math.cos(enemy.dir) * enemy.speed

        local flipped = playdate.graphics.kImageUnflipped
        --print(math.sin(enemy.dir))
        if math.sin(enemy.dir)< -0.01 then 
            flipped = playdate.graphics.kImageFlippedX 
        end

        animEnemy:draw(enemy.x,enemy.y, flipped)
        sprEnemies:moveTo(enemy.x,enemy.y)
        
        -- death
        if #sprEnemies:overlappingSprites() > 0  and #sprSquare:overlappingSprites() == 0 then
            die()
            break
        end
    end

    -- despawn enemies out of camera
    for enemyNo = 1, #enemies do
        local enemy = enemies[enemyNo]
        if enemy.x > 400 or enemy.x < -34 or enemy.y > 240 or enemy.y < -44 then
            table.remove(enemies,enemyNo)
            break
        end
    end

    -- draw the circle around items when they spawn
    if cubeCirc < 32 then
        cubeCirc += 1
        gfx.setColor(gfx.kColorXOR)
        gfx.fillCircleAtPoint(sprSquare.x,sprSquare.y,math.sin(cubeCirc/10) * 19)
    end

    imgSecurity:draw(200-42,120-38)

    -- overlay
    gfx.setDrawOffset(0,0)
    imgCart:draw(2,2)
    gfx.drawText(score,30,5)
end

function die()
    -- vars
    titleLerpY = 0
    mode = "title"
    yOffset = 240
    score = 0

    sfxLose:play()
    
    -- spawn particles on each enemy + other objects
    for enemy = 1, #enemies do
        spawnParts(enemies[enemy].x,enemies[enemy].y)
    end
    enemies = {}
    
    spawnParts(sprPlayer.x,sprPlayer.y)
    spawnParts(sprSquare.x,sprSquare.y)
end

-- particle functions
function spawnParts(_x,_y)
    for i = 1, 10, 1 do
        local part = {
            x = _x,
            y = _y,
            dir = math.random(0,359),
            size = math.random(10,15),
            speed = math.random(1,3)
        }
        particles[#particles+1] = part
    end
end

function processParticles()
    gfx.setColor(gfx.kColorBlack)
    for part = 1, #particles do
        local particle = particles[part]

        particle.x += math.sin(particle.dir) * particle.speed
        particle.y -= math.cos(particle.dir) * particle.speed
        gfx.fillCircleAtPoint(particle.x,particle.y,particle.size)
        particles[part].size -= .3

        if particles[part].size < 0 then particles[part].size = 0 end
    end

    for part = 1, #particles do
        if particles[part].size <= 0.1 then
            table.remove(particles, part)
            break
        end
    end
end