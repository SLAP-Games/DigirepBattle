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
    // --- ダイス関連 ---
    case doubleDice              // ダブルダイス（サイコロ2つ振る）
    case fixNextRoll(Int)        // 次回ロールを 1..6 に固定
    case teleport(to: Int)       // 盤上の任意ノードへ
    // --- 戦闘系 ---
    case buffPower(Int)          // 戦闘力+N
    case buffDefense(Int)        // 耐久力+N
    case firstStrike             // 先制攻撃
    case poison                  // 敵に毒付与
    case reflectSkill            // 敵の特殊スキル反射
    // --- 手札操作 ---
    case drawCards(Int)          // 自分の手札を n 枚引く
    case discardOpponentCards(Int) // 相手の手札を n 枚捨てさせる
    // --- クリーチャー / 土地操作 ---
    case fullHealAnyCreature     // 任意のマスのクリーチャーを全回復
    case changeLandLevel(delta: Int) // 土地レベルを delta だけ変化（腐敗なら -1）
    case setLandTollZero         // 通行料 0（荒廃）
    case multiplyLandToll(Double)    // 通行料倍率（豊作なら 2.0）
    case damageAnyCreature(Int)  // 任意のクリーチャーにダメージ（大嵐など）
    case healHP(Int)             // 回復
    // --- 耐性条件つき全体攻撃 ---
    enum ResistCategory {
        case dry      // 乾耐性
        case water    // 水耐性
        case heat     // 熱耐性
        case cold     // 冷耐性
    }
    case aoeDamageByResist(
        category: ResistCategory,
        threshold: Int,
        amount: Int
    )
    // --- マス属性変更 ---
    enum TileKind {
        case normal
        case dry
        case water
        case heat
        case cold
    }
    case changeTileAttribute(TileKind)
    // --- 全体浄化 ---
    case purgeAllCreatures       // 全マスのクリーチャー破壊
    // --- GOLD 関連 ---
    case gainGold(Int)           // GOLD 増加（財宝）
    case stealGold(Int)          // GOLD 奪取（略奪）

    // --- 情報系 ---
    case inspectCreature         // 透視：ステータス確認
}

// 将来 Set/Dictionary でも使えるように Hashable も付ける（Equatableは自動で含まれる）
struct Card: Identifiable, Hashable {
    let id: CardID
    let kind: CardKind
    let name: String
    let symbol: String
    var cost: Int = 0
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
