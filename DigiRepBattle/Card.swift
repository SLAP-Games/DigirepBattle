//
//  Untitled.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

enum CardKind { case spell, creature }
enum SpellEffect: Equatable {
    case fixNextRoll(Int)        // 次回ロールを 1..6 に固定（今回実装）
    // ここから将来追加予定の例：
    case buffPower(Int)          // 戦闘力+N（例）
    case buffDefense(Int)        // 耐久力+N
    case moveRelative(Int)       // 相対移動（+N / -N）
    case teleport(to: Int)       // 盤上の任意ノードへ
    case healHP(Int)             // 回復
}

// 将来 Set/Dictionary でも使えるように Hashable も付ける（Equatableは自動で含まれる）
struct Card: Identifiable, Hashable {
    let id = UUID()
    let kind: CardKind
    let name: String
    let symbol: String
    var stats: CreatureStats? = nil      // クリーチャー用（spell では nil）
    var spell: SpellEffect? = nil        // スペル用（creature では nil）

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// 使い間違いを避けるためのイニシャライザ補助
extension Card {
    static func creature(name: String, symbol: String, stats: CreatureStats) -> Card {
        Card(kind: .creature, name: name, symbol: symbol, stats: stats, spell: nil)
    }
    static func spell(name: String, symbol: String, effect: SpellEffect) -> Card {
        Card(kind: .spell, name: name, symbol: symbol, stats: nil, spell: effect)
    }
}
