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
    instance.cardType = cardType -- "shapes"
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
    instance.animationTime = 0

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

    -- Update animation time for shape animations
    self.animationTime = self.animationTime + dt

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
    if self.cardType == "shapes" then
        self:drawShape()
    end
end

function Card:drawShape()
    local shape = self.content
    if not shape then return end

    -- Apply shape animations
    local anim = shape.animation or {}
    local scale = 1
    local rotation = 0

    if anim.type == "pulse" then
        scale = 0.9 + 0.2 * math_sin(self.animationTime * (anim.speed or 1) * math_pi * 2)
    elseif anim.type == "rotate" then
        rotation = self.animationTime * (anim.speed or 1) * math_pi * 2
    end

    love.graphics.push()
    love.graphics.rotate(rotation)
    love.graphics.scale(scale, scale)

    -- Set shape color
    love.graphics.setColor(shape.color or { 1, 1, 1 })

    -- Draw different shape types
    if shape.type == "circle" then
        local radius = (shape.radius or 0.4) * math_min(self.width, self.height) * 0.4
        love.graphics.circle("fill", 0, 0, radius)
    elseif shape.type == "square" then
        local size = (shape.size or 0.7) * math_min(self.width, self.height) * 0.4
        love.graphics.rectangle("fill", -size / 2, -size / 2, size, size)
    elseif shape.type == "triangle" then
        local size = (shape.size or 0.6) * math_min(self.width, self.height) * 0.4
        love.graphics.polygon("fill",
            0, -size / 2,
            -size / 2, size / 2,
            size / 2, size / 2
        )
    elseif shape.type == "star" then
        self:drawStar(shape.points or 5, shape.outerRadius or 0.5, shape.innerRadius or 0.2)
    elseif shape.type == "hexagon" then
        self:drawRegularPolygon(shape.sides or 6, shape.radius or 0.4)
    elseif shape.type == "diamond" then
        local size = (shape.size or 0.6) * math_min(self.width, self.height) * 0.4
        love.graphics.polygon("fill",
            0, -size / 2,
            size / 2, 0,
            0, size / 2,
            -size / 2, 0
        )
    elseif shape.type == "heart" then
        self:drawHeart(shape.size or 0.5)
    elseif shape.type == "cross" then
        self:drawCross(shape.size or 0.6)
    elseif shape.type == "spiral" then
        self:drawSpiral(shape.segments or 8)
    elseif shape.type == "gear" then
        self:drawGear(shape.teeth or 8, shape.outerRadius or 0.5, shape.innerRadius or 0.3)
    elseif shape.type == "flower" then
        self:drawFlower(shape.petals or 6, shape.size or 0.5)
    elseif shape.type == "sun" then
        self:drawSun(shape.rays or 12, shape.size or 0.5)
    elseif shape.type == "snowflake" then
        self:drawSnowflake(shape.branches or 6, shape.size or 0.5)
    elseif shape.type == "atom" then
        self:drawAtom(shape.orbits or 3, shape.size or 0.5)
    elseif shape.type == "cogwheel" then
        self:drawCogwheel(shape.teeth or 10, shape.size or 0.5)
    elseif shape.type == "moon" then
        self:drawMoon(shape.phase or 0.7, shape.size or 0.5)
    elseif shape.type == "mandala" then
        self:drawMandala(shape.layers or 3, shape.size or 0.5)
    elseif shape.type == "crystal" then
        self:drawCrystal(shape.points or 7, shape.size or 0.5)
    elseif shape.type == "nebula" then
        self:drawNebula(shape.swirls or 4, shape.size or 0.5)
    elseif shape.type == "comet" then
        self:drawComet(shape.size or 0.5)
    elseif shape.type == "galaxy" then
        self:drawGalaxy(shape.arms or 2, shape.size or 0.5)
    end

    love.graphics.pop()
end

-- Shape drawing methods
function Card:drawStar(points, outerRadius, innerRadius)
    local vertices = {}
    local maxRadius = math_min(self.width, self.height) * 0.4

    for i = 1, points * 2 do
        local angle = (i - 1) * math_pi / points
        local radius = (i % 2 == 1) and (outerRadius * maxRadius) or (innerRadius * maxRadius)
        table_insert(vertices, math_cos(angle) * radius)
        table_insert(vertices, math_sin(angle) * radius)
    end

    love.graphics.polygon("fill", vertices)
end

