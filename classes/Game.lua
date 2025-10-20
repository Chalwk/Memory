-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_floor = math.floor
local math_random = math.random
local math_min = math.min
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format

local Card = require("classes/Card")
local DeckManager = require("classes/DeckManager")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.deckManager = DeckManager.new()
    instance.cards = {}
    instance.flippedCards = {}
    instance.matchedPairs = 0
    instance.totalPairs = 0
    instance.moves = 0
    instance.score = 0
    instance.timeElapsed = 0
    instance.gameOver = false
    instance.won = false
    instance.difficulty = "medium"
    instance.deckType = "shapes" -- Only shapes now
    instance.animations = {}
    instance.combo = 0
    instance.comboTimer = 0
    instance.maxComboTime = 3
    instance.streak = 0
    instance.bonusActive = false
    instance.bonusTimer = 0
    instance.bonusType = nil

    -- Power-ups
    instance.powerUps = {
        preview = {
            name = "Memory Preview",
            description = "Briefly reveal all cards",
            cost = 3,
            available = true,
            used = false
        },
        time_freeze = {
            name = "Time Freeze",
            description = "Stop timer for 5 seconds",
            cost = 4,
            available = true,
            used = false
        },
        match_assist = {
            name = "Match Assist",
            description = "Highlight matching pairs",
            cost = 5,
            available = true,
            used = false
        }
    }
    instance.tokens = 0
    instance.globalParticles = {}

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:arrangeCards()
end

function Game:startNewGame(difficulty, deckType)
    self.difficulty = difficulty or "medium"
    self.deckType = deckType or "words"
    self.cards = {}
    self.flippedCards = {}
    self.matchedPairs = 0
    self.totalPairs = 0
    self.moves = 0
    self.score = 0
    self.timeElapsed = 0
    self.gameOver = false
    self.won = false
    self.combo = 0
    self.comboTimer = 0
    self.streak = 0
    self.bonusActive = false
    self.bonusTimer = 0
    self.bonusType = nil
    self.animations = {}
    self.globalParticles = {}
    self.tokens = 5 -- Start with some tokens

    -- Reset power-ups
    for _, powerUp in pairs(self.powerUps) do
        powerUp.used = false
        powerUp.available = true
    end

    -- Get card pairs based on difficulty
    local pairsCount = self:getPairsCount()
    self.totalPairs = pairsCount
    local cardData = self.deckManager:getCardPairs(pairsCount, self.deckType)

    -- Create card objects
    for _, data in ipairs(cardData) do
        local card = Card.new(data.id, data.content, data.cardType, 0, 0, 80, 120)
        if self.fonts then
            card:setFonts(self.fonts)
        end
        table_insert(self.cards, card)
    end

    self:arrangeCards()
end

function Game:getPairsCount()
    if self.difficulty == "easy" then return 8 end
    if self.difficulty == "medium" then return 12 end
    if self.difficulty == "hard" then return 18 end
    return 12
end

function Game:arrangeCards()
    if #self.cards == 0 then return end

    local cols, rows
    if self.difficulty == "easy" then
        cols, rows = 4, 4
    elseif self.difficulty == "medium" then
        cols, rows = 6, 4
    else -- hard
        cols, rows = 6, 6
    end

    local cardWidth = 80
    local cardHeight = 120
    local spacing = 20
    local totalWidth = cols * cardWidth + (cols - 1) * spacing
    local totalHeight = rows * cardHeight + (rows - 1) * spacing

    local startX = (self.screenWidth - totalWidth) / 2
    local startY = (self.screenHeight - totalHeight) / 2 + 40

    -- Shuffle cards before arranging
    self:shuffleCards()

    for i, card in ipairs(self.cards) do
        local col = (i - 1) % cols
        local row = math_floor((i - 1) / cols)

        card.x = startX + col * (cardWidth + spacing)
        card.y = startY + row * (cardHeight + spacing)
        card.width = cardWidth
        card.height = cardHeight
    end
end

function Game:shuffleCards()
    for i = #self.cards, 2, -1 do
        local j = math_random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Game:update(dt)
    if self.gameOver then return end

    self.timeElapsed = self.timeElapsed + dt

    -- Update combo timer
    if self.combo > 0 then
        self.comboTimer = self.comboTimer + dt
        if self.comboTimer >= self.maxComboTime then
            self.combo = 0
            self.comboTimer = 0
        end
    end

    -- Update bonus timer
    if self.bonusActive then
        self.bonusTimer = self.bonusTimer - dt
        if self.bonusTimer <= 0 then
            self.bonusActive = false
            self.bonusType = nil
        end
    end

    -- Update cards
    for _, card in ipairs(self.cards) do
        card:update(dt)
    end

    -- Update global particles
    for i = #self.globalParticles, 1, -1 do
        local particle = self.globalParticles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table_remove(self.globalParticles, i)
        end
    end

    -- Update animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration

        if anim.progress >= 1 then
            if anim.callback then
                anim.callback()
            end
            table_remove(self.animations, i)
        end
    end

    -- Check win condition
    if not self.won and self.matchedPairs >= self.totalPairs then
        self.won = true
        self.gameOver = true
        self:calculateFinalScore()
    end
