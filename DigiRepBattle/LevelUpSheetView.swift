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
            Text("土地をレベルアップ").font(.bestTenHeadline)
            ForEach(2...5, id: \.self) { lv in
                let currentLevel = (vm.level.indices.contains(tile) ? vm.level[tile] : 0)
                let cost = vm.incrementalLevelUpCost(from: currentLevel, to: lv)
                Button("Lv\(lv) にする（\(cost ?? 0)G）") {
                    vm.confirmLevelUp(tile: tile, to: lv)
                }
                .disabled(!(vm.owner.indices.contains(tile)
                            && vm.owner[tile] == vm.turn
                            && vm.level.indices.contains(tile)
                            && lv > vm.level[tile]
                            && cost != nil
                            && vm.players[vm.turn].gold >= (cost ?? 0)))
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
