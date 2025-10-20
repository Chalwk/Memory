-- Memory Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

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
        words = {
            -- Neuroscience and psychology themed words
            "NEURON", "SYNAPSE", "MEMORY", "THOUGHT", "DREAM", "LEARN",
            "RECALL", "COGNITION", "FOCUS", "LOGIC", "REASON", "IDEA",
            "BRAIN", "MIND", "AWARE", "LOGIC", "INSIGHT", "WISDOM",
            "ANALYZE", "PROCESS", "PERCEPTION", "CONSCIOUS", "SUBCONSCIOUS",
            "INTUITION", "CREATIVITY", "IMAGINATION", "CONCENTRATION", "ATTENTION"
        },

        ascii = {
            -- Simple ASCII art patterns
            [[
 /\
/  \
\  /
 \/
            ]],
            [[
 ____
|    |
|____|
            ]],
            [[
  /\
 /  \
/____\
            ]],
            [[
 *
***
 *
            ]],
            [[
  /\
 /  \
----
            ]],
            [[
O
|
O
            ]],
            [[
 /\
/  \
            ]],
            [[
---
| |
---
            ]],
            [[
 /\
 \/
            ]],
            [[
*
* *
*
            ]],
            [[
----
|  |
----
            ]],
            [[
 /\
/  \
\  /
 \/
            ]]
        },

        numbers = {
            -- Mathematical sequences and patterns
            "1,1,2,3,5", "2,4,8,16,32", "1,4,9,16,25", "1,3,6,10,15",
            "1,2,4,7,11", "3,1,4,1,5", "2,7,1,8,2", "1,1,2,3,5",
            "1,2,3,5,8", "2,3,5,7,11", "1,4,7,10,13", "2,5,10,17,26",
            "π=3.14", "e=2.71", "φ=1.61", "√2=1.41", "√3=1.73", "√5=2.23"
        }
    }
end

function DeckManager:getCardPairs(pairsCount, deckType)
    local deck = self.decks[deckType] or self.decks.words
    local cards = {}
    local usedIndices = {}

    -- Ensure we don't request more pairs than available
    local availablePairs = math_min(pairsCount, math_floor(#deck / 2))

    for i = 1, availablePairs do
        local index1, index2

        -- Find first unique index
        repeat
            index1 = math_random(1, #deck)
        until not usedIndices[index1]
        usedIndices[index1] = true

        -- Find second unique index (different from first)
        repeat
            index2 = math_random(1, #deck)
        until not usedIndices[index2] and index2 ~= index1
        usedIndices[index2] = true

        -- Create card pair
        local cardData = {
            id = i,
            content = deck[index1],
            cardType = deckType
        }

        table_insert(cards, cardData)
        table_insert(cards, {
            id = i,
            content = deck[index2],
            cardType = deckType
        })
    end

    -- If we need more pairs than available in the deck, duplicate some
    if #cards < pairsCount * 2 then
        local neededPairs = pairsCount - math_floor(#cards / 2)
        for i = 1, neededPairs do
            local sourceIndex = ((i - 1) % availablePairs) + 1
            local sourceCard1 = cards[sourceIndex * 2 - 1]
            local sourceCard2 = cards[sourceIndex * 2]

            table_insert(cards, {
                id = availablePairs + i,
                content = sourceCard1.content,
                cardType = sourceCard1.cardType
            })
            table_insert(cards, {
                id = availablePairs + i,
                content = sourceCard2.content,
                cardType = sourceCard2.cardType
            })
        end
    end

    return cards
end

-- Method to add custom images to the deck
function DeckManager:addImageDeck(imagePaths)
    if not self.decks.images then
        self.decks.images = {}
    end

    for _, path in ipairs(imagePaths) do
        table_insert(self.decks.images, path)
    end
end

-- Method to add custom words to the deck
function DeckManager:addCustomWords(words)
    for _, word in ipairs(words) do
        table_insert(self.decks.words, word)
    end
end

return DeckManager