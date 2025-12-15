//
//  DeckList.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/16.
//

import SwiftUI

//プレイヤーデッキ
//        cardStates[0].deckList.creatureSlots = [
//            "cre-defaultLizard": 5,
//            "cre-defaultCrocodile": 5,
//            "cre-defaultTurtle": 5,
//            "cre-defaultBeardedDragon": 5,
//            "cre-defaultHornedFrog": 5,
//            "cre-defaultGreenIguana": 5,
//            "cre-defaultBallPython": 5
//        ]
//        cardStates[0].deckList.spellSlots = [

//        ]

extension DeckList {
    static var defaultBattleDeck: DeckList {
        var deck = DeckList()

        deck.creatureSlots = [
            "cre-defaultLizard":        5,
            "cre-defaultCrocodile":     5,
            "cre-defaultTurtle":        5,
            "cre-defaultBeardedDragon": 5,
            "cre-defaultHornedFrog":    5,
            "cre-defaultGreenIguana":   5,
            "cre-defaultBallPython":    5
            
//            "cre-defaultGreenIguana":        25
        ]

        deck.spellSlots = [
//以下テスト用
//            "sp-dice1": 25,
//            "sp-dice3": 1,
//            "sp-dice4": 25,
//            "sp-dice6": 5,
//            "sp-doubleDice": 1,
//            "sp-firstStrike": 1,
//            "sp-hardFang": 3,
//            "sp-poisonFang": 25,
//            "sp-hardScale": 1,
//            "sp-draw2": 1,
//            "sp-deleteHand": 1,
//            "sp-elixir": 25,
//            "sp-decay": 2,
//            "sp-devastation": 2,
//            "sp-harvest": 3,
//            "sp-greatStorm": 5,
//            "sp-disaster": 2,
//            "sp-poisonSmoke": 2,
//            "sp-cure": 3,
//            "sp-treasure": 25,
//            "sp-plunder": 10,
//            "sp-clairvoyance": 25,
//            "sp-blizzard": 3,
//            "sp-eruption": 6,
//            "sp-heavyRain": 6,
//            "sp-drought": 6,
//            "sp-snowMountain": 6,
//            "sp-desert": 6,
//            "sp-volcano": 6,
//            "sp-jungle": 3
            
//以下本番テスト用
            "sp-dice1": 1,
            "sp-dice2": 1,
            "sp-dice3": 1,
            "sp-dice4": 1,
            "sp-dice5": 1,
            "sp-dice6": 1,
            "sp-firstStrike": 2,
            "sp-hardFang": 2,
            "sp-poisonFang": 1,
            "sp-hardScale": 2,
            "sp-draw2": 2,
            "sp-elixir": 2,
            "sp-harvest": 2,
            "sp-greatStorm": 2,
            "sp-snowMountain": 1,
            "sp-desert": 1,
            "sp-volcano": 1,
            "sp-jungle": 1
        ]

        return deck
    }

    static var previewSample: DeckList {
        defaultBattleDeck
    }
}

struct DeckList: Codable {
    // クリーチャー用：合計35枚
    var creatureSlots: [CardID: Int] = [:]
    // スペル用：合計25枚
    var spellSlots: [CardID: Int] = [:]

    static let creatureLimit = 35
    static let spellLimit = 25

    var totalCreatures: Int {
        creatureSlots.values.reduce(0, +)
    }

    var totalSpells: Int {
        spellSlots.values.reduce(0, +)
    }

    mutating func setCount(for id: CardID, kind: CardKind, count: Int) {
        switch kind {
        case .creature:
            if count <= 0 {
                creatureSlots.removeValue(forKey: id)
            } else {
                creatureSlots[id] = count
            }
        case .spell:
            if count <= 0 {
                spellSlots.removeValue(forKey: id)
            } else {
                spellSlots[id] = count
            }
        }
    }
}

extension DeckList {
    func canSetCount(
        for id: CardID,
        kind: CardKind,
        to newCount: Int,
        collection: CardCollection
    ) -> Bool {
        guard newCount >= 0 else { return false }

        // 所持数チェック
        let owned = collection.count(of: id)
        if newCount > owned { return false }

        // 枚数上限チェック
        switch kind {
        case .creature:
            let others = totalCreatures - (creatureSlots[id] ?? 0)
            return (others + newCount) <= DeckList.creatureLimit
        case .spell:
            let others = totalSpells - (spellSlots[id] ?? 0)
            return (others + newCount) <= DeckList.spellLimit
        }
    }
    func buildDeckCards() -> [Card] {
        var cards: [Card] = []

        // クリーチャー
        for (id, count) in creatureSlots {
            guard let def = CardDatabase.definition(for: id) else { continue }
            for _ in 0..<count {
                cards.append(def.makeInstance())
            }
        }

        // スペル
        for (id, count) in spellSlots {
            guard let def = CardDatabase.definition(for: id) else { continue }
            for _ in 0..<count {
                cards.append(def.makeInstance())
            }
        }

        return cards.shuffled()
    }
}
