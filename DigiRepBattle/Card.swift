//
//  Untitled.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/27.
//

import Foundation

enum CardKind { case spell, creature }

struct Card: Identifiable, Equatable {
    let id = UUID()
    let kind: CardKind
    let name: String
    let symbol: String
    var stats: CreatureStats? = nil
}
