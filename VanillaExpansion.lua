--- STEAMODDED HEADER
--- MOD_NAME: VanillaExpansion
--- MOD_ID: vanilla_expansion
--- PREFIX: vanexp
--- MOD_AUTHOR: [nekojoe]
--- MOD_DESCRIPTION: adds stuff to the game, trying to keep it vanilla

----------------------------------------------
------------MOD CODE -------------------------

-- variables

local discover_all = false

-- ben (my testing helper)

function ben(info)
    if info then
        if type(info) == 'table' then
            sendTraceMessage('no', 'ben')
            for k, v in ipairs(info) do
                sendTraceMessage('yes', 'ben')
                sendTraceMessage(tostring(k), 'ben')
                sendTraceMessage(tostring(v), 'ben')
                sendTraceMessage('no', 'ben')
            end
        else
            sendTraceMessage(tostring(info), 'ben')
        end
    else
        sendTraceMessage('yes', 'ben')
    end
end

-- update any global values when needed

function SMODS.current_mod.reset_game_globals()
    G.GAME.vanexp_jackpot_card = pick_from_deck('jackpot')
    G.GAME.vanexp_clock_card = pick_from_deck('clock')   
end

-- function to pick a new card for jokers that pick random cards from your deck, like idol

function pick_from_deck(seed)
    local valid_cards = {}
    for k, v in ipairs(G.playing_cards) do
        if v.ability.effect ~= 'Stone Card' then
            valid_cards[#valid_cards+1] = v
        end
    end
    if valid_cards[1] then 
        local random_card = pseudorandom_element(valid_cards, pseudoseed(seed..G.GAME.round_resets.ante))
        return {
            rank = random_card.base.value,
            suit = random_card.base.suit,
            id = random_card.base.id,
        }
    else
        return {
            rank = 'Ace',
            suit = 'Spades',
            id = 14,
        }
    end
end

-- atlases

local joker_atlas = SMODS.Atlas{
    key = 'jokers',
    px = 71,
    py = 95,
    path = 'Jokers.png',
}

-- jokers

local j_professor = SMODS.Joker{
    key = 'j_professor',
    loc_txt = {
        name = 'Professor',
        text = {
            'Retrigger all',
            'played {C:attention}#1#s'
        },
    },
    config = {
        name = 'Professor',
        extra = 1,
    },
    rarity = 2,
    pos = {
        x = 1,
        y = 0,
    },
    atlas = 'jokers',
    cost = 6,
    unlocked = true,
    discovered = false or discover_all,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    set_ability = function(self, card, initial, delay_sprites)
        self.ability = self.config
    end,

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                'Ace',
            },
        }
    end,
    
    calculate = function(self, card, context)
        if context.repetition then
            if context.cardarea == G.play then
                if self.ability and self.ability.name == 'Professor' and
                context.other_card:get_id() == 14 then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = self.ability.extra,
                        card = card
                    }
                end
            end
        end
        return nil
    end,
}

local j_squared = SMODS.Joker{
    key = 'j_squared',
    loc_txt = {
        name = 'Squared Joker',
        text = {
            'Played cards with',
            '{C:attention}square{} rank give',
            '{C:mult}+#1#{} Mult when scored',
            '{C:inactive}(A, 9, 4)',
        },
    },
    config = {
        name = 'Squared Joker',
        extra = 9,
    },
    rarity = 2,
    pos = {
        x = 2,
        y = 0,
    },
    atlas = 'jokers',
    cost = 8,
    unlocked = true,
    discovered = false or discover_all,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    set_ability = function(self, card, initial, delay_sprites)
        self.ability = self.config
    end,

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                self.ability.extra,
            },
        }
    end,

    calculate = function(self, card, context)
        if context.individual then
            if context.cardarea == G.play then
                if self.ability and self.ability.name == 'Squared Joker' and
                context.other_card:get_id() == 14 or
                context.other_card:get_id() == 9 or
                context.other_card:get_id() == 4
                then
                    return {
                        mult = self.ability.extra,
                        card = self
                    }
                end
            end
        end
        return nil
    end,
}

