//
//  LevelUpSheetView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import SwiftUI

struct LevelUpSheetView: View {
    @ObservedObject var vm: GameVM
    let tile: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("土地をレベルアップ").font(.headline)
            ForEach(2...5, id: \.self) { lv in
                let cost = vm.levelUpCost[lv] ?? 0
                Button("Lv\(lv) にする（\(cost)G）") {
                    vm.confirmLevelUp(tile: tile, to: lv)
                }
                .disabled(!(vm.owner.indices.contains(tile)
                            && vm.owner[tile] == vm.turn
                            && vm.level.indices.contains(tile)
                            && lv > vm.level[tile]
                            && vm.players[vm.turn].gold >= cost))
                .buttonStyle(.borderedProminent)
            }
            Button("閉じる") {
                vm.activeSpecialSheet = nil
                vm.specialPending = nil
            }
        }
        .padding()
    }
}