end

function Game:draw()
    -- Draw cards
    for _, card in ipairs(self.cards) do
        card:draw()
    end

    -- Draw UI
    self:drawUI()

    -- Draw global particles
    self:drawGlobalParticles()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawUI()
    local uiY = 20

    -- Score and moves
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)
    love.graphics.print("Score: " .. self.score, 20, uiY)
    love.graphics.print("Moves: " .. self.moves, 20, uiY + 30)
    love.graphics.print("Pairs: " .. self.matchedPairs .. "/" .. self.totalPairs, 20, uiY + 60)

    -- Time
    local minutes = math_floor(self.timeElapsed / 60)
    local seconds = math_floor(self.timeElapsed % 60)
    love.graphics.printf(string_format("Time: %02d:%02d", minutes, seconds),
        0, uiY, self.screenWidth - 20, "right")

    -- Combo
    if self.combo > 1 then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("Combo: x" .. self.combo, self.screenWidth / 2 - 50, uiY)

        -- Combo timer bar
        local barWidth = 100
        local progress = self.comboTimer / self.maxComboTime
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("fill", self.screenWidth / 2 - 50, uiY + 25, barWidth, 5)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.rectangle("fill", self.screenWidth / 2 - 50, uiY + 25, barWidth * progress, 5)
    end

    -- Tokens
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("Tokens: " .. self.tokens, 20, uiY + 90)

    -- Draw power-up buttons
    self:drawPowerUpButtons()

    -- Bonus indicator
    if self.bonusActive then
        love.graphics.setColor(0.2, 0.8, 1, 0.8)
        love.graphics.printf("BONUS: " .. self.bonusType:upper(),
            0, uiY + 120, self.screenWidth, "center")
    end
end

function Game:drawPowerUpButtons()
    local buttonY = 150
    local buttonWidth = 140
    local buttonHeight = 40
    local spacing = 10

    local powerUpsList = {
        self.powerUps.preview,
        self.powerUps.time_freeze,
        self.powerUps.match_assist
    }

    for i, powerUp in ipairs(powerUpsList) do
        local buttonX = 20
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)

        -- Button background
        if powerUp.used then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        elseif self.tokens >= powerUp.cost then
            love.graphics.setColor(0.4, 0.6, 1, 0.8)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        end

        love.graphics.rectangle("fill", buttonX, currentY, buttonWidth, buttonHeight, 5)

        -- Button border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", buttonX, currentY, buttonWidth, buttonHeight, 5)

        -- Button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(12))

        if powerUp.used then
            love.graphics.print("USED", buttonX + 50, currentY + 14)
        else
            love.graphics.print(powerUp.name, buttonX + 10, currentY + 5)
            love.graphics.print("Cost: " .. powerUp.cost, buttonX + 10, currentY + 22)
        end
    end
end

function Game:drawGlobalParticles()
    for _, particle in ipairs(self.globalParticles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)

    if self.won then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.printf("MEMORY MASTER!", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")
    else
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")
    end

    -- Stats
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2 - 30, self.screenWidth, "center")
    love.graphics.printf("Time: " .. math_floor(self.timeElapsed) .. "s", 0, self.screenHeight / 2, self.screenWidth,
        "center")
    love.graphics.printf("Moves: " .. self.moves, 0, self.screenHeight / 2 + 30, self.screenWidth, "center")

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:handleClick(x, y)
    if self.gameOver then return end

    -- Check power-up buttons first
    if self:checkPowerUpClicks(x, y) then return end

    -- Check cards
    for _, card in ipairs(self.cards) do
        if card:isPointInside(x, y) and not card.isMatched and not card.isFlipped and #self.flippedCards < 2 then
            self:flipCard(card)
            break
        end
    end
end

function Game:flipCard(card)
    -- Prevent flipping if card is already being animated or is matched
    if card.flipDirection ~= 0 or card.isMatched then return end

    card:flipUp()
    table_insert(self.flippedCards, card)

    if #self.flippedCards == 2 then
        self.moves = self.moves + 1
        self:checkMatch()
    end
end

function Game:checkMatch()
    if #self.flippedCards ~= 2 then return end

    local card1, card2 = self.flippedCards[1], self.flippedCards[2]

    if card1.id == card2.id then
        -- Match found
        self:handleMatch()
    else
        -- No match
        self:handleMismatch()
    end
end

