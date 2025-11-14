//
//  SpecialNodeMenu.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct SpecialNodeMenu: View {
    let kind: SpecialNodeKind?
    let levelUp: () -> Void
    let moveCreature: () -> Void
    let buySkill: () -> Void
    let endTurn: () -> Void

    var title: String {
        switch kind {
        case .some(.castle): return "城（ボーナスポイント）"
        case .some(.tower):  return "塔（チェックポイント）"
        case .none:          return "特別マス"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                Button("領地強化", action: levelUp)
                    .buttonStyle(.borderedProminent)

                Button("デジレプ転送", action: moveCreature)
                    .buttonStyle(.bordered)

                Button("スキル購入", action: buySkill)
                    .buttonStyle(.bordered)

                Button("ターン終了", action: endTurn)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