function Card:drawRegularPolygon(sides, radius)
    local vertices = {}
    local maxRadius = math_min(self.width, self.height) * 0.4 * radius

    for i = 1, sides do
        local angle = (i - 1) * 2 * math_pi / sides
        table_insert(vertices, math_cos(angle) * maxRadius)
        table_insert(vertices, math_sin(angle) * maxRadius)
    end

    love.graphics.polygon("fill", vertices)
end

function Card:drawHeart(size)
    local scale = math_min(self.width, self.height) * 0.4 * size
    love.graphics.push()
    love.graphics.scale(scale, scale)

    -- Draw heart using circles and triangle
    love.graphics.circle("fill", -0.3, 0, 0.3)
    love.graphics.circle("fill", 0.3, 0, 0.3)
    love.graphics.polygon("fill",
        -0.6, 0,
        0, 0.8,
        0.6, 0
    )

    love.graphics.pop()
end

function Card:drawCross(size)
    local scale = math_min(self.width, self.height) * 0.4 * size
    local armWidth = 0.2 * scale
    local armLength = 0.8 * scale

    love.graphics.rectangle("fill", -armLength / 2, -armWidth / 2, armLength, armWidth)
    love.graphics.rectangle("fill", -armWidth / 2, -armLength / 2, armWidth, armLength)
end

function Card:drawSpiral(segments)
    local maxRadius = math_min(self.width, self.height) * 0.4
    love.graphics.setLineWidth(3)

    for i = 1, segments do
        local progress = i / segments
        local angle = progress * math_pi * 4
        local radius = progress * maxRadius

        love.graphics.points(
            math_cos(angle) * radius,
            math_sin(angle) * radius
        )
    end
    love.graphics.setLineWidth(1)
end

function Card:drawGear(teeth, outerRadius, innerRadius)
    local maxRadius = math_min(self.width, self.height) * 0.4
    local vertices = {}

    for i = 1, teeth * 2 do
        local angle = (i - 1) * math_pi / teeth
        local radius = (i % 2 == 1) and (outerRadius * maxRadius) or (innerRadius * maxRadius)
        table_insert(vertices, math_cos(angle) * radius)
        table_insert(vertices, math_sin(angle) * radius)
    end

    love.graphics.polygon("fill", vertices)
end

