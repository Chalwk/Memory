-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local math_max = math.max
local math_min = math.min
local table_insert = table.insert
local table_remove = table.remove

local Card = {}
Card.__index = Card

function Card.new(id, content, cardType, x, y, width, height)
    local instance = setmetatable({}, Card)

    instance.id = id
    instance.content = content
    instance.cardType = cardType -- "words", "ascii", "numbers"
    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    instance.isFlipped = false
    instance.isMatched = false
    instance.flipProgress = 0
    instance.flipSpeed = 5
    instance.flipDirection = 0 -- 0: not flipping, 1: flipping up, -1: flipping down
    instance.hoverProgress = 0
    instance.pulsePhase = math_random() * math_pi * 2
    instance.glowIntensity = 0
    instance.particles = {}

    instance.colors = {
        background = { 0.1, 0.15, 0.25 },
        border = { 0.3, 0.5, 0.8 },
        hover = { 0.4, 0.6, 1.0 },
        matched = { 0.2, 0.8, 0.3 },
        text = { 1, 1, 1 }
    }

    return instance
end

function Card:setFonts(fonts)
    self.fonts = fonts
end

function Card:update(dt)
    -- Update flip animation
    if self.flipDirection ~= 0 then
        self.flipProgress = self.flipProgress + self.flipDirection * self.flipSpeed * dt
        self.flipProgress = math_max(0, math_min(1, self.flipProgress))

        if self.flipProgress == 0 or self.flipProgress == 1 then
            self.flipDirection = 0
        end
    end

    -- Update hover animation
    local targetHover = self:isPointInside(love.mouse.getX(), love.mouse.getY()) and 1 or 0
    self.hoverProgress = self.hoverProgress + (targetHover - self.hoverProgress) * 8 * dt

    -- Update pulse for matched cards
    if self.isMatched then
        self.pulsePhase = self.pulsePhase + dt * 2
        self.glowIntensity = (math_sin(self.pulsePhase) + 1) * 0.3
    else
        self.glowIntensity = 0
    end

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        end
    end
end

function Card:draw()
    love.graphics.push()
    love.graphics.translate(self.x + self.width / 2, self.y + self.height / 2)

    local scaleX
    if self.flipProgress <= 0.5 then
        -- First half of flip: back disappearing
        scaleX = 1 - (self.flipProgress * 2)
    else
        -- Second half of flip: front appearing
        scaleX = (self.flipProgress - 0.5) * 2
    end

    -- Ensure minimum visibility
    scaleX = math_max(0.1, scaleX)

    love.graphics.scale(scaleX, 1)

    -- Card background with rounded corners
    local bgColor = self.colors.background
    local borderColor = self.colors.border

    if self.isMatched then
        bgColor = { bgColor[1] + self.glowIntensity * 0.3,
            bgColor[2] + self.glowIntensity * 0.6,
            bgColor[3] + self.glowIntensity * 0.2 }
        borderColor = self.colors.matched
    end

    -- Hover effect
    local hoverOffset = self.hoverProgress * 3
    local hoverGlow = self.hoverProgress * 0.3

    love.graphics.setColor(borderColor[1] + hoverGlow,
        borderColor[2] + hoverGlow,
        borderColor[3] + hoverGlow,
        0.8 + hoverGlow)
    love.graphics.rectangle("fill", -self.width / 2 - 2 - hoverOffset, -self.height / 2 - 2 - hoverOffset,
        self.width + 4 + hoverOffset * 2, self.height + 4 + hoverOffset * 2, 8, 8)

    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 1)
    love.graphics.rectangle("fill", -self.width / 2, -self.height / 2, self.width, self.height, 6, 6)

    if self.isFlipped or self.flipProgress > 0.5 then
        self:drawContent()
    else
        self:drawBack()
    end

    -- Draw particles
    self:drawParticles()

    love.graphics.pop()
end

function Card:drawBack()
    -- Neural pattern back design
    love.graphics.setColor(0.2, 0.3, 0.5)

    -- Center neuron
    local neuronSize = math_min(self.width, self.height) * 0.15
    love.graphics.circle("fill", 0, 0, neuronSize)

    -- Dendrites
    love.graphics.setLineWidth(2)
    for i = 1, 8 do
        local angle = (i / 8) * math_pi * 2
        local length = math_min(self.width, self.height) * 0.3
        love.graphics.line(
            math_cos(angle) * neuronSize,
            math_sin(angle) * neuronSize,
            math_cos(angle) * length,
            math_sin(angle) * length
        )
    end
    love.graphics.setLineWidth(1)

    -- Brainwave pattern
    love.graphics.setColor(0.3, 0.4, 0.7)
    local points = {}
    for x = -self.width / 2, self.width / 2, 2 do
        local progress = (x + self.width / 2) / self.width
        local y = math_sin(progress * math_pi * 4 + self.pulsePhase) * 5
        table_insert(points, x)
        table_insert(points, y)
    end
    love.graphics.line(points)
end

function Card:drawContent()
    love.graphics.setColor(self.colors.text)

    if self.cardType == "words" or self.cardType == "numbers" then
        -- Use card font for words and numbers
        love.graphics.setFont(self.fonts.cardLarge)
        local text = tostring(self.content)
        local textWidth = self.fonts.cardLarge:getWidth(text)
        local textHeight = self.fonts.cardLarge:getHeight()

        -- Center the text
        love.graphics.print(text, -textWidth / 2, -textHeight / 2)

    elseif self.cardType == "ascii" then
        -- Use monospace font for ASCII art and scale appropriately
        love.graphics.setFont(self.fonts.ascii)
        local scale = math_min(self.width, self.height) * 0.008 -- Adjusted scale
        local lines = {}
        for line in self.content:gmatch("[^\r\n]+") do
            table_insert(lines, line)
        end

        local totalHeight = #lines * self.fonts.ascii:getHeight() * scale
        local startY = -totalHeight / 2

        for i, line in ipairs(lines) do
            local lineWidth = self.fonts.ascii:getWidth(line) * scale
            love.graphics.print(line, -lineWidth / 2, startY + (i-1) * self.fonts.ascii:getHeight() * scale, 0, scale)
        end
    end
end

function Card:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function Card:flipUp()
    if not self.isFlipped and self.flipDirection == 0 then
        self.isFlipped = true
        self.flipDirection = 1
        self:createFlipParticles()
    end
end

function Card:flipDown()
    if self.isFlipped and self.flipDirection == 0 then
        self.isFlipped = false
        self.flipDirection = -1
    end
end

function Card:createFlipParticles()
    for i = 1, 15 do
        table_insert(self.particles, {
            x = (math_random() - 0.5) * self.width * 0.8,
            y = (math_random() - 0.5) * self.height * 0.8,
            dx = (math_random() - 0.5) * 100,
            dy = (math_random() - 0.5) * 100,
            life = math_random(0.5, 1.5),
            size = math_random(2, 5),
            color = { math_random(0.6, 1.0), math_random(0.6, 1.0), math_random(0.8, 1.0) }
        })
    end
end

function Card:createMatchParticles()
    for _ = 1, 30 do
        table_insert(self.particles, {
            x = (math_random() - 0.5) * self.width,
            y = (math_random() - 0.5) * self.height,
            dx = (math_random() - 0.5) * 200,
            dy = (math_random() - 0.5) * 200,
            life = math_random(1.0, 2.0),
            size = math_random(3, 8),
            color = { 0.2, 0.8, 0.3 }
        })
    end
end

function Card:isPointInside(x, y)
    return x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height
end

function Card:setMatched()
    self.isMatched = true
    self:createMatchParticles()
end

return Card