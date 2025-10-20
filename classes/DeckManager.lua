-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_min = math.min
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert

local DeckManager = {}
DeckManager.__index = DeckManager

function DeckManager.new()
    local instance = setmetatable({}, DeckManager)
    instance:initDecks()
    return instance
end

function DeckManager:initDecks()
    self.decks = {
        shapes = self:generateShapesDeck()
    }
end

function DeckManager:generateShapesDeck()
    local shapes = {}

    -- Geometric Shapes
    table_insert(shapes, {
        type = "circle",
        color = { 0.9, 0.2, 0.2 }, -- Red
        radius = 0.4,
        animation = { type = "pulse", speed = 2 }
    })

    table_insert(shapes, {
        type = "square",
        color = { 0.2, 0.7, 0.9 }, -- Blue
        size = 0.7,
        animation = { type = "rotate", speed = 1 }
    })

    table_insert(shapes, {
        type = "triangle",
        color = { 0.3, 0.8, 0.3 }, -- Green
        size = 0.6,
        animation = { type = "pulse", speed = 1.5 }
    })

    table_insert(shapes, {
        type = "star",
        color = { 1.0, 0.8, 0.2 }, -- Yellow
        points = 5,
        outerRadius = 0.5,
        innerRadius = 0.2,
        animation = { type = "rotate", speed = 2 }
    })

    table_insert(shapes, {
        type = "hexagon",
        color = { 0.8, 0.3, 0.8 }, -- Purple
        sides = 6,
        radius = 0.4,
        animation = { type = "pulse", speed = 1.2 }
    })

    table_insert(shapes, {
        type = "diamond",
        color = { 0.2, 0.8, 0.8 }, -- Cyan
        size = 0.6,
        animation = { type = "rotate", speed = 1.8 }
    })

    table_insert(shapes, {
        type = "heart",
        color = { 0.9, 0.3, 0.5 }, -- Pink
        size = 0.5,
        animation = { type = "pulse", speed = 1.3 }
    })

    table_insert(shapes, {
        type = "cross",
        color = { 0.7, 0.7, 0.9 }, -- Light Blue
        size = 0.6,
        animation = { type = "rotate", speed = 1.4 }
    })

    -- Pattern-based Shapes
    table_insert(shapes, {
        type = "spiral",
        color = { 0.9, 0.6, 0.2 }, -- Orange
        segments = 8,
        animation = { type = "rotate", speed = 3 }
    })

    table_insert(shapes, {
        type = "gear",
        color = { 0.4, 0.4, 0.6 }, -- Steel Blue
        teeth = 8,
        outerRadius = 0.5,
        innerRadius = 0.3,
        animation = { type = "rotate", speed = 2.5 }
    })

    table_insert(shapes, {
        type = "flower",
        color = { 0.9, 0.4, 0.7 }, -- Magenta
        petals = 6,
        size = 0.5,
        animation = { type = "pulse", speed = 1.7 }
    })

    table_insert(shapes, {
        type = "sun",
        color = { 1.0, 0.9, 0.3 }, -- Gold
        rays = 12,
        size = 0.5,
        animation = { type = "rotate", speed = 1.6 }
    })

    table_insert(shapes, {
        type = "snowflake",
        color = { 0.7, 0.9, 1.0 }, -- Ice Blue
        branches = 6,
        size = 0.5,
        animation = { type = "rotate", speed = 2.2 }
    })

    table_insert(shapes, {
        type = "atom",
        color = { 0.6, 0.9, 0.4 }, -- Lime Green
        orbits = 3,
        size = 0.5,
        animation = { type = "rotate", speed = 2.8 }
    })

    table_insert(shapes, {
        type = "cogwheel",
        color = { 0.5, 0.5, 0.7 }, -- Gray Blue
        teeth = 10,
        size = 0.5,
        animation = { type = "rotate", speed = 1.9 }
    })

    table_insert(shapes, {
        type = "moon",
        color = { 0.8, 0.8, 0.3 }, -- Yellow Gray
        phase = 0.7,
        size = 0.5,
        animation = { type = "pulse", speed = 1.1 }
    })

    -- Complex Shapes
    table_insert(shapes, {
        type = "mandala",
        color = { 0.8, 0.4, 0.9 }, -- Violet
        layers = 3,
        size = 0.5,
        animation = { type = "rotate", speed = 1.3 }
    })

    table_insert(shapes, {
        type = "crystal",
        color = { 0.3, 0.8, 0.8 }, -- Teal
        points = 7,
        size = 0.5,
        animation = { type = "pulse", speed = 1.8 }
    })

    table_insert(shapes, {
        type = "nebula",
        color = { 0.7, 0.3, 0.9 }, -- Deep Purple
        swirls = 4,
        size = 0.5,
        animation = { type = "rotate", speed = 2.1 }
    })

    table_insert(shapes, {
        type = "comet",
        color = { 0.9, 0.7, 0.3 }, -- Amber
        size = 0.5,
        animation = { type = "pulse", speed = 2.4 }
    })

    table_insert(shapes, {
        type = "galaxy",
        color = { 0.4, 0.3, 0.8 }, -- Indigo
        arms = 2,
        size = 0.5,
        animation = { type = "rotate", speed = 1.5 }
    })

    return shapes
end

function DeckManager:getCardPairs(pairsCount, deckType)
    local deck = self.decks[deckType] or self.decks.shapes
    local cards = {}

    -- Shuffle the deck to get random shapes
    local shuffledDeck = {}
    for i, shape in ipairs(deck) do
        table_insert(shuffledDeck, shape)
    end

    -- Fisher-Yates shuffle
    for i = #shuffledDeck, 2, -1 do
        local j = math_random(1, i)
        shuffledDeck[i], shuffledDeck[j] = shuffledDeck[j], shuffledDeck[i]
    end

    -- Ensure we don't request more pairs than available
    local availablePairs = math_min(pairsCount, math_floor(#shuffledDeck))

    -- Create complete pairs
    for i = 1, availablePairs do
        local shape = shuffledDeck[i]

        -- Create two identical cards for the pair
        table_insert(cards, {
            id = i,
            content = shape,
            cardType = "shapes"
        })
        table_insert(cards, {
            id = i,
            content = shape,
            cardType = "shapes"
        })
    end

    -- If we need more pairs than available, duplicate some shapes
    if #cards < pairsCount * 2 then
        local neededPairs = pairsCount - math_floor(#cards / 2)
        for i = 1, neededPairs do
            local sourceIndex = ((i - 1) % availablePairs) + 1
            local sourceShape = shuffledDeck[sourceIndex]
            local newPairId = availablePairs + i

            table_insert(cards, {
                id = newPairId,
                content = sourceShape,
                cardType = "shapes"
            })
            table_insert(cards, {
                id = newPairId,
                content = sourceShape,
                cardType = "shapes"
            })
        end
    end

    -- Final shuffle to mix all cards
    for i = #cards, 2, -1 do
        local j = math_random(1, i)
        cards[i], cards[j] = cards[j], cards[i]
    end

    return cards
end

-- Method to add custom shapes to the deck
function DeckManager:addCustomShapes(customShapes)
    for _, shape in ipairs(customShapes) do
        table_insert(self.decks.shapes, shape)
    end
end

return DeckManager
