//
//  CreatureStats.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

public enum CreatureSkill: String, Equatable, Hashable {
    case attackPlus
    case attackPlus2
    case blockPlus
    case blockPlus2
    case bombSkill
    case cancelSkill
    case coldPlus
    case coldPlus2
    case deleteSkill
    case dryPlus
    case dryPlus2
    case heatPlus
    case heatPlus2
    case waterPlus
    case waterPlus2
    case criticalSkill
    case delete
    case double
    case gatherSkill
    case goldSkill
    case goldSkill2
    case harvestSkill
    case healSkill
    case poisonSkill
    case randomSkill
    case rapidSkill
    case trapSkill

    static let placeholderImageName = "blankSkill"

    var imageName: String { rawValue }

    var battleAttackBonus: Int {
        switch self {
        case .attackPlus:
            return 10
        case .attackPlus2:
            return 20
        case .gatherSkill:
            return 0 // future: +3 per same tribe
        default:
            return 0
        }
    }
}

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
    var skills: [CreatureSkill] = []

    var highestResist: Int {
        max(resistDry, resistWater, resistHeat, resistCold)
    }

    var cappedSkills: [CreatureSkill] {
        skills.cappedForBattle
    }

    var skillAttackBonus: Int {
        skills.totalBattleAttackBonus
    }

    static let defaultLizard = CreatureStats(
        hpMax: 25, affection: 3, power: 7, durability: 7,
        resistDry: 8, resistWater: 1, resistHeat: 1, resistCold: 1, cost: 30,
        skills: [.dryPlus]
    )
    static let defaultGecko = CreatureStats(
        hpMax: 25, affection: 3, power: 7, durability: 7,
        resistDry: 1, resistWater: 1, resistHeat: 1, resistCold: 8, cost: 30,
        skills: [.waterPlus]
    )
    static let defaultCrocodile = CreatureStats(
        hpMax: 30, affection: 0, power: 12, durability: 1,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 1, cost: 40,
        skills: [.attackPlus]
    )
    static let defaultSnake = CreatureStats(
        hpMax: 30, affection: 1, power: 5, durability: 5,
        resistDry: 6, resistWater: 6, resistHeat: 6, resistCold: 6, cost: 30,
        skills: [.randomSkill]
    )
    static let defaultIguana = CreatureStats(
        hpMax: 30, affection: 2, power: 10, durability: 2,
        resistDry: 1, resistWater: 1, resistHeat: 8, resistCold: 1, cost: 30,
        skills: [.heatPlus]
    )
    static let defaultTurtle = CreatureStats(
        hpMax: 35, affection: 4, power: 1, durability: 12,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 1, cost: 30,
        skills: [.blockPlus]
    )
    static let defaultFrog = CreatureStats(
        hpMax: 20, affection: 4, power: 4, durability: 4,
        resistDry: 1, resistWater: 8, resistHeat: 1, resistCold: 8, cost: 20,
        skills: [.coldPlus]
    )
    static let defaultBeardedDragon = CreatureStats(
        hpMax: 50, affection: 5, power: 12, durability: 8,
        resistDry: 10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 50,
        skills: [.dryPlus, .attackPlus]
    )
    static let defaultLeopardGecko = CreatureStats(
        hpMax: 50, affection: 6, power: 8, durability: 12,
        resistDry: 10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 50,
        skills: [.healSkill, .blockPlus]
    )
    static let defaultNileCrocodile = CreatureStats(
        hpMax: 50, affection: 0, power: 18, durability: 4,
        resistDry: 2, resistWater: 12, resistHeat: 2, resistCold: 2, cost: 70,
        skills: [.attackPlus2, .deleteSkill]
    )
    static let defaultBallPython = CreatureStats(
        hpMax: 50, affection: 3, power: 10, durability: 10,
        resistDry: 9, resistWater: 9, resistHeat: 9, resistCold: 9, cost: 50,
        skills: [.randomSkill, .waterPlus]
    )
    static let defaultGreenIguana = CreatureStats(
        hpMax: 50, affection: 2, power: 14, durability: 10,
        resistDry: 2, resistWater: 2, resistHeat: 12, resistCold: 2, cost: 50,
        skills: [.attackPlus, .heatPlus]
    )
    static let defaultStarTurtle = CreatureStats(
        hpMax: 50, affection: 5, power: 4, durability: 20,
        resistDry:  10, resistWater: 2, resistHeat: 2, resistCold: 2, cost: 70,
        skills: [.blockPlus, .dryPlus]
    )
    static let defaultHornedFrog = CreatureStats(
        hpMax: 40, affection: 6, power: 8, durability: 8,
        resistDry: 2, resistWater: 12, resistHeat: 2, resistCold: 6, cost: 30,
        skills: [.gatherSkill, .coldPlus]
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

extension Collection where Element == CreatureSkill {
    public var cappedForBattle: [CreatureSkill] {
        Array(prefix(2))
    }

    public var totalBattleAttackBonus: Int {
        cappedForBattle.reduce(0) { $0 + $1.battleAttackBonus }
    }

    public func paddedSkillImageNames(maxCount: Int = 2) -> [String] {
        let capped = cappedForBattle
        var names = capped.map { $0.imageName }
        if names.count < maxCount {
            names.append(contentsOf: Array(repeating: CreatureSkill.placeholderImageName, count: maxCount - names.count))
        }
        return names
    }
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
