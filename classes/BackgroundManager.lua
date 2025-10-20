-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.memoryParticles = {}
    instance.neuronConnections = {}
    instance.time = 0
    instance:initMemoryParticles()
    instance:initNeuronConnections()
    return instance
end

function BackgroundManager:initMemoryParticles()
    self.memoryParticles = {}
    for i = 1, 50 do
        table_insert(self.memoryParticles, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(2, 8),
            speed = math_random(10, 40),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4), -- 1: thought, 2: memory, 3: idea, 4: dream
            life = math_random(5, 15),
            maxLife = math_random(5, 15),
            color = {
                math_random(0.6, 0.9),
                math_random(0.6, 0.9),
                math_random(0.8, 1.0)
            }
        })
    end
end

function BackgroundManager:initNeuronConnections()
    self.neuronConnections = {}
    for i = 1, 20 do
        table_insert(self.neuronConnections, {
            x1 = math_random() * 1200,
            y1 = math_random() * 800,
            x2 = math_random() * 1200,
            y2 = math_random() * 800,
            pulsePhase = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.2, 1),
            active = math_random() > 0.7
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update memory particles
    for i = #self.memoryParticles, 1, -1 do
        local particle = self.memoryParticles[i]
        particle.life = particle.life - dt

        if particle.life <= 0 then
            table.remove(self.memoryParticles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

            if particle.x < -100 then particle.x = 1300 end
            if particle.x > 1300 then particle.x = -100 end
            if particle.y < -100 then particle.y = 900 end
            if particle.y > 900 then particle.y = -100 end
        end
    end

    -- Add new particles to maintain count
    while #self.memoryParticles < 50 do
        table_insert(self.memoryParticles, {
            x = math_random() * 1200,
            y = -50,
            size = math_random(2, 8),
            speed = math_random(10, 40),
            angle = math_random(0.2, 0.8) * math_pi,
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4),
            life = math_random(5, 15),
            maxLife = math_random(5, 15),
            color = {
                math_random(0.6, 0.9),
                math_random(0.6, 0.9),
                math_random(0.8, 1.0)
            }
        })
    end

    -- Update neuron connections
    for _, connection in ipairs(self.neuronConnections) do
        connection.pulsePhase = connection.pulsePhase + connection.pulseSpeed * dt
        if connection.pulsePhase > math_pi * 2 then
            connection.pulsePhase = 0
            connection.active = math_random() > 0.3
        end
    end
end

function BackgroundManager:draw(screenWidth, screenHeight, gameState)
    local time = love.timer.getTime()

    -- Brain-inspired gradient background
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 0.8 + progress * 4) + 1) * 0.05

        local r = 0.05 + progress * 0.1 + pulse
        local g = 0.08 + progress * 0.15 + pulse * 0.5
        local b = 0.15 + progress * 0.2 + pulse

        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Neuron connections (synapses)
    for _, connection in ipairs(self.neuronConnections) do
        if connection.active then
            local alpha = (math_sin(connection.pulsePhase) + 1) * 0.3
            love.graphics.setColor(0.8, 0.9, 1, alpha)
            love.graphics.setLineWidth(1 + math_sin(connection.pulsePhase) * 0.5)
            love.graphics.line(connection.x1, connection.y1, connection.x2, connection.y2)
        end
    end

    love.graphics.setLineWidth(1)

    -- Memory particles (thoughts, ideas, dreams)
    for _, particle in ipairs(self.memoryParticles) do
        local lifeProgress = particle.life / particle.maxLife
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.7 + pulse * 0.3)
        local alpha = lifeProgress * (0.3 + pulse * 0.4)

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        -- Different shapes for different memory types
        if particle.type == 1 then -- Thought (circle)
            love.graphics.circle("fill", particle.x, particle.y, currentSize)
        elseif particle.type == 2 then -- Memory (square)
            love.graphics.rectangle("fill", particle.x - currentSize, particle.y - currentSize,
                                  currentSize * 2, currentSize * 2)
        elseif particle.type == 3 then -- Idea (triangle)
            self:drawTriangle(particle.x, particle.y, currentSize)
        else -- Dream (diamond)
            self:drawDiamond(particle.x, particle.y, currentSize)
        end
    end

    -- Brain hemisphere outline in background
    love.graphics.setColor(0.3, 0.4, 0.6, 0.1)
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    local brainWidth = screenWidth * 0.6
    local brainHeight = screenHeight * 0.4

    self:drawBrainSilhouette(centerX, centerY, brainWidth, brainHeight, time)
end

function BackgroundManager:drawTriangle(x, y, size)
    love.graphics.polygon("fill",
        x, y - size,
        x - size, y + size,
        x + size, y + size
    )
end

function BackgroundManager:drawDiamond(x, y, size)
    love.graphics.polygon("fill",
        x, y - size,
        x + size, y,
        x, y + size,
        x - size, y
    )
end

function BackgroundManager:drawBrainSilhouette(centerX, centerY, width, height, time)
    local pulse = math_sin(time * 0.5) * 0.1 + 1

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(pulse, pulse)

    -- Left hemisphere
    love.graphics.arc("line", -width * 0.15, 0, width * 0.35, math_pi * 0.5, math_pi * 1.5)
    love.graphics.arc("line", -width * 0.15, -height * 0.2, width * 0.2, math_pi * 0.3, math_pi * 0.7)
    love.graphics.arc("line", -width * 0.15, height * 0.2, width * 0.2, math_pi * 1.3, math_pi * 1.7)

    -- Right hemisphere
    love.graphics.arc("line", width * 0.15, 0, width * 0.35, -math_pi * 0.5, math_pi * 0.5)
    love.graphics.arc("line", width * 0.15, -height * 0.2, width * 0.2, math_pi * 1.3, math_pi * 1.7)
    love.graphics.arc("line", width * 0.15, height * 0.2, width * 0.2, math_pi * 0.3, math_pi * 0.7)

    love.graphics.pop()
end

return BackgroundManager
-- [file content end]