function Game:handleMatch()
    self.matchedPairs = self.matchedPairs + 1

    -- Calculate score
    local baseScore = 100
    local timeBonus = math.max(0, 50 - math_floor(self.timeElapsed / 10))
    local comboBonus = self.combo * 25
    local streakBonus = self.streak * 10

    local matchScore = baseScore + timeBonus + comboBonus + streakBonus
    self.score = self.score + matchScore

    -- Award token
    self.tokens = self.tokens + 1

    -- Update combo and streak
    self.combo = self.combo + 1
    self.comboTimer = 0
    self.streak = self.streak + 1

    -- Check for bonus
    if self.streak >= 3 then
        self:activateBonus("streak")
    end

    -- Immediately mark cards as matched and clear flipped cards
    for _, card in ipairs(self.flippedCards) do
        card.isMatched = true
        card:createMatchParticles()
    end
    self.flippedCards = {}

    self:createScoreParticles(matchScore)
end

function Game:handleMismatch()
    self.combo = 0
    self.streak = 0

    -- Store references to the cards that need to be flipped back
    local cardsToFlip = {}
    for _, card in ipairs(self.flippedCards) do
        table_insert(cardsToFlip, card)
    end

    -- Clear flipped cards immediately so new cards can be clicked
    self.flippedCards = {}

    -- Flip back both cards after a short delay using animation
    table_insert(self.animations, {
        type = "flip_back",
        cards = cardsToFlip,
        progress = 0,
        duration = 0.8,
        callback = function()
            for _, card in ipairs(cardsToFlip) do
                if not card.isMatched then
                    card:flipDown()
                end
            end
        end
    })
end

function Game:activateBonus(bonusType)
    self.bonusActive = true
    self.bonusType = bonusType
    self.bonusTimer = 5

    if bonusType == "streak" then
        self.score = self.score + 200
    end

    self:createBonusParticles()
end

function Game:createScoreParticles(score)
    for _ = 1, 10 do
        table_insert(self.globalParticles, {
            x = self.screenWidth / 2,
            y = self.screenHeight / 2,
            dx = (math_random() - 0.5) * 100,
            dy = (math_random() - 0.5) * 100 - 50,
            life = math_random(1.0, 2.0),
            size = math_random(3, 6),
            color = { 0.2, 0.8, 0.3 }
        })
    end
end

function Game:createBonusParticles()
    for _ = 1, 20 do
        table_insert(self.globalParticles, {
            x = self.screenWidth / 2,
            y = self.screenHeight / 2,
            dx = (math_random() - 0.5) * 150,
            dy = (math_random() - 0.5) * 150,
            life = math_random(1.5, 2.5),
            size = math_random(4, 8),
            color = { 0.2, 0.6, 1.0 }
        })
    end
end

function Game:checkPowerUpClicks(x, y)
    local buttonY = 150
    local buttonWidth = 140
    local buttonHeight = 40
    local spacing = 10

    local powerUpsList = {
        self.powerUps.preview,
        self.powerUps.time_freeze,
        self.powerUps.match_assist
    }

    for i, powerUp in ipairs(powerUpsList) do
        local buttonX = 20
        local currentY = buttonY + (i - 1) * (buttonHeight + spacing)

        if x >= buttonX and x <= buttonX + buttonWidth and
            y >= currentY and y <= currentY + buttonHeight then
            self:usePowerUp(powerUp)
            return true
        end
    end

    return false
end

function Game:usePowerUp(powerUp)
    if powerUp.used or self.tokens < powerUp.cost then return end

    self.tokens = self.tokens - powerUp.cost
    powerUp.used = true

    if powerUp == self.powerUps.preview then
        self:activatePreview()
    elseif powerUp == self.powerUps.time_freeze then
        self:activateTimeFreeze()
    elseif powerUp == self.powerUps.match_assist then
        self:activateMatchAssist()
    end
end

function Game:activatePreview()
    -- Briefly show all cards
    for _, card in ipairs(self.cards) do
        if not card.isMatched then
            card:flipUp()
        end
    end

    table_insert(self.animations, {
        type = "preview",
        progress = 0,
        duration = 2,
        callback = function()
            for _, card in ipairs(self.cards) do
                if not card.isMatched and card.isFlipped then
                    card:flipDown()
                end
            end
        end
    })
end

function Game:activateTimeFreeze()
    self.bonusActive = true
    self.bonusType = "time_freeze"
    self.bonusTimer = 5
    -- todo: In a full implementation, this would actually freeze the timer
end

function Game:activateMatchAssist()
    self.bonusActive = true
    self.bonusType = "match_assist"
    self.bonusTimer = 10
    -- todo: This would highlight matching pairs in the actual implementation
end

function Game:getCardById(id)
    for _, card in ipairs(self.cards) do
        if card.id == id then return card end
    end
    return nil
end

function Game:calculateFinalScore()
    local timeBonus = math.max(0, 1000 - math_floor(self.timeElapsed))
    local moveBonus = math.max(0, 500 - self.moves * 10)
    local perfectBonus = self.matchedPairs == self.totalPairs and 500 or 0

    self.score = self.score + timeBonus + moveBonus + perfectBonus
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.deckType)
end

function Game:isGameOver()
    return self.gameOver
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game
