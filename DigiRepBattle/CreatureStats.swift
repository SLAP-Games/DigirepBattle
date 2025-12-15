//
//  CreatureStats.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

struct CreatureStats: Equatable {
    var hpMax: Int
    var affection: Int
    var power: Int
    var durability: Int
    var resistDry: Int
    var resistWater: Int
    var resistHeat: Int
    var resistCold: Int
    let cost: Int

    var highestResist: Int {
        max(resistDry, resistWater, resistHeat, resistCold)
    }

    static let defaultLizard = CreatureStats(
        hpMax: 25, affection: 3, power: 7, durability: 7,
        resistDry: 8, resistWater: 1, resistHeat: 1, resistCold: 1, cost: 30
    )
    static let defaultGecko = CreatureStats(
        hpMax: 25, affection: 3, power: 7, durability: 7,
        resistDry: 1, resistWater: 1, resistHeat: 1, resistCold: 8, cost: 30
    )
    static let defaultCrocodile = CreatureStats(
        hpMax: 30, affection: 0, power: 12, durability: 1,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 1, cost: 40
    )
    static let defaultSnake = CreatureStats(
        hpMax: 30, affection: 1, power: 5, durability: 5,
        resistDry: 6, resistWater: 6, resistHeat: 6, resistCold: 6, cost: 30
    )
    static let defaultIguana = CreatureStats(
        hpMax: 30, affection: 2, power: 10, durability: 2,
        resistDry: 1, resistWater: 1, resistHeat: 8, resistCold: 1, cost: 30
    )
    static let defaultTurtle = CreatureStats(
        hpMax: 35, affection: 4, power: 1, durability: 12,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 1, cost: 30
    )
    static let defaultFrog = CreatureStats(
        hpMax: 20, affection: 4, power: 4, durability: 4,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 8, cost: 20
    )
    static let defaultBeardedDragon = CreatureStats(
        hpMax: 50, affection: 5, power: 12, durability: 8,
        resistDry: 10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 50
    )
    static let defaultLeopardGecko = CreatureStats(
        hpMax: 50, affection: 6, power: 8, durability: 12,
        resistDry: 10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 50
    )
    static let defaultNileCrocodile = CreatureStats(
        hpMax: 50, affection: 0, power: 18, durability: 4,
        resistDry: 2, resistWater: 12, resistHeat: 2, resistCold: 2, cost: 70
    )
    static let defaultBallPython = CreatureStats(
        hpMax: 50, affection: 3, power: 10, durability: 10,
        resistDry: 9, resistWater: 9, resistHeat: 9, resistCold: 9, cost: 50
    )
    static let defaultGreenIguana = CreatureStats(
        hpMax: 50, affection: 2, power: 14, durability: 10,
        resistDry: 2, resistWater: 2, resistHeat: 12, resistCold: 2, cost: 50
    )
    static let defaultStarTurtle = CreatureStats(
        hpMax: 50, affection: 5, power: 4, durability: 20,
        resistDry:  10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 70
    )
    static let defaultHornedFrog = CreatureStats(
        hpMax: 40, affection: 6, power: 8, durability: 8,
        resistDry: 2, resistWater: 12, resistHeat: 2, resistCold: 6, cost: 30
    )
    
}

struct Creature: Identifiable, Equatable {
    let id: String
    let owner: Int        // 0=You, 1=CPU
    var imageName: String
    var stats: CreatureStats  // 基礎能力（種のテンプレを束ねる）
    var hp: Int               // 現在HP（最大は stats.hpMax）

    // 将来の拡張余地（鑑定や装備、バフ/デバフ）
    var revealed: RevealLevel = .hpOnly
    var buffs: [Buff] = []
}

// 鑑定や可視化方針を切り替えやすく
enum RevealLevel {
    case none       // 何も見せない（使わない想定）
    case hpOnly     // 敵の基本
    case full       // 自分 or 鑑定アイテム適用時
}

// 例：バフの型（必要になったら）
struct Buff: Equatable {
    enum Kind { case powerUp, guardUp, resistAllUp }
    let kind: Kind
    let amount: Int
    let untilTurn: Int
}
