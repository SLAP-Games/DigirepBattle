//
//  CreatureStats.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

struct CreatureStats: Equatable {
    var hpMax: Int
    var affection: Int         // なつき度
    var power: Int             // 戦闘力
    var durability: Int        // 耐久力
    var resistDry: Int
    var resistWater: Int
    var resistHeat: Int
    var resistCold: Int

    var highestResist: Int {
        max(resistDry, resistWater, resistHeat, resistCold)
    }

    static let defaultLizard = CreatureStats(
        hpMax: 60, affection: 5, power: 12, durability: 6,
        resistDry: 3, resistWater: 2, resistHeat: 3, resistCold: 4
    )
}
