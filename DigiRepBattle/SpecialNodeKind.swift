//
//  SpecialNodeKind.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import Foundation

enum SpecialNodeKind {
    case castle   // マス1
    case tower    // マス5, マス21
}

func specialNodeKind(for index: Int) -> SpecialNodeKind? {
    switch index {      // 0始まり
    case 0:  return .castle   // マス1
    case 4:  return .tower    // マス5
    case 20: return .tower    // マス21
    default: return nil
    }
}

func isSpecialNode(_ index: Int) -> Bool {
    return specialNodeKind(for: index) != nil
}
