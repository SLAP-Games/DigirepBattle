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
                .font(.bestTenHeadline)

            HStack(spacing: 12) {
                Button("領地\n強化", action: levelUp)
                    .buttonStyle(.borderedProminent)

                Button("デジレプ\n転送", action: moveCreature)
                    .buttonStyle(.borderedProminent)

                Button("スキル\n購入", action: buySkill)
                    .buttonStyle(.borderedProminent)

                Button("ターン\n終了", action: endTurn)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
