-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin

local helpText = {
    "Match pairs of cards to train your memory!",
    "",
    "Features:",
    "• Combo system - chain matches for bonus points",
    "• Streak bonuses - get rewards for consecutive matches",
    "• Power-ups - use tokens to activate special abilities",
    "• Multiple difficulties with colorful shapes",
    "",
    "Power-ups:",
    "• Memory Preview - Briefly reveal all cards",
    "• Time Freeze - Stop the timer temporarily",
    "• Match Assist - Highlight matching pairs",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.difficulty = "medium"
    instance.deckType = "shapes" -- Only shapes now
    instance.title = {
        text = "MEMORY",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2
    }
    instance.showHelp = false

    instance:createMenuButtons()
    instance:createOptionsButtons()

    return instance
end

function Menu:setFonts(fonts)
    self.smallFont = fonts.small
    self.mediumFont = fonts.medium
    self.largeFont = fonts.large
    self.sectionFont = fonts.section
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
    self:updateOptionsButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        },
        {
            text = "Options",
            action = "options",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        },
        {
            text = "How to Play",
            action = "help",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        },
        {
            text = "Quit",
            action = "quit",
            width = 220,
            height = 50,
            x = 0,
            y = 0
        }
    }

    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        -- Difficulty Section
        {
            text = "Easy (8 pairs)",
            action = "diff easy",
            width = 180,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Medium (12 pairs)",
            action = "diff medium",
            width = 180,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Hard (18 pairs)",
            action = "diff hard",
            width = 180,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },

        -- Navigation
        {
            text = "Back to Menu",
            action = "back",
            width = 180,
            height = 45,
            x = 0,
            y = 0,
            section = "navigation"
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 70
    end
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local totalSectionsHeight = 200
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Difficulty buttons
    local diffButtonW, diffButtonH, diffSpacing = 180, 40, 15
    local diffTotalW = 3 * diffButtonW + 2 * diffSpacing
    local diffStartX = centerX - diffTotalW / 2
    local diffY = startY + 40

    -- Navigation
    local navY = startY + 120

    local diffIndex = 0
    for _, button in ipairs(self.optionsButtons) do
        if button.section == "difficulty" then
            button.x = diffStartX + diffIndex * (diffButtonW + diffSpacing)
            button.y = diffY
            diffIndex = diffIndex + 1
        elseif button.section == "navigation" then
            button.x = centerX - button.width / 2
            button.y = navY
        end
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateOptionsButtonPositions()
    end

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Draw animated title
    love.graphics.setColor(0.4, 0.6, 1.0)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 4)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.05)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay(screenWidth, screenHeight)
        else
            self:drawMenuButtons()
            -- Draw tagline
            love.graphics.setColor(0.8, 0.9, 1.0)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf("Train Your Brain - Match Shapes",
                0, screenHeight / 3 + 50, screenWidth, "center")
        end
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – Memory", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpOverlay(screenWidth, screenHeight)
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Help box
    local boxWidth = 700
    local boxHeight = 500
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Box background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)

    -- Box border
    love.graphics.setColor(0.4, 0.6, 1.0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf("How to Play", boxX, boxY + 20, boxWidth, "center")

    -- Help text
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.smallFont)

    local lineHeight = 22
    for i, line in ipairs(helpText) do
        local y = boxY + 80 + (i - 1) * lineHeight
        love.graphics.printf(line, boxX + 30, y, boxWidth - 60, "left")
    end

    love.graphics.setLineWidth(1)
end

function Menu:drawOptionsInterface()
    local totalSectionsHeight = 200
    local startY = (self.screenHeight - totalSectionsHeight) / 2

    -- Draw section headers
    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("Difficulty", 0, startY + 15, self.screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            self:drawButton(button)

            -- Draw selection highlight
            if button.action:sub(1, 4) == "diff" then
                local difficulty = button.action:sub(6)
                if difficulty == self.difficulty then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            end
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    love.graphics.setColor(0.25, 0.25, 0.4, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local textWidth = self.smallFont:getWidth(button.text)
    local textHeight = self.smallFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    -- If help is showing, any click closes it
    if state == "menu" and self.showHelp then
        self.showHelp = false
        return "help_close"
    end

    return nil
end

function Menu:setDifficulty(difficulty)
    self.difficulty = difficulty
end

function Menu:getDifficulty()
    return self.difficulty
end

function Menu:setDeckType(deckType)
    self.deckType = deckType
end

function Menu:getDeckType()
    return self.deckType
end

return Menu