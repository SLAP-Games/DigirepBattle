//
//  DeckList.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/16.
//

import SwiftUI

struct DeckList: Codable {
    // クリーチャー用：合計30枚
    var creatureSlots: [CardID: Int] = [:]
    // スペル用：合計20枚
    var spellSlots: [CardID: Int] = [:]

    static let creatureLimit = 30
    static let spellLimit = 20

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

