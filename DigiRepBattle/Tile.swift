//
//  Tile.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

struct BoardTile: Identifiable {
    let id = UUID()
    let index: Int           // 0..15（表示は +1）
    var owner: Int? = nil    // 0=You, 1=CPU, nil=未占領
    var level: Int = 0       // 0=未占領, 1..5
    var toll: Int = 0        // Lv1=30（簡易）
    var creatureIcon: String? = nil // SFSymbol 名（例： "lizard.fill"）
}
