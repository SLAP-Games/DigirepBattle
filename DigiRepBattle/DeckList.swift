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
//            "sp-dice1": 1,
//            "sp-dice2": 1,
//            "sp-dice3": 1,
//            "sp-dice4": 1,
//            "sp-dice5": 1,
//            "sp-dice6": 2,
//            "sp-doubleDice": 2,
//            "sp-firstStrike": 2,
//            "sp-hardFang": 2,
//            "sp-sharpFang": 2,
//            "sp-poisonFang": 2,
//            "sp-hardScale": 2,
//            "sp-bigScale": 2,
//            "sp-draw2": 2,
//            "sp-deleteHand": 2
//        ]

extension DeckList {
    static var previewSample: DeckList {
        var list = DeckList()

        list.setCount(for: "cre-defaultLizard",   kind: .creature, count: 5)
        list.setCount(for: "cre-defaultCrocodile", kind: .creature, count: 5)
        list.setCount(for: "cre-defaultTurtle",   kind: .creature, count: 5)
        list.setCount(for: "cre-defaultBeardedDragon",   kind: .creature, count: 5)
        list.setCount(for: "cre-defaultHornedFrog",   kind: .creature, count: 5)
        list.setCount(for: "cre-defaultGreenIguana",   kind: .creature, count: 5)
        list.setCount(for: "cre-defaultBallPython",   kind: .creature, count: 5)

        list.setCount(for: "sp-dice1", kind: .spell, count: 12)
//        list.setCount(for: "sp-dice2", kind: .spell, count: 1)
//        list.setCount(for: "sp-dice3", kind: .spell, count: 1)
//        list.setCount(for: "sp-dice4", kind: .spell, count: 1)
//        list.setCount(for: "sp-dice5", kind: .spell, count: 1)
        list.setCount(for: "sp-dice6", kind: .spell, count: 13)
//        list.setCount(for: "sp-doubleDice", kind: .spell, count: 2)
//        list.setCount(for: "sp-firstStrike", kind: .spell, count: 2)
//        list.setCount(for: "sp-hardFang", kind: .spell, count: 2)
//        list.setCount(for: "sp-sharpFang", kind: .spell, count: 2)
//        list.setCount(for: "sp-poisonFang", kind: .spell, count: 12)
//        list.setCount(for: "sp-hardScale", kind: .spell, count: 2)
//        list.setCount(for: "sp-bigScale", kind: .spell, count: 2)
//        list.setCount(for: "sp-draw2", kind: .spell, count: 2)
//        list.setCount(for: "sp-deleteHand", kind: .spell, count: 2)
//        list.setCount(for: "sp-elixir", kind: .spell, count: 13)
//        list.setCount(for: "sp-decay", kind: .spell, count: 25)

        return list
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