local j_jackpot = SMODS.Joker{
    key = 'j_jackpot',
    loc_txt = {
        name = 'Jackpot',
        text = {
            'If played hand contains',
            '{C:attention}only{} three {C:attention}#1#{} of',
            '{V:1}#2#{}, each card gives',
            '{X:mult,C:white}X#3#{} Mult when scored',
            '{s:0.8}Card changes every round',
        },
    },
    config = {
        name = 'Jackpot',
        extra = 3.2,
    },
    rarity = 3,
    pos = {
        x = 3,
        y = 0,
    },
    atlas = 'jokers',
    cost = 9,
    unlocked = true,
    discovered = false or discover_all,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    set_ability = function(self, card, initial, delay_sprites)
        self.ability = self.config
    end,

    loc_vars = function(self, info_queue, card)
        if G.GAME.vanexp_jackpot_card then
            return {
                vars = {
                    G.GAME.vanexp_jackpot_card.rank,
                    G.GAME.vanexp_jackpot_card.suit,
                    self.ability.extra,
                    colours = {
                        G.C.SUITS[G.GAME.vanexp_jackpot_card.suit],
                    },
                },
            }
        else
            return {
                vars = {
                    'Ace',
                    'Spades',
                    self.ability.extra,
                    colours = {
                        G.C.SUITS['Spades'],
                    },
                },
            }
        end
    end,

    calculate = function(self, card, context)
        if G.GAME.vanexp_jackpot_card then
            if context.individual then
                if context.cardarea == G.play then
                    if self.ability and self.ability.name == 'Jackpot' and
                    -- wish i could think of a better way to do this
                    #context.full_hand == 3 and 
                    context.scoring_hand[1]:get_id() == G.GAME.vanexp_jackpot_card.id and
                    context.scoring_hand[1]:is_suit(G.GAME.vanexp_jackpot_card.suit) and
                    context.scoring_hand[2]:get_id() == G.GAME.vanexp_jackpot_card.id and
                    context.scoring_hand[2]:is_suit(G.GAME.vanexp_jackpot_card.suit) and
                    context.scoring_hand[3]:get_id() == G.GAME.vanexp_jackpot_card.id and
                    context.scoring_hand[3]:is_suit(G.GAME.vanexp_jackpot_card.suit) then
                        return {
                            x_mult = self.ability.extra,
                            colour = G.C.RED,
                            card = self
                        }
                    end
                end
            end
        end
        return nil
    end,
}

local j_clock = SMODS.Joker{
    key = 'j_clock',
    loc_txt = {
        name = 'Calling the Clock',
        text = {
            'Retrigger all',
            'played {C:attention}#1#s{}',
            '{s:0.8}Card changes every round',
        },
    },
    config = {
        name = 'Calling the Clock',
        extra = 1,
    },
    rarity = 2,
    pos = {
        x = 4,
        y = 0,
    },
    atlas = 'jokers',
    cost = 6,
    unlocked = true,
    discovered = false or discover_all,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    set_ability = function(self, card, initial, delay_sprites)
        self.ability = self.config
    end,

    loc_vars = function(self, info_queue, card)
        if G.GAME.vanexp_clock_card then
            return {
                vars = {
                    G.GAME.vanexp_clock_card.rank,
                },
            }
        else
            return {
                vars = {
                    'Ace',
                }
            }
        end
    end,

    calculate = function(self, card, context)
        if G.GAME.vanexp_clock_card then
            if context.repetition then
                if context.cardarea == G.play then
                    if self.ability and self.ability.name == 'Calling the Clock' and
                    context.other_card:get_id() == G.GAME.vanexp_clock_card.id then
                        return {
                            message = localize('k_again_ex'),
                            repetitions = self.ability.extra,
                            card = card
                        }
                    end
                end
            end
        end
        return nil
    end,
}

----------------------------------------------
------------MOD CODE END----------------------