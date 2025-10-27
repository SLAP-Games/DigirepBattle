//
//  Player.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

struct Player {
    var name: String
    var pos: Int = 0        // 外周インデックス（0..15）※表示は+1して「マス1..16」
    var gold: Int = 500
}
