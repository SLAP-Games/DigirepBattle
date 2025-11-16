//
//  Untitled.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

typealias CardID = String

enum CardKind: String {
    case creature
    case spell
}

enum SpellEffect: Equatable {
    case fixNextRoll(Int)        // 次回ロールを 1..6 に固定
    case buffPower(Int)          // 戦闘力+N
    case buffDefense(Int)        // 耐久力+N
    case teleport(to: Int)       // 盤上の任意ノードへ
    case healHP(Int)             // 回復
}

// 将来 Set/Dictionary でも使えるように Hashable も付ける（Equatableは自動で含まれる）
struct Card: Identifiable, Hashable {
    let id: CardID
    let kind: CardKind
    let name: String
    let symbol: String
    var stats: CreatureStats? = nil
    var spell: SpellEffect? = nil
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 使い間違いを避けるためのイニシャライザ補助
extension Card {
    static func creature(
        id: CardID,
        name: String,
        symbol: String,
        stats: CreatureStats
    ) -> Card {
        Card(
            id: id,
            kind: .creature,
            name: name,
            symbol: symbol,
            stats: stats,
            spell: nil
        )
    }

    static func spell(
        id: CardID,
        name: String,
        symbol: String,
        effect: SpellEffect
    ) -> Card {
        Card(
            id: id,
            kind: .spell,
            name: name,
            symbol: symbol,
            stats: nil,
            spell: effect
        )
    }
}