function Card:drawFlower(petals, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    for i = 1, petals do
        local angle = (i - 1) * 2 * math_pi / petals
        love.graphics.push()
        love.graphics.rotate(angle)
        love.graphics.translate(maxRadius * 0.6, 0)
        love.graphics.scale(0.8, 0.8)
        love.graphics.rotate(-angle)
        love.graphics.ellipse("fill", 0, 0, maxRadius * 0.4, maxRadius * 0.2)
        love.graphics.pop()
    end

    -- Center circle
    love.graphics.circle("fill", 0, 0, maxRadius * 0.2)
end

function Card:drawSun(rays, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    -- Center circle
    love.graphics.circle("fill", 0, 0, maxRadius * 0.3)

    -- Rays
    for i = 1, rays do
        local angle = (i - 1) * 2 * math_pi / rays
        love.graphics.push()
        love.graphics.rotate(angle)
        love.graphics.rectangle("fill", maxRadius * 0.2, -maxRadius * 0.05, maxRadius * 0.4, maxRadius * 0.1)
        love.graphics.pop()
    end
end

function Card:drawSnowflake(branches, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size
    love.graphics.setLineWidth(2)

    for i = 1, branches do
        local angle = (i - 1) * 2 * math_pi / branches
        love.graphics.push()
        love.graphics.rotate(angle)

        -- Main branch
        love.graphics.line(0, 0, 0, maxRadius)

        -- Side branches
        love.graphics.line(maxRadius * 0.3, maxRadius * 0.3, maxRadius * 0.5, maxRadius * 0.5)
        love.graphics.line(-maxRadius * 0.3, maxRadius * 0.3, -maxRadius * 0.5, maxRadius * 0.5)

        love.graphics.pop()
    end
    love.graphics.setLineWidth(1)
end

function Card:drawAtom(orbits, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size
    love.graphics.setLineWidth(2)

    -- Nucleus
    love.graphics.circle("fill", 0, 0, maxRadius * 0.1)

    -- Electron orbits
    for i = 1, orbits do
        local radius = maxRadius * (0.2 + 0.2 * i)
        love.graphics.circle("line", 0, 0, radius)

        -- Electrons
        local electronAngle = self.animationTime * (i + 1)
        love.graphics.circle("fill",
            math_cos(electronAngle) * radius,
            math_sin(electronAngle) * radius,
            maxRadius * 0.05
        )
    end
    love.graphics.setLineWidth(1)
end

function Card:drawCogwheel(teeth, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size
    local vertices = {}

    for i = 1, teeth do
        local angle1 = (i - 1) * 2 * math_pi / teeth
        local angle2 = angle1 + math_pi / teeth

        -- Outer points
        table_insert(vertices, math_cos(angle1) * maxRadius)
        table_insert(vertices, math_sin(angle1) * maxRadius)

        -- Inner points
        table_insert(vertices, math_cos(angle2) * maxRadius * 0.7)
        table_insert(vertices, math_sin(angle2) * maxRadius * 0.7)
    end

    love.graphics.polygon("fill", vertices)
end

function Card:drawMoon(phase, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    -- Full circle (moon)
    love.graphics.circle("fill", 0, 0, maxRadius)

    -- Phase shadow
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.arc("fill", maxRadius * (phase - 0.5) * 2, 0, maxRadius,
        -math_pi / 2, math_pi / 2)
end

function Card:drawMandala(layers, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    for layer = 1, layers do
        local radius = maxRadius * (layer / layers)
        local elements = 6 + layer * 2

        for i = 1, elements do
            local angle = (i - 1) * 2 * math_pi / elements
            love.graphics.push()
            love.graphics.rotate(angle)
            love.graphics.translate(radius, 0)
            love.graphics.rotate(-angle + self.animationTime)

            if layer % 2 == 0 then
                love.graphics.circle("fill", 0, 0, radius * 0.2)
            else
                love.graphics.rectangle("fill", -radius * 0.1, -radius * 0.3,
                    radius * 0.2, radius * 0.6)
            end

            love.graphics.pop()
        end
    end
end

function Card:drawCrystal(points, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size
    local vertices = {}

    for i = 1, points do
        local angle = (i - 1) * 2 * math_pi / points
        local radius = maxRadius * (0.7 + 0.3 * math_sin(angle * 2))
        table_insert(vertices, math_cos(angle) * radius)
        table_insert(vertices, math_sin(angle) * radius)
    end

    love.graphics.polygon("fill", vertices)
end

function Card:drawNebula(swirls, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size
    love.graphics.setLineWidth(2)

    for i = 1, swirls do
        local startAngle = (i - 1) * 2 * math_pi / swirls
        for j = 1, 5 do
            local progress = j / 5
            local angle = startAngle + progress * math_pi * 2 + self.animationTime
            local radius = maxRadius * progress

            love.graphics.points(
                math_cos(angle) * radius,
                math_sin(angle) * radius
            )
        end
    end
    love.graphics.setLineWidth(1)
end

function Card:drawComet(size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    -- Comet head
    love.graphics.circle("fill", 0, 0, maxRadius * 0.2)

    -- Comet tail
    love.graphics.push()
    love.graphics.rotate(self.animationTime)
    for i = 1, 5 do
        local progress = i / 5
        local alpha = 1 - progress
        love.graphics.setColor(self.content.color[1], self.content.color[2],
            self.content.color[3], alpha)
        love.graphics.circle("fill", -maxRadius * progress * 0.8, 0,
            maxRadius * 0.1 * (1 - progress))
    end
    love.graphics.pop()
end

function Card:drawGalaxy(arms, size)
    local maxRadius = math_min(self.width, self.height) * 0.4 * size

    -- Galactic center
    love.graphics.circle("fill", 0, 0, maxRadius * 0.3)

    -- Spiral arms
    love.graphics.setLineWidth(2)
    for arm = 1, arms do
        local startAngle = (arm - 1) * 2 * math_pi / arms

        for i = 1, 20 do
            local progress = i / 20
            local angle = startAngle + progress * math_pi * 2 + self.animationTime
            local radius = maxRadius * (0.3 + progress * 0.7)

            love.graphics.points(
                math_cos(angle) * radius,
                math_sin(angle) * radius
            )
        end
    end
    love.graphics.setLineWidth(1)
end

function Card:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function Card:flipUp(sounds)
    if not self.isFlipped and self.flipDirection == 0 then
        self.isFlipped = true
        self.flipDirection = 1
        self.flipProgress = 0
        self:createFlipParticles()
        love.audio.play(sounds.card_flipup)
        return true
    end
    return false
end

function Card:flipDown(sounds)
    if self.isFlipped and self.flipDirection == 0 then
        self.isFlipped = false
        self.flipDirection = -1
        self.flipProgress = 1
        love.audio.play(sounds.card_flipdown)
        return true
    end
    return false
end

function Card:createFlipParticles()
    for _ = 1, 15 do
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
    self.isFlipped = true
    self.flipProgress = 1
    self.flipDirection = 0
end

return Card
