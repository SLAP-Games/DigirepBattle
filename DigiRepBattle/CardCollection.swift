//
//  CardCollection.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/16.
//

import Foundation

struct CardCollection: Codable {
    // 所持枚数：CardID → 枚数
    private(set) var owned: [CardID: Int] = [:]

    /// カードを増やす（ガチャや報酬など）
    mutating func add(_ id: CardID, count: Int = 1) {
        guard count > 0 else { return }
        owned[id, default: 0] += count
    }

    /// カードを減らす（分解や消滅など）
    mutating func remove(_ id: CardID, count: Int = 1) {
        guard count > 0 else { return }
        let current = owned[id, default: 0]
        let newValue = max(current - count, 0)
        if newValue == 0 {
            owned.removeValue(forKey: id)
        } else {
            owned[id] = newValue
        }
    }

    /// そのカードIDを何枚持っているか
    func count(of id: CardID) -> Int {
        owned[id] ?? 0
    }
}